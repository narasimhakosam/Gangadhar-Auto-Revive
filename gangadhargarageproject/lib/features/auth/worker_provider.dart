import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';

final workerProvider = StateNotifierProvider<WorkerNotifier, AsyncValue<List<dynamic>>>((ref) {
  return WorkerNotifier()..fetchWorkers();
});

class WorkerNotifier extends StateNotifier<AsyncValue<List<dynamic>>> {
  WorkerNotifier() : super(const AsyncValue.loading());

  Future<void> fetchWorkers() async {
    try {
      final data = await supabase
          .from('profiles')
          .select()
          .neq('is_main_admin', true)
          .order('name', ascending: true);
      state = AsyncValue.data(data as List<dynamic>);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }


  Future<bool> addWorker(String name, String email, String password, String role) async {
    try {
      // NOTE: In a serverless Supabase setup, an admin cannot create another user's Auth account
      // without being logged out and switched to that user's session, unless using a backend Edge Function.
      
      // Recommendation: Create the auth user in the Supabase Dashboard, 
      // which will trigger the 'on_auth_user_created' profile creation automatically.
      
      // For now, we try to create a profile entry, but this may fail if RLS is strict 
      // or if the user record doesn't exist in auth.users yet.
      
      final res = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name, 'role': role},
      );

      if (res.user != null) {
        await fetchWorkers();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateWorker(String id, String name, String email, String role, [String? password]) async {
    try {
      await supabase.from('profiles').update({
        'name': name,
        'role': role,
      }).eq('id', id);
      
      if (password != null && password.isNotEmpty) {
        // Admin cannot update other user's password directly from frontend
      }
      
      await fetchWorkers();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteWorker(String id) async {
    try {
      // Note: This only deletes the profile record, not the Auth user.
      await supabase.from('profiles').delete().eq('id', id);
      await fetchWorkers();
      return true;
    } catch (e) {
      return false;
    }
  }
}
