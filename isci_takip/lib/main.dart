import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'views/login_view.dart';
import 'view_models/login_view_model.dart';
import 'view_models/worker_view_model.dart';
import 'view_models/project_view_model.dart';
import 'view_models/attendance_view_model.dart';
import 'view_models/photo_upload_view_model.dart';
import 'view_models/user_view_model.dart';
import 'firebase_options.dart';

void main() async {
  // Flutter binding'i başlat
  WidgetsFlutterBinding.ensureInitialized();
  
  // Hata ayıklama için try-catch bloğu
  try {
    print('Firebase başlatılıyor...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase başarıyla başlatıldı');
    
    // Firebase başarıyla başlatıldıysa uygulamayı çalıştır
    runApp(const MyApp());
  } catch (e, stackTrace) {
    // Hata durumunda detaylı bilgi göster
    print('Firebase başlatma hatası: $e');
    print('Stack trace: $stackTrace');
    
    // Basit bir hata ekranı göster
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            'Uygulama başlatılamadı: $e',
            style: TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginViewModel()),
        ChangeNotifierProvider(create: (_) => WorkerViewModel()),
        ChangeNotifierProvider(create: (_) => ProjectViewModel()),
        ChangeNotifierProvider(create: (_) => AttendanceViewModel()),
        ChangeNotifierProvider(create: (_) => PhotoUploadViewModel()),
        ChangeNotifierProvider(create: (_) => UserViewModel()),
      ],
      child: MaterialApp(
        title: 'Sarsılmaz İnşaat İşçi Takip Sistemi',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('tr', 'TR'),
          Locale('en', 'US'),
        ],
        locale: const Locale('tr', 'TR'),
        home: const LoginView(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
