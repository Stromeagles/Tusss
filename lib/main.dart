import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'auth/auth_view_model.dart';
import 'theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/ai_service.dart';
import 'services/auth_service.dart';
import 'services/focus_service.dart';
import 'services/notification_service.dart';
import 'services/theme_service.dart';
import 'widgets/responsive_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase baslatma
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
          title: 'AsisTus',
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
/// Giris yapilmissa -> Onboarding (ilk seferde) veya HomeScreen.
/// Giriş yapmadan uygulamanin HICBIR yerine erisilemez.
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool? _onboardingDone;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _onboardingDone = prefs.getBool('onboarding_done') ?? false);
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) setState(() => _onboardingDone = true);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges,
      builder: (context, snapshot) {
        // Baglanti bekleniyor — splash
        if (snapshot.connectionState == ConnectionState.waiting || _onboardingDone == null) {
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
          // İlk açılış → Onboarding
          if (!_onboardingDone!) {
            return OnboardingScreen(onComplete: _completeOnboarding);
          }
          return const HomeScreen();
        }

        // Giris yapilmamis — login ekranina yonlendir
        return const LoginScreen();
      },
    );
  }
}
