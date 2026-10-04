# AGENTS.md

FuRescue mobile: Flutter Android client for residents and rescuers in Mati City. This repo is a **client**, not a second backend. The product lives in the sibling web repo at `D:\pepot\furescue`.

Daily work is Cursor + `flutter` CLI + a **physical phone**. Do not use the Android emulator.

Before changing product behavior, read the web study + `WORKFLOWS.md` + `src/Http/Routes`. If web and mobile docs disagree, **web wins** (except Flutter / phone rules, which only exist here).

Labels: **STUDY** (web) / **IMPLEMENTATION** (phone-only) / **OPEN**.

## Hard rules

- **Flutter only.** Android minSdk 26. Physical phone. Never add a Kotlin / React Native second app. Never treat the emulator as the default device.
- **One API.** Call the existing FuRescue PHP server (`/api/v1`). No Firebase, no second REST stack, no local mock API that becomes the source of truth.
- **Auth is Bearer JWT** (`POST /api/v1/auth/login` + refresh). Do not use PHP `$_SESSION` from the web login page.
- **Admin stays on web.** Mobile v1 is resident + rescuer only. If an admin JWT lands in the app, show “use the web console” and stop. Do not call admin-gated routes (verify, assign, animal write, analytics, broadcast).
- **Mati City only.** Dogs/cats, Aspin/Puspin. No payments, no AI recognition, no Messenger/WhatsApp.
- **Do not invent science or expand scope** past the study. Product “what” is in `D:\pepot\furescue\docs\study`.
- **No Blender work in this repo.** 3D is playback of `model_3d_url` / a 360 set — or a placeholder. Do not author `.blend` files.
- **Web UI stays in `furescue`.** Never copy PHP pages into Flutter.
- **Tokens, not raw hex.** Port from the web design system into `theme/tokens.dart` when we scaffold. Change tokens on web first.

## Live truth (do not copy)

| Kind of truth | Canonical place |
|---------------|-----------------|
| Objectives, scope, limitations, IPO | `D:\pepot\furescue\docs\study` |
| Roles, status machines, page map | `D:\pepot\furescue\docs\technical\WORKFLOWS.md` |
| Which endpoints exist | `D:\pepot\furescue\src\Http\Routes` |
| Envelope / CORS | `D:\pepot\furescue\src\Http\Response.php` |
| JWT shape / TTL | `D:\pepot\furescue\src\Auth\JwtService.php` |
| Colors / type | `D:\pepot\furescue\public\assets\css\tokens.css` + `docs\study\DESIGN_SYSTEM.md` |
| How to run PHP / MySQL | `D:\pepot\furescue\docs\technical\HOW_TO_RUN.md` |

Do not maintain a parallel route list or a second study. If the web adds a route, the route file is the contract the day it lands.

Phone-only spec: `docs/01-mobile.md`. Phone + LAN API: `docs/02-how-to-run.md`.

## Layout

```text
docs/                phone-only spec (two files)
app/                 Flutter Android project (minSdk 26)
```

## Modular files

One concern per file. Split past ~300 lines. Screens stay out of API / session / theme files.

## Commands (after `app/` exists)

```bat
cd app
flutter pub get
flutter devices
flutter run
flutter test
flutter analyze
flutter test integration_test -d <phone-id>
```

Phone only. See `docs/02-how-to-run.md`.
