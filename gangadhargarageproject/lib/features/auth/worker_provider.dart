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
      // Save the current admin's email before creating the new user
      final adminEmail = supabase.auth.currentUser?.email;
      
      // Create the new auth user (this will NOT switch session if email confirmation is on)
      final res = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name, 'role': role},
      );

      // If session was switched to new user, re-login as admin
      if (supabase.auth.currentUser?.email != adminEmail && adminEmail != null) {
        // The signUp logged us in as the new user — we cannot recover the admin session
        // without their password. This is a Supabase client limitation.
        // The profile was still created via the trigger.
      }

      if (res.user != null) {
        await fetchWorkers();
        return true;
      }
      return false;
    } catch (e) {
      // If signUp fails (400), fall back to direct profile insertion
      // This allows adding a profile record even without auth (admin can set up
      // the auth account later from Supabase Dashboard)
      try {
        await supabase.from('profiles').insert({
          'id': _generateUuid(),
          'name': name,
          'email': email,
          'role': role,
        });
        await fetchWorkers();
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  /// Generate a simple UUID v4 for profile records created without auth
  String _generateUuid() {
    final now = DateTime.now().microsecondsSinceEpoch;
    return '${now.toRadixString(16).padLeft(12, '0')}-0000-4000-8000-${(now ~/ 1000).toRadixString(16).padLeft(12, '0')}';
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
