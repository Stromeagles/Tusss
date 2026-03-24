import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'auth/auth_view_model.dart';
import 'theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/web_landing_screen.dart';
import 'services/ai_service.dart';
import 'services/auth_service.dart';
import 'services/focus_service.dart';
import 'services/spaced_repetition_service.dart';
import 'services/mock_exam_service.dart';
import 'services/collection_service.dart';
import 'services/notification_service.dart';
import 'services/theme_service.dart';
import 'services/specialty_score_service.dart';
import 'widgets/responsive_wrapper.dart';

void main() async {
  // İlk frame'in hızlıca renderlanması için kritik başlangıç
  WidgetsFlutterBinding.ensureInitialized();

  // Web'de sistem yönlendirmesini kısıtlamaya gerek yok veya kIsWeb ile korunuyor
  if (!kIsWeb) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  // Firebase ve diğer servislerin başlatılması arka planda yapılabilir
  // Ancak runApp öncesi yapılarak AuthWrapper'ın snapshot beklemesi sağlanıyor
  runApp(const TusAsistaniApp());
}

class TusAsistaniApp extends StatelessWidget {
  const TusAsistaniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthViewModel>(create: (_) => AuthViewModel()),
        ChangeNotifierProvider<FocusService>(create: (_) => FocusService()),
        ChangeNotifierProvider<MockExamService>(create: (_) => MockExamService()),
        ChangeNotifierProvider<CollectionService>(create: (_) => CollectionService()),
      ],
      child: ValueListenableBuilder<AppThemeMode>(
        valueListenable: ThemeService.mode,
        builder: (_, appMode, __) {
          final isDark = appMode == AppThemeMode.dark;

          SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            systemNavigationBarColor: isDark
                ? AppTheme.background
                : appMode == AppThemeMode.soft
                    ? AppTheme.softBackground
                    : AppTheme.lightBackground,
            systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          ));

          final ThemeData effectiveTheme = switch (appMode) {
            AppThemeMode.dark => AppTheme.darkTheme,
            AppThemeMode.light => AppTheme.lightTheme,
            AppThemeMode.soft => AppTheme.softTheme,
          };

          return MaterialApp(
            title: 'AsisTus',
            debugShowCheckedModeBanner: false,
            themeMode: ThemeMode.light,
            theme: effectiveTheme,
            darkTheme: AppTheme.darkTheme,
            home: const AuthWrapper(),
            builder: (context, child) => ResponsiveWrapper(child: child!),
          );
        },
      ),
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
  bool _proceededToWeb = false; // Session-only: her yeni ziyarette false başlar
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 1) Firebase baslatma — web'de timeout ile korunuyor
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 8));
    } catch (_) {}

    // 2) Onboarding kontrol
    try {
      final prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 4));
      _onboardingDone = prefs.getBool('onboarding_done') ?? false;
      // _proceededToWeb SharedPreferences'e kaydedilmiyor —
      // her yeni oturumda landing page gösterilsin
    } catch (_) {
      _onboardingDone = false;
    }

    // 3) İlk frame render edildikten sonra ağır servisleri lazy başlat
    Future.delayed(const Duration(seconds: 2), () {
      AIService().warmUpCache();
      SpecialtyScoreService().init();
    });
    if (!kIsWeb) NotificationService().init();

    if (mounted) {
      setState(() => _initialized = true);
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) setState(() => _onboardingDone = true);
  }

  Future<void> _handleWebContinue() async {
    // Sadece state güncelle — SharedPreferences'e kaydetme
    // Landing page her yeni ziyarette tekrar gösterilsin
    if (mounted) setState(() => _proceededToWeb = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return _buildSplashScreen();
    }

    // Web landing logic
    if (kIsWeb && !_proceededToWeb) {
      return WebLandingScreen(onContinue: _handleWebContinue);
    }

    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSplashScreen();
        }

        if (snapshot.hasData && snapshot.data != null) {
          // Giriş yapıldı — SRS cache'ini temizle, Firestore'dan çeksin
          SpacedRepetitionService().onUserLogin();
          if (!(_onboardingDone ?? false)) {
            return OnboardingScreen(onComplete: _completeOnboarding);
          }
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }

  Widget _buildSplashScreen() {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/hero_splash.jpg',
                width: 250,
                fit: BoxFit.cover,
                cacheWidth: 750, // 250px × 3x — bellek tasarrufu
              ),
            ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.9, 0.9)),
            const SizedBox(height: 32),
            Text(
              'AsisTus',
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                letterSpacing: -0.5,
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 12),
            const SizedBox(
              width: 120,
              child: LinearProgressIndicator(
                color: AppTheme.cyan,
                backgroundColor: AppTheme.surfaceVariant,
                minHeight: 2,
              ),
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }
}
