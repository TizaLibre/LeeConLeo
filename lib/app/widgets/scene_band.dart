import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SceneBand extends StatelessWidget {
  const SceneBand({super.key, required this.asset});

  static const tileAspectRatio = 400 / 800;
  static const seamOverlap = 1.0;

  final String asset;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final tileWidth = box.maxHeight * tileAspectRatio;
        final tilesPerSide = (box.maxWidth / tileWidth / 2).ceil();
        final firstLeft = box.maxWidth / 2 - tileWidth / 2 - tilesPerSide * tileWidth;
        return ClipRect(
          child: Stack(
            children: [
              for (var i = 0; i < 2 * tilesPerSide + 1; i++)
                Positioned(
                  left: firstLeft + i * tileWidth,
                  top: 0,
                  width: tileWidth + seamOverlap,
                  height: box.maxHeight,
                  child: SvgPicture.asset(asset, fit: BoxFit.fill),
                ),
            ],
          ),
        );
      },
    );
  }
}
