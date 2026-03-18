import 'package:flutter/material.dart';

class AppStyles {
  // Brand Colors
  static const Color primary = Color(0xFFFF5E1E);
  static const Color primaryDark = Color(0xFFD94A1A);
  static const Color dark = Color(0xFF1F2937);
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Colors.white;

  // Gradients
  static const Gradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadows
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 10,
      offset: const Offset(0, 4),
    )
  ];

  static List<BoxShadow> glowShadow = [
    BoxShadow(
      color: primary.withValues(alpha: 0.3),
      blurRadius: 15,
      offset: const Offset(0, 8),
    )
  ];

  // Text Styles
  static const TextStyle heading1 = TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: dark);
  static const TextStyle heading2 = TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: dark);
  static const TextStyle body = TextStyle(fontSize: 14, color: Colors.black87);
  static const TextStyle caption = TextStyle(fontSize: 12, color: Colors.black54);
}
