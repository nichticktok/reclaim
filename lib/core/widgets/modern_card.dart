import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_design_system.dart';

/// Modern card widget with glassmorphism and gradients
class ModernCard extends StatelessWidget {
  final Widget child;
  final List<Color>? gradient;
  final Color? backgroundColor;
  final double borderRadius;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? borderColor;
  final double? borderWidth;
  final List<BoxShadow>? shadows;
  final VoidCallback? onTap;
  final bool useGlassmorphism;

  const ModernCard({
    super.key,
    required this.child,
    this.gradient,
    this.backgroundColor,
    this.borderRadius = 20,
    this.padding,
    this.margin,
    this.borderColor,
    this.borderWidth,
    this.shadows,
    this.onTap,
    this.useGlassmorphism = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      margin: margin ?? const EdgeInsets.only(bottom: 16),
      decoration: useGlassmorphism
          ? AppDesignSystem.glassCard(
              color: backgroundColor,
              borderRadius: borderRadius,
              border: borderColor != null
                  ? Border.all(
                      color: borderColor!,
                      width: borderWidth ?? 1.5,
                    )
                  : null,
            )
          : AppDesignSystem.modernCard(
              backgroundColor: backgroundColor,
              gradient: gradient,
              borderRadius: borderRadius,
              shadows: shadows,
              borderColor: borderColor,
            ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: useGlassmorphism
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Padding(
                  padding: padding ?? const EdgeInsets.all(20),
                  child: child,
                ),
              )
            : Padding(
                padding: padding ?? const EdgeInsets.all(20),
                child: child,
              ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}

