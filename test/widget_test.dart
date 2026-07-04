// This is a basic Flutter widget test for Jain Tiles Gallery.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jain_tiles_gallery/main.dart';
import 'package:jain_tiles_gallery/screens/splash/splash_screen.dart';

void main() {
  testWidgets('App launches and displays SplashScreen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const JainTilesGalleryApp());

    // Verify that the SplashScreen is rendered.
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);

    // Advance virtual time by 2 seconds to trigger splash timer and navigation
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });
}
