import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/login_view_model.dart';
import '../view_models/user_view_model.dart';
import '../services/shared_preferences_service.dart';
import 'home_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegisterMode = false;
  bool _rememberMe = false;
  bool _obscurePassword = true; // Şifre görünürlüğü kontrolü
  
  @override
  void initState() {
    super.initState();
    // Kaydedilmiş oturum bilgilerini yükle
    _loadSavedCredentials();
  }
  
  // Kaydedilmiş oturum bilgilerini yükle
  Future<void> _loadSavedCredentials() async {
    final loginViewModel = Provider.of<LoginViewModel>(context, listen: false);
    
    // "Beni hatırla" durumunu yükle
    _rememberMe = await SharedPreferencesService.getRememberMe();
    loginViewModel.setRememberMe(_rememberMe);
    
    // Kaydedilmiş e-posta adresini yükle
    if (_rememberMe) {
      final savedEmail = await loginViewModel.getSavedEmail();
      if (savedEmail != null && savedEmail.isNotEmpty) {
        _emailController.text = savedEmail;
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final loginViewModel = Provider.of<LoginViewModel>(context, listen: false);
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      
      // "Beni hatırla" durumunu ayarla
      loginViewModel.setRememberMe(_rememberMe);
      
      bool success;
      if (_isRegisterMode) {
        // Kayıt işlemi
        success = await loginViewModel.register(email, password);
        if (success) {
          // Kullanıcı rolünü başlat
          await userViewModel.initializeCurrentUser();
          
          // Kayıt başarılı mesajı
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Kayıt başarılı. Yönetici onayı bekleniyor.')),
            );
          }
        }
      } else {
        // Giriş işlemi
        success = await loginViewModel.signIn(email, password);
        if (success) {
          // Kullanıcı rol bilgilerini yükle
          await userViewModel.initializeCurrentUser();
        }
      }
      
      if (success && mounted) {
        // Ana sayfaya yönlendir
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeView()),
        );
      } else if (mounted) {
        // Hata mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loginViewModel.errorMessage ?? 'Bir hata oluştu')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<LoginViewModel>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_isRegisterMode ? 'Kayıt Ol' : 'Giriş Yap'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo or app name
              const Icon(
                Icons.people_alt_rounded,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 8),
              Text(
                'Sarsılmaz İnşaat',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              Text(
                'İşçi Takip Sistemi',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Email field
              AutofillGroup(
                child: Column(
                  children: [
                    TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-posta',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                    hintText: 'ornek@email.com',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  enableSuggestions: true,
                  autofillHints: const [AutofillHints.email, AutofillHints.username],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen e-posta adresinizi girin';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Geçerli bir e-posta adresi girin';
                    }
                    return null;
                  },
                    ),
                    const SizedBox(height: 16),
                    
                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Şifre',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        // Kullanıcıya şifre görünürlüğü kontrolü ekle
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          tooltip: _obscurePassword ? 'Şifreyi göster' : 'Şifreyi gizle',
                        ),
                      ),
                      obscureText: _obscurePassword,
                      autocorrect: false,
                      enableSuggestions: false,
                      keyboardType: TextInputType.visiblePassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _submitForm(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen şifrenizi girin';
                        }
                        if (_isRegisterMode && value.length < 6) {
                          return 'Şifre en az 6 karakter olmalıdır';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              // "Beni hatırla" seçeneği
              if (!_isRegisterMode) // Sadece giriş modunda göster
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (value) {
                        setState(() {
                          _rememberMe = value ?? false;
                        });
                      },
                    ),
                    const Text('Beni hatırla'),
                  ],
                ),
              
              const SizedBox(height: 24),
              
              // Login/Register button
              ElevatedButton(
                onPressed: viewModel.isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: viewModel.isLoading
                    ? const CircularProgressIndicator()
                    : Text(_isRegisterMode ? 'Kayıt Ol' : 'Giriş Yap'),
              ),
              const SizedBox(height: 16),
              
              // Toggle between login and register
              TextButton(
                onPressed: () {
                  setState(() {
                    _isRegisterMode = !_isRegisterMode;
                  });
                },
                child: Text(_isRegisterMode
                    ? 'Zaten hesabınız var mı? Giriş yapın'
                    : 'Hesabınız yok mu? Kayıt olun'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
