/// Web OAuth client id. The API checks the Google ID token audience
/// against `GOOGLE_CLIENT_ID` in the web `.env`.
///
/// Override with `--dart-define=GOOGLE_SERVER_CLIENT_ID=...` if that value changes.
const googleServerClientId = String.fromEnvironment(
  'GOOGLE_SERVER_CLIENT_ID',
  defaultValue:
      '834001682148-4ihrmh94oeob559qotfqaqbjkidrth3a.apps.googleusercontent.com',
);
