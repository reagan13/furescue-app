import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furescue_app/api/api_client.dart';
import 'package:furescue_app/api/config.dart';
import 'package:furescue_app/models/auth_tokens.dart';
import 'package:furescue_app/models/user.dart';
import 'package:furescue_app/screens/reports_list_screen.dart';
import 'package:furescue_app/session/auth_session.dart';
import 'package:furescue_app/session/session_scope.dart';
import 'package:furescue_app/session/session_store.dart';

import '../support/http_json.dart';

void main() {
  const config = ApiConfig(baseUrl: 'http://127.0.0.1:8000');

  AuthSession sessionFor(ApiClient api) {
    final session = AuthSession(api: api, store: MemorySessionStore())
      ..booting = false
      ..tokens = const AuthTokens(accessToken: 'access-1', refreshToken: 'refresh-1')
      ..user = User.fromJson(fixtureUser(role: 'resident'));
    session.api.accessToken = 'access-1';
    return session;
  }

  testWidgets('empty reports list shows the pin-an-animal copy', (tester) async {
    final api = ApiClient(
      config: config,
      httpClient: jsonClient((request) async {
        expect(request.url.path, contains('/reports/me'));
        return jsonResponse(okEnvelope([]));
      }),
    );
    await tester.pumpWidget(
      SessionScope(
        session: sessionFor(api),
        child: const MaterialApp(home: ReportsListScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('No reports yet. Use the Report tab to pin an animal in Mati City.'),
      findsOneWidget,
    );
  });

  testWidgets('failed reports list shows the error and retry', (tester) async {
    final api = ApiClient(
      config: config,
      httpClient: jsonClient((request) async {
        return jsonResponse(
          errorEnvelope('SERVER_ERROR', 'Inbox is down'),
          status: 500,
        );
      }),
    );
    await tester.pumpWidget(
      SessionScope(
        session: sessionFor(api),
        child: const MaterialApp(home: ReportsListScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Inbox is down'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });
}
