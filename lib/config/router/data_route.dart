import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// In-memory route arguments are absent after opening a deep link or restoring
/// a browser URL. Recover on the existing error page instead of a cast crash.
class DataRoute extends GoRoute {
  DataRoute({
    required super.path,
    required GoRouterWidgetBuilder builder,
    required Widget Function() missingDataBuilder,
    super.routes = const <RouteBase>[],
  }) : super(
          builder: (context, state) {
            try {
              return builder(context, state);
            } on TypeError {
              return missingDataBuilder();
            }
          },
        );
}
