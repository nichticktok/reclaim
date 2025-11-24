import 'package:flutter/material.dart';
import '../theme/app_design_system.dart';

/// Wrapper widget that adds the rounded top accent/divider between content and bottom navigation
class ScreenContentWrapper extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? backgroundColor;

  const ScreenContentWrapper({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: backgroundColor != null
              ? [
                  backgroundColor!,
                  backgroundColor!.withOpacity(0.95),
                ]
              : [
                  AppDesignSystem.backgroundMain,
                  AppDesignSystem.surface,
                ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: child,
      ),
    );
  }
}

