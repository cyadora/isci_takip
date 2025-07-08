import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/shared_preferences_service.dart';
import '../views/home_view.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  bool isLoading = false;
  String? errorMessage;
  User? currentUser;
  bool rememberMe = false;

  LoginViewModel() {
    // Listen to auth state changes
    _authService.authStateChanges.listen((User? user) {
      currentUser = user;
      notifyListeners();
    });
    
    // Kaydedilmiş oturum bilgilerini yükle
    _loadSavedPreferences();
  }
  
  // Kaydedilmiş oturum bilgilerini yükle
  Future<void> _loadSavedPreferences() async {
    rememberMe = await SharedPreferencesService.getRememberMe();
    notifyListeners();
  }

  bool get isLoggedIn => currentUser != null;

  // "Beni hatırla" durumunu ayarla
  void setRememberMe(bool value) {
    rememberMe = value;
    SharedPreferencesService.saveRememberMe(value);
    notifyListeners();
  }
  
  // Kaydedilmiş e-posta adresini getir
  Future<String?> getSavedEmail() async {
    return SharedPreferencesService.getUserEmail();
  }

  Future<bool> signIn(String email, String password) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();
      
      // Giriş işlemi
      final userCredential = await _authService.signInWithEmailAndPassword(email, password);
      
      // Kullanıcı modelini al
      final userModel = await _authService.getCurrentUserModel();
      
      // Kullanıcı onay durumunu kontrol et
      if (userModel != null && !userModel.canLogin) {
        // Eğer kullanıcı onaylanmamışsa çıkış yap
        await _authService.signOut();
        isLoading = false;
        errorMessage = 'Hesabınız henüz yönetici tarafından onaylanmamış. Lütfen daha sonra tekrar deneyin.';
        notifyListeners();
        return false;
      }
      
      // Eğer "Beni hatırla" seçili ise e-posta adresini kaydet
      if (rememberMe) {
        await SharedPreferencesService.saveUserEmail(email);
      }
      
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
      
      // Kullanıcıyı kayıt et
      final userId = await _authService.registerWithEmailAndPassword(email, password);
      
      // Kayıt başarılıysa ve "Beni hatırla" seçili ise e-posta adresini kaydet
      if (rememberMe) {
        await SharedPreferencesService.saveUserEmail(email);
      }
      
      // Normal kayıt olan kullanıcılar için otomatik olarak çıkış yap
      // Böylece admin onayı olmadan giriş yapamayacaklar
      await _authService.signOut();
      
      isLoading = false;
      errorMessage = 'Kayıt başarılı. Yönetici onayı bekleniyor.';
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
      // "Beni hatırla" seçili değilse oturum bilgilerini temizle
      if (!rememberMe) {
        await SharedPreferencesService.clearUserSession();
      }
      
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
