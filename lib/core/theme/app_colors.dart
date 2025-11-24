import 'package:flutter/material.dart';
import 'app_design_system.dart';

/// App colors - uses design system
class AppColors {
  // Backgrounds
  static const Color background = AppDesignSystem.backgroundMain;
  static const Color backgroundDeep = AppDesignSystem.backgroundDeep;
  static const Color surface = AppDesignSystem.surface;
  static const Color surfaceLight = AppDesignSystem.surfaceElevated;
  static const Color surfaceElevated = AppDesignSystem.surfaceHighlight;
  
  // Primary
  static const Color primary = AppDesignSystem.primary;
  static const Color primaryDark = AppDesignSystem.primaryDark;
  static const Color primaryLight = AppDesignSystem.primaryLight;
  
  // Accents
  static const Color accentPurple = AppDesignSystem.accentPurple;
  static const Color accentBlue = AppDesignSystem.accentBlue;
  static const Color accentTeal = AppDesignSystem.accentTeal;
  static const Color accentGreen = AppDesignSystem.accentGreen;
  static const Color accentPink = AppDesignSystem.accentPink;
  static const Color accentAmber = AppDesignSystem.accentAmber;
  
  // Status
  static const Color success = AppDesignSystem.success;
  static const Color error = AppDesignSystem.error;
  static const Color warning = AppDesignSystem.warning;
  static const Color info = AppDesignSystem.info;
  
  // Text
  static const Color textPrimary = AppDesignSystem.textPrimary;
  static const Color textSecondary = AppDesignSystem.textSecondary;
  static const Color textTertiary = AppDesignSystem.textTertiary;
  static const Color textDisabled = AppDesignSystem.textDisabled;
  
  // Gradients
  static List<Color> get primaryGradient => AppDesignSystem.primaryGradient;
  static List<Color> get backgroundGradient => AppDesignSystem.backgroundGradient;
  static List<Color> get surfaceGradient => AppDesignSystem.surfaceGradient;
  static List<Color> get successGradient => AppDesignSystem.successGradient;
  static List<Color> get warningGradient => AppDesignSystem.warningGradient;
  static List<Color> get errorGradient => AppDesignSystem.errorGradient;
  
  // Border & Divider
  static const Color border = AppDesignSystem.surfaceElevated;
  static const Color divider = AppDesignSystem.surface;
}

