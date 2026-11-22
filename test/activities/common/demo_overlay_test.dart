import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lee_con_leo/activities/common/widgets/demo_overlay.dart';

void main() {
  Widget overlay({required bool show}) => MaterialApp(
    home: DemoOverlay(
      show: show,
      path: const [Offset(100, 100), Offset(300, 300)],
      child: const ColoredBox(color: Colors.white),
    ),
  );

  testWidgets('the hand shows the move until the child touches the screen', (tester) async {
    await tester.pumpWidget(overlay(show: true));
    expect(find.byKey(DemoOverlay.handKey), findsOneWidget);

    await tester.tapAt(const Offset(10, 10));
    await tester.pump();
    expect(find.byKey(DemoOverlay.handKey), findsNothing);
  });

  testWidgets('the hand comes back when it is asked to show again', (tester) async {
    await tester.pumpWidget(overlay(show: true));
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpWidget(overlay(show: false));
    await tester.pumpWidget(overlay(show: true));

    expect(find.byKey(DemoOverlay.handKey), findsOneWidget);
    await tester.pumpAndSettle();
  });
}
