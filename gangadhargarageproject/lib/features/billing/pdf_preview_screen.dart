import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'billing_provider.dart';

class PdfPreviewScreen extends ConsumerWidget {
  final String billId;
  const PdfPreviewScreen({super.key, required this.billId});

  Future<Uint8List> _generatePdf(Map<String, dynamic> bill) async {
    final pdf = pw.Document();
    
    final fontData = await PdfGoogleFonts.notoSansRegular();
    final fontBoldData = await PdfGoogleFonts.notoSansBold();
    
    final theme = pw.ThemeData.withFont(
      base: fontData,
      bold: fontBoldData,
    );

    final items = List.from(bill['bill_items'] ?? []);
    final vehicle = bill['vehicles'] ?? {};
    
    // Safety check for date parsing
    DateTime date;
    try {
      date = DateTime.parse(bill['created_at']).toLocal();
    } catch (e) {
      date = DateTime.now();
    }

    final isGstEnabled = bill['is_gst_enabled'] ?? false;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('GANGADHAR AUTO REVIVE', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
              pw.SizedBox(height: 4),
              pw.Text('123 Auto Workshop Rd, Motor City'),
              pw.SizedBox(height: 24),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                   pw.Column(
                     crossAxisAlignment: pw.CrossAxisAlignment.start,
                     children: [
                       pw.Text('Bill To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                       pw.Text('Vehicle No: ${vehicle['registration_number'] ?? 'N/A'}'),
                       if (vehicle['model'] != null) pw.Text('Model: ${vehicle['model']}'),
                       if (vehicle['owner_name'] != null) pw.Text('Owner: ${vehicle['owner_name']}'),
                       if (vehicle['owner_phone'] != null) pw.Text('Phone: ${vehicle['owner_phone']}'),
                     ]
                   ),
                   pw.Column(
                     crossAxisAlignment: pw.CrossAxisAlignment.end,
                     children: [
                       pw.Text('Bill No: ${bill['bill_number'] ?? 'N/A'}'),
                       pw.Text('Date: ${date.day}/${date.month}/${date.year}'),
                     ]
                   )
                ]
              ),
              pw.SizedBox(height: 32),
              pw.Table.fromTextArray(
                context: context,
                border: const pw.TableBorder(
                  bottom: pw.BorderSide(color: PdfColors.grey),
                  horizontalInside: pw.BorderSide(color: PdfColors.grey300),
                ),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, font: fontData),
                cellStyle: pw.TextStyle(font: fontData),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey800),
                data: <List<String>>[
                  <String>['Description', 'Qty', 'Unit Price', 'Total'],
                  ...items.map((item) => [
                    item['name']?.toString() ?? '',
                    item['quantity']?.toString() ?? '0',
                    '₹${(item['unit_price'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                    '₹${(item['total_price'] as num?)?.toStringAsFixed(2) ?? '0.00'}'
                  ]),
                  ['Labour Charge', '', '', '₹${(bill['labour_charge'] as num?)?.toStringAsFixed(2) ?? '0.00'}']
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Subtotal: ₹${(bill['sub_total'] as num?)?.toStringAsFixed(2) ?? '0.00'}'),
                      if (isGstEnabled)
                        pw.Text('GST (18%): ₹${(bill['gst_amount'] as num?)?.toStringAsFixed(2) ?? '0.00'}'),
                      pw.SizedBox(height: 8),
                      pw.Text('Grand Total: ₹${(bill['total'] as num?)?.toStringAsFixed(2) ?? '0.00'}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
                    ]
                  )
                ]
              )
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bill Preview')),
      body: FutureBuilder(
        future: ref.read(billingProvider).getBill(billId),
        builder: (context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
             return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
             return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
             return const Center(child: Text('Bill not found'));
          }

          final bill = snapshot.data!;
          final vehicleNo = bill['vehicles']?['registration_number'] ?? 'VEHICLE';

          return PdfPreview(
            build: (format) => _generatePdf(bill),
            pdfFileName: '${vehicleNo}_${billId.substring(0, 8)}.pdf',
            canChangeOrientation: false,
            canChangePageFormat: false,
            canDebug: false,
          );
        },
      ),
    );
  }
}
