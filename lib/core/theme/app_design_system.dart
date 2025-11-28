import 'package:flutter/material.dart';

/// Modern design system inspired by top self-improvement apps
class AppDesignSystem {
  // ========== COLOR PALETTE ==========
  
  // Backgrounds - Layered depth with color tint options
  // You can customize these colors to change the overall theme
  // Options: Warm (brown/amber), Cool (blue/purple), Neutral (gray), Green, etc.
  
  // Current: Blue theme - much lighter and more vibrant
  static const Color backgroundDeep = Color(0xFF1E3A5F);      // Deep blue
  static const Color backgroundMain = Color(0xFF2A4A6F);      // Medium blue
  static const Color surface = Color(0xFF365A7F);             // Light blue
  static const Color surfaceElevated = Color(0xFF426A8F);     // Even lighter blue
  static const Color surfaceHighlight = Color(0xFF4E7A9F);    // Lightest blue
  
  // Alternative color schemes (uncomment to use):
  
  // Cool Blue/Purple Theme:
  // static const Color backgroundDeep = Color(0xFF1A1B26);
  // static const Color backgroundMain = Color(0xFF242530);
  // static const Color surface = Color(0xFF2A2B36);
  // static const Color surfaceElevated = Color(0xFF333440);
  // static const Color surfaceHighlight = Color(0xFF3A3B46);
  
  // Warm Amber Theme:
  // static const Color backgroundDeep = Color(0xFF1F1A14);
  // static const Color backgroundMain = Color(0xFF29241E);
  // static const Color surface = Color(0xFF332E28);
  // static const Color surfaceElevated = Color(0xFF3D3832);
  // static const Color surfaceHighlight = Color(0xFF47423C);
  
  // Neutral Gray Theme:
  // static const Color backgroundDeep = Color(0xFF1E1E1E);
  // static const Color backgroundMain = Color(0xFF242424);
  // static const Color surface = Color(0xFF2A2A2A);
  // static const Color surfaceElevated = Color(0xFF333333);
  // static const Color surfaceHighlight = Color(0xFF3A3A3A);
  
  // Deep Purple Theme:
  // static const Color backgroundDeep = Color(0xFF1A1626);
  // static const Color backgroundMain = Color(0xFF242030);
  // static const Color surface = Color(0xFF2A2636);
  // static const Color surfaceElevated = Color(0xFF332F40);
  // static const Color surfaceHighlight = Color(0xFF3A3646);
  
  // Primary Brand Colors
  static const Color primary = Color(0xFFFF7A00);
  static const Color primaryDark = Color(0xFFE66A00);
  static const Color primaryLight = Color(0xFFFF9A33);
  
