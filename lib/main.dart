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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2575FC)),
      ),
      // Halkan LoginPage looma baahna in la siiyo userRole, 
      // waayo isagaa laga dhex dooranayaa.
      home: const AuthPage(userRole: '',), 
    );
  }
}