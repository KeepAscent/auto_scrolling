import 'package:auto_scrolling/auto_scrolling.dart';
import 'package:flutter/cupertino.dart';

/// Describes how [Scrollable] widgets behave for [CupertinoApp]s.
///
/// This is an extension of the default [CupertinoScrollBehavior], providing
/// [AutoScroll] for every [Scrollable] widget.
///
/// See also:
///
///  * [ScrollBehavior], the default scrolling behavior extended by this class.
///  * [CupertinoAutoScrollBehavior], alternative for Material widget set.
class CupertinoAutoScrollBehavior extends CupertinoScrollBehavior {
  /// Creates a CupertinoScrollBehavior that adds [AutoScroll]s on desktop
  /// platforms in addition to default CupertinoScrollBehavior.
  const CupertinoAutoScrollBehavior();

  @override
  Widget buildScrollbar(
      BuildContext context, Widget child, ScrollableDetails details) {
    switch (getPlatform(context)) {
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        switch (axisDirectionToAxis(details.direction)) {
          case Axis.horizontal:
            return AutoScroll(
              controller: details.controller,
              scrollDirection: Axis.horizontal,
              anchorBuilder: (_) => const SingleDirectionAnchor(
                direction: Axis.horizontal,
              ),
              child: CupertinoScrollbar(
                controller: details.controller,
                child: child,
              ),
            );
          case Axis.vertical:
            return AutoScroll(
              controller: details.controller,
              anchorBuilder: (_) => const SingleDirectionAnchor(),
              child: CupertinoScrollbar(
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
