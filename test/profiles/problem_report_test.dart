import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lee_con_leo/core/logging/in_memory_event_log.dart';
import 'package:lee_con_leo/core/logging/item_event.dart';
import 'package:lee_con_leo/core/logging/logging_providers.dart';
import 'package:lee_con_leo/profiles/about_view.dart';
import 'package:lee_con_leo/profiles/problem_report.dart';

final _answer = ItemEvent(
  timestamp: DateTime(2026, 11, 8),
  sessionId: 's',
  stepId: 'ta',
  activityId: 'syllables.trace',
  itemId: 'ta',
  target: 'ta',
  answer: 'ta',
  responseTime: const Duration(seconds: 2),
  attempt: 1,
  hintUsed: false,
);

void main() {
  test('the report email carries the version, the device and the last game', () {
    final uri = ProblemReport.mailto(
      email: 'leo@example.org',
      version: '1.0.0',
      platform: 'android 14',
      lastAnswer: _answer,
    );

    expect(uri.scheme, 'mailto');
    expect(uri.path, 'leo@example.org');
    expect(uri.queryParameters['subject'], ProblemReport.subject);
    final body = uri.queryParameters['body']!;
    expect(body, contains('Versión: 1.0.0'));
    expect(body, contains('Dispositivo: android 14'));
    expect(body, contains('Último juego: ta / syllables.trace'));
    expect(uri.toString(), isNot(contains('+')));
  });

  testWidgets('reporting a problem opens an email draft, or shows the address without a mail app', (
    tester,
  ) async {
    final opened = <Uri>[];
    var hasMailApp = true;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appVersionProvider.overrideWith((ref) async => '1.0.0'),
          eventLogProvider.overrideWithValue(InMemoryEventLog([_answer])),
          mailLauncherProvider.overrideWithValue((uri) async {
            opened.add(uri);
            return hasMailApp;
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: AboutView())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(AboutView.reportKey));
    await tester.pumpAndSettle();
    expect(opened.single.path, AboutView.contactEmail);
    expect(opened.single.queryParameters['body'], contains('Último juego: ta / syllables.trace'));
    expect(find.byType(SnackBar), findsNothing);

    hasMailApp = false;
    await tester.tap(find.byKey(AboutView.reportKey));
    await tester.pumpAndSettle();
    expect(find.textContaining('Escríbenos a ${AboutView.contactEmail}'), findsOneWidget);
  });
}
