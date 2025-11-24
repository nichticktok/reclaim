import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/screen_blocker_controller.dart';

/// Widget that monitors app lifecycle and prevents/minimizes app closure
/// when screen blocker is active
class ScreenBlockerLifecycleObserver extends StatefulWidget {
  final Widget child;

  const ScreenBlockerLifecycleObserver({
    super.key,
    required this.child,
  });

  @override
  State<ScreenBlockerLifecycleObserver> createState() =>
      _ScreenBlockerLifecycleObserverState();
}

class _ScreenBlockerLifecycleObserverState
    extends State<ScreenBlockerLifecycleObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (!mounted) return;
    
    final controller = context.read<ScreenBlockerController>();
    
    if (!controller.isBlocked) return;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // App is going to background - track and show warning
        controller.onAppBackgrounded();
        // Note: We can't show UI when app is in background, but we track it
        debugPrint('🔒 App went to background while screen blocker is active');
        break;
      case AppLifecycleState.resumed:
        // App came back to foreground - show reminder
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showReturnReminder(controller);
          }
        });
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App is being closed or hidden
        _showClosureWarning();
        break;
    }
  }

  void _showReturnReminder(ScreenBlockerController controller) {
    if (!mounted) return;
    
    final backgroundCount = controller.backgroundCount;
    final message = backgroundCount > 0
        ? 'You left the app $backgroundCount time${backgroundCount > 1 ? 's' : ''} while the blocker was active. ${controller.remainingTimeString} remaining.'
        : 'Screen blocker still active. ${controller.remainingTimeString} remaining.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              backgroundCount > 0 ? Icons.warning : Icons.lock,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundCount > 0
            ? Colors.orange
            : const Color(0xFF5D6D7E),
        duration: Duration(seconds: backgroundCount > 0 ? 5 : 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }


  void _showClosureWarning() {
    if (!mounted) return;
    
    // Note: This may not always show if app is force-closed
    debugPrint('🔒 Warning: App closure detected while screen blocker is active');
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

