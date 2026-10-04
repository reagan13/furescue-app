import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furescue_app/app.dart';
import 'package:furescue_app/screens/resident_shell.dart';
import 'package:furescue_app/session/session_store.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('resident tabs load lists without submitting GPS', (tester) async {
    await tester.pumpWidget(
      FuRescueApp(store: MemorySessionStore(), skipRestore: true),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'juan@furescue.local');
    await tester.enterText(find.byType(TextField).last, 'Password123!');
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pumpAndSettle(const Duration(seconds: 8));
    expect(find.byType(ResidentShell), findsOneWidget);

    await tester.tap(find.text('Browse'));
    await tester.pumpAndSettle();
    expect(find.text('Browse'), findsWidgets);

    await tester.tap(find.text('Report'));
    await tester.pumpAndSettle();
    expect(find.text('Report'), findsWidgets);

    await tester.tap(find.text('Learn'));
    await tester.pumpAndSettle();
    expect(find.text('Learn'), findsWidgets);

    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    expect(find.text('Account'), findsWidgets);
    expect(find.text('My adoptions'), findsOneWidget);
    expect(find.text('My listings'), findsOneWidget);
  });
}
