import 'package:auto_scrolling/auto_scrolling.dart';
import 'package:flutter/material.dart';

class SingleDirectionScrollSample extends StatefulWidget {
  const SingleDirectionScrollSample({super.key});

  @override
  State<SingleDirectionScrollSample> createState() =>
      _SingleDirectionScrollSampleState();
}

class _SingleDirectionScrollSampleState
    extends State<SingleDirectionScrollSample> {
  bool isVertical = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(isVertical ? 'Vertical' : 'Horizontal'),
              const SizedBox(width: 4),
              Switch(
                value: isVertical,
                onChanged: (value) => setState(() => isVertical = value),
              ),
            ],
          ),
        ),
        Expanded(
          child: AutoScroll(
            willUseCustomCursor: (direction) => switch (direction) {
              AutoScrollDirection.down ||
              AutoScrollDirection.up ||
              AutoScrollDirection.left ||
              AutoScrollDirection.right =>
                true,
              _ => false,
            },
            cursorBuilder: (direction) {
              if (direction == AutoScrollDirection.none) {
                return null;
              }

              return DirectionArrow(direction: direction);
            },
            anchorBuilder: (_) => SingleDirectionAnchor(
              direction: isVertical ? Axis.vertical : Axis.horizontal,
            ),
            scrollDirection: isVertical ? Axis.vertical : Axis.horizontal,
            child: ListView.builder(
              primary: true,
              scrollDirection: isVertical ? Axis.vertical : Axis.horizontal,
              itemCount: 100,
              itemBuilder: (_, index) => Container(
                height: isVertical ? 500 : double.infinity,
                width: isVertical ? double.infinity : 500,
                color: colorForIndex(index),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color colorForIndex(int index) {
    if (index % 5 == 0) return Colors.blue;
    if (index % 5 == 1) return Colors.red;
    if (index % 5 == 2) return Colors.orange;
    if (index % 5 == 3) return Colors.green;
    if (index % 5 == 4) return Colors.purple;

    return Colors.black;
  }
}
