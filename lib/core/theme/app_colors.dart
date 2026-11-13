import 'package:flutter/material.dart';

/// QB Suite brand specification: design-system/colors.json.
/// Identical in CRM, Customer and Production. Do not create module palettes.
abstract final class AppColors {
  static const primary = Color(0xFF23C45E);
  static const actionGreen = Color(0xFF23C45E);
  static const darkPrimary = Color(0xFF1AA14D);
  static const lightPrimary = Color(0xFFE8F9EE);
  static const background = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF64748B);
  static const border = Color(0xFFE5E7EB);
  static const success = primary;
  static const danger = Color(0xFFDC2626);
}
