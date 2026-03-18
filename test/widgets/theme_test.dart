import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tus_asistani/services/theme_service.dart';

void main() {
  group('ThemeService', () {
    setUp(() {
      // Her testten önce dark mode'a sıfırla
      ThemeService.mode.value = ThemeMode.dark;
    });

    test('Başlangıç değeri dark olmalı', () {
      expect(ThemeService.mode.value, ThemeMode.dark);
    });

    test('isDark dark modda true döner', () {
      ThemeService.mode.value = ThemeMode.dark;
      expect(ThemeService.isDark, isTrue);
    });

    test('isDark light modda false döner', () {
      ThemeService.mode.value = ThemeMode.light;
      expect(ThemeService.isDark, isFalse);
    });

    test('toggle() dark → light geçişi yapar', () {
      ThemeService.mode.value = ThemeMode.dark;
      ThemeService.toggle();
      expect(ThemeService.mode.value, ThemeMode.light);
    });

    test('toggle() light → dark geçişi yapar', () {
      ThemeService.mode.value = ThemeMode.light;
      ThemeService.toggle();
      expect(ThemeService.mode.value, ThemeMode.dark);
    });

    test('toggle() iki kez çağrılırsa başlangıç değerine döner', () {
      final initial = ThemeService.mode.value;
      ThemeService.toggle();
      ThemeService.toggle();
      expect(ThemeService.mode.value, initial);
    });

    test('ValueNotifier listener toggle sonrası tetiklenir', () {
      int callCount = 0;
      ThemeService.mode.addListener(() => callCount++);

      ThemeService.toggle();
      expect(callCount, 1);

      ThemeService.toggle();
      expect(callCount, 2);

      ThemeService.mode.removeListener(() {});
    });

    testWidgets('ValueListenableBuilder tema değişikliğini yansıtır',
        (tester) async {
      ThemeService.mode.value = ThemeMode.dark;

      await tester.pumpWidget(
        ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeService.mode,
          builder: (_, mode, __) {
            return MaterialApp(
              home: Scaffold(
                body: Text(
                  mode == ThemeMode.dark ? 'Koyu Tema' : 'Açık Tema',
                ),
              ),
            );
          },
        ),
      );

      expect(find.text('Koyu Tema'), findsOneWidget);
      expect(find.text('Açık Tema'), findsNothing);

      ThemeService.toggle();
      await tester.pump();

      expect(find.text('Açık Tema'), findsOneWidget);
      expect(find.text('Koyu Tema'), findsNothing);
    });
  });
}
