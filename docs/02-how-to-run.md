# How to run the Flutter app (laptop-safe)

**IMPLEMENTATION** — same laptop rule as MarineSee: physical phone, no emulator. Goal: install an APK and hit the **existing** FuRescue API.

PHP / MySQL / seed / demo accounts: `D:\pepot\furescue\docs\technical\HOW_TO_RUN.md`. This file only adds Flutter and how the phone reaches that server.

The Flutter project is `app/`. Phone only — do not use the emulator.

## You need

1. **Windows 11** (already)
2. **Git**
3. **Flutter SDK** (stable) on PATH
4. **Android command-line tools + a platform-26+ SDK**
5. **A physical phone**: Android **8.0 (API 26)** or higher, USB cable, **Developer options → USB debugging** on
6. The web repo running (`D:\pepot\furescue`)
7. **Cursor** for editing

You do **not** need:

- Android Emulator
- Android Studio open every day
- A second REST server

## 1. Install Flutter

1. Download the Windows stable SDK from [flutter.dev/install](https://docs.flutter.dev/get-started/install/windows).
2. Unzip to something like `C:\src\flutter` (not under `Program Files` or OneDrive if you can help it — OneDrive + Gradle is painful). Putting the **SDK** outside OneDrive is enough.
3. Add `C:\src\flutter\bin` to your user PATH.
4. New terminal:

```bat
flutter doctor
```

Install whatever `flutter doctor` marks `[X]` except the emulator.

## 2. Android SDK without living in Android Studio

1. Install **Android Studio** once (supported way to get the SDK).
2. Open it **once**: SDK Manager → install **Android SDK Platform 34** (or current) **and API 26**, plus **Android SDK Command-line Tools**.
3. Do **not** install the Emulator system images.
4. Set `ANDROID_HOME` to the SDK path (usually `%LOCALAPPDATA%\Android\Sdk`).
5. **Quit Android Studio.** Daily work is Cursor + `flutter` CLI.

```bat
flutter doctor --android-licenses
```

## 3. Phone, not emulator

On the phone:

1. Settings → About → tap Build number 7 times.
2. Developer options → USB debugging.
3. Plug in USB. Allow the PC.

On the PC:

```bat
flutter devices
```

You should see the phone. If you only see `windows` / `chrome`, the cable or driver is wrong. Do not start an emulator to “just try.”

## 4. Point the phone at the local API

The phone is not the laptop. `http://127.0.0.1:8000` on the phone is the phone itself.

Do the web setup in `HOW_TO_RUN.md` first (`.env` with `DB_DRIVER=mysql`, migrate, seed). Then bind the PHP server to all interfaces:

From `D:\pepot\furescue`:

```bat
php -S 0.0.0.0:8000 -t public public\index.php
```

Pick **one** way for the app’s API base URL:

| Method | App base URL | Notes |
|--------|--------------|--------|
| `adb reverse` (USB) | `http://127.0.0.1:8000` | Run `adb reverse tcp:8000 tcp:8000` after the phone is connected. Survives until unplug / `adb reverse --remove-all`. |
| LAN IP | `http://<laptop-lan-ip>:8000` | Same Wi-Fi. Allow port 8000 in Windows Firewall. IP changes on new networks. |

Check from the phone’s browser (LAN) or from the PC after reverse:

```bat
curl -X POST http://127.0.0.1:8000/api/v1/auth/login -H "Content-Type: application/json" -d "{\"email\":\"juan@furescue.local\",\"password\":\"Password123!\"}"
```

Use a **resident or rescuer** seed account from the web how-to — not admin. Admin belongs on web.

Envelope and CORS: `src/Http/Response.php`. Native Flutter does not need CORS; keep `CORS_ALLOWED_ORIGINS` as the web how-to describes.

Mati geovalidation stays in the web `.env`. Do not copy bounds into the app as a second source of truth.

## 5. Run the app (after `app/` exists)

```bat
cd app
flutter pub get
flutter run
```

First Gradle build can take several minutes. Later runs are shorter.

Release APK (for testers, not Play Store):

```bat
cd app
flutter build apk --release
```

APK path: `app\build\app\outputs\flutter-apk\app-release.apk`.

## 6. Keep the machine alive

| Do | Don’t |
|----|--------|
| One `flutter run` + Cursor + one `php -S` | Emulator + Android Studio + Chrome piled on |
| Unplug / `q` in the Flutter CLI when done | Leave Gradle daemons + AS for hours |
| Close Chrome tabs if RAM hits 90% | Treat `127.0.0.1` on the phone as the laptop |

If Windows feels stuck: Task Manager → end **qemu** / **emulator** if it ever appeared, and **Android Studio**.

## 7. `flutter doctor` checklist before you call setup done

- [ ] Flutter (stable)
- [ ] Windows toolchain (can stay unused)
- [ ] Android toolchain (SDK, licenses)
- [ ] Connected device = **your phone**, not `emulator-5554`
- [ ] Web API reachable via reverse or LAN (login curl succeeds)
- [ ] VS Code / Cursor plugin optional

A red **Android Studio** line is OK if `flutter devices` shows the phone and `flutter run` installs.

## 8. Tests

Widget / API-contract tests (no phone, no server):

```bat
cd D:\pepot\furescue-app\app
flutter test
```

Live `integration_test` hits the same PHP `/api/v1` as the product. Point it at `furescue_test` (`D:\pepot\furescue\bin\serve-test.bat`), then:

```bat
adb reverse tcp:8000 tcp:8000
cd D:\pepot\furescue-app\app
flutter test integration_test -d <phone-id>
```

Do not use the emulator. GPS submit, camera, Google OAuth, and 3D playback stay on the manual checklist in `D:\pepot\furescue\docs\technical\TESTING.md`.
