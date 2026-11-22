import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lee_con_leo/app/widgets/pulse.dart';

void main() {
  double scaleOf(WidgetTester tester) =>
      tester.widget<ScaleTransition>(find.byType(ScaleTransition)).scale.value;

  testWidgets('grows and shrinks over and over', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Pulse(child: SizedBox.square(dimension: 10))));
    await tester.pump(Pulse.period);
    expect(scaleOf(tester), closeTo(Pulse.maxScale, 0.01));

    await tester.pump(Pulse.period);
    expect(scaleOf(tester), closeTo(1, 0.01));
  });

  testWidgets('stays still when the device asks to reduce motion', (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: Pulse(child: SizedBox.square(dimension: 10)),
      ),
    );
    await tester.pump(Pulse.period);

    expect(scaleOf(tester), 1);
  });
}
