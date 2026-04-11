import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/api/api_client.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthState {
  final bool isLoading;
  final String? error;
  final User? user;
  final Map<String, dynamic>? profile;

  AuthState({this.isLoading = false, this.error, this.user, this.profile});

  AuthState copyWith({bool? isLoading, String? error, User? user, Map<String, dynamic>? profile}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
      profile: profile ?? this.profile,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState()) {
    _loadSession();
  }

  Future<void> _loadSession() async {
    final session = supabase.auth.currentSession;
    if (session != null) {
      await _loadProfile(session.user);
    }
  }

  Future<void> _loadProfile(User user) async {
    try {
      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
      state = state.copyWith(user: user, profile: data);
    } catch (_) {
      // Profile may not exist yet; ignore
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      await _loadProfile(response.user!);
      state = state.copyWith(isLoading: false);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'An unexpected error occurred.');
      return false;
    }
  }

  Future<void> logout() async {
    await supabase.auth.signOut();
    state = AuthState();
  }

  String? get role => state.profile?['role'] as String?;
  String? get userName => state.profile?['name'] as String?;
  bool get isLoggedIn => supabase.auth.currentSession != null;
}
