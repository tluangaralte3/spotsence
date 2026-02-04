import 'package:flutter/material.dart';

/// App color palette aligned with Mizoram tourism branding
class AppColors {
  // Primary Colors - Mizoram Green Theme
  static const Color primary = Color(0xFF2E7D32); // Forest Green
  static const Color primaryLight = Color(0xFF60AD5E);
  static const Color primaryDark = Color(0xFF005005);

  // Secondary Colors - Cultural Accent
  static const Color secondary = Color(0xFFFF6F00); // Warm Orange
  static const Color secondaryLight = Color(0xFFFF9E40);
  static const Color secondaryDark = Color(0xFFC43E00);

  // Feature Colors (matching web sections)
  static const Color restaurantTheme = Color(0xFFFF6B35); // Orange
  static const Color adventureTheme = Color(0xFF10B981); // Emerald
  static const Color shoppingTheme = Color(0xFF6366F1); // Indigo
  static const Color spotsTheme = Color(0xFF2E7D32); // Green

  // Gamification Colors
  static const Color gold = Color(0xFFFFD700);
  static const Color silver = Color(0xFFC0C0C0);
  static const Color bronze = Color(0xFFCD7F32);
  static const Color diamond = Color(0xFFB9F2FF);

  // Badge Rarity Colors
  static const Color commonBadge = Color(0xFF9E9E9E);
  static const Color rareBadge = Color(0xFF2196F3);
  static const Color epicBadge = Color(0xFF9C27B0);
  static const Color legendaryBadge = Color(0xFFFF9800);

  // Difficulty Colors
  static const Color easyDifficulty = Color(0xFF4CAF50);
  static const Color moderateDifficulty = Color(0xFFFF9800);
  static const Color hardDifficulty = Color(0xFFF44336);
  static const Color expertDifficulty = Color(0xFF9C27B0);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Neutral Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color divider = Color(0xFFE0E0E0);

  // Surface Colors (Light Theme)
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF5F5F5);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Surface Colors (Dark Theme)
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color cardBackgroundDark = Color(0xFF2C2C2C);

  // Overlay Colors
  static const Color overlay = Color(0x66000000);
  static const Color overlayLight = Color(0x33000000);
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
