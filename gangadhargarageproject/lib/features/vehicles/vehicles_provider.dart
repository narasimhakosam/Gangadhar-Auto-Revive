import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';

final vehicleSearchProvider = StateNotifierProvider<VehicleSearchNotifier, List<dynamic>>((ref) {
  return VehicleSearchNotifier();
});

class VehicleSearchNotifier extends StateNotifier<List<dynamic>> {
  VehicleSearchNotifier() : super([]);

  Future<void> searchVehicles(String query) async {
    try {
      final q = supabase
          .from('vehicles')
          .select();
      
      final data = query.isEmpty
          ? await q.order('created_at', ascending: false).limit(20)
          : await q
              .or('registration_number.ilike.%$query%,owner_name.ilike.%$query%,owner_phone.ilike.%$query%')
              .order('created_at', ascending: false)
              .limit(20);
      state = data as List<dynamic>;
    } catch (e) {
      state = [];
    }
  }


  Future<void> loadAll() async {
    try {
      final data = await supabase
          .from('vehicles')
          .select()
          .order('created_at', ascending: false);
      state = data as List<dynamic>;
    } catch (e) {
      state = [];
    }
  }
}

final vehicleDetailProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final data = await supabase
      .from('vehicles')
      .select('''
        *,
        visits (
          *,
          profiles ( name ),
          parts ( * ),
          visit_images ( * ),
          bills ( id, bill_number, total, status )
        )
      ''')
      .eq('id', id)
      .single();
  return data as Map<String, dynamic>;
});
