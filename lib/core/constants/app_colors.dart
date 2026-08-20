import 'package:flutter/material.dart';

class AppColors {
  // Background Colors
  static const Color bgDark = Color(0xFF0A0E21);
  static const Color bgNavy = Color(0xFF0F172A);
  static const Color bgCard = Color(0xFF1E293B);
  static const Color bgCardGlass = Color(0x33334155);

  // Brand Neon Accents
  static const Color neonCyan = Color(0xFF00F0FF);
  static const Color neonPurple = Color(0xFFA855F7);
  static const Color neonPink = Color(0xFFEC4899);
  static const Color neonGold = Color(0xFFFFB800);
  static const Color neonGreen = Color(0xFF10B981);
  static const Color neonRed = Color(0xFFEF4444);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0x661E293B), Color(0x440F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient fireGradient = LinearGradient(
    colors: [Color(0xFFFF4500), Color(0xFFFF8C00), Color(0xFFFFD700)],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );

  // Text Colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
}
