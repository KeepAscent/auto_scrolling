import 'package:auto_scrolling/auto_scrolling.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AutoScroll widget', () {
    testWidgets('Scroll disabled when not scrollable', (tester) async {
      var isScrolling = false;
      final controller = ScrollController();
      await tester.pumpWidget(
        _buildAutoScroll(
          controller: controller,
          addEnoughScrollSpace: false,
          onScrolling: (isS) => isScrolling = isS,
        ),
      );
      await tester.pumpAndSettle();

      expect(controller.position.maxScrollExtent, 0.0);
      expect(isScrolling, false);

      final center = tester.getCenter(find.byType(AutoScroll));

      await tester.tapAt(center, buttons: kMiddleMouseButton);
      await tester.pump();

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: center);
      await tester.pump();

      await gesture.moveBy(const Offset(0, 100));
      await tester.pumpAndSettle();

      expect(isScrolling, false);
    });

    testWidgets('Use PrimaryScrollController by default', (tester) async {
      late final BuildContext context;
      await tester.pumpWidget(
        _buildAutoScroll(
          isPrimary: true,
          onBuildContextReady: (ctx) => context = ctx,
        ),
      );
      await tester.pumpAndSettle();

      final controller = PrimaryScrollController.of(context);
      expect(controller, isNotNull);
      expect(controller.offset, 0.0);

      final center = tester.getCenter(find.byType(AutoScroll));

      await tester.tapAt(center, buttons: kMiddleMouseButton);
      await tester.pump();

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: center);
      await tester.pump();

      await gesture.moveBy(const Offset(0, 100));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(controller.offset, controller.position.maxScrollExtent);
    });

    testWidgets('Scroll vertically', (tester) async {
      final controller = ScrollController();
      await tester.pumpWidget(_buildAutoScroll(controller: controller));
      await tester.pumpAndSettle();

      expect(controller.offset, 0.0);

      final center = tester.getCenter(find.byType(AutoScroll));

      await tester.tapAt(center, buttons: kMiddleMouseButton);
      await tester.pump();

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: center);
      await tester.pump();

      await gesture.moveBy(const Offset(0, 100));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // We expect to be at the end, so the offset should be the maximum.
      expect(controller.offset, controller.position.maxScrollExtent);
    });

    testWidgets('Scroll horizontally', (tester) async {
      final controller = ScrollController();
      await tester.pumpWidget(
        _buildAutoScroll(
          controller: controller,
          scrollDirection: Axis.horizontal,
        ),
      );
      await tester.pumpAndSettle();

      expect(controller.offset, 0.0);

      final center = tester.getCenter(find.byType(AutoScroll));

      await tester.tapAt(center, buttons: kMiddleMouseButton);
      await tester.pump();

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: center);
      await tester.pump();

      await gesture.moveBy(const Offset(100, 0));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // We expect to be at the end, so the offset should be the maximum.
      expect(controller.offset, controller.position.maxScrollExtent);
    });

    testWidgets('Scroll horizontally and cancel scroll', (tester) async {
      final controller = ScrollController();
      var isScrolling = false;
      await tester.pumpWidget(
        _buildAutoScroll(
          controller: controller,
          scrollDirection: Axis.horizontal,
          onScrolling: (isS) => isScrolling = isS,
        ),
      );
      await tester.pumpAndSettle();

      expect(controller.offset, 0.0);

      final center = tester.getCenter(find.byType(AutoScroll));

      await tester.tapAt(center, buttons: kMiddleMouseButton);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: center);
      await gesture.moveBy(const Offset(15, 0));
      await tester.pump(const Duration(seconds: 1));

      expect(isScrolling, true);

      await tester.tapAt(center, buttons: kMiddleMouseButton);
      await tester.pumpAndSettle();

      final currentOffset = controller.offset;

      expect(isScrolling, false);

      // We expect to not be at the beginning or end
      expect(controller.offset, isNot(controller.position.maxScrollExtent));
      expect(controller.offset, isNot(0));

      await tester.pump(const Duration(seconds: 1));

      // We expect currentOffset to not have changed
      expect(controller.offset, currentOffset);
    });

    testWidgets('Show anchor when auto scrolling', (tester) async {
      const anchorLabel = 'Anchor';
      final controller = ScrollController();
      await tester.pumpWidget(
        _buildAutoScroll(
          controller: controller,
          scrollDirection: Axis.horizontal,
          anchorBuilder: (_) => const IgnorePointer(child: Text(anchorLabel)),
        ),
      );
      await tester.pumpAndSettle();

      expect(controller.offset, 0.0);

      final center = tester.getCenter(find.byType(AutoScroll));

      await tester.tapAt(center, buttons: kMiddleMouseButton);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: center);
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text(anchorLabel), findsOneWidget);

      await tester.tapAt(center, buttons: kMiddleMouseButton);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Auto scrolling has stopped, we should not see the anchor
      expect(find.text(anchorLabel), findsNothing);
    });

    testWidgets('Scroll vertically without releasing middle mouse button',
        (tester) async {
      var isScrolling = false;
      final controller = ScrollController();
      await tester.pumpWidget(
        _buildAutoScroll(
          controller: controller,
          onScrolling: (isS) => isScrolling = isS,
        ),
      );
      await tester.pumpAndSettle();

      expect(controller.offset, 0.0);

      final center = tester.getCenter(find.byType(AutoScroll));
      final pointer = TestPointer(
        1,
        PointerDeviceKind.mouse,
        null,
        kMiddleMouseButton,
      )..hover(center);

      await tester.sendEventToBinding(
        pointer.down(center, buttons: kMiddleMouseButton),
      );
      await tester.sendEventToBinding(
        pointer.move(center + const Offset(0, 100)),
      );

      expect(isScrolling, true);

      await tester.pumpAndSettle(const Duration(seconds: 5));

      // We expect to be at the end, so the offset should be the maximum.
      expect(controller.offset, controller.position.maxScrollExtent);

      expect(isScrolling, true);

      // Release auto scrolling
      await tester.sendEventToBinding(pointer.up());
      await tester.pump();

      expect(isScrolling, false);
    });

    testWidgets('Click to enable auto scrolling', (tester) async {
      final controller = ScrollController();
      var isScrolling = false;
      await tester.pumpWidget(
        _buildAutoScroll(
          controller: controller,
          onScrolling: (isS) => isScrolling = isS,
        ),
      );
      await tester.pumpAndSettle();

      expect(controller.offset, 0.0);

      final center = tester.getCenter(find.byType(AutoScroll));

      final pointer = TestPointer(
        1,
        PointerDeviceKind.mouse,
        null,
        kMiddleMouseButton,
      )..hover(center);

      await tester.sendEventToBinding(
        pointer.down(center, buttons: kMiddleMouseButton),
      );
      await tester.sendEventToBinding(pointer.up());

      await tester.pumpAndSettle(const Duration(seconds: 5));

      // We expect to not have moved
      expect(controller.offset, 0.0);

      // We expect auto scrolling to be engaged
      expect(isScrolling, true);
    });

    testWidgets('AutoScroll honors default deadZoneRadius', (tester) async {
      final controller = ScrollController();
      await tester.pumpWidget(_buildAutoScroll(controller: controller));
      await tester.pumpAndSettle();

      expect(controller.offset, 0.0);

      final center = tester.getCenter(find.byType(AutoScroll));

      final pointer = TestPointer(
        1,
        PointerDeviceKind.mouse,
        null,
        kMiddleMouseButton,
      )..hover(center);

      await tester.sendEventToBinding(
        pointer.down(center, buttons: kMiddleMouseButton),
      );

      // 10 is the default deadZoneRadius, so we move 9 pixels to be inside the
      // dead zone.
      await tester.sendEventToBinding(
        pointer.move(center + const Offset(0, 9)),
      );

      await tester.pumpAndSettle(const Duration(seconds: 5));

      // We expect to not have moved
      expect(controller.offset, 0.0);

      // Now move one more pixel to be outside the dead zone
      await tester.sendEventToBinding(
        pointer.move(center + const Offset(0, 10)),
      );

      await tester.pumpAndSettle(const Duration(seconds: 5));

      // We expect to have moved
      expect(controller.offset, isNot(0.0));
    });

    testWidgets('AutoScroll honors custom deadZoneRadius', (tester) async {
      const deadZoneRadius = 20;
      final controller = ScrollController();
      await tester.pumpWidget(
        _buildAutoScroll(
          controller: controller,
          deadZoneRadius: deadZoneRadius,
        ),
      );
      await tester.pumpAndSettle();

      expect(controller.offset, 0.0);

      final center = tester.getCenter(find.byType(AutoScroll));

      final pointer = TestPointer(
        1,
        PointerDeviceKind.mouse,
        null,
        kMiddleMouseButton,
      )..hover(center);

      await tester.sendEventToBinding(
        pointer.down(center, buttons: kMiddleMouseButton),
      );

      await tester.sendEventToBinding(
        pointer.move(center + const Offset(0, deadZoneRadius - 1)),
      );

      await tester.pumpAndSettle(const Duration(seconds: 5));

      // We expect to not have moved
      expect(controller.offset, 0.0);

      await tester.sendEventToBinding(
        pointer.move(center + Offset(0, deadZoneRadius.toDouble())),
      );

      await tester.pumpAndSettle(const Duration(seconds: 5));

      // We expect to have moved
      expect(controller.offset, isNot(0.0));
    });

    testWidgets('Custom cursor vertically', (tester) async {
      const upLabel = 'UP';
      const downLabel = 'DOWN';

      final controller = ScrollController();
      await tester.pumpWidget(
        _buildAutoScroll(
          controller: controller,
          willUseCustomCursor: (direction) => [
            AutoScrollDirection.up,
            AutoScrollDirection.down
          ].contains(direction),
          cursorBuilder: (direction) {
            if (direction == AutoScrollDirection.up) {
              return const Text(upLabel);
            } else if (direction == AutoScrollDirection.down) {
              return const Text(downLabel);
            }

            return null;
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(controller.offset, 0.0);

      final center = tester.getCenter(find.byType(AutoScroll));

      await tester.tapAt(center, buttons: kMiddleMouseButton);
      await tester.pump();

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: center);
      await tester.pump();

      expect(find.text(upLabel), findsNothing);
      expect(find.text(downLabel), findsNothing);

      await gesture.moveBy(const Offset(0, 15));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text(downLabel), findsOneWidget);
      expect(find.text(upLabel), findsNothing);

      await tester.pumpAndSettle(const Duration(seconds: 5));

      // We expect to be at the end, so the offset should be the maximum.
      expect(controller.offset, controller.position.maxScrollExtent);

      // Now we scroll up to test the other version of the cursor

      await gesture.moveTo(center + const Offset(0, -15));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text(upLabel), findsOneWidget);
      expect(find.text(downLabel), findsNothing);

      await tester.pumpAndSettle(const Duration(seconds: 5));

      // We expect to be at the beginning, so the offset should be 0.
      expect(controller.offset, 0.0);
    });
  });
}

