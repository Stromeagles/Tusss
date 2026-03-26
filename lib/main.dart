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
import 'screens/onboarding_screen.dart';
import 'web/adaptive_app_shell.dart';
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
import 'services/user_service.dart';
import 'services/progress_service.dart';
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
  bool _proceededToWeb = false;
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

    // 2) Onboarding + landing tercihi kontrol
    try {
      final prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 4));
      _onboardingDone  = prefs.getBool('onboarding_done')  ?? false;
      _proceededToWeb  = prefs.getBool('hasSeenLanding')   ?? false;
    } catch (_) {
      _onboardingDone = false;
      _proceededToWeb = false;
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
    // SharedPreferences'e kaydet — bir sonraki ziyarette landing atlanır
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasSeenLanding', true);
    } catch (_) {}
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
          // Giriş yapıldı — Tüm servisleri Firestore senkronizasyonu için tetikle
          SpacedRepetitionService().onUserLogin();
          UserService().onUserLogin();
          CollectionService().syncWithCloud();
          MockExamService().syncWithCloud();
          ProgressService().syncWithCloud();
          
          if (!(_onboardingDone ?? false)) {
            return OnboardingScreen(onComplete: _completeOnboarding);
          }
          // AdaptiveAppShell: web'de sidebar+IndexedStack, mobilde HomeScreen
          return const AdaptiveAppShell();
        }

        return const LoginScreen();
      },
    );
  }

  Widget _buildSplashScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Stack(
        children: [
          // Ambient orb — sol üst (cyan)
          Positioned(
            top: -120, left: -100,
            child: Container(
              width: 420, height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.cyan.withValues(alpha: 0.13),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Ambient orb — sağ alt (violet)
          Positioned(
            bottom: -140, right: -80,
            child: Container(
              width: 480, height: 480,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.neonPurple.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // İçerik
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo mark — gradyan kutu + monogram
                Hero(
                  tag: 'asistus-logo',
                  child: Container(
                    width: 96, height: 96,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00E5FF), Color(0xFFA371F7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.cyan.withValues(alpha: 0.30),
                          blurRadius: 36, offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: AppTheme.neonPurple.withValues(alpha: 0.18),
                          blurRadius: 60, offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'A',
                        style: GoogleFonts.outfit(
                          fontSize: 52,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -2,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                )
                .animate()
                .fadeIn(duration: 600.ms)
                .scale(begin: const Offset(0.6, 0.6), curve: Curves.easeOutBack),

                const SizedBox(height: 28),

                // Wordmark — "Asis" beyaz, "Tus" cyan
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Asis',
                        style: GoogleFonts.outfit(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          letterSpacing: -1.5,
                        ),
                      ),
                      TextSpan(
                        text: 'Tus',
                        style: GoogleFonts.outfit(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.cyan,
                          letterSpacing: -1.5,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 250.ms, duration: 500.ms).slideY(begin: 0.12),

                const SizedBox(height: 10),

                // Tagline
                Text(
                  'AI Destekli TUS Hazırlık',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.4,
                  ),
                ).animate().fadeIn(delay: 400.ms, duration: 500.ms),

                const SizedBox(height: 52),

                // Nefes alan üç nokta
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    return Container(
                      width: 7, height: 7,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.cyan,
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(
                      begin: 0.4, end: 1.0,
                      delay: Duration(milliseconds: 500 + i * 180),
                      duration: 500.ms,
                      curve: Curves.easeInOut,
                    )
                    .fadeIn(
                      delay: Duration(milliseconds: 500 + i * 180),
                      duration: 400.ms,
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
