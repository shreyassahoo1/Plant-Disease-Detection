import 'package:flutter/material.dart';

class AppColors {
  // Futuristic Agriculture Palette
  static const Color primary = Color(0xFF00D4FF); // Cyan
  static const Color secondary = Color(0xFF00FF87); // Neon Green
  static const Color backgroundDark = Color(0xFF090A0F);
  static const Color backgroundLight = Color(0xFFF0F4F8);
  static const Color surfaceDark = Color(0xFF141722);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  
  static const Color textDark = Color(0xFFE2E8F0);
  static const Color textLight = Color(0xFF1A202C);
  
  static const Color error = Color(0xFFFF3B30);
  static const Color warning = Color(0xFFFF9500);
  static const Color success = Color(0xFF34C759);

  // Glassmorphism effects
  static Color glassDark = Colors.white.withValues(alpha: 0.05);
  static Color glassLight = Colors.black.withValues(alpha: 0.05);
  static Color glassBorderDark = Colors.white.withValues(alpha: 0.1);
  static Color glassBorderLight = Colors.black.withValues(alpha: 0.1);
}
