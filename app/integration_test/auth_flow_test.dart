import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furescue_app/app.dart';
import 'package:furescue_app/screens/admin_blocked_screen.dart';
import 'package:furescue_app/screens/rescuer_shell.dart';
import 'package:furescue_app/screens/resident_shell.dart';
import 'package:furescue_app/session/session_store.dart';
import 'package:integration_test/integration_test.dart';

const password = 'Password123!';

Future<void> login(WidgetTester tester, String email) async {
  await tester.pumpWidget(FuRescueApp(store: MemorySessionStore(), skipRestore: true));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).first, email);
  await tester.enterText(find.byType(TextField).last, password);
  await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
  await tester.pumpAndSettle(const Duration(seconds: 8));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('resident seed account opens ResidentShell', (tester) async {
    await login(tester, 'juan@furescue.local');
    expect(find.byType(ResidentShell), findsOneWidget);
  });

  testWidgets('rescuer seed account opens RescuerShell', (tester) async {
    await login(tester, 'rescuer@furescue.local');
    expect(find.byType(RescuerShell), findsOneWidget);
  });

  testWidgets('admin seed account is blocked on the phone', (tester) async {
    await login(tester, 'admin@furescue.local');
    expect(find.byType(AdminBlockedScreen), findsOneWidget);
    expect(find.text('Use the web console'), findsOneWidget);
  });
}