  // Accent Colors - Vibrant but balanced
  static const Color accentPurple = Color(0xFF9C27B0);
  static const Color accentBlue = Color(0xFF2196F3);
  static const Color accentTeal = Color(0xFF00BCD4);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color accentPink = Color(0xFFE91E63);
  static const Color accentAmber = Color(0xFFFFC107);
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE57373);
  static const Color warning = Color(0xFFFFB74D);
  static const Color info = Color(0xFF64B5F6);
  
  // Text Colors - High contrast for readability
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFE0E0E0);
  static const Color textTertiary = Color(0xFFB0B0B0);
  static const Color textDisabled = Color(0xFF808080);
  
  // ========== GRADIENTS ==========
  
  static List<Color> get primaryGradient => [
    primary,
    primaryLight,
  ];
  
  static List<Color> get backgroundGradient => [
    backgroundDeep,
    backgroundMain,
    surface,
  ];
  
  // Main screen background gradient (blue theme - vibrant and visible)
  static List<Color> get lightBackgroundGradient => [
    const Color(0xFF1E3A5F),  // Top - deep blue
    const Color(0xFF2A4A6F),  // Middle - medium blue
    const Color(0xFF365A7F),  // Bottom - lighter blue
  ];
  
  // Alternative gradient with more color variation
  static List<Color> get warmBackgroundGradient => [
    const Color(0xFF1F1A14),  // Deep warm brown
    const Color(0xFF29241E),  // Medium warm brown
    const Color(0xFF332E28),  // Light warm brown
  ];
  
  static List<Color> get coolBackgroundGradient => [
    const Color(0xFF1A1B26),  // Deep blue-gray
    const Color(0xFF242530),  // Medium blue-gray
    const Color(0xFF2A2B36),  // Light blue-gray
  ];
  
  static List<Color> get purpleBackgroundGradient => [
    const Color(0xFF1A1626),  // Deep purple-gray
    const Color(0xFF242030),  // Medium purple-gray
    const Color(0xFF2A2636),  // Light purple-gray
  ];
  
  static List<Color> get surfaceGradient => [
    surface,
    surfaceElevated,
  ];
  
  // Status Gradients
  static List<Color> get successGradient => [
    const Color(0xFF4CAF50),
    const Color(0xFF66BB6A),
  ];
  
  static List<Color> get warningGradient => [
    const Color(0xFFFFB74D),
    const Color(0xFFFFCA28),
  ];
  
  static List<Color> get errorGradient => [
    const Color(0xFFE57373),
    const Color(0xFFEF5350),
  ];
  
  // ========== SHADOWS & ELEVATION ==========
  
  static List<BoxShadow> get shadowSmall => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get shadowMedium => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.3),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get shadowLarge => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.4),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];
  
  // Colored shadows for cards
  static List<BoxShadow> getColoredShadow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.4),
      blurRadius: 16,
      offset: const Offset(0, 6),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.3),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
  
  // ========== GLASSMORPHISM ==========
  
  static BoxDecoration glassCard({
    Color? color,
    double borderRadius = 20,
    Border? border,
  }) {
    return BoxDecoration(
      color: (color ?? surface).withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(borderRadius),
      border: border ?? Border.all(
        color: Colors.white.withValues(alpha: 0.1),
        width: 1,
      ),
      boxShadow: shadowMedium,
    );
  }
  
  // ========== CARD STYLES ==========
  
  static BoxDecoration modernCard({
    Color? backgroundColor,
    List<Color>? gradient,
    double borderRadius = 20,
    List<BoxShadow>? shadows,
    Border? border,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: gradient == null ? (backgroundColor ?? surface) : null,
      gradient: gradient != null
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            )
          : null,
      borderRadius: BorderRadius.circular(borderRadius),
      border: border ??
          (borderColor != null
              ? Border.all(color: borderColor, width: 1.5)
              : null),
      boxShadow: shadows ?? shadowMedium,
    );
  }
  
  // ========== BUTTON STYLES ==========
  
  static BoxDecoration primaryButton({bool isActive = true}) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isActive ? primaryGradient : [
          textTertiary,
          textDisabled,
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: isActive ? [
        BoxShadow(
          color: primary.withValues(alpha: 0.4),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ] : null,
    );
  }
  
  static BoxDecoration outlineButton({Color? borderColor}) {
    return BoxDecoration(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: borderColor ?? primary,
        width: 2,
      ),
    );
  }
  
  // ========== TYPOGRAPHY ==========
  
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: -0.3,
    height: 1.3,
  );
  
  static const TextStyle heading3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: 0,
    height: 1.4,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.normal,
    color: textSecondary,
    letterSpacing: 0.2,
    height: 1.6,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textSecondary,
    letterSpacing: 0.2,
    height: 1.5,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textTertiary,
    letterSpacing: 0.2,
    height: 1.4,
  );
  
  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: 0.3,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textTertiary,
    letterSpacing: 0.3,
  );
  
  // ========== SPACING ==========
  
  static const double spacingXS = 4;
  static const double spacingSM = 8;
  static const double spacingMD = 16;
  static const double spacingLG = 24;
  static const double spacingXL = 32;
  static const double spacingXXL = 48;
  
  // ========== BORDER RADIUS ==========
  
  static const double radiusSM = 8;
  static const double radiusMD = 12;
  static const double radiusLG = 16;
  static const double radiusXL = 20;
  static const double radiusXXL = 24;
  
  // ========== ANIMATIONS ==========
  
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  
  static const Curve animationCurve = Curves.easeOutCubic;
  
  // ========== DECORATIVE ELEMENTS ==========
  
  /// Creates a subtle gradient overlay for depth
  static Widget gradientOverlay({
    required List<Color> colors,
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: begin,
          end: end,
          colors: colors,
        ),
      ),
    );
  }
  
  /// Creates a radial glow effect
  static Widget radialGlow({
    required Color color,
    double radius = 100,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: radius,
            spreadRadius: radius * 0.5,
          ),
        ],
      ),
    );
  }
}

