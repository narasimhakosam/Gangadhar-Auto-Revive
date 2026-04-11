import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';

final workerProvider = StateNotifierProvider<WorkerNotifier, AsyncValue<List<dynamic>>>((ref) {
  return WorkerNotifier();
});

class WorkerNotifier extends StateNotifier<AsyncValue<List<dynamic>>> {
  WorkerNotifier() : super(const AsyncValue.loading()) {
    fetchWorkers();
  }

  Future<void> fetchWorkers() async {
    state = const AsyncValue.loading();
    try {
      // Fetch all non-main-admin profiles from the database
      final data = await supabase
          .from('profiles')
          .select()
          .eq('is_main_admin', false)
          .order('created_at', ascending: false);
      state = AsyncValue.data(data as List<dynamic>);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> addWorker(String name, String email, String password, String role) async {
    try {
      // 1. Create the auth user via admin API (handled by Supabase Edge Function or signUp)
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );
      if (response.user == null) return false;

      // 2. Create the profile record
      await supabase.from('profiles').insert({
        'id': response.user!.id,
        'name': name,
        'email': email,
        'role': role,
      });
      
      await fetchWorkers();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateWorker(String id, String name, String email, String role, String? password) async {
    try {
      await supabase.from('profiles').update({
        'name': name,
        'email': email,
        'role': role,
      }).eq('id', id);
      
      await fetchWorkers();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteWorker(String id) async {
    try {
      // Delete the profile (cascade will handle associated records)
      await supabase.from('profiles').delete().eq('id', id);
      await fetchWorkers();
      return true;
    } catch (e) {
      return false;
    }
  }
}
