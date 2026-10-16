import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furescue_app/app.dart';
import 'package:furescue_app/screens/rescuer_shell.dart';
import 'package:furescue_app/session/session_store.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('rescuer sees cases and can toggle duty', (tester) async {
    await tester.pumpWidget(
      FuRescueApp(store: MemorySessionStore(), skipRestore: true),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).first,
      'rescuer@furescue.local',
    );
    await tester.enterText(find.byType(TextField).last, 'Password123!');
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pumpAndSettle(const Duration(seconds: 8));
    expect(find.byType(RescuerShell), findsOneWidget);
    expect(find.text('Cases'), findsWidgets);

    final duty = find.textContaining('duty');
    expect(duty, findsWidgets);
    await tester.tap(
      find.text('Off duty').evaluate().isEmpty
          ? find.text('On duty')
          : find.text('Off duty'),
    );
    await tester.pumpAndSettle();
    final confirm = find.text('Go on duty').evaluate().isEmpty
        ? find.text('Go off duty')
        : find.text('Go on duty');
    await tester.tap(confirm);
    await tester.pumpAndSettle(const Duration(seconds: 8));
    expect(find.byType(RescuerShell), findsOneWidget);
  });
}
