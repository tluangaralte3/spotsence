import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// SpotSence Design System
/// Minimal dark-first palette with gamified accent colours.
abstract class AppColors {
  // ── Brand ──────────────────────────────────────────────────────────────
  static const primary = Color(0xFF00E5A0); // Emerald green — primary action
  static const primaryDim = Color(0xFF00B37A);
  static const secondary = Color(0xFF6C63FF); // Indigo — secondary accent
  static const accent = Color(0xFFFFB300); // Gold — XP / badges / rewards

  // ── Dark surfaces ──────────────────────────────────────────────────────
  static const bg = Color(0xFF0A0E1A); // App background
  static const surface = Color(0xFF121827); // Cards, sheets
  static const surfaceElevated = Color(0xFF1C2333); // Elevated cards
  static const border = Color(0xFF2A3347); // Dividers

  // ── Text ───────────────────────────────────────────────────────────────
  static const textPrimary = Color(0xFFF0F4FF);
  static const textSecondary = Color(0xFF8892A4);
  static const textMuted = Color(0xFF4A5568);

  // ── Semantic ───────────────────────────────────────────────────────────
  static const success = Color(0xFF22C55E);
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF3B82F6);

  // ── Rating stars / gold ──────────────────────────────────────────────
  static const star = Color(0xFFFFB300);
  static const gold = Color(0xFFFFB300);

  // ── Medal / podium colours ─────────────────────────────────────────────
  static const silverMedal = Color(0xFFC0C0C0);
  static const bronzeMedal = Color(0xFFCD7F32);

  // ── Category accent ────────────────────────────────────────────────────
  static const categoryPurple = Color(0xFF9C27B0);

  // ── Badge rarity ──────────────────────────────────────────────────────
  static const rarityCommon = Color(0xFF9E9E9E);
  static const rarityRare = Color(0xFF42A5F5);
  static const rarityEpic = Color(0xFFAB47BC);
  static const rarityLegendary = Color(0xFFFFB300);

  // ── Light theme equivalents ────────────────────────────────────────────
  static const bgLight = Color(0xFFF4F7FF);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceElevatedLight = Color(0xFFF0F4FF);
  static const borderLight = Color(0xFFE0E8F4);
  static const textPrimaryLight = Color(0xFF0A0E1A);
  static const textSecondaryLight = Color(0xFF4A5568);
  static const textMutedLight = Color(0xFF9AA3B2);
}

// ─────────────────────────────────────────────────────────────────────────────
// Semantic colour accessor — use via context.col.bg etc.
// Resolves to the correct dark/light value automatically.
// ─────────────────────────────────────────────────────────────────────────────

class AppColorScheme {
  final bool isDark;
  const AppColorScheme(this.isDark);

  Color get bg => isDark ? AppColors.bg : AppColors.bgLight;
  Color get surface => isDark ? AppColors.surface : AppColors.surfaceLight;
  Color get surfaceElevated =>
      isDark ? AppColors.surfaceElevated : AppColors.surfaceElevatedLight;
  Color get border => isDark ? AppColors.border : AppColors.borderLight;
  Color get textPrimary =>
      isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;
  Color get textSecondary =>
      isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;
  Color get textMuted =>
      isDark ? AppColors.textMuted : AppColors.textMutedLight;

  // Brand colours are theme-invariant
  Color get primary => AppColors.primary;
  Color get primaryDim => AppColors.primaryDim;
  Color get secondary => AppColors.secondary;
  Color get gold => AppColors.gold;
  Color get success => AppColors.success;
  Color get error => AppColors.error;
  Color get warning => AppColors.warning;
  Color get info => AppColors.info;
}

extension AppColorsContext on BuildContext {
  /// Semantic colours that adapt to the current theme.
  /// Usage: `context.col.bg`, `context.col.textSecondary`, etc.
  AppColorScheme get col {
    final brightness = Theme.of(this).brightness;
    return AppColorScheme(brightness == Brightness.dark);
  }

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

abstract class AppTheme {
  static ThemeData get dark => _build(Brightness.dark);
  static ThemeData get light => _build(Brightness.light);

  /// Returns the colour for a badge rarity string.
  static Color rarityColor(String rarity) {
    switch (rarity) {
      case 'rare':
        return AppColors.rarityRare;
      case 'epic':
        return AppColors.rarityEpic;
      case 'legendary':
        return AppColors.rarityLegendary;
      default:
        return AppColors.rarityCommon;
    }
  }

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = isDark
        ? const ColorScheme.dark(
            primary: AppColors.primary,
            secondary: AppColors.secondary,
            surface: AppColors.surface,
            surfaceContainerHigh: AppColors.surfaceElevated,
            error: AppColors.error,
            onPrimary: AppColors.bg,
            onSecondary: Colors.white,
            onSurface: AppColors.textPrimary,
          )
        : const ColorScheme.light(
            primary: AppColors.primary,
            secondary: AppColors.secondary,
            surface: AppColors.surfaceLight,
            surfaceContainerHigh: AppColors.surfaceElevatedLight,
            error: AppColors.error,
            onPrimary: AppColors.bg,
            onSurface: AppColors.textPrimaryLight,
          );

    final textTheme = GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
        letterSpacing: -0.5,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 15,
        color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: isDark ? AppColors.bg : AppColors.bgLight,
      cardTheme: CardThemeData(
        color: isDark ? AppColors.surface : AppColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? AppColors.border : const Color(0xFFE8EEF7),
          ),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.bg : AppColors.surfaceLight,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
        ),
        iconTheme: IconThemeData(
          color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? AppColors.surface : AppColors.surfaceLight,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.surfaceElevated : const Color(0xFFF0F4FF),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.bg,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark
              ? AppColors.textPrimary
              : AppColors.textPrimaryLight,
          minimumSize: const Size(double.infinity, 52),
          side: BorderSide(
            color: isDark ? AppColors.border : const Color(0xFFD1D9E6),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark
            ? AppColors.surfaceElevated
            : const Color(0xFFF0F4FF),
        selectedColor: AppColors.primary.withOpacity(0.2),
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          color: isDark
              ? AppColors.textSecondary
              : AppColors.textSecondaryLight,
        ),
        side: BorderSide(
          color: isDark ? AppColors.border : const Color(0xFFE0E8F0),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.border : const Color(0xFFE8EEF7),
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark
            ? AppColors.surfaceElevated
            : AppColors.textPrimaryLight,
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: isDark ? AppColors.textPrimary : AppColors.surfaceLight,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
