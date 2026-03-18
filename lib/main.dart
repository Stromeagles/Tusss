import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'services/theme_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const TusAsistaniApp());
}

class TusAsistaniApp extends StatelessWidget {
  const TusAsistaniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.mode,
      builder: (_, themeMode, __) {
        final isDark = themeMode == ThemeMode.dark;

        // Status / nav bar renkleri temaya göre güncellenir
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
          title: 'TUS Asistanı',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme:     AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: const HomeScreen(),
        );
      },
    );
  }
}
