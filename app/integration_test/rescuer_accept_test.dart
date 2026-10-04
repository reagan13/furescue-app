import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furescue_app/app.dart';
import 'package:furescue_app/screens/rescuer_shell.dart';
import 'package:furescue_app/session/session_store.dart';
import 'package:integration_test/integration_test.dart';

const _password = 'Password123!';

Future<void> _loginRescuer(WidgetTester tester) async {
  await tester.pumpWidget(
    FuRescueApp(store: MemorySessionStore(), skipRestore: true),
  );
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).first, 'rescuer@furescue.local');
  await tester.enterText(find.byType(TextField).last, _password);
  await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
  await tester.pumpAndSettle(const Duration(seconds: 8));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('rescuer accepts an assigned case when one is listed', (tester) async {
    await _loginRescuer(tester);
    expect(find.byType(RescuerShell), findsOneWidget);
    expect(find.text('My cases'), findsOneWidget);

    final assigned = find.text('Assigned');
    if (assigned.evaluate().isEmpty) {
      return;
    }

    await tester.tap(assigned.first);
    await tester.pumpAndSettle(const Duration(seconds: 8));
    final accept = find.widgetWithText(FilledButton, 'Accept case');
    if (accept.evaluate().isEmpty) {
      return;
    }

    await tester.tap(accept);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Accept case'));
    await tester.pumpAndSettle(const Duration(seconds: 8));
    expect(find.textContaining('Case accepted'), findsOneWidget);
  });
}
