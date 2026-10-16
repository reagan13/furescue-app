import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furescue_app/app.dart';
import 'package:furescue_app/screens/animal_detail_screen.dart';
import 'package:furescue_app/screens/animals_list_screen.dart';
import 'package:furescue_app/screens/resident_shell.dart';
import 'package:furescue_app/session/session_store.dart';
import 'package:furescue_app/widgets/scan_card.dart';
import 'package:integration_test/integration_test.dart';

const _password = 'Password123!';

const _emptyGallery = 'No animals listed yet';

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

Finder _detailList() {
  return find.descendant(
    of: find.byType(AnimalDetailScreen),
    matching: find.byWidgetPredicate(
      (widget) => widget is ListView && widget.scrollDirection == Axis.vertical,
    ),
  );
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

    final cards = find.descendant(
      of: find.byType(AnimalsListScreen),
      matching: find.byType(ScanCard),
    );
    expect(
      cards,
      findsWidgets,
      reason: 'Seed must include an available animal.',
    );

    await tester.ensureVisible(cards.first);
    await tester.pumpAndSettle();
    final visible = cards.hitTestable();
    expect(
      visible,
      findsWidgets,
      reason: 'An animal card must be on screen before it is tapped.',
    );
    await tester.tap(visible.first);
    await tester.pumpAndSettle(const Duration(seconds: 8));
    expect(find.byType(AnimalDetailScreen), findsOneWidget);

    final submit = find.widgetWithText(FilledButton, 'Submit application');
    for (var i = 0; i < 8 && submit.evaluate().isEmpty; i++) {
      await tester.drag(_detailList(), const Offset(0, -400));
      await tester.pumpAndSettle();
    }
    expect(submit, findsOneWidget);
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Apply'));
    final submitted = find.textContaining('Application submitted');
    for (var i = 0; i < 20 && submitted.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(submitted, findsOneWidget);
  });
}
