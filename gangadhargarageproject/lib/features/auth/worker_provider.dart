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
      final res = await apiClient.get('/auth');
      state = AsyncValue.data(res.data as List<dynamic>);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<bool> addWorker(String name, String email, String password, String role) async {
    try {
      await apiClient.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
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
      final data = {
        'name': name,
        'email': email,
        'role': role,
      };
      if (password != null && password.isNotEmpty) {
        data['password'] = password;
      }
      
      await apiClient.put('/auth/$id', data: data);
      await fetchWorkers();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteWorker(String id) async {
    try {
      await apiClient.delete('/auth/$id');
      await fetchWorkers();
      return true;
    } catch (e) {
      return false;
    }
  }
}
