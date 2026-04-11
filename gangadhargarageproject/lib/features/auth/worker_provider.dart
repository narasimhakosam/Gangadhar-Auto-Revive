import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
      // Save the admin's current session so we can restore it after signUp
      final adminRefreshToken = supabase.auth.currentSession?.refreshToken;

      // 1. Create the auth user
      final res = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name, 'role': role},
      );

      if (res.user != null) {
        // 2. Ensure profile exists using the REAL auth user ID
        //    (in case the database trigger didn't fire)
        try {
          await supabase.from('profiles').upsert({
            'id': res.user!.id,
            'name': name,
            'email': email,
            'role': role,
          }, onConflict: 'id');
        } catch (_) {
          // Profile may already have been created by trigger — that's fine
        }

        // 3. Restore the admin session (signUp may have swapped it)
        if (adminRefreshToken != null) {
          try {
            await supabase.auth.setSession(adminRefreshToken);
          } catch (_) {
            // If restore fails, admin will need to re-login
          }
        }

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

      await fetchWorkers();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteWorker(String id) async {
    try {
      await supabase.from('profiles').delete().eq('id', id);
      await fetchWorkers();
      return true;
    } catch (e) {
      return false;
    }
  }
}
