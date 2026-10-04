# FuRescue (mobile)

Flutter Android client for **residents and rescuers** in Mati City. It talks to the same PHP API as the web system. It is **not** a second backend and **not** a rewrite of the admin console.

Product truth stays in the sibling web repo: [`D:\pepot\furescue`](../furescue).

| Need | Where |
|------|--------|
| Study, scope, roles, status machines | `D:\pepot\furescue\docs\study` and `docs\technical\WORKFLOWS.md` |
| Live API routes | `D:\pepot\furescue\src\Http\Routes` |
| Run PHP / MySQL | `D:\pepot\furescue\docs\technical\HOW_TO_RUN.md` |
| What the phone is (and is not) | [docs/01-mobile.md](docs/01-mobile.md) |
| Flutter + physical phone + LAN API | [docs/02-how-to-run.md](docs/02-how-to-run.md) |

The Flutter project lives in [`app/`](app/). **Physical phone only** — do not use the emulator.

```bat
cd app
flutter pub get
flutter devices
flutter run
```

Default API base URL is `http://127.0.0.1:8000` (use `adb reverse tcp:8000 tcp:8000`). For Wi-Fi, pass `--dart-define=API_BASE_URL=http://<laptop-lan-ip>:8000`. Details: [app/README.md](app/README.md).
