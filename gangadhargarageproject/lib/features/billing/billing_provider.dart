import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';

final billingProvider = Provider((ref) => BillingService());

class BillingService {
  Future<bool> createBill({
    required String vehicleId,
    required String visitId,
    required List<Map<String, dynamic>> items,
    required double labourCharge,
    required bool isGstEnabled,
  }) async {
    try {
      await apiClient.post('/billing', data: {
        'vehicleId': vehicleId,
        'visitId': visitId,
        'items': items,
        'labourCharge': labourCharge,
        'isGstEnabled': isGstEnabled,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getBill(String id) async {
    final response = await apiClient.get('/billing/$id');
    return response.data;
  }
}
