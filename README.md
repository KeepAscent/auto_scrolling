# Auto Scrolling

[![Pub](https://img.shields.io/pub/v/auto_scrolling.svg)](https://pub.dev/packages/auto_scrolling) [![codecov](https://codecov.io/gh/KeepAscent/auto_scrolling/graph/badge.svg?token=TZZMYDU9Y7)](https://codecov.io/gh/KeepAscent/auto_scrolling) [![License: MIT](https://img.shields.io/badge/License-MIT-brightgreen.svg)](https://opensource.org/license/mit) ![Continuous integration](https://github.com/KeepAscent/auto_scrolling/actions/workflows/ci.yml/badge.svg)

This package provides widgets that enhances scrollable widgets by enabling auto-scrolling, a common feature in desktop and web applications.

## Features

- Two ways to engage auto scroll
- Supports custom anchor (similar to FireFox)
- Supports custom cursor for directional cursor
- Pre-built anchors and cursors to get you up and auto scrolling quickly
- Support for both single and multi directional scrolling

This package supports two built-in methods to activate auto-scrolling:

**Middle Mouse Click (Press & Release)**

- Click the middle mouse button (scroll wheel) once to activate auto-scrolling.
- Move the cursor in the desired direction to scroll.
- Click any mouse button to exit auto-scrolling mode.

**Middle Mouse Click & Drag**

- Press and hold the middle mouse button (scroll wheel) to activate auto-scrolling.
- Drag the cursor in the desired direction to scroll.
- Release the middle mouse button to exit auto-scrolling mode.

## Platform Support

This package supports all platforms, but does require mouse events to trigger the auto scroll feature.

## Getting started

### Install

Add the package to your dependencies, see how under [`Installing`](https://pub.dev/packages/auto_scrolling/install).

### Usage

Simply wrap your scrollable such as ListView, SingleChildScrollView, etc. With the AutoScroll widget as such:

```dart
AutoScroll(
  controller: controller,
  child: ListView.builder(
    controller: controller,
    itemCount: ...,
    itemBuilder: ...,
  ),
),
```

_Notice that the `AutoScroll` widget requires the same `ScrollController` as your scrollable._

The `AutoScroll` widget only supports single direction scrolling, to enable auto scroll on a view with both horizontal and vertical scrollables, use the `MultiAxisAutoScroll` widget like this:

```dart
MultiAxisAutoScroll(
  verticalController: verticalController,
  horizontalController: horizontalController,
  child: ...,
),
```

_Notice again, that the vertical and horizontal controller should be the same as those attached to your scrollables._

## Customization

Both `AutoScroll` and `MultiAxisAutoScroll` support custom anchor and cursor widgets.

An anchor is a widget that stays at the start offset when engaging auto scroll, similar to on FireFox. The anchor builder can be used simply like this:

```dart
AutoScroll(
  anchorBuilder: (context) => SingleDirectionAnchor(
    direction: Axis.horizontal,
  ),
  ...,
),
```

The above will ensure that an anchor with an arrow left and right, stays on the starting position when engaging auto scroll. For an anchor with arrows in all directions, use `MultiDirectionAnchor()`.

In some applications, example Google Chrome, the cursor turns into an anchor instead when auto scroll is engaged but there is no movement. This happens when the cursor is too close to the anchor position (start offset).

This can be achieved by leveraging `CursorBuilder`. To do so, simply provide a `CursorBuilder` method as such:

```dart
AutoScroll(
  willUseCustomCursor: (direction) => switch (direction) {
    AutoScrollDirection.none => true,
    _ => false,
  },
  cursorBuilder: (bool isMoving, AutoScrollDirection direction) {
    if (direction == AutoScrollDirection.none) {
      // No scroll currently active
      return SingleDirectionAnchor();
    }

    // Show default cursor
    return null;
  },
  ...,
),
```

It is important to notice the `willUseCustomCursor` callback, in the above case we want to show a custom cursor only when there is no scroll direction. If we change it to an example in which we show an arrow up or down depending on the scroll direction, we should add it to the callback:

```dart
AutoScroll(
  willUseCustomCursor: (direction) => switch (direction) {
    AutoScrollDirection.none ||
     AutoScrollDirection.up ||
     AutoScrollDirection.down => true,
    _ => false,
  },
  cursorBuilder: (bool isMoving, AutoScrollDirection direction) {
    if (direction == AutoScrollDirection.none) {
      // No scroll currently active
      return SingleDirectionAnchor();
    }

    // If we are moving up or down, turn the cursor into an arrow
    // turned in the corresponding scroll direction.
    return switch (direction) {
      AutoScrollDirection.none => const SingleDirectionAnchor(),
      AutoScrollDirection.up || AutoScrollDirection.down => DirectionArrow(direction: direction),
      _ => null,
    };
  },
  ...,
),
```

When using `AutoScroll` or `MultiAxisAutoScroll` the default dead zone radius is set to 10 pixels, and can be modified by providing a different value for `deadZoneRadius`, like this:

```dart
AutoScroll(
  deadZoneRadius: 15,
  ...,
),
```
