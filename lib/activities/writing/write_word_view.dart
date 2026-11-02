import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/app_theme.dart';
import '../../utils/geometry/ink_score.dart';
import '../../utils/geometry/resample_polyline.dart';
import '../common/item_controller.dart';
import '../common/widgets/demo_overlay.dart';
import 'word_model.dart';
import 'write_word_activity.dart';

class WriteWordView extends StatefulWidget {
  const WriteWordView({super.key, required this.item, required this.controller});

  static const canvasKey = ValueKey('write-canvas');
  static const clearKey = ValueKey('write-clear');
  static const doneKey = ValueKey('write-done');
  static const pictureShare = 0.22;
  static const buttonsHeight = 88.0;
  static const modelAlpha = 0.22;
  static const hintAlpha = 0.5;
  static const inkColor = Color(0xFF2F6FD6);
  static const paperColor = Color(0xFFFFFDF7);
  static const lineColor = Color(0xFF9CC3E6);

  final WriteWordItem item;
  final ItemController controller;

  @override
  State<WriteWordView> createState() => _WriteWordViewState();
}

class _WriteWordViewState extends State<WriteWordView> {
  final List<List<Offset>> _strokes = [];
  WordModel? _model;
  int? _pointer;
  int? _stars;
  bool _isGrading = false;

  @override
  void didUpdateWidget(WriteWordView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id) {
      _strokes.clear();
      _model = null;
      _stars = null;
    }
  }

  bool get _isLocked => widget.controller.isSolved || _isGrading;

  WordModel _fit(Size size) {
    final model = _model;
    if (model != null && model.area == size) return model;
    return _model = WordModel(widget.item.target, size);
  }

  void _down(PointerDownEvent event) {
    if (_isLocked || _pointer != null) return;
    _pointer = event.pointer;
    setState(() => _strokes.add([event.localPosition]));
  }

  void _move(PointerMoveEvent event) {
    if (event.pointer != _pointer || _isLocked) return;
    setState(() => _strokes.last.add(event.localPosition));
  }

  void _up(PointerEvent event) {
    if (event.pointer == _pointer) _pointer = null;
  }

  void _clear() {
    if (_isLocked) return;
    setState(_strokes.clear);
  }

  Future<void> _done() async {
    final model = _model;
    if (_isLocked || model == null || _strokes.isEmpty) return;
    setState(() => _isGrading = true);
    final score = InkScore.of(
      model: await model.points(),
      ink: [
        for (final stroke in _strokes)
          ...resamplePolyline([
            for (final offset in stroke) Point(offset.dx, offset.dy),
          ], model.inkWidth / 2),
      ],
      tolerance: model.tolerance,
    );
    if (!mounted) return;
    final stars = max(score.stars, widget.controller.isHintActive ? 1 : 0);
    setState(() {
      _isGrading = false;
      if (stars == 0) {
        _strokes.clear();
      } else {
        _stars = stars;
      }
    });
    widget.controller.answer(stars == 0 ? '' : widget.item.target);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final pictureHeight = constraints.maxHeight * WriteWordView.pictureShare;
          return Column(
            children: [
              SizedBox(
                height: pictureHeight,
                child: SvgPicture.asset('assets/images/${widget.item.image}'),
              ),
              Expanded(child: _paper()),
              SizedBox(height: WriteWordView.buttonsHeight, child: _buttons()),
            ],
          );
        },
      ),
    );
  }

  Widget _paper() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final model = _fit(constraints.biggest);
        final bounds = model.bounds;
        return DemoOverlay(
          key: ValueKey('demo-${widget.item.id}'),
          show: widget.controller.showsDemo,
          path: [
            Offset(bounds.left, model.baseline - model.xHeight / 2),
            Offset(bounds.right, model.baseline - model.xHeight / 2),
          ],
          child: Stack(
            children: [
              Positioned.fill(
                child: Listener(
                  key: WriteWordView.canvasKey,
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: _down,
                  onPointerMove: _move,
                  onPointerUp: _up,
                  onPointerCancel: _up,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: CustomPaint(
                      painter: _PaperPainter(
                        model: model,
                        strokes: _strokes,
                        modelAlpha: widget.controller.isHintActive
                            ? WriteWordView.hintAlpha
                            : WriteWordView.modelAlpha,
                      ),
                    ),
                  ),
                ),
              ),
              if (_stars case final stars?) Center(child: _starRow(stars)),
            ],
          ),
        );
      },
    );
  }

  Widget _starRow(int stars) => Row(
    key: ValueKey('write-stars-$stars'),
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < InkScore.starThresholds.length; i++)
        Icon(
          i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 96,
          color: AppTheme.starGold,
        ),
    ],
  );

  Widget _buttons() {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton.filledTonal(
          key: WriteWordView.clearKey,
          iconSize: 48,
          onPressed: _clear,
          icon: const Icon(Icons.refresh_rounded),
        ),
        const SizedBox(width: 48),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _strokes.isEmpty ? 0.35 : 1,
          child: IconButton.filled(
            key: WriteWordView.doneKey,
            style: IconButton.styleFrom(backgroundColor: colors.tertiary),
            iconSize: 48,
            onPressed: _done,
            icon: const Icon(Icons.check_rounded),
          ),
        ),
      ],
    );
  }
}

class _PaperPainter extends CustomPainter {
  _PaperPainter({required this.model, required this.strokes, required this.modelAlpha})
    : _strokeCount = strokes.fold(0, (sum, stroke) => sum + stroke.length);

  final WordModel model;
  final List<List<Offset>> strokes;
  final double modelAlpha;
  final int _strokeCount;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = WriteWordView.paperColor);
    final line = Paint()
      ..color = WriteWordView.lineColor
      ..strokeWidth = 3;
    final baseline = model.baseline;
    canvas.drawLine(Offset(0, baseline), Offset(size.width, baseline), line);
    canvas.drawLine(
      Offset(0, baseline - model.xHeight),
      Offset(size.width, baseline - model.xHeight),
      line..strokeWidth = 1.5,
    );
    model.paint(canvas, AppTheme.outline.withValues(alpha: modelAlpha));
    final ink = Paint()
      ..color = WriteWordView.inkColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = model.inkWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final stroke in strokes) {
      if (stroke.length == 1) {
        canvas.drawCircle(stroke.single, model.inkWidth / 2, ink..style = PaintingStyle.fill);
        ink.style = PaintingStyle.stroke;
        continue;
      }
      canvas.drawPath(Path()..addPolygon(stroke, false), ink);
    }
  }

  @override
  bool shouldRepaint(_PaperPainter old) =>
      old.model != model || old._strokeCount != _strokeCount || old.modelAlpha != modelAlpha;
}
