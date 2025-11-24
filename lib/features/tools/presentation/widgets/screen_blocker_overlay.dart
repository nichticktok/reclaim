import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/screen_blocker_controller.dart';

/// Overlay widget that blocks app access when screen blocker is active
/// This should be placed at the root of the app to intercept all interactions
class ScreenBlockerOverlay extends StatelessWidget {
  final Widget child;

  const ScreenBlockerOverlay({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ScreenBlockerController>(
      builder: (context, controller, child) {
        if (!controller.isBlocked) {
          return this.child;
        }

        // Show blocking overlay - prevent all navigation and interactions
        return PopScope(
          canPop: false, // Prevent back navigation when blocked
          onPopInvokedWithResult: (bool didPop, dynamic result) {
            // Explicitly prevent pop
            if (didPop) {
              // This shouldn't happen, but if it does, we log it
              debugPrint('🔒 Attempted to pop while screen is blocked');
            }
          },
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Stack(
              children: [
                // Original content (blocked)
                IgnorePointer(
                  ignoring: true, // Block all pointer events to underlying content
                  child: this.child,
                ),
                // Blocking overlay - blocks all gestures using AbsorbPointer
                Positioned.fill(
                  child: AbsorbPointer(
                    absorbing: true, // Absorb all pointer events
                    child: Material(
                      color: const Color(0xFF0D0D0F),
                      child: SafeArea(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.lock,
                                color: Color(0xFF5D6D7E),
                                size: 80,
                              ),
                              const SizedBox(height: 32),
                              const Text(
                                'Screen Blocked',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                controller.remainingTimeString,
                                style: const TextStyle(
                                  color: Color(0xFF5D6D7E),
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Remaining',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 48),
                              if (controller.blockEndTime != null)
                                Text(
                                  'Block ends at ${_formatTime(controller.blockEndTime!)}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour < 12 ? 'AM' : 'PM';
    return '${hour == 0 ? 12 : hour}:$minute $period';
  }
}

