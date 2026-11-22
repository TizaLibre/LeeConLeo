import 'package:material_ui/material_ui.dart';

import '../../../app/app_theme.dart';

class ProgressStar extends StatefulWidget {
  const ProgressStar({super.key, required this.isEarned, this.size = 32});

  static const popDuration = Duration(milliseconds: 900);
  static const popScale = 2.2;

  final bool isEarned;
  final double size;

  @override
  State<ProgressStar> createState() => _ProgressStarState();
}

class _ProgressStarState extends State<ProgressStar> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: ProgressStar.popDuration);
  late final _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: 1.0, end: ProgressStar.popScale).chain(CurveTween(curve: Curves.easeOut)),
      weight: 35,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: ProgressStar.popScale,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.elasticOut)),
      weight: 65,
    ),
  ]).animate(_controller);

  @override
  void didUpdateWidget(ProgressStar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isEarned && !oldWidget.isEarned) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Icon(
        Icons.star_rounded,
        size: widget.size,
        color: widget.isEarned ? AppTheme.starGold : Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }
}
