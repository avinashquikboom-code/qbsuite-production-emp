import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Outfit, the same family used by the CRM and visitor apps.
abstract final class AppTypography {
  static TextStyle get regular => GoogleFonts.outfit(fontWeight: FontWeight.w400);
  static TextStyle get medium => GoogleFonts.outfit(fontWeight: FontWeight.w500);
  static TextStyle get semiBold => GoogleFonts.outfit(fontWeight: FontWeight.w600);
  static TextStyle get bold => GoogleFonts.outfit(fontWeight: FontWeight.w700);

  static TextStyle inter({
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<ui.Shadow>? shadows,
    List<ui.FontFeature>? fontFeatures,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
  }) => GoogleFonts.outfit(
    textStyle: textStyle,
    color: color,
    backgroundColor: backgroundColor,
    fontSize: fontSize,
    fontWeight: fontWeight,
    fontStyle: fontStyle,
    letterSpacing: letterSpacing,
    wordSpacing: wordSpacing,
    textBaseline: textBaseline,
    height: height,
    locale: locale,
    foreground: foreground,
    background: background,
    shadows: shadows,
    fontFeatures: fontFeatures,
    decoration: decoration,
    decorationColor: decorationColor,
    decorationStyle: decorationStyle,
    decorationThickness: decorationThickness,
  );

  static TextTheme interTextTheme([TextTheme? theme]) =>
      GoogleFonts.outfitTextTheme(theme ?? ThemeData.light().textTheme);
}
