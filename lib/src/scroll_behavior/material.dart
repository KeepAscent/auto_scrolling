import 'package:auto_scrolling/auto_scrolling.dart';
import 'package:flutter/material.dart';

/// Describes how [Scrollable] widgets behave for [MaterialApp]s.
///
/// This is an extension of the default [MaterialScrollBehavior], providing
/// [AutoScroll] for every [Scrollable] widget.
///
/// See also:
///
///  * [ScrollBehavior], the default scrolling behavior extended by this class.
///  * [CupertinoAutoScrollBehavior], alternative for Cupertino widget set.
class MaterialAutoScrollBehavior extends MaterialScrollBehavior {
  /// Creates a MaterialScrollBehavior that adds [AutoScroll]s on desktop
  /// platforms in addition to default MaterialScrollBehavior.
  const MaterialAutoScrollBehavior();

  @override
  Widget buildScrollbar(
      BuildContext context, Widget child, ScrollableDetails details) {
    switch (getPlatform(context)) {
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        assert(details.controller != null, 'Controller cannot be null.');
        switch (axisDirectionToAxis(details.direction)) {
          case Axis.horizontal:
            return AutoScroll(
              controller: details.controller,
              scrollDirection: Axis.horizontal,
              anchorBuilder: (_) => const SingleDirectionAnchor(
                direction: Axis.horizontal,
              ),
              child: Scrollbar(
                controller: details.controller,
                child: child,
              ),
            );
          case Axis.vertical:
            return AutoScroll(
              controller: details.controller,
              anchorBuilder: (_) => const SingleDirectionAnchor(),
              child: Scrollbar(
                controller: details.controller,
                child: child,
              ),
            );
        }
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.iOS:
        return child;
    }
  }
}
