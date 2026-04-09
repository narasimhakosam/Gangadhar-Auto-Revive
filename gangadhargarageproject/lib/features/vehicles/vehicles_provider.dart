import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';

final vehicleSearchProvider = StateNotifierProvider<VehicleSearchNotifier, List<dynamic>>((ref) {
  return VehicleSearchNotifier();
});

class VehicleSearchNotifier extends StateNotifier<List<dynamic>> {
  VehicleSearchNotifier() : super([]);

  Future<void> searchVehicles(String query) async {
    try {
      final response = await apiClient.get('/vehicles', queryParameters: {'search': query});
      state = response.data;
    } catch (e) {
      state = [];
    }
  }
}

final vehicleDetailProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final response = await apiClient.get('/vehicles/$id');
  return response.data;
});
