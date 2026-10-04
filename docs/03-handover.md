# Handover — phone client

Open `D:\pepot\furescue-app` + `D:\pepot\furescue`. Do not use the emulator. Do not edit `D:\pepot\marinesee`.

## Already done

- Flutter Android client (`com.furescue.app`, minSdk 26), tokens, JWT session
- Login / signup / admin “use the web console” wall
- Resident + rescuer shells (role split)
- Resident: My reports, new report (GPS + photos), browse + animal detail (3D via `model_3d_url`), apply / my adoptions, my listings
- Rescuer: My cases, case detail, accept / decline, proof photos, duty on/off
- Duty status is restored from `GET /users/me` (`duty_status` for rescuers)
- Shared: e-learning, messages inbox + thread, notifications, account edit + photo
- Seed password: `Password123!` (`juan@furescue.local`, `rescuer@furescue.local`)

## Still open (do not invent)

- Offline report queue
- Google Sign-In / FCM / map widget
- Case **resolve** is admin-only on the API (`CaseWorkflowService`). Phone uploads proof; City Vet resolves on web.

## Run

```bat
cd D:\pepot\furescue
php -S 0.0.0.0:8000 -t public public\index.php
adb reverse tcp:8000 tcp:8000
cd D:\pepot\furescue-app\app
flutter run
```
