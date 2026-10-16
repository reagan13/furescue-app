import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furescue_app/app.dart';
import 'package:furescue_app/screens/rescuer_shell.dart';
import 'package:furescue_app/session/session_store.dart';
import 'package:integration_test/integration_test.dart';

const _password = 'Password123!';

// Case detail keeps a looping wave animation, so pumpAndSettle never finishes.
Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 50; i++) {
    if (finder.evaluate().isNotEmpty) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 300));
  }
}

Future<void> _loginRescuer(WidgetTester tester) async {
  await tester.pumpWidget(
    FuRescueApp(store: MemorySessionStore(), skipRestore: true),
  );
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byType(TextField).first,
    'rescuer@furescue.local',
  );
  await tester.enterText(find.byType(TextField).last, _password);
  await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
  await tester.pumpAndSettle(const Duration(seconds: 8));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('rescuer accepts an assigned case when one is listed', (
    tester,
  ) async {
    await _loginRescuer(tester);
    expect(find.byType(RescuerShell), findsOneWidget);
    expect(find.text('Cases'), findsWidgets);

    final assigned = find.text('Assigned');
    if (assigned.evaluate().isEmpty) {
      return;
    }

    await tester.tap(assigned.first);
    final accept = find.widgetWithText(FilledButton, 'Accept case');
    await _pumpUntil(tester, accept);
    expect(
      accept,
      findsOneWidget,
      reason: 'An assigned case should offer Accept case.',
    );

    await tester.ensureVisible(accept);
    await tester.tap(accept);
    final confirm = find.widgetWithText(TextButton, 'Accept case');
    await _pumpUntil(tester, confirm);
    expect(confirm, findsOneWidget);
    await tester.tap(confirm);
    final accepted = find.textContaining('Case accepted');
    await _pumpUntil(tester, accepted);
    expect(accepted, findsOneWidget);
  });
}
