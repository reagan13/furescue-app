import 'package:flutter_test/flutter_test.dart';
import 'package:furescue_app/api/api_client.dart';
import 'package:furescue_app/api/api_exception.dart';
import 'package:furescue_app/api/config.dart';
import 'package:furescue_app/models/auth_tokens.dart';
import 'package:furescue_app/models/user.dart';
import 'package:furescue_app/session/auth_session.dart';
import 'package:furescue_app/session/session_store.dart';

import '../support/http_json.dart';

void main() {
  const config = ApiConfig(baseUrl: 'http://127.0.0.1:8000');
  const tokens = AuthTokens(accessToken: 'access-1', refreshToken: 'refresh-1');

  test('memory store round-trips tokens and clears them', () async {
    final store = MemorySessionStore();
    expect(await store.read(), isNull);
    await store.write(tokens);
    final stored = await store.read();
    expect(stored?.accessToken, 'access-1');
    expect(stored?.refreshToken, 'refresh-1');
    await store.clear();
    expect(await store.read(), isNull);
  });

  test('login stores both tokens and the signed-in user', () async {
    final store = MemorySessionStore();
    final session = AuthSession(
      api: ApiClient(
        config: config,
        httpClient: jsonClient((request) async {
          final path = request.url.path;
          if (path.endsWith('/auth/login')) {
            expect(request.headers['authorization'], isNull);
            return jsonResponse(
              okEnvelope({
                'user': fixtureUser(role: 'resident'),
                'tokens': {
                  'access_token': 'access-1',
                  'refresh_token': 'refresh-1',
                },
              }),
            );
          }
          expect(request.headers['authorization'], 'Bearer access-1');
          expect(path, endsWith('/users/me'));
          return jsonResponse(
            okEnvelope({'user': fixtureUser(role: 'resident')}),
          );
        }),
      ),
      store: store,
    );

    await session.login(email: ' juan@furescue.local ', password: 'Password123!');

    expect(session.isSignedIn, isTrue);
    expect(session.user?.email, 'juan@furescue.local');
    expect(session.user?.isResident, isTrue);
    expect(session.api.accessToken, 'access-1');
    expect((await store.read())?.refreshToken, 'refresh-1');
    expect(session.busy, isFalse);
  });

  test('login failure does not write a session', () async {
    final store = MemorySessionStore();
    final session = AuthSession(
      api: ApiClient(
        config: config,
        httpClient: jsonClient((request) async {
          return jsonResponse(
            errorEnvelope('INVALID_CREDENTIALS', 'Email or password is incorrect'),
            status: 401,
          );
        }),
      ),
      store: store,
    );

    await expectLater(
      session.login(email: 'juan@furescue.local', password: 'nope'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.code,
          'code',
          'INVALID_CREDENTIALS',
        ),
      ),
    );
    expect(session.isSignedIn, isFalse);
    expect(await store.read(), isNull);
  });

  test('incomplete login tokens stay unsigned-in', () async {
    final store = MemorySessionStore();
    final session = AuthSession(
      api: ApiClient(
        config: config,
        httpClient: jsonClient((request) async {
          return jsonResponse(
            okEnvelope({
              'tokens': {'access_token': 'access-1', 'refresh_token': ''},
            }),
          );
        }),
      ),
      store: store,
    );

    await expectLater(
      session.login(email: 'juan@furescue.local', password: 'Password123!'),
      throwsA(
        isA<ApiException>().having((e) => e.code, 'code', 'BAD_RESPONSE'),
      ),
    );
    expect(session.isSignedIn, isFalse);
    expect(await store.read(), isNull);
  });

  test('pending registration does not sign in', () async {
    final store = MemorySessionStore();
    final session = AuthSession(
      api: ApiClient(
        config: config,
        httpClient: jsonClient((request) async {
          return jsonResponse(
            okEnvelope({
              'user': fixtureUser(
                role: 'rescuer',
                email: 'rescuer6@furescue.local',
                accountStatus: 'pending',
              ),
            }),
          );
        }),
      ),
      store: store,
    );

    final message = await session.register(
      fullName: 'Pending Rescuer',
      email: 'rescuer6@furescue.local',
      password: 'Password123!',
      role: 'rescuer',
    );

    expect(message, 'Your account needs admin approval before you can sign in.');
    expect(session.isSignedIn, isFalse);
    expect(await store.read(), isNull);
  });

  test('restore loads the user, and a failed me call clears the store', () async {
    final store = MemorySessionStore();
    await store.write(tokens);
    var meCalls = 0;
    final session = AuthSession(
      api: ApiClient(
        config: config,
        httpClient: jsonClient((request) async {
          meCalls++;
          if (meCalls == 1) {
            expect(request.headers['authorization'], 'Bearer access-1');
            return jsonResponse(
              okEnvelope({
                'user': {
                  ...fixtureUser(role: 'rescuer'),
                  'duty_status': 'on_duty',
                },
              }),
            );
          }
          return jsonResponse(
            errorEnvelope('UNAUTHENTICATED', 'expired'),
            status: 401,
          );
        }),
      ),
      store: store,
    );

    await session.restore();
    expect(session.booting, isFalse);
    expect(session.isSignedIn, isTrue);
    expect(session.isOnDuty, isTrue);

    await session.restore();
    expect(session.isSignedIn, isFalse);
    expect(session.dutyStatus, 'off_duty');
    expect(await store.read(), isNull);
    expect(session.booting, isFalse);
  });

  test('refresh rotates the access token and keeps the refresh token', () async {
    final store = MemorySessionStore();
    await store.write(tokens);
    final session = AuthSession(
      api: ApiClient(
        config: config,
        httpClient: jsonClient((request) async {
          expect(request.url.path, endsWith('/auth/refresh'));
          return jsonResponse(okEnvelope({'access_token': 'access-2'}));
        }),
      ),
      store: store,
    )..tokens = tokens;

    final next = await session.refreshAccess();
    expect(next, 'access-2');
    expect(session.api.accessToken, 'access-2');
    expect((await store.read())?.accessToken, 'access-2');
    expect((await store.read())?.refreshToken, 'refresh-1');
  });

  test('a failed refresh leaves the stored session in place', () async {
    final store = MemorySessionStore();
    await store.write(tokens);
    final session = AuthSession(
      api: ApiClient(
        config: config,
        httpClient: jsonClient((request) async {
          return jsonResponse(
            errorEnvelope('UNAUTHENTICATED', 'expired'),
            status: 401,
          );
        }),
      ),
      store: store,
    )..tokens = tokens;

    expect(await session.refreshAccess(), isNull);
    expect((await store.read())?.accessToken, 'access-1');
  });

  test('logout clears tokens from memory and the store', () async {
    final store = MemorySessionStore();
    await store.write(tokens);
    final session = AuthSession(
      api: ApiClient(config: config),
      store: store,
    )..tokens = tokens
      ..api.accessToken = 'access-1';

    await session.logout();
    expect(session.tokens, isNull);
    expect(session.user, isNull);
    expect(session.api.accessToken, isNull);
    expect(await store.read(), isNull);
  });

  test('setDuty updates a rescuer and refuses a signed-out call', () async {
    final store = MemorySessionStore();
    final session = AuthSession(
      api: ApiClient(
        config: config,
        httpClient: jsonClient((request) async {
          expect(request.method, 'PATCH');
          expect(request.url.path, contains('/rescuers/'));
          expect(request.url.path, endsWith('/duty'));
          return jsonResponse(okEnvelope({'duty_status': 'on_duty'}));
        }),
      ),
      store: store,
    );

    await expectLater(
      session.setDuty('on_duty'),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'NO_USER')),
    );

    session.user = User.fromJson(fixtureUser(role: 'rescuer'));
    await session.setDuty('on_duty');
    expect(session.isOnDuty, isTrue);
  });
}
