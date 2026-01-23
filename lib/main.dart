// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:success_motors/auth/auth_wrapper.dart';
import 'package:success_motors/auth/onboarding_screen.dart';
import 'package:success_motors/auth/splash_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SuccessMotorsApp());
}

class SuccessMotorsApp extends StatelessWidget {
  const SuccessMotorsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Success Motors',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true, // Clean modern look
        fontFamily: GoogleFonts.poppins().fontFamily, // Keep nice font
      ),
      home: const AuthWrapper(),
      //home: const SplashScreen(),
      //home: const OnboardingScreen(),
    );
  }
}
