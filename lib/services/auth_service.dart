import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<User?> getCurrentUser() async {
    return _supabaseClient.auth.currentUser;
  }

  Future<AuthResponse> signUp(String email, String password) async {
    return await _supabaseClient.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signIn(String email, String password) async {
    return await _supabaseClient.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse?> signInWithGoogle() async {
    try {
      debugPrint('Google oturum açma başlatılıyor...');
      
      // Google ile oturum açma işlemi
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // Kullanıcı Google oturum açma işlemini iptal etti
        debugPrint('Kullanıcı Google oturum açma işlemini iptal etti');
        return null;
      }

      // Google kimlik bilgilerini al
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      developer.log('Google oturum açma başarılı: ${googleUser.email}');
      debugPrint('Google token alındı: ${googleAuth.accessToken != null}');

      // Supabase ile Google oturum açma
      if (googleAuth.idToken == null) {
        throw Exception('Google ID token alınamadı');
      }
      
      final AuthResponse response = await _supabaseClient.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );
      
      developer.log('Supabase Google ile giriş başarılı: ${response.user?.email}');
      return response;
    } catch (e) {
      developer.log('Google ile giriş hatası: ${e.toString()}', error: e);
      debugPrint('Google oturum açma hata detayı: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _supabaseClient.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _supabaseClient.auth.resetPasswordForEmail(email);
  }

  Stream<AuthState> get authStateChanges => 
    _supabaseClient.auth.onAuthStateChange;
} 