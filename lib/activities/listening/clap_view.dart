import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/app_theme.dart';
import '../../app/widgets/leo_avatar.dart';
import '../../core/audio/audio_providers.dart';
import '../../core/audio/sound_effects.dart';
import '../../core/content/models/spoken_line.dart';
import '../common/item_controller.dart';
import '../common/widgets/demo_overlay.dart';
import '../common/widgets/leo_beside.dart';
import 'clap_activity.dart';

class ClapView extends ConsumerStatefulWidget {
  const ClapView({super.key, required this.item, required this.controller});

  static const clapKey = ValueKey('clap');
  static const doneKey = ValueKey('clap-done');
  static const maxClaps = 6;
  static const pictureShare = 0.45;
  static const dotsShare = 0.15;
  static const clapHold = Duration(milliseconds: 180);
  static const leoDot = Color(0xFF3E8EDE);

  final ClapItem item;
  final ItemController controller;

  @override
  ConsumerState<ClapView> createState() => _ClapViewState();
}

class _ClapViewState extends ConsumerState<ClapView> {
  int _claps = 0;
  int _leoClaps = 0;
  bool _isLeoClapping = false;
  final List<Timer> _beats = [];
  StreamSubscription<SpokenLine>? _lines;

  @override
  void initState() {
    super.initState();
    _lines = widget.controller.linesSpoken.listen(_follow);
  }

  @override
  void didUpdateWidget(ClapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _lines?.cancel();
      _lines = widget.controller.linesSpoken.listen(_follow);
    }
    if (oldWidget.item.id != widget.item.id) {
      _stopBeats();
      _claps = 0;
      _leoClaps = 0;
      _isLeoClapping = false;
    }
  }

  @override
  void dispose() {
    _lines?.cancel();
    _stopBeats();
    super.dispose();
  }

  void _stopBeats() {
    for (final beat in _beats) {
      beat.cancel();
    }
    _beats.clear();
  }

  void _follow(SpokenLine line) {
    if (!mounted) return;
    setState(() {
      _leoClaps = 0;
      _isLeoClapping = false;
    });
    for (final (index, beat) in line.beats.indexed) {
      _beats.add(
        Timer(Duration(milliseconds: (beat * 1000).round()), () {
          setState(() {
            _leoClaps = index + 1;
            _isLeoClapping = true;
          });
          _beats.add(Timer(ClapView.clapHold, () => setState(() => _isLeoClapping = false)));
        }),
      );
    }
  }

  void _clap() {
    if (widget.controller.isSolved || _claps >= ClapView.maxClaps) return;
    _stopBeats();
    ref.read(soundEffectsProvider).play(SoundEffects.clap);
    setState(() {
      _claps++;
      _leoClaps = 0;
      _isLeoClapping = false;
    });
  }

  void _done() {
    if (widget.controller.isSolved || _claps == 0) return;
    widget.controller.answer('$_claps');
    if (!widget.controller.isSolved) setState(() => _claps = 0);
  }

  @override
  Widget build(BuildContext context) {
    return LeoBeside(
      controller: widget.controller,
      pose: _isLeoClapping ? LeoPose.clapping : null,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          final picture = Rect.fromLTWH(0, 0, size.width, size.height * ClapView.pictureShare);
          final dots = Rect.fromLTWH(
            0,
            picture.bottom,
            size.width,
            size.height * ClapView.dotsShare,
          );
          final buttons = Rect.fromLTRB(0, dots.bottom, size.width, size.height);
          final button = min(buttons.height * 0.9, buttons.width * 0.4);
          final clapCenter = Offset(buttons.center.dx - button * 0.6, buttons.center.dy);
          return DemoOverlay(
            key: ValueKey('demo-${widget.item.id}'),
            show: widget.controller.showsDemo,
            path: [clapCenter],
            child: Stack(
              children: [
                Positioned.fromRect(
                  rect: picture.deflate(8),
                  child: SvgPicture.asset('assets/images/${widget.item.image}'),
                ),
                Positioned.fromRect(rect: dots, child: _dots(dots.height * 0.5)),
                Positioned.fromRect(
                  rect: Rect.fromCenter(center: clapCenter, width: button, height: button),
                  child: _clapButton(),
                ),
                Positioned.fromRect(
                  rect: Rect.fromCenter(
                    center: Offset(buttons.center.dx + button * 0.75, buttons.center.dy),
                    width: button * 0.6,
                    height: button * 0.6,
                  ),
                  child: _doneButton(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _dots(double size) {
    final hinted = widget.controller.isHintActive ? widget.item.claps : 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < max(max(_claps, hinted), _leoClaps); i++)
          Padding(
            key: ValueKey('clap-dot-$i'),
            padding: EdgeInsets.symmetric(horizontal: size * 0.2),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < _claps
                    ? AppTheme.starGold
                    : (i < _leoClaps ? ClapView.leoDot : Colors.transparent),
                border: Border.all(color: AppTheme.outline, width: 4),
              ),
            ),
          ),
      ],
    );
  }

  Widget _clapButton() => AnimatedScale(
    scale: _isLeoClapping ? 0.88 : 1,
    duration: const Duration(milliseconds: 90),
    child: _clapFace(),
  );

  Widget _clapFace() => Material(
    color: Colors.white,
    shape: const CircleBorder(side: BorderSide(color: AppTheme.outline, width: 6)),
    elevation: 4,
    child: InkWell(
      key: ClapView.clapKey,
      customBorder: const CircleBorder(),
      onTap: _clap,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SvgPicture.asset('assets/images/games/clap.svg'),
      ),
    ),
  );

  Widget _doneButton() {
    final colors = Theme.of(context).colorScheme;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: _claps == 0 ? 0.35 : 1,
      child: IconButton.filled(
        key: ClapView.doneKey,
        style: IconButton.styleFrom(backgroundColor: colors.tertiary),
        iconSize: 48,
        onPressed: _done,
        icon: const Icon(Icons.check_rounded),
      ),
    );
  }
}
