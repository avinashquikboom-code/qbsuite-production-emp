import 'package:flutter/material.dart';

/// QB Suite brand specification: design-system/colors.json.
/// Identical in CRM, Customer and Production. Do not create module palettes.
abstract final class AppColors {
  static const primary = Color(0xFF5EC269);
  static const actionGreen = Color(0xFF1FC45B);
  static const darkPrimary = Color(0xFF169F4D);
  static const lightPrimary = Color(0xFFE8F8EE);
  static const background = Color(0xFFF8F9FC);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF172033);
  static const textSecondary = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);
  static const success = primary;
  static const danger = Color(0xFFE11D48);
}
