# FuRescue Android app

Flutter client for residents and rescuers. It calls the existing PHP API in `D:\pepot\furescue`. Physical **phone only** — do not use the Android emulator.

## Run

On the phone: USB debugging on, plugged in. Then:

```bat
cd D:\pepot\furescue-app\app
flutter devices
flutter pub get
flutter run
```

`flutter devices` must list your phone (for example `SM A135F`). If you only see `windows` / `chrome`, fix the cable. Do not start an emulator.

## Point the phone at the API

The phone is not the laptop. `http://127.0.0.1:8000` on the device is the phone itself unless you reverse the port.

From `D:\pepot\furescue`:

```bat
php -S 0.0.0.0:8000 -t public public\index.php
```

Then pick **one**:

| Method | App base URL | How |
|--------|--------------|-----|
| `adb reverse` (USB, default) | `http://127.0.0.1:8000` | After the phone is connected: `adb reverse tcp:8000 tcp:8000`. Then `flutter run` with no extra flags. |
| LAN | `http://<laptop-lan-ip>:8000` | Same Wi-Fi. Allow port 8000 in Windows Firewall. `flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8000` |

Seed accounts and password: `D:\pepot\furescue\docs\technical\HOW_TO_RUN.md` and `WORKFLOWS.md`. Demo password is `Password123!`.

- `juan@furescue.local` → resident shell
- `rescuer@furescue.local` → rescuer shell
- `admin@furescue.local` → “Use the web console” (no admin tabs)

## Tests

```bat
cd D:\pepot\furescue-app\app
flutter test
```

That is the CI-safe suite (tokens, envelope/ApiClient mocks, login errors, role gate, list empty/error). It does not need MySQL or a phone.

Physical-phone `integration_test` (USB debugging, `adb reverse tcp:8000 tcp:8000`, PHP serving `.env.test`):

```bat
flutter test integration_test -d <phone-id>
```

See `../docs/02-how-to-run.md` and `D:\pepot\furescue\docs\technical\TESTING.md`.

## Analyze

```bat
cd D:\pepot\furescue-app\app
flutter analyze
```

Phone-only spec: `../docs/01-mobile.md`. Full run notes: `../docs/02-how-to-run.md`.
