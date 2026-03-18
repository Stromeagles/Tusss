// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tus_asistani/main.dart';

void main() {
  testWidgets('App basic smoke test', (WidgetTester tester) async {
    // Uygulamanın hatasız başlayıp render ettiğini doğrula.
    await tester.pumpWidget(const TusAsistaniApp());
    // flutter_animate animasyonları için zaman ver
    await tester.pump(const Duration(seconds: 2));
    // En az bir widget render edilmeli
    expect(find.byType(MaterialApp), findsOneWidget);
  }, timeout: const Timeout(Duration(seconds: 30)));
}
