import 'package:flutter/material.dart';

/// A helper widget that listens to the mouse events and provides callbacks
/// for when auto scrolling should be engaged/disengaged, and when the
/// cursor is moved while auto scrolling is engaged.
///
class AutoScrollMouseListener extends StatefulWidget {
  /// Creates an [AutoScrollMouseListener] widget.
  ///
  const AutoScrollMouseListener({
    super.key,
    this.onStartScrolling,
    this.onEndScrolling,
    this.onMouseMoved,
    this.hideCursor = false,
    this.deadZoneRadius = 10,
    required this.child,
  });

  /// A callback that is called when the scrolling is engaged.
  ///
  final void Function(Offset startOffset)? onStartScrolling;

  /// A callback that is called when the scrolling is disengaged.
  ///
  final void Function()? onEndScrolling;

  /// A callback that is called when the mouse is moved.
  ///
  /// The callback is only called if scrolling is engaged.
  ///
  /// The startOffset is the position where the scrolling was engaged.
  /// The cursorOffset is the current position of the cursor.
  ///
  final void Function(Offset startOffset, Offset cursorOffset)? onMouseMoved;

  /// Whether to hide the cursor while scrolling.
  ///
  /// Defaults to `false`.
  ///
  final bool hideCursor;

  /// The radius of the dead zone.
  ///
  /// The dead zone is the area around the cursor where scrolling is not
  /// engaged.
  ///
  final int deadZoneRadius;

  /// The child [Widget].
  ///
  final Widget child;

  @override
  State<AutoScrollMouseListener> createState() =>
      _AutoScrollMouseListenerState();
}

class _AutoScrollMouseListenerState extends State<AutoScrollMouseListener> {
  bool isScrolling = false;
  bool leftDeadZone = false;
  Offset? startOffset;

  @override
  Widget build(BuildContext context) {
    // This is used to detect the cursor position, in the case where
    // auto scrolling is engaged by middle mouse click rather than
    // middle mouse click+drag.
    return MouseRegion(
      cursor: widget.hideCursor && isScrolling
          ? SystemMouseCursors.none
          : SystemMouseCursors.basic,
      onHover: (event) {
        if (isScrolling && startOffset != null) {
          widget.onMouseMoved?.call(startOffset!, event.position);
        }
      },
      child: Listener(
        onPointerDown: (event) {
          if (isScrolling) {
            return stopScrolling();
          }

          if (event.buttons != 4) return;

          setState(() {
            isScrolling = true;
            startOffset = event.position;
          });
          widget.onStartScrolling?.call(event.position);
        },
        onPointerUp: (event) {
          checkLeftDeadZone(event);

          if (leftDeadZone) {
            stopScrolling();
          }
        },
        onPointerMove: (event) {
          if (event.buttons != 4 || !isScrolling || startOffset == null) return;

          checkLeftDeadZone(event);
          widget.onMouseMoved?.call(startOffset!, event.position);
        },
        child: widget.child,
      ),
    );
  }

  void checkLeftDeadZone(PointerEvent event) {
    if (startOffset != null &&
        (event.position - startOffset!).distance > widget.deadZoneRadius) {
      setState(() => leftDeadZone = true);
    }
  }

  void stopScrolling() {
    widget.onEndScrolling?.call();
    setState(() {
      isScrolling = false;
      leftDeadZone = false;
    });
  }
}
