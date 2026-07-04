import 'package:flutter/material.dart';
import 'app/app_theme.dart';
import 'screens/splash/splash_screen.dart';

void main() {
  runApp(const JainTilesGalleryApp());
}

class JainTilesGalleryApp extends StatelessWidget {
  const JainTilesGalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Jain Tiles Gallery',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
