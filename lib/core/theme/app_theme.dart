import '../icons/remix_icon.dart';

import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Apply using MaterialApp(theme: AppTheme.light).
/// Text uses Outfit, the same family as the CRM and visitor apps.
/// UI icons must come from remixicon; do not use Icons.* glyphs.
abstract final class AppTheme {
  static ThemeData get lightTheme => light;
  static const buttonRadius = 12.0;
  static const controlPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 12,
  );

  static ThemeData get light {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          primaryContainer: AppColors.lightPrimary,
          onPrimaryContainer: AppColors.textPrimary,
          secondary: AppColors.primary,
          onSecondary: AppColors.textPrimary,
          secondaryContainer: AppColors.lightPrimary,
          onSecondaryContainer: AppColors.textPrimary,
          tertiary: AppColors.darkPrimary,
          onTertiary: AppColors.surface,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
          onSurfaceVariant: AppColors.textSecondary,
          outline: AppColors.border,
          outlineVariant: AppColors.border,
          surfaceTint: Colors.transparent,
          error: AppColors.danger,
        );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(buttonRadius),
    );
    final buttonStyle = ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return AppColors.border;
        if (states.contains(WidgetState.pressed) ||
            states.contains(WidgetState.hovered)) {
          return AppColors.darkPrimary;
        }
        return AppColors.primary;
      }),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? AppColors.textSecondary
            : AppColors.textPrimary,
      ),
      padding: const WidgetStatePropertyAll(controlPadding),
      shape: WidgetStatePropertyAll(shape),
      minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
      textStyle: WidgetStatePropertyAll(
        GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    );
    return ThemeData(
      actionIconTheme: ActionIconThemeData(
        backButtonIconBuilder: (_) => const RemixIcon(AppIcon.back),
        closeButtonIconBuilder: (_) => const RemixIcon(AppIcon.close),
        drawerButtonIconBuilder: (_) => const RemixIcon(AppIcon.menu),
        endDrawerButtonIconBuilder: (_) => const RemixIcon(AppIcon.menu),
      ),
      useMaterial3: true,
      colorScheme: scheme,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.outfitTextTheme().apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      primaryTextTheme: GoogleFonts.outfitTextTheme().apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: buttonStyle),
      filledButtonTheme: FilledButtonThemeData(style: buttonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkPrimary,
          side: const BorderSide(color: AppColors.border),
          shape: shape,
          padding: controlPadding,
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.darkPrimary,
          shape: shape,
          padding: controlPadding,
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: shape,
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: controlPadding,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        hintStyle: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 14),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(AppColors.textPrimary),
        side: const BorderSide(color: AppColors.border),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.textSecondary,
        ),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.border,
        ),
        thumbColor: const WidgetStatePropertyAll(AppColors.surface),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.lightPrimary,
        circularTrackColor: AppColors.lightPrimary,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.darkPrimary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 22),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.lightPrimary,
        labelTextStyle: WidgetStatePropertyAll(
          AppTypography.inter(fontSize: 11, fontWeight: FontWeight.w600),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textSecondary,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.lightPrimary,
        selectedIconTheme: const IconThemeData(color: AppColors.primary),
        unselectedIconTheme: const IconThemeData(color: AppColors.textSecondary),
        selectedLabelTextStyle: GoogleFonts.outfit(
          color: AppColors.darkPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: GoogleFonts.outfit(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: AppTypography.inter(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: AppTypography.inter(fontWeight: FontWeight.w500, fontSize: 12),
      ),
      listTileTheme: const ListTileThemeData(
        selectedColor: AppColors.darkPrimary,
        selectedTileColor: AppColors.lightPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        toolbarTextStyle: GoogleFonts.outfit(fontSize: 14, color: AppColors.textPrimary),
      ),
    );
  }
}
