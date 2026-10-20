# Handover run and check

**For the next agent that opened this repo.** The phone is a client. Seed, migrate, and the API live in `D:\pepot\furescue`. Run the steps below before `flutter run`. What the app already does is [03-handover.md](03-handover.md). Install (PHP extensions, MySQL user SQL) is `D:\pepot\furescue\docs\technical\HOW_TO_RUN.md`. The same checklist also sits at `D:\pepot\furescue\docs\technical\HANDOVER_RUN.md`.

Leave `D:\pepot\marinesee` alone. Do not start an emulator.

| Repo | Path | Role |
|------|------|------|
| Web + API | `D:\pepot\furescue` | The only server and the only database |
| Android | `D:\pepot\furescue-app` | This repo. Resident and rescuer only |

One PHP process serves pages and `/api/v1`. The app calls that process with a Bearer JWT. It does not use the web page session.

## Which database

| Job | Database | Env file | How it is filled |
|-----|----------|----------|------------------|
| Tap through the app and the website | `furescue` | `.env` in the web repo | `php seeders\seed.php` |
| PHPUnit, Playwright, phone `integration_test` | `furescue_test` | `.env.test` | `php bin\reset-test-db.php` |

A hand check uses `furescue`. Automated suites use `furescue_test`. `bin\serve-test.bat` loads `.env.test` and does not overwrite `.env`.

`.env` must contain `DB_DRIVER=mysql`. Without it the web app falls back to Postgres and migrate fails.

## 1. First time on this machine

In `D:\pepot\furescue`, follow HOW_TO_RUN through the MySQL user, `.env`, `composer install`, and `npm run build`. Then return here.

This repo also needs Flutter on PATH, an Android SDK, and a physical phone (Android 8 / API 26 or higher) with USB debugging on.

Minimum `.env` in the web repo:

```ini
DB_DRIVER=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_NAME=furescue
DB_USER=furescue
DB_PASS=furescue_pass
APP_SECRET=change_me_app_secret
JWT_SECRET=change_me_jwt_secret
JWT_REFRESH_SECRET=change_me_refresh_secret
CORS_ALLOWED_ORIGINS=http://127.0.0.1:8000
```

The app does not read `.env`. Its API address is `app/lib/api/config.dart`: `http://127.0.0.1:8000` unless you pass `--dart-define=API_BASE_URL=...`.

## 2. Database: migrate, then seed

From `D:\pepot\furescue`:

```bat
php bin\migrate.php
php seeders\seed.php
```

`migrate.php` creates tables. It does not insert demo rows. `seed.php` is safe to run again. It fills accounts plus reports, cases, animals, health, adoptions, messages, notifications, and e-learning, so the phone lists are not empty.

| Command | Use it when |
|---------|-------------|
| `php seeders\seed.php` | Phone screens should already show reports, cases, animals, messages, and lessons |
| `php seeders\seed_users.php` | You only need to log in. Lists stay empty |
| `php bin\migrate.php --fresh --yes` | Wipe every table. Run `php seeders\seed.php` again or login fails |

## 3. Accounts

Password for every seeded account: **`Password123!`**.

| Role | Email | On the phone |
|------|-------|----------------|
| Resident | `juan@furescue.local`, also `maria@`, `ana@`, `pedro@`, `rosa@`, `miguel@` | Resident shell. Reports, browse, adoptions, listings |
| Rescuer, on duty | `rescuer@furescue.local` through `rescuer5@furescue.local` | Rescuer shell. Cases, duty |
| Rescuer, pending | `rescuer6@furescue.local`, `rescuer7@furescue.local` | Blocked until an admin approves them on the website |
| Admin | `admin@furescue.local` | Must show “use the web console” and stop. Admin work is `http://127.0.0.1:8000/admin/` |

Give each phone a different resident or rescuer. Two phones on `juan@` share one inbox.

## 4. Start the server

Phones cannot use a server bound only to loopback. From `D:\pepot\furescue`:

```bat
php -S 0.0.0.0:8000 -t public public\index.php
```

Leave that window open. Confirm the seed from the laptop:

```bat
curl -X POST http://127.0.0.1:8000/api/v1/auth/login -H "Content-Type: application/json" -d "{\"email\":\"juan@furescue.local\",\"password\":\"Password123!\"}"
```

`success: true` and a `tokens.access_token` means the API is up. A database error here is migrate, `.env`, or MySQL.

Website homes while that server is running: juan at http://127.0.0.1:8000/reports/ , rescuer at http://127.0.0.1:8000/cases/ , admin at http://127.0.0.1:8000/admin/ . Unstyled pages mean `npm run build` has not been run in the web repo.

## 5. Install the app on a phone

`http://127.0.0.1:8000` on the phone is the phone itself.

**One phone, cable plugged in**

```bat
adb reverse tcp:8000 tcp:8000
cd D:\pepot\furescue-app\app
flutter pub get
flutter devices
flutter run
```

`flutter devices` must list that phone. Windows or Chrome alone means the cable or the driver is wrong.

**Several phones, no cable**

1. The server is already `php -S 0.0.0.0:8000`.
2. On the laptop, `ipconfig`. Use the Wi-Fi IPv4 address, for example `192.168.1.20`.
3. Allow inbound TCP 8000 on private networks when Windows Firewall asks.
4. Each phone joins that Wi-Fi. In the phone browser, open `http://192.168.1.20:8000` before installing.
5. Build one APK with that address:

```bat
cd D:\pepot\furescue-app\app
flutter build apk --release --dart-define=API_BASE_URL=http://192.168.1.20:8000
```

APK: `app\build\app\outputs\flutter-apk\app-release.apk`. Send it to each phone. If the laptop IP changes, build again.

`flutter run` is one device at a time. Several people tapping at once use the release APK.

## 6. What a pass looks like

Stop at the first failure.

1. `php bin\migrate.php` finishes.
2. `php seeders\seed.php` finishes.
3. The juan login `curl` returns `success: true`.
4. On a phone, `juan@furescue.local` opens the resident shell and sees seeded reports.
5. `rescuer@furescue.local` opens the rescuer shell and sees seeded cases.
6. `admin@furescue.local` is stopped with the web-console message.
7. A second phone, different account, reaches the same server.

Phone GPS submit, a real camera photo, Google sign-in, and 3D playback stay manual. Case **resolve** stays on the website. The app does not alert while it is closed. Both are written in [03-handover.md](03-handover.md).

## 7. Automated check

Widget tests need no server and no phone:

```bat
cd D:\pepot\furescue-app\app
flutter test
flutter analyze
```

`integration_test` hits `furescue_test`, not the demo database. From the web repo, `php bin\reset-test-db.php`, then `bin\serve-test.bat` left open. With the phone on USB:

```bat
adb reverse tcp:8000 tcp:8000
cd D:\pepot\furescue-app\app
flutter test integration_test -d <phone-id>
```

The rest of the pyramid is `D:\pepot\furescue\docs\technical\TESTING.md`.
