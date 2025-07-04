import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../views/home_view.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  bool isLoading = false;
  String? errorMessage;
  User? currentUser;

  LoginViewModel() {
    // Listen to auth state changes
    _authService.authStateChanges.listen((User? user) {
      currentUser = user;
      notifyListeners();
    });
  }

  bool get isLoggedIn => currentUser != null;

  Future<bool> signIn(String email, String password) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();
      
      await _authService.signInWithEmailAndPassword(email, password);
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      isLoading = false;
      errorMessage = _handleAuthError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String password) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();
      
      await _authService.registerWithEmailAndPassword(email, password);
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      isLoading = false;
      errorMessage = _handleAuthError(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  void navigateToHomeIfLoggedIn(BuildContext context) {
    if (isLoggedIn) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeView()),
      );
    }
  }

  String _handleAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'Bu e-posta adresine ait bir kullanıcı bulunamadı.';
        case 'wrong-password':
          return 'Hatalı şifre girdiniz.';
        case 'email-already-in-use':
          return 'Bu e-posta adresi zaten kullanımda.';
        case 'weak-password':
          return 'Şifre çok zayıf. Daha güçlü bir şifre seçin.';
        case 'invalid-email':
          return 'Geçersiz e-posta adresi.';
        case 'operation-not-allowed':
          return 'Bu işlem şu anda izin verilmiyor.';
        case 'too-many-requests':
          return 'Çok fazla başarısız giriş denemesi. Lütfen daha sonra tekrar deneyin.';
        default:
          return 'Bir hata oluştu: ${error.message}';
      }
    }
    return error.toString();
  }
}
