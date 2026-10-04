import 'package:flutter_test/flutter_test.dart';
import 'package:furescue_app/api/api_client.dart';
import 'package:furescue_app/api/config.dart';
import 'package:furescue_app/app.dart';
import 'package:furescue_app/models/auth_tokens.dart';
import 'package:furescue_app/screens/admin_blocked_screen.dart';
import 'package:furescue_app/screens/login_screen.dart';
import 'package:furescue_app/screens/rescuer_shell.dart';
import 'package:furescue_app/screens/resident_shell.dart';
import 'package:furescue_app/session/session_store.dart';

import 'support/http_json.dart';

void main() {
  const tokens = AuthTokens(accessToken: 'access-1', refreshToken: 'refresh-1');
  const config = ApiConfig(baseUrl: 'http://127.0.0.1:8000');

  Future<void> pumpSignedIn(WidgetTester tester, String role) async {
    final store = MemorySessionStore();
    await store.write(tokens);
    final api = ApiClient(
      config: config,
      httpClient: jsonClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/users/me')) {
          return jsonResponse(
            okEnvelope({
              'user': fixtureUser(
                role: role,
                email: '$role@furescue.local',
                fullName: role,
              ),
            }),
          );
        }
        if (path.contains('/elearning/progress')) {
          return jsonResponse(okEnvelope({'progress': []}));
        }
        if (path.contains('/messages/threads')) {
          return jsonResponse(okEnvelope({'threads': []}));
        }
        return jsonResponse(okEnvelope([]));
      }),
    );
    await tester.pumpWidget(FuRescueApp(api: api, store: store));
    await tester.pumpAndSettle();
  }

  testWidgets('unsigned session shows login', (tester) async {
    await tester.pumpWidget(
      FuRescueApp(
        api: ApiClient(
          config: config,
          httpClient: jsonClient((request) async {
            return jsonResponse(okEnvelope([]));
          }),
        ),
        store: MemorySessionStore(),
        skipRestore: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('resident JWT opens ResidentShell', (tester) async {
    await pumpSignedIn(tester, 'resident');
    expect(find.byType(ResidentShell), findsOneWidget);
  });

  testWidgets('rescuer JWT opens RescuerShell', (tester) async {
    await pumpSignedIn(tester, 'rescuer');
    expect(find.byType(RescuerShell), findsOneWidget);
  });

  testWidgets('admin JWT shows the web-console block', (tester) async {
    await pumpSignedIn(tester, 'admin');
    expect(find.byType(AdminBlockedScreen), findsOneWidget);
    expect(find.text('Use the web console'), findsOneWidget);
  });
}
