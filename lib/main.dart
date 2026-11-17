import 'package:flutter/material.dart';
import 'login_page.dart'; // Hubi in jidkani sax yahay

void main() {
  runApp(const EliteSchoolApp());
}

class EliteSchoolApp extends StatelessWidget {
  const EliteSchoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Elite School System',
      theme: ThemeData(
        fontFamily: 'Poppins', // Hubi in aad Poppins ku dartay pubspec.yaml
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2575FC),
          primary: const Color(0xFF2575FC),
          secondary: const Color(0xFF00D2FF),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        cardTheme: CardThemeData(
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.06),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 1.5,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: ZoomPageTransitionsBuilder(),
            TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
            TargetPlatform.linux: ZoomPageTransitionsBuilder(),
          },
        ),
      ),
      // Halkan LoginPage looma baahna in la siiyo userRole, 
      // waayo isagaa laga dhex dooranayaa.
      home: const AuthPage(userRole: '',), 
    );
  }
}