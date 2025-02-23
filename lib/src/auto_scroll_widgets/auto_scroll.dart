import 'dart:async';

import 'package:auto_scrolling/auto_scrolling.dart';
import 'package:auto_scrolling/src/auto_scroll_mouse_listener.dart';
import 'package:flutter/material.dart';

/// A widget that wraps a [Scrollable] widget and enables auto-scrolling in
/// a singular direction at a time. For multi-directional auto scrolling, see
/// the MultiAxisAutoScroll widget.
///
/// It provides 2 ways to engage auto-scrolling:
///  1. By pressing and releasing the middle mouse button, drag the cursor to
///   the desired direction.
///
///   The auto-scrolling will stay engaged until a click is made. This can be
///   done both by pressing the middle mouse button again or by pressing any
///   other mouse button.
///
///  2. By pressing the middle mouse button and dragging the cursor to the
///   desired direction.
///
///   The auto-scrolling will stay engaged until the middle mouse button
///   is released.
///
class AutoScroll extends StatefulWidget {
  /// Creates an [AutoScroll] widget.
  ///
  const AutoScroll({
    super.key,
    this.controller,
    this.scrollDirection = Axis.vertical,
    this.onScrolling,
    this.deadZoneRadius = 10,
    this.velocity = 0.2,
    this.scrollTick = 15,
    this.anchorBuilder,
    this.willUseCustomCursor,
    this.cursorBuilder,
    required this.child,
  });

  /// The [ScrollController] attached to the [Scrollable] widget.
  ///
  /// This has to be the same controller that is attached to
  /// the [Scrollable] widget.
  ///
  /// If the controller is not provided, it will default to the
  /// [PrimaryScrollController].
  ///
  final ScrollController? controller;

  /// The direction of the scroll.
  ///
  /// Defaults to [Axis.vertical].
  ///
  final Axis scrollDirection;

  /// A callback that is called when the scroll engages or disengages.
  ///
  final void Function(bool isScrolling)? onScrolling;

  /// A radius around the start position of the cursor, where the scrolling
  /// will not engage.
  ///
  /// Defaults to 10 pixels.
  ///
  final int deadZoneRadius;

  /// The velocity of the scroll, can be used to adjust the speed by a factor.
  ///
  /// The higher the value, the faster the scroll.
  ///
  /// Defaults to 0.2.
  ///
  final double velocity;

  /// The time in milliseconds between each scroll tick.
  ///
  /// Can be used in tandem with [velocity] to fine-tune the scroll speed. It
  /// is generally not recommended to change this value, as it can lead to
  /// visual issues such as stuttering due to the delay in scrolling.
  ///
  /// The lower the value, the smoother and faster the scroll will be. However,
  /// it will also trigger more often, which can be a performance trade-off for
  /// complex scrollable widgets.
  ///
  /// If the value is too low, it can also lead to the scroll being too fast
  /// and uncontrollable. It is recommended to test the scroll speed with the
  /// default value before changing it.
  ///
  /// Defaults to 15 milliseconds.
  ///
  ///
  final int scrollTick;

  /// A function that is called to build the anchor widget.
  ///
  /// The anchor widget is the widget that will be placed at the cursors
  /// initial position when the auto-scrolling is engaged.
  ///
  /// If not provided, the anchor won't be displayed.
  ///
  final Widget Function(BuildContext)? anchorBuilder;

  /// A function that is called to determine wether a custom cursor should
  /// be displayed. If the function returns `true`, the custom cursor will
  /// be displayed, otherwise the system cursor will be displayed.
  ///
  /// The function is called with the current direction of the auto-scroll.
  ///
  final bool Function(AutoScrollDirection direction)? willUseCustomCursor;

  /// The cursor builder that is called to build the cursor widget.
  ///
  /// If not provided, the cursor will default to the system cursor.
  ///
  final CursorBuilder? cursorBuilder;

  /// The child [Widget].
  ///
  final Widget child;

  @override
  State<AutoScroll> createState() => _AutoScrollState();
}

class _AutoScrollState extends State<AutoScroll> {
  final _key = GlobalKey();

  late ScrollController controller;

  Timer? scrollTimer;

  Offset? startOffset;
  Offset? cursorOffset;
  AutoScrollDirection direction = AutoScrollDirection.none;

  bool get useCustomCursor =>
      startOffset != null &&
      widget.cursorBuilder != null &&
      (widget.willUseCustomCursor?.call(direction) ?? false);

  bool canScroll = false;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller = widget.controller ?? PrimaryScrollController.of(context);

      setState(() {
        canScroll =
            controller.hasClients && controller.position.maxScrollExtent > 0;
      });
    });
    super.initState();
  }

  @override
  void didUpdateWidget(covariant AutoScroll oldWidget) {
    if (widget.controller != oldWidget.controller) {
      controller = widget.controller ?? PrimaryScrollController.of(context);
      scrollTimer?.cancel();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    scrollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: useCustomCursor ? SystemMouseCursors.none : MouseCursor.defer,
      child: Stack(
        key: _key,
        children: [
          Positioned.fill(
            child: AutoScrollMouseListener(
              isEnabled: canScroll,
              deadZoneRadius: widget.deadZoneRadius,
              hideCursor: useCustomCursor,
              onStartScrolling: (startOffset) {
                setState(() {
                  this.startOffset = startOffset;
                  cursorOffset = startOffset;
                });
                startScrolling();
              },
              onEndScrolling: stopScrolling,
              onMouseMoved: (_, cursorOffset) {
                setState(() => this.cursorOffset = cursorOffset);
              },
              child: widget.child,
            ),
          ),
          buildAnchor(),
          if (cursorOffset != null && widget.cursorBuilder != null)
            AutoScrollCustomCursor(
              parentKey: _key,
              cursorOffset: cursorOffset!,
              direction: direction,
              cursorBuilder: widget.cursorBuilder!,
            ),
        ],
      ),
    );
  }

  Offset getAnchorOffset() {
    final renderBox = _key.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox == null || startOffset == null) return Offset.zero;

    return renderBox.globalToLocal(startOffset!);
  }

  Widget buildAnchor() {
    if (startOffset == null || widget.anchorBuilder == null) {
      return const SizedBox.expand();
    }

    final localOffset = getAnchorOffset();
    return Positioned(
      left: localOffset.dx,
      top: localOffset.dy,
      child: GestureDetector(
        onTap: stopScrolling,
        child: FractionalTranslation(
          translation: const Offset(-0.5, -0.5),
          child: widget.anchorBuilder!.call(context),
        ),
      ),
    );
  }

  /// Starts scrolling according to the cursors placement compared to the
  /// start offset.
  ///
  /// This method starts a timer, that will repeatedly move the position of
  /// the [ScrollController].
  ///
  void startScrolling() {
    // Notify that scrolling has started.
    widget.onScrolling?.call(true);

    scrollTimer?.cancel();
    scrollTimer =
        Timer.periodic(Duration(milliseconds: widget.scrollTick), (timer) {
      if (startOffset == null || cursorOffset == null) {
        return scrollTimer?.cancel();
      }

      if (!shouldMove()) {
        direction = AutoScrollDirection.none;
        return;
      }

      final move = switch (widget.scrollDirection) {
        Axis.horizontal => startOffset!.dx - cursorOffset!.dx,
        Axis.vertical => startOffset!.dy - cursorOffset!.dy,
      };

      controller.position.moveTo(
        controller.position.pixels - move * widget.velocity,
      );

      direction = switch (widget.scrollDirection) {
        Axis.horizontal =>
          move > 0 ? AutoScrollDirection.left : AutoScrollDirection.right,
        Axis.vertical =>
          move > 0 ? AutoScrollDirection.up : AutoScrollDirection.down,
      };
    });
  }

  /// Stops scrolling by cancelling the timer and resetting the state.
  ///
  void stopScrolling() {
    setState(() {
      scrollTimer?.cancel();
      startOffset = null;
      cursorOffset = null;
      direction = AutoScrollDirection.none;
    });

    // Notify that scrolling has ended.
    widget.onScrolling?.call(false);
  }

  /// Checks whether the cursor has moved out of the deadZoneRadius from
  /// the [startOffset].
  ///
  /// Returns `true` if the cursor has moved out of the dead zone,
  /// otherwise `false`.
  ///
  bool shouldMove() {
    final difference = widget.scrollDirection == Axis.horizontal
        ? (cursorOffset!.dx - startOffset!.dx).abs()
        : (cursorOffset!.dy - startOffset!.dy).abs();
    if (difference < widget.deadZoneRadius) {
      return false;
    }

    return true;
  }
}
