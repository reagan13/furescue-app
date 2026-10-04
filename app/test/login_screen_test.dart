import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furescue_app/api/api_client.dart';
import 'package:furescue_app/api/config.dart';
import 'package:furescue_app/screens/login_screen.dart';
import 'package:furescue_app/session/auth_session.dart';
import 'package:furescue_app/session/session_scope.dart';
import 'package:furescue_app/session/session_store.dart';
import 'package:furescue_app/widgets/brand_mark.dart';

import 'support/http_json.dart';

void main() {
  const config = ApiConfig(baseUrl: 'http://127.0.0.1:8000');

  Future<void> pumpLogin(
    WidgetTester tester, {
    ApiClient? api,
  }) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final session = AuthSession(
      api: api ?? ApiClient(config: config),
      store: MemorySessionStore(),
    )..booting = false;

    await tester.pumpWidget(
      SessionScope(
        session: session,
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('login form sits in the vertical middle on a phone', (
    tester,
  ) async {
    await pumpLogin(tester);

    final formTop = tester.getRect(find.byType(BrandMark)).top;
    final formBottom = tester.getRect(find.text('Create an account')).bottom;
    final formCenter = (formTop + formBottom) / 2;

    expect(formCenter, closeTo(478, 24));
    expect(formTop, greaterThan(150));
  });

  testWidgets('empty fields stay on the form with a validation message', (
    tester,
  ) async {
    await pumpLogin(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pump();
    expect(find.text('Please enter your email and password.'), findsOneWidget);
  });

  testWidgets('INVALID_CREDENTIALS shows the friendly password error', (
    tester,
  ) async {
    final api = ApiClient(
      config: config,
      httpClient: jsonClient((request) async {
        return jsonResponse(
          errorEnvelope('INVALID_CREDENTIALS', 'Email or password is incorrect'),
          status: 401,
        );
      }),
    );
    await pumpLogin(tester, api: api);
    await tester.enterText(find.byType(TextField).first, 'juan@furescue.local');
    await tester.enterText(find.byType(TextField).last, 'wrong');
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pumpAndSettle();
    expect(find.text('Email or password is incorrect.'), findsOneWidget);
  });

  testWidgets('pending rescuer shows the API pending message', (tester) async {
    final api = ApiClient(
      config: config,
      httpClient: jsonClient((request) async {
        return jsonResponse(
          errorEnvelope(
            'ACCOUNT_PENDING',
            'Account is not active (status: pending)',
          ),
          status: 403,
        );
      }),
    );
    await pumpLogin(tester, api: api);
    await tester.enterText(
      find.byType(TextField).first,
      'rescuer6@furescue.local',
    );
    await tester.enterText(find.byType(TextField).last, 'Password123!');
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pumpAndSettle();
    expect(find.text('Account is not active (status: pending)'), findsOneWidget);
  });
}
