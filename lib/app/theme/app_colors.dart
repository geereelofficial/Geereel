import 'package:flutter/material.dart';

/// Centralized color tokens for Geereel.
///
/// Swap these values to re-brand the whole app from one place.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFFF3B6F);
  static const Color secondary = Color(0xFF6C2BD9);

  static const Color background = Color(0xFF0E0E10);
  static const Color surface = Color(0xFF1B1B1F);
  static const Color surfaceVariant = Color(0xFF26262B);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA0A0A8);
  static const Color textDisabled = Color(0xFF5C5C63);

  static const Color success = Color(0xFF2ED573);
  static const Color error = Color(0xFFFF4757);
  static const Color warning = Color(0xFFFFA502);

  static const Color divider = Color(0xFF2A2A2E);
  static const Color overlay = Color(0x99000000);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );
}
