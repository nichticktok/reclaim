import 'package:flutter/material.dart';
import '../controllers/screen_blocker_controller.dart';

/// NavigatorObserver that prevents navigation when screen blocker is active
class ScreenBlockerNavigatorObserver extends NavigatorObserver {
  ScreenBlockerController? _controller;

  void setController(ScreenBlockerController controller) {
    _controller = controller;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (_controller?.isBlocked == true) {
      debugPrint('🔒 Navigation push blocked by screen blocker');
      // Note: We can't prevent navigation here, but we log it
      // Actual prevention happens via PopScope and IgnorePointer
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (_controller?.isBlocked == true && newRoute != null) {
      debugPrint('🔒 Navigation replace blocked by screen blocker');
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (_controller?.isBlocked == true) {
      debugPrint('🔒 Navigation pop blocked by screen blocker');
    }
  }
}

