// lib/constants.dart
import 'package:flutter/material.dart';

class AppColors {
  // Your orange for buttons and accents
  static const Color orange = Color(0xFFFE9901);

  // Optional: lighter/darker shades if needed later
  static const Color orangeLight = Color(0xFFFFB74D);
  static const Color orangeDark = Color(0xFFC67100);
}

class AppStyles {
  // Reusable button style — orange background, white text, rounded corners
  static final ButtonStyle orangeButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: AppColors.orange,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    elevation: 6,
    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
  );
}

// If you're using Agora for video calls (e.g., live vehicle viewing), keep this
const String agoraAppId = "2168b9a9007143fe95e922f0e516fab7";
