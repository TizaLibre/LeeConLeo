import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum LeoPose { front, side, happy, thinking, cheering, clapping }

class LeoAvatar extends StatelessWidget {
  const LeoAvatar({super.key, this.size = 160, this.pose = LeoPose.front});

  static const aspectRatio = 400 / 560;

  final double size;
  final LeoPose pose;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/leo/leo_${pose.name}.svg',
      key: ValueKey('leo-${pose.name}'),
      height: size,
      width: size * aspectRatio,
    );
  }
}
