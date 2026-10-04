import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furescue_app/app.dart';
import 'package:furescue_app/screens/resident_shell.dart';
import 'package:furescue_app/session/session_store.dart';
import 'package:furescue_app/widgets/app_card.dart';
import 'package:integration_test/integration_test.dart';

const _password = 'Password123!';
const _emptyGallery = 'No animals are listed for adoption right now.';

Future<void> _loginJuan(WidgetTester tester) async {
  await tester.pumpWidget(
    FuRescueApp(store: MemorySessionStore(), skipRestore: true),
  );
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).first, 'juan@furescue.local');
  await tester.enterText(find.byType(TextField).last, _password);
  await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
  await tester.pumpAndSettle(const Duration(seconds: 8));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('resident applies to an available animal', (tester) async {
    await _loginJuan(tester);
    expect(find.byType(ResidentShell), findsOneWidget);

    await tester.tap(find.text('Browse'));
    await tester.pumpAndSettle(const Duration(seconds: 8));
    if (find.text(_emptyGallery).evaluate().isNotEmpty) {
      fail('Seed must include an available animal.');
    }

    final cards = find.byType(AppCard);
    expect(
      cards,
      findsWidgets,
      reason: 'Seed must include an available animal.',
    );

    final count = cards.evaluate().length;
    for (var i = 0; i < count && i < 8; i++) {
      await tester.tap(find.byType(AppCard).at(i));
      await tester.pumpAndSettle(const Duration(seconds: 8));
      final submit = find.widgetWithText(FilledButton, 'Submit application');
      expect(submit, findsOneWidget);
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Apply'));
      await tester.pumpAndSettle(const Duration(seconds: 8));
      if (find.textContaining('Application submitted').evaluate().isNotEmpty) {
        return;
      }
      await tester.pageBack();
      await tester.pumpAndSettle();
    }

    fail(
      'Could not submit an application. Seed must include an available animal '
      'that juan has not already applied for.',
    );
  });
}
