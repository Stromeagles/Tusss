import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'auth/auth_view_model.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/ai_service.dart';
import 'services/auth_service.dart';
import 'services/focus_service.dart';
import 'services/pomodoro_service.dart';
import 'services/notification_service.dart';
import 'services/theme_service.dart';
import 'widgets/responsive_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase baslatma
  await Firebase.initializeApp();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  AIService().warmUpCache();
  NotificationService().init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthViewModel>(create: (_) => AuthViewModel()),
        ChangeNotifierProvider<FocusService>(create: (_) => FocusService()),
        ChangeNotifierProvider<PomodoroService>(create: (_) => PomodoroService()),
      ],
      child: const TusAsistaniApp(),
    ),
  );
}

class TusAsistaniApp extends StatelessWidget {
  const TusAsistaniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.mode,
      builder: (_, themeMode, __) {
        final isDark = themeMode == ThemeMode.dark;

        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarColor:
              isDark ? AppTheme.background : AppTheme.lightBackground,
          systemNavigationBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
        ));

        return MaterialApp(
          title: 'TUS Asistani',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: const AuthWrapper(),
          builder: (context, child) => ResponsiveWrapper(child: child!),
        );
      },
    );
  }
}

/// Firebase Auth stream'ini dinler.
/// Giris yapilmissa -> HomeScreen, yapilmamissa -> LoginScreen.
/// Giriş yapmadan uygulamanin HICBIR yerine erisilemez.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges,
      builder: (context, snapshot) {
        // Baglanti bekleniyor — splash
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(
              child: CircularProgressIndicator(
                  color: AppTheme.cyan, strokeWidth: 2.5),
            ),
          );
        }

        // Kullanici giris yapmis
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreen();
        }

        // Giris yapilmamis — login ekranina yonlendir
        return const LoginScreen();
      },
    );
  }
}
