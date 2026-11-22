import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/app_theme.dart';
import '../common/item_controller.dart';
import '../common/widgets/choice_button.dart';
import '../common/widgets/demo_overlay.dart';
import '../common/widgets/leo_beside.dart';
import '../common/widgets/letter_glyph.dart';
import 'picture_sound_activity.dart';

class PictureSoundView extends StatelessWidget {
  const PictureSoundView({super.key, required this.item, required this.controller});

  static const soundKey = ValueKey('sound-card');
  static const soundShare = 0.24;
  static const gap = 12.0;

  final PictureItem item;
  final ItemController controller;

  bool _isWide(Size size) => size.width > size.height * 1.5;

  Rect _soundRect(Size size) => _isWide(size)
      ? Rect.fromLTWH(0, 0, size.width * soundShare, size.height)
      : Rect.fromLTWH(0, 0, size.width, size.height * soundShare);

  Rect _gridRect(Size size) {
    if (!item.showsSound) return Offset.zero & size;
    final sound = _soundRect(size);
    return _isWide(size)
        ? Rect.fromLTRB(sound.right + gap, 0, size.width, size.height)
        : Rect.fromLTRB(0, sound.bottom + gap, size.width, size.height);
  }

  int _columns(Size grid) => grid.width > grid.height * 1.5 ? item.options.length : 2;

  int _rows(Size grid) => (item.options.length / _columns(grid)).ceil();

  @override
  Widget build(BuildContext context) {
    return LeoBeside(
      controller: controller,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          final grid = _gridRect(size);
          final columns = _columns(grid.size);
          return DemoOverlay(
            key: ValueKey('demo-${item.id}'),
            show: controller.showsDemo,
            path: [grid.topLeft + _centerOf(item.options.indexOf(item.target), grid.size)],
            child: Stack(
              children: [
                if (item.showsSound) Positioned.fromRect(rect: _soundRect(size), child: _sound()),
                Positioned.fromRect(
                  rect: grid,
                  child: Column(
                    children: [
                      for (var row = 0; row < _rows(grid.size); row++)
                        Expanded(
                          child: Row(
                            children: [
                              for (final word in item.options.skip(row * columns).take(columns))
                                Expanded(child: _picture(word)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Offset _centerOf(int index, Size grid) {
    final columns = _columns(grid);
    return Offset(
      (index % columns + 0.5) * grid.width / columns,
      (index ~/ columns + 0.5) * grid.height / _rows(grid),
    );
  }

  Widget _sound() => Center(
    child: DecoratedBox(
      key: soundKey,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outline, width: 3),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 4),
        child: FittedBox(child: LetterGlyph(item.sound, color: AppTheme.outline)),
      ),
    ),
  );

  Widget _picture(String word) => ChoiceButton(
    key: ValueKey('choice-$word'),
    isHighlighted: controller.isHintActive && word == item.target,
    onPressed: () => controller.answer(word),
    child: SvgPicture.asset('assets/images/${item.images[word]}'),
  );
}
