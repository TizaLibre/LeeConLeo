import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lee_con_leo/activities/common/widgets/progress_star.dart';
import 'package:lee_con_leo/app/app_theme.dart';

void main() {
  Future<void> pumpStar(WidgetTester tester, {required bool isEarned}) => tester.pumpWidget(
    MaterialApp(
      home: Center(child: ProgressStar(isEarned: isEarned)),
    ),
  );

  double scaleOf(WidgetTester tester) =>
      tester.widget<ScaleTransition>(find.byType(ScaleTransition)).scale.value;

  testWidgets('a star pops and turns gold when it is earned', (tester) async {
    await pumpStar(tester, isEarned: false);
    expect(scaleOf(tester), 1);

    await pumpStar(tester, isEarned: true);
    await tester.pump(ProgressStar.popDuration * 0.35);
    expect(scaleOf(tester), closeTo(ProgressStar.popScale, 0.01));
    expect(tester.widget<Icon>(find.byType(Icon)).color, AppTheme.starGold);

    await tester.pumpAndSettle();
    expect(scaleOf(tester), 1);
  });

  testWidgets('a star that was already earned does not pop again', (tester) async {
    await pumpStar(tester, isEarned: true);
    await pumpStar(tester, isEarned: true);
    await tester.pump(ProgressStar.popDuration * 0.35);

    expect(scaleOf(tester), 1);
  });
}
