import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furescue_app/api/api_client.dart';
import 'package:furescue_app/api/config.dart';
import 'package:furescue_app/models/auth_tokens.dart';
import 'package:furescue_app/models/message_thread.dart';
import 'package:furescue_app/models/user.dart';
import 'package:furescue_app/screens/message_compose_screen.dart';
import 'package:furescue_app/screens/message_thread_screen.dart';
import 'package:furescue_app/screens/messages_list_screen.dart';
import 'package:furescue_app/session/auth_session.dart';
import 'package:furescue_app/session/session_scope.dart';
import 'package:furescue_app/session/session_store.dart';
import 'package:furescue_app/theme/theme.dart';
import 'package:google_fonts/google_fonts.dart';

import '../support/http_json.dart';

void main() {
  const config = ApiConfig(baseUrl: 'http://127.0.0.1:8000');
  const me = '11111111-1111-4111-8111-111111111111';
  const other = '22222222-2222-4222-8222-222222222222';
  const related = '33333333-3333-4333-8333-333333333333';
  final longName = 'City Veterinary Office ${'Name' * 40}';
  final longPreview = 'Please bring the dog ${'soon ' * 40}';
  final longTopic = 'Report · ${'injured puppy on the shore ' * 8}';
  final longWord = 'https://example.test/${'segment' * 30}';

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  AuthSession sessionFor(ApiClient api) {
    final session = AuthSession(api: api, store: MemorySessionStore())
      ..booting = false
      ..tokens = const AuthTokens(
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
      )
      ..user = User.fromJson(fixtureUser(role: 'resident', id: me));
    session.api.accessToken = 'access-1';
    return session;
  }

  Future<void> pumpPhone(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(home);
    await tester.pumpAndSettle();
  }

  testWidgets('inbox rows shrink long names, previews, and unread counts', (
    tester,
  ) async {
    final api = ApiClient(
      config: config,
      httpClient: jsonClient((request) async {
        return jsonResponse(
          okEnvelope({
            'threads': [
              {
                'related_type': 'report',
                'related_id': related,
                'other_user_id': other,
                'other_user_name': longName,
                'last_message': longPreview,
                'last_sent_at': '2020-01-15 08:00:00',
                'unread_count': 128,
              },
            ],
          }),
        );
      }),
    );

    await pumpPhone(
      tester,
      SessionScope(
        session: sessionFor(api),
        child: MaterialApp(
          theme: buildFuRescueTheme(),
          home: const MessagesListScreen(),
        ),
      ),
    );

    expect(find.text(longName), findsOneWidget);
    expect(find.text('Report'), findsOneWidget);
    expect(find.textContaining('Please bring the dog'), findsOneWidget);
    expect(find.text('Jan 15, 2020'), findsOneWidget);
    expect(find.text('128'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(tester.getTopRight(find.text('128')).dx, lessThanOrEqualTo(360));
    expect(tester.getTopRight(find.text(longName)).dx, lessThanOrEqualTo(360));
  });

  testWidgets('thread stacks own messages at the end and keeps the composer', (
    tester,
  ) async {
    final api = ApiClient(
      config: config,
      httpClient: jsonClient((request) async {
        if (request.method == 'PATCH') {
          return jsonResponse(okEnvelope({'message': <String, Object?>{}}));
        }
        return jsonResponse(
          okEnvelope({
            'messages': [
              {
                'id': '44444444-4444-4444-8444-444444444444',
                'sender_id': other,
                'receiver_id': me,
                'message_text': 'On my way',
                'sent_at': '2020-01-15 08:00:00',
                'read_at': null,
              },
              {
                'id': '55555555-5555-4555-8555-555555555555',
                'sender_id': me,
                'receiver_id': other,
                'message_text': 'Thanks',
                'sent_at': '2020-01-15 09:00:00',
                'read_at': '2020-01-15 09:01:00',
              },
              {
                'id': '66666666-6666-4666-8666-666666666666',
                'sender_id': me,
                'receiver_id': other,
                'message_text': longWord,
                'sent_at': '2020-01-15 09:05:00',
                'read_at': null,
              },
            ],
          }),
        );
      }),
    );

    await pumpPhone(
      tester,
      SessionScope(
        session: sessionFor(api),
        child: MaterialApp(
          theme: buildFuRescueTheme(),
          home: MessageThreadScreen(
            thread: MessageThread(
              relatedType: 'report',
              relatedId: related,
              otherUserId: other,
              otherUserName: longName,
              lastMessage: 'Thanks',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Write a message'), findsOneWidget);
    expect(find.textContaining('https://example'), findsOneWidget);
    expect(find.text('Jan 15, 2020'), findsWidgets);
    final theirs = tester.getTopLeft(find.text('On my way'));
    final mine = tester.getTopLeft(find.text('Thanks'));
    expect(mine.dx, greaterThan(theirs.dx));
    expect(tester.takeException(), isNull);
    expect(
      tester.getTopRight(find.textContaining('https://example')).dx,
      lessThanOrEqualTo(360),
    );
  });

  testWidgets('compose topic dropdown ellipsizes a long label', (tester) async {
    final api = ApiClient(
      config: config,
      httpClient: jsonClient((request) async {
        return jsonResponse(
          okEnvelope({
            'receiver': {'id': other, 'full_name': longName},
            'topics': [
              {
                'related_type': 'report',
                'related_id': related,
                'label': longTopic,
              },
            ],
          }),
        );
      }),
    );

    await pumpPhone(
      tester,
      SessionScope(
        session: sessionFor(api),
        child: MaterialApp(
          theme: buildFuRescueTheme(),
          home: const MessageComposeScreen(),
        ),
      ),
    );

    expect(find.text(longTopic), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty thread and a failed send stay readable', (tester) async {
    final api = ApiClient(
      config: config,
      httpClient: jsonClient((request) async {
        if (request.method == 'POST') {
          return jsonResponse(
            errorEnvelope('SERVER_ERROR', 'Could not send that message'),
            status: 500,
          );
        }
        return jsonResponse(okEnvelope({'messages': <Object?>[]}));
      }),
    );

    await pumpPhone(
      tester,
      SessionScope(
        session: sessionFor(api),
        child: MaterialApp(
          theme: buildFuRescueTheme(),
          home: const MessageThreadScreen(
            thread: MessageThread(
              relatedType: 'adoption',
              relatedId: related,
              otherUserId: other,
              otherUserName: 'City Vet',
            ),
          ),
        ),
      ),
    );

    expect(find.text('No messages yet. Write the first one.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Hello from the shore');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    expect(find.text('Could not send that message'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
