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
    
    // Load a font that supports the Rupee symbol
    final fontData = await PdfGoogleFonts.notoSansRegular();
    final fontBoldData = await PdfGoogleFonts.notoSansBold();
    
    final theme = pw.ThemeData.withFont(
      base: fontData,
      bold: fontBoldData,
    );

    final items = List.from(bill['items'] ?? []);
    final vehicle = bill['vehicle'] ?? {};
    final date = DateTime.parse(bill['createdAt']).toLocal();
    final isGstEnabled = bill['isGstEnabled'] ?? false;

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
                       pw.Text('Vehicle No: ${vehicle['registrationNumber']}'),
                       if (vehicle['model'] != null) pw.Text('Model: ${vehicle['model']}'),
                       if (vehicle['ownerName'] != null) pw.Text('Owner: ${vehicle['ownerName']}'),
                       if (vehicle['ownerPhone'] != null) pw.Text('Phone: ${vehicle['ownerPhone']}'),
                     ]
                   ),
                   pw.Column(
                     crossAxisAlignment: pw.CrossAxisAlignment.end,
                     children: [
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
                    item['name'],
                    item['quantity'].toString(),
                    '₹${item['unitPrice']}',
                    '₹${item['totalPrice']}'
                  ]),
                  ['Labour Charge', '', '', '₹${bill['labourCharge']}']
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Subtotal: ₹${bill['subTotal'].toStringAsFixed(2)}'),
                      if (isGstEnabled)
                        pw.Text('GST (18%): ₹${bill['gstAmount'].toStringAsFixed(2)}'),
                      pw.SizedBox(height: 8),
                      pw.Text('Grand Total: ₹${bill['total'].toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
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
          final vehicleNo = bill['vehicle']?['registrationNumber'] ?? 'VEHICLE';

          return PdfPreview(
            build: (format) => _generatePdf(bill),
            pdfFileName: '${vehicleNo}_${billId.substring(18)}.pdf',
            canChangeOrientation: false,
            canChangePageFormat: false,
            canDebug: false,
          );
        },
      ),
    );
  }
}
