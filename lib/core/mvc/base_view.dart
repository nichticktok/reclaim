import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'base_controller.dart';

typedef ControllerBuilder<T extends BaseController> =
    Widget Function(BuildContext context, T controller);

/// Convenience widget for wiring a controller to a view using Provider.
class BaseView<T extends BaseController> extends StatelessWidget {
  const BaseView({
    super.key,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
  });

  final ControllerBuilder<T> builder;
  final WidgetBuilder? loadingBuilder;
  final Widget Function(BuildContext, Object error)? errorBuilder;

  @override
  Widget build(BuildContext context) {
    return Consumer<T>(
      builder: (context, controller, child) {
        if (controller.isLoading && loadingBuilder != null) {
          return loadingBuilder!(context);
        }
        if (controller.lastError != null && errorBuilder != null) {
          return errorBuilder!(context, controller.lastError!);
        }
        return builder(context, controller);
      },
    );
  }
}
