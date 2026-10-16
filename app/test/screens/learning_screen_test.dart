import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furescue_app/api/api_client.dart';
import 'package:furescue_app/api/config.dart';
import 'package:furescue_app/models/auth_tokens.dart';
import 'package:furescue_app/models/user.dart';
import 'package:furescue_app/screens/learning_list_screen.dart';
import 'package:furescue_app/screens/learning_module_screen.dart';
import 'package:furescue_app/session/auth_session.dart';
import 'package:furescue_app/session/session_scope.dart';
import 'package:furescue_app/session/session_store.dart';
import 'package:http/http.dart' as http;

import '../support/http_json.dart';
import '../support/signed_in.dart';

void main() {
  const config = ApiConfig(baseUrl: 'http://127.0.0.1:8000');

  AuthSession sessionFor(ApiClient api) {
    final session = AuthSession(api: api, store: MemorySessionStore())
      ..booting = false
      ..tokens = const AuthTokens(
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
      )
      ..user = User.fromJson(fixtureUser(role: 'resident'));
    session.api.accessToken = 'access-1';
    return session;
  }

  Future<void> pumpLearn(WidgetTester tester, Widget home, ApiClient api) {
    return tester.pumpWidget(
      SessionScope(
        session: sessionFor(api),
        child: MaterialApp(home: home),
      ),
    );
  }

  testWidgets('learn tab first frame does not throw', (tester) async {
    final gates = <Completer<http.Response>>[];
    final api = ApiClient(
      config: config,
      httpClient: jsonClient((request) {
        final gate = Completer<http.Response>();
        gates.add(gate);
        return gate.future;
      }),
    );
    await pumpLearn(tester, const LearningListScreen(), api);
    expect(tester.takeException(), isNull);
    expect(find.text('Loading courses'), findsOneWidget);

    gates.single.complete(jsonResponse(okEnvelope([])));
    await tester.pump();
    gates.last.complete(jsonResponse(okEnvelope({'progress': []})));
    await tester.pumpAndSettle();
    expect(find.text('No published courses yet'), findsOneWidget);
  });

  testWidgets('catalog shows course cards, progress, and subject filters', (
    tester,
  ) async {
    final api = ApiClient(
      config: config,
      httpClient: jsonClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/elearning/progress')) {
          return jsonResponse(
            okEnvelope({
              'progress': [
                {
                  'module_id': 'm-cat',
                  'status': 'in_progress',
                  'read_pct': 40,
                  'quiz_passed': 0,
                  'badge_earned': 0,
                },
              ],
            }),
          );
        }
        return jsonResponse(
          okEnvelope([
            {
              'id': 'm-dog',
              'title': 'Street dogs',
              'category': 'dog_behavior',
              'published_status': 'published',
              'content_body': '<p>Approach sideways and let the dog sniff.</p>',
            },
            {
              'id': 'm-cat',
              'title': 'Quiet rooms',
              'category': 'cat_behavior',
              'published_status': 'published',
            },
          ]),
        );
      }),
    );
    await pumpLearn(tester, const LearningListScreen(), api);
    await tester.pumpAndSettle();
    expect(find.text('Course catalog'), findsOneWidget);
    expect(find.text('Street dogs'), findsOneWidget);
    expect(find.text('Quiet rooms'), findsOneWidget);
    expect(
      find.text('Approach sideways and let the dog sniff.'),
      findsOneWidget,
    );
    expect(find.text('Not started'), findsOneWidget);
    expect(find.text('In progress'), findsOneWidget);
    expect(find.text('Dog behavior'), findsWidgets);
    expect(
      find.text('2 courses · 1 in progress · 0 completed'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(ChoiceChip, 'Dog behavior'));
    await tester.pumpAndSettle();
    expect(find.text('Street dogs'), findsOneWidget);
    expect(find.text('Quiet rooms'), findsNothing);
    expect(find.text('No courses in Cat behavior.'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Cat behavior'));
    await tester.pumpAndSettle();
    expect(find.text('Quiet rooms'), findsOneWidget);
    expect(find.text('Street dogs'), findsNothing);
  });

  testWidgets('catalog null fields render an untitled course', (tester) async {
    final api = ApiClient(
      config: config,
      httpClient: jsonClient((request) async {
        if (request.url.path.endsWith('/elearning/progress')) {
          return jsonResponse(
            okEnvelope({
              'progress': [
                {
                  'module_id': null,
                  'status': null,
                  'read_pct': null,
                  'quiz_passed': null,
                  'badge_earned': null,
                },
              ],
            }),
          );
        }
        return jsonResponse(
          okEnvelope([
            {
              'id': 'm-blank',
              'title': null,
              'category': null,
              'content_body': null,
              'published_status': null,
            },
          ]),
        );
      }),
    );
    await pumpLearn(tester, const LearningListScreen(), api);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Untitled course'), findsOneWidget);
    expect(find.text('Course'), findsOneWidget);
    expect(find.text('Not started'), findsOneWidget);
  });

  testWidgets('a long course title does not overflow at 360px', (tester) async {
    final title = 'Street dogs ${'and quiet rooms ' * 8}${'x' * 40}';
    final api = ApiClient(
      config: config,
      httpClient: jsonClient((request) async {
        if (request.url.path.endsWith('/elearning/progress')) {
          return jsonResponse(okEnvelope({'progress': []}));
        }
        return jsonResponse(
          okEnvelope([
            {
              'id': 'm-long',
              'title': title,
              'category': 'dog_behavior',
              'published_status': 'published',
              'content_body': '<p>${'Approach sideways. ' * 20}</p>',
            },
          ]),
        );
      }),
    );

    usePhoneSurface(tester);
    await pumpLearn(tester, const LearningListScreen(), api);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Street dogs'), findsOneWidget);
    expect(
      tester.getTopRight(find.textContaining('Street dogs')).dx,
      lessThanOrEqualTo(360),
    );
  });

  testWidgets('empty catalog shows a readable empty state', (tester) async {
    final api = ApiClient(
      config: config,
      httpClient: jsonClient((request) async {
        if (request.url.path.endsWith('/elearning/progress')) {
          return jsonResponse(okEnvelope({'progress': []}));
        }
        return jsonResponse(okEnvelope([]));
      }),
    );
    await pumpLearn(tester, const LearningListScreen(), api);
    await tester.pumpAndSettle();
    expect(find.text('No published courses yet'), findsOneWidget);
    expect(find.text("Courses didn't load"), findsNothing);
  });

  testWidgets('failed catalog shows the error and retry', (tester) async {
    final api = ApiClient(
      config: config,
      httpClient: jsonClient((request) async {
        return jsonResponse(
          errorEnvelope('SERVER_ERROR', 'Lessons are down'),
          status: 500,
        );
      }),
    );
    await pumpLearn(tester, const LearningListScreen(), api);
    await tester.pumpAndSettle();
    expect(find.text('Lessons are down'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lesson first frame does not throw while the module is null', (
    tester,
  ) async {
    final gates = <Completer<http.Response>>[];
    final api = ApiClient(
      config: config,
      httpClient: jsonClient((request) {
        final gate = Completer<http.Response>();
        gates.add(gate);
        return gate.future;
      }),
    );
    await pumpLearn(tester, const LearningModuleScreen(moduleId: 'm1'), api);
    expect(tester.takeException(), isNull);
    expect(find.text('Loading lesson'), findsOneWidget);
    expect(find.text('Lesson'), findsOneWidget);

    gates.single.complete(jsonResponse(okEnvelope({'module': _lessonJson()})));
    await tester.pump();
    gates.last.complete(jsonResponse(okEnvelope({'progress': []})));
    await tester.pumpAndSettle();
    expect(find.text('Approach sideways.'), findsOneWidget);
  });

  testWidgets('lesson renders paragraphs and marks progress', (tester) async {
    final posted = <Map<String, dynamic>>[];
    final api = ApiClient(
      config: config,
      httpClient: jsonClient((request) async {
        final path = request.url.path;
        if (request.method == 'POST' && path.endsWith('/elearning/progress')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          posted.add(body);
          final status = body['status'];
          return jsonResponse(
            okEnvelope({
              'progress': {
                'module_id': 'm1',
                'status': status,
                'read_pct': status == 'completed' ? 100 : 0,
                'quiz_passed': status == 'completed' ? 1 : 0,
                'badge_earned': status == 'completed' ? 1 : 0,
              },
            }),
          );
        }
        if (path.endsWith('/elearning/progress')) {
          return jsonResponse(okEnvelope({'progress': []}));
        }
        return jsonResponse(okEnvelope({'module': _lessonJson()}));
      }),
    );
    await pumpLearn(tester, const LearningModuleScreen(moduleId: 'm1'), api);
    await tester.pumpAndSettle();
    expect(find.text('Dog Behavior Basics'), findsWidgets);
    expect(find.text('Dog behavior'), findsOneWidget);
    expect(find.text('This course is not started.'), findsOneWidget);
    expect(find.text('Approach sideways.'), findsOneWidget);
    expect(find.text('Wait for the sniff.'), findsOneWidget);
    expect(find.text('Mark in progress'), findsOneWidget);
    expect(find.text('Mark completed'), findsOneWidget);

    await tester.ensureVisible(find.text('Mark in progress'));
    await tester.tap(find.text('Mark in progress'));
    await tester.pumpAndSettle();
    expect(posted.single['status'], 'in_progress');
    expect(posted.single['module_id'], 'm1');
    expect(find.text('This course is in progress.'), findsOneWidget);
    expect(find.text('Mark in progress'), findsNothing);

    await tester.ensureVisible(find.text('Mark completed'));
    await tester.tap(find.text('Mark completed'));
    await tester.pumpAndSettle();
    expect(posted.last['status'], 'completed');
    expect(find.text('You completed this course.'), findsOneWidget);
    expect(find.text('Mark completed'), findsNothing);
  });

  testWidgets('lesson with null body and quiz does not throw', (tester) async {
    final api = ApiClient(
      config: config,
      httpClient: jsonClient((request) async {
        if (request.url.path.endsWith('/elearning/progress')) {
          return jsonResponse(okEnvelope({'progress': null}));
        }
        return jsonResponse(
          okEnvelope({
            'module': {
              'id': 'm1',
              'title': null,
              'category': null,
              'content_body': null,
              'published_status': null,
              'has_quiz': null,
              'quiz': null,
            },
          }),
        );
      }),
    );
    await pumpLearn(tester, const LearningModuleScreen(moduleId: 'm1'), api);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Untitled course'), findsWidgets);
    expect(find.text('This lesson has no text yet.'), findsOneWidget);
    expect(find.text('Quiz'), findsNothing);
  });
}

Map<String, Object?> _lessonJson() {
  return {
    'id': 'm1',
    'title': 'Dog Behavior Basics',
    'category': 'dog_behavior',
    'published_status': 'published',
    'content_body': '<p>Approach sideways.</p><p>Wait for the sniff.</p>',
    'has_quiz': false,
    'quiz': null,
  };
}
