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
///  * [MaterialAutoScrollBehavior], alternative for the Material widget set.
///
class CupertinoAutoScrollBehavior extends CupertinoScrollBehavior {
  /// Creates a CupertinoScrollBehavior that adds [AutoScroll]s on desktop
  /// platforms in addition to default CupertinoScrollBehavior.
  ///
  /// To modify the built-in [AutoScroll] wrapper, specify `autoScrollBuilder`.
  ///
  const CupertinoAutoScrollBehavior({this.autoScrollBuilder});

  /// The [AutoScroll] builder that is called to build the [AutoScroll] wrapper
  /// to wrap every scroll views with [AutoScroll].
  ///
  /// If not provided, a default [AutoScroll] with [SingleDirectionAnchor]
  // widget will be used.
  ///
  final Widget Function(
    Widget child,
    Axis axis,
    ScrollController? controller,
  )? autoScrollBuilder;

  Widget _defaultAutoScroll(
    Widget child,
    Axis axis,
    ScrollController? controller,
  ) =>
      AutoScroll(
        controller: controller,
        scrollDirection: axis,
        anchorBuilder: (_) => SingleDirectionAnchor(
          direction: axis,
        ),
        child: child,
      );

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    final axis = axisDirectionToAxis(details.direction);
    final autoScrollWrapper = autoScrollBuilder ?? _defaultAutoScroll;

    switch (getPlatform(context)) {
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        assert(details.controller != null, 'Controller cannot be null.');
        return autoScrollWrapper(
          CupertinoScrollbar(
            controller: details.controller,
            child: child,
          ),
          axis,
          details.controller,
        );
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.iOS:
        return child;
    }
  }
}
