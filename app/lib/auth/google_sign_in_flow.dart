import 'package:google_sign_in/google_sign_in.dart';

import 'google_config.dart';

/// Returns a Google ID token, or null if the person cancels the prompt.
Future<String?> requestGoogleIdToken() async {
  final google = GoogleSignIn(serverClientId: googleServerClientId);
  final account = await google.signIn();
  if (account == null) {
    return null;
  }
  final auth = await account.authentication;
  final token = auth.idToken;
  if (token == null || token.isEmpty) {
    throw StateError('Google did not return an ID token.');
  }
  return token;
}
