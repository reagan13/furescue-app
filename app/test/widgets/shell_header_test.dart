import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furescue_app/api/api_client.dart';
import 'package:furescue_app/api/config.dart';
import 'package:furescue_app/app.dart';
import 'package:furescue_app/inbox/inbox_watch.dart';
import 'package:furescue_app/models/auth_tokens.dart';
import 'package:furescue_app/screens/animals_list_screen.dart';
import 'package:furescue_app/screens/cases_list_screen.dart';
import 'package:furescue_app/screens/learning_list_screen.dart';
import 'package:furescue_app/screens/messages_list_screen.dart';
import 'package:furescue_app/screens/notifications_screen.dart';
import 'package:furescue_app/screens/reports_list_screen.dart';
import 'package:furescue_app/screens/rescuer_shell.dart';
import 'package:furescue_app/screens/resident_shell.dart';
import 'package:furescue_app/session/session_scope.dart';
import 'package:furescue_app/session/session_store.dart';
import 'package:furescue_app/theme/theme.dart';
import 'package:furescue_app/widgets/shell_header.dart';
import 'package:google_fonts/google_fonts.dart';

import '../support/http_json.dart';
import '../support/signed_in.dart';

void main() {
  const config = ApiConfig(baseUrl: 'http://127.0.0.1:8000');
  const phone = Size(360, 740);

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  ApiClient quietApi() {
    return ApiClient(
      config: config,
      httpClient: jsonClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/elearning/progress')) {
          return jsonResponse(okEnvelope({'progress': []}));
        }
        if (path.endsWith('/messages/threads')) {
          return jsonResponse(okEnvelope({'threads': []}));
        }
        return jsonResponse(okEnvelope([]));
      }),
    );
  }

  Future<void> pumpTab(
    WidgetTester tester, {
    required String title,
    required Widget body,
    String role = 'resident',
  }) async {
    await pumpSignedIn(
      tester,
      Scaffold(
        appBar: ShellHeader(title: title),
        body: body,
      ),
      quietApi(),
      role: role,
      size: phone,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('browse under the shell header has one Browse title', (
    tester,
  ) async {
    await pumpTab(
      tester,
      title: 'Browse',
      body: const AnimalsListScreen(showAppBar: false),
    );
    expect(find.widgetWithText(AppBar, 'Browse'), findsOneWidget);
    expect(find.text('Dogs'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cases under the shell header has one Cases title', (
    tester,
  ) async {
    await pumpTab(
      tester,
      title: 'Cases',
      body: const CasesListScreen(),
      role: 'rescuer',
    );
    expect(find.widgetWithText(AppBar, 'Cases'), findsOneWidget);
    expect(find.text('Cases assigned to you.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reports, learn, and messages keep a single shell title', (
    tester,
  ) async {
    await pumpTab(tester, title: 'Reports', body: const ReportsListScreen());
    expect(find.widgetWithText(AppBar, 'Reports'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await pumpTab(tester, title: 'Learn', body: const LearningListScreen());
    expect(find.widgetWithText(AppBar, 'Learn'), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Course catalog'), findsNothing);
    expect(find.text('No published courses yet'), findsOneWidget);

    await pumpTab(
      tester,
      title: 'Messages',
      body: const MessagesListScreen(showAppBar: false),
    );
    expect(find.widgetWithText(AppBar, 'Messages'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('messages and notifications open from the header and back returns', (
    tester,
  ) async {
    await pumpSignedIn(
      tester,
      const Scaffold(
        appBar: ShellHeader(title: 'Reports'),
        body: SizedBox.shrink(),
      ),
      quietApi(),
      size: phone,
    );
    await tester.pumpAndSettle();
    expect(find.byType(BackButton), findsNothing);

    await tester.tap(find.byTooltip('Messages'));
    await tester.pumpAndSettle();
    expect(find.byType(MessagesListScreen), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(MessagesListScreen), findsNothing);
    expect(find.widgetWithText(AppBar, 'Reports'), findsOneWidget);

    await tester.tap(find.byTooltip('Notifications'));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationsScreen), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(NotificationsScreen), findsNothing);
    expect(find.widgetWithText(AppBar, 'Reports'), findsOneWidget);
  });

  Future<void> openShell(WidgetTester tester, String role) async {
    usePhoneSurface(tester);
    final store = MemorySessionStore();
    await store.write(
      const AuthTokens(accessToken: 'access-1', refreshToken: 'refresh-1'),
    );
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
        if (path.endsWith('/elearning/progress')) {
          return jsonResponse(okEnvelope({'progress': []}));
        }
        if (path.endsWith('/messages/threads')) {
          return jsonResponse(okEnvelope({'threads': []}));
        }
        return jsonResponse(okEnvelope([]));
      }),
    );
    await tester.pumpWidget(FuRescueApp(api: api, store: store));
    await tester.pumpAndSettle();
  }

  testWidgets('resident shell Browse has one title', (tester) async {
    await openShell(tester, 'resident');
    expect(find.byType(ResidentShell), findsOneWidget);
    await tester.tap(find.text('Browse'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Browse'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rescuer shell Cases has one title', (tester) async {
    await openShell(tester, 'rescuer');
    expect(find.byType(RescuerShell), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Cases'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the header bell shows 9+ when unread is past nine', (tester) async {
    final api = quietApi();
    final watch = InboxWatch(api: api)..unread = 12;
    addTearDown(watch.dispose);

    usePhoneSurface(tester);
    await tester.pumpWidget(
      SessionScope(
        session: signedInSession(api),
        child: InboxScope(
          watch: watch,
          child: MaterialApp(
            theme: buildFuRescueTheme(),
            home: const Scaffold(
              appBar: ShellHeader(title: 'Reports'),
              body: SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('9+'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
