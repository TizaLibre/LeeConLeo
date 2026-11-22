import 'package:material_ui/material_ui.dart';

abstract final class AppTheme {
  static const _seed = Color(0xFFFF9F1C);
  static const starGold = Color(0xFFF2B632);
  static const outline = Color(0xFF3B2A20);
  static const road = Color(0xFFF5D78E);
  static const letterFont = 'PlaywriteCL';
  static const cream = Color(0xFFFDF4DE);

  static ThemeData light() =>
      ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: _seed), useMaterial3: true);
}