Widget _buildAutoScroll({
  ScrollController? controller,
  bool addEnoughScrollSpace = true,
  Axis scrollDirection = Axis.vertical,
  void Function(bool isScrolling)? onScrolling,
  Widget Function(BuildContext)? anchorBuilder,
  int deadZoneRadius = 10,
  Widget? Function(AutoScrollDirection)? cursorBuilder,
  bool Function(AutoScrollDirection)? willUseCustomCursor,
  bool isPrimary = false,
  void Function(BuildContext)? onBuildContextReady,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) {
          onBuildContextReady?.call(context);

          return AutoScroll(
            willUseCustomCursor: willUseCustomCursor,
            cursorBuilder: cursorBuilder,
            deadZoneRadius: deadZoneRadius,
            anchorBuilder: anchorBuilder,
            controller: controller,
            scrollDirection: scrollDirection,
            onScrolling: onScrolling,
            child: ListView.builder(
              primary: isPrimary,
              controller: controller,
              scrollDirection: scrollDirection,
              itemCount: addEnoughScrollSpace ? 100 : 1,
              itemBuilder: (_, __) => SizedBox(
                height: addEnoughScrollSpace ? 500 : 30,
                width: addEnoughScrollSpace ? 500 : 30,
              ),
            ),
          );
        },
      ),
    ),
  );
}
