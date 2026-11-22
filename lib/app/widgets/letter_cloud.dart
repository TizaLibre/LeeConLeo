import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../../activities/common/widgets/letter_bubble.dart';

class FloatingLetter {
  const FloatingLetter(this.letter, this.center, this.size);

  final String letter;
  final Alignment center;
  final double size;
}

class LetterCloud extends StatefulWidget {
  const LetterCloud({
    super.key,
    required this.letters,
    required this.child,
    this.childSize = 0.6,
    this.childCenter = Alignment.center,
    this.animate = true,
    this.letterShare = 0.9,
  });

  static const floatPeriod = Duration(seconds: 3);
  static const floatShare = 0.06;

  final List<FloatingLetter> letters;
  final Widget child;
  final double childSize;
  final Alignment childCenter;
  final bool animate;
  final double letterShare;

  @override
  State<LetterCloud> createState() => _LetterCloudState();
}

class _LetterCloudState extends State<LetterCloud> with SingleTickerProviderStateMixin {
  late final _float = AnimationController(vsync: this, duration: LetterCloud.floatPeriod);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.animate || MediaQuery.disableAnimationsOf(context)) {
      _float.stop();
    } else if (!_float.isAnimating) {
      _float.repeat();
    }
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide;
        final letters = widget.letters;
        return SizedBox.square(
          dimension: side,
          child: Stack(
            children: [
              _place(
                widget.childCenter,
                side * widget.childSize,
                side,
                FittedBox(child: widget.child),
              ),
              for (final (index, letter) in letters.indexed)
                _place(
                  letter.center,
                  side * letter.size,
                  side,
                  AnimatedBuilder(
                    animation: _float,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(
                        0,
                        sin(2 * pi * (_float.value + index / letters.length)) *
                            side *
                            letter.size *
                            LetterCloud.floatShare,
                      ),
                      child: child,
                    ),
                    child: LetterBubble(letter: letter.letter, letterShare: widget.letterShare),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _place(Alignment center, double size, double side, Widget child) => Positioned(
    left: (center.x + 1) / 2 * side - size / 2,
    top: (center.y + 1) / 2 * side - size / 2,
    width: size,
    height: size,
    child: child,
  );
}
