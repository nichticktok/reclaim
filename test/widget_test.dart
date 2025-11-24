// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter/material.dart';

import 'package:recalim/features/web/landing_page.dart';

void main() {
  testWidgets('LandingPage renders primary call-to-action buttons', (tester) async {
    final view = tester.view;
    view.physicalSize = const Size(1440, 900);
    view.devicePixelRatio = 1.0;
    addTearDown(() {
      view.resetPhysicalSize();
      view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const MaterialApp(home: LandingPage()));

    expect(find.text('Reclaim Your Routine'), findsOneWidget);
    expect(find.text('Download on the App Store'), findsOneWidget);
    expect(find.text('Get it on Google Play'), findsOneWidget);
  });
}
