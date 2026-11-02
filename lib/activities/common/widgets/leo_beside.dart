import 'package:flutter/material.dart';

import '../../../app/widgets/leo_avatar.dart';
import '../item_controller.dart';

LeoPose leoPoseFor(ItemController controller) {
  if (controller.isSolved) return LeoPose.cheering;
  if (controller.hasMistake) return LeoPose.thinking;
  return LeoPose.front;
}

class LeoBeside extends StatelessWidget {
  const LeoBeside({super.key, required this.controller, required this.child, this.pose});

  static const maxLeoHeight = 180.0;
  static const leoShare = 0.3;

  final ItemController controller;
  final Widget child;
  final LeoPose? pose;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > constraints.maxHeight;
        final room = isWide ? constraints.maxHeight : constraints.maxHeight * leoShare;
        final leo = Padding(
          padding: const EdgeInsets.all(16),
          child: LeoAvatar(
            size: room.clamp(0, maxLeoHeight) - 32,
            pose: pose ?? leoPoseFor(controller),
          ),
        );
        return Flex(
          direction: isWide ? Axis.horizontal : Axis.vertical,
          crossAxisAlignment: isWide ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: isWide ? [leo, Expanded(child: child)] : [Expanded(child: child), leo],
        );
      },
    );
  }
}
