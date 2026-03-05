import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client;

  AuthService(this._client);

  User? get currentUser => _client.auth.currentUser;
  String? get userId => currentUser?.id;
  bool get isAuthenticated => currentUser != null;

  /// Sign in anonymously (creates auth.users entry → triggers profile creation)
  Future<void> signInAnonymously() async {
    if (isAuthenticated) return;
    await _client.auth.signInAnonymously();
  }

  /// Get current session access token for Edge Function calls
  String? get accessToken => _client.auth.currentSession?.accessToken;

  /// Listen to auth state changes
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}
