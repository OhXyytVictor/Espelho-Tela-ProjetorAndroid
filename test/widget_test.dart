import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumicast/main.dart';

void main() {
  testWidgets('LumiCast smoke test', (WidgetTester tester) async {
    // Simulate 1080p landscape TV / Projector resolution
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(const LumiCastApp());
    expect(find.byType(LumiCastApp), findsOneWidget);
  });
}
