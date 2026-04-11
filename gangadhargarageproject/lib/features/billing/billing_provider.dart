import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';

final billingProvider = Provider((ref) => BillingService());

class BillingService {
  Future<bool> createBill({
    required String vehicleId,
    required String visitId,
    required String? workerId,
    required List<Map<String, dynamic>> items,
    required double labourCharge,
    required bool isGstEnabled,
  }) async {
    try {
      // Calculate totals
      double subTotal = items.fold(0, (sum, i) => sum + (i['total_price'] as num));
      double gstAmount = isGstEnabled ? subTotal * 0.18 : 0;
      double total = subTotal + labourCharge + gstAmount;

      // Generate a unique bill number
      final billNumber = 'GAR-${DateTime.now().millisecondsSinceEpoch}';

      // Insert bill header
      final billRow = await supabase.from('bills').insert({
        'vehicle_id': vehicleId,
        'visit_id': visitId,
        'worker_id': workerId,
        'bill_number': billNumber,
        'labour_charge': labourCharge,
        'sub_total': subTotal,
        'is_gst_enabled': isGstEnabled,
        'gst_amount': gstAmount,
        'total': total,
        'status': 'Pending',
      }).select().single();

      // Insert bill items
      final billId = billRow['id'];
      final billItems = items.map((item) => {
        'bill_id': billId,
        'name': item['name'],
        'quantity': item['quantity'],
        'unit_price': item['unit_price'],
        'total_price': item['total_price'],
      }).toList();

      await supabase.from('bill_items').insert(billItems);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getBill(String id) async {
    final data = await supabase
        .from('bills')
        .select('''
          *,
          vehicles ( registration_number, model, owner_name, owner_phone ),
          bill_items ( * )
        ''')
        .eq('id', id)
        .single();
    return data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getBillsByStatus(String status) async {
    final data = await supabase
        .from('bills')
        .select('''
          *,
          vehicles ( registration_number, model, owner_name, owner_phone ),
          bill_items ( * )
        ''')
        .eq('status', status)
        .order('created_at', ascending: false);
    return data as List<dynamic>;
  }

  Future<bool> updateBillStatus(String id, String status) async {
    try {
      await supabase.from('bills').update({
        'status': status,
        if (status == 'Completed') 'completed_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getStats() async {
    final pending = await supabase
        .from('bills')
        .select('total')
        .eq('status', 'Pending');
    
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day).toIso8601String();
    final completed = await supabase
        .from('bills')
        .select('total')
        .eq('status', 'Completed')
        .gte('completed_at', startOfToday);

    final pendingTotal = (pending as List).fold<double>(0, (sum, r) => sum + ((r['total'] as num).toDouble()));
    final todayTotal = (completed as List).fold<double>(0, (sum, r) => sum + ((r['total'] as num).toDouble()));

    return {
      'Pending': {'total': pendingTotal},
      'TodayReceived': {'total': todayTotal},
    };
  }
}
