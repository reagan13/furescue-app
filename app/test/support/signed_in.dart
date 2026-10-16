import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furescue_app/api/api_client.dart';
import 'package:furescue_app/models/auth_tokens.dart';
import 'package:furescue_app/models/user.dart';
import 'package:furescue_app/session/auth_session.dart';
import 'package:furescue_app/session/session_scope.dart';
import 'package:furescue_app/session/session_store.dart';
import 'package:furescue_app/theme/theme.dart';
import 'package:google_fonts/google_fonts.dart';

import 'http_json.dart';

/// A signed-in session that never touches the Android keystore.
AuthSession signedInSession(
  ApiClient api, {
  String role = 'resident',
  String id = '11111111-1111-4111-8111-111111111111',
}) {
  final session = AuthSession(api: api, store: MemorySessionStore())
    ..booting = false
    ..tokens = const AuthTokens(
      accessToken: 'access-1',
      refreshToken: 'refresh-1',
    )
    ..user = User.fromJson(fixtureUser(role: role, id: id));
  session.api.accessToken = 'access-1';
  return session;
}

void usePhoneSurface(
  WidgetTester tester, {
  Size size = const Size(360, 740),
}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Pumps [home] under a resident or rescuer session. Does not settle, so a
/// caller can assert the first frame before a mocked request returns.
Future<void> pumpSignedIn(
  WidgetTester tester,
  Widget home,
  ApiClient api, {
  String role = 'resident',
  Size? size,
}) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  if (size != null) {
    usePhoneSurface(tester, size: size);
  }
  await tester.pumpWidget(
    SessionScope(
      session: signedInSession(api, role: role),
      child: MaterialApp(theme: buildFuRescueTheme(), home: home),
    ),
  );
}
