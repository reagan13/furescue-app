# Phone scope and architecture

**IMPLEMENTATION** — questions the web repo cannot answer. Product “what” stays in `D:\pepot\furescue`.

## This folder is a client

The web system is already the product: PHP 8.1+ REST API (`/api/v1`), MySQL, admin console, and resident/rescuer pages. The study already asks for cross-platform access (`SIGNIFICANCE_AND_SCOPE.md`).

This repo only adds a Flutter Android client that calls that API.

```text
Phone  →  Flutter app (this repo)  →  FuRescue PHP /api/v1  (D:\pepot\furescue)
Browser →  admin + resident/rescuer web  →  same API
```

Do not add a second backend, Firebase, or a rewrite of admin.

## Auth on the device

Web pages use a PHP session after the login form. The phone does not.

- Login / register / refresh: `POST /api/v1/auth/login`, `/register`, `/refresh` (see `src/Http/Routes/AuthRoutes.php`).
- Store the access + refresh tokens on the device. Send `Authorization: Bearer <access_token>`.
- Token shape and TTL: `src/Auth/JwtService.php`. Envelope: `src/Http/Response.php` (`{ success, data, error }`).
- Do not scrape cookies from `/auth/login.php`.

## Who the phone is for

**STUDY** roles and page map: `docs/technical/WORKFLOWS.md`.

**IMPLEMENTATION** — mobile v1 is **resident + rescuer** only. Admin (heatmap, verify/assign, animals, health CMS, analytics) stays on web.

If an admin JWT lands in the app, show “use the web console” and stop. Do not build admin screens.

Residents never see My Cases. Rescuers never see Report / Browse / My Adoptions / My Listings.

### Phone screens (map to web URLs)

Shared:

| Phone screen | Web URL |
|--------------|---------|
| Login | `/auth/login.php` |
| Signup (resident or rescuer-applicant) | `/auth/signup.php` |
| Account | `/account/` |
| Notifications | `/notifications/` |
| Messages | `/messages/` |
| E-learning | `/learning/` |

Resident:

| Phone screen | Web URL |
|--------------|---------|
| New report (GPS + photos; Mati bbox is server-side) | `/report/` |
| My reports | `/reports/` |
| Browse animals + detail (play 3D if `model_3d_url` exists) | `/animals/` · `/animals/detail.php?id=` |
| Apply / my adoptions | `/adoptions/` |
| My listings | `/listings/` |

Rescuer:

| Phone screen | Web URL |
|--------------|---------|
| Duty on/off | `/cases/` (`PATCH /api/v1/rescuers/{id}/duty`) |
| My cases | `/cases/` · `/cases/detail.php?id=` |
| Accept / decline, proof photos, resolve | same |

Do not invent extra report/case/adoption states. The machines in `WORKFLOWS.md` §4 are the contract.

## API (live in web, not copied)

Call whatever `D:\pepot\furescue\src\Http\Routes` exposes today. Permission names on those routes decide what a resident vs rescuer may call.

**Do not call admin-gated routes** from the phone: verify, assign, animal write, analytics, broadcast. Admin stays web.

Mati bounds stay server-side (`MATI_LAT_*` / `MATI_LNG_*` in the web `.env`). The phone sends GPS; the API rejects out-of-bounds reports.

The phone cannot use the laptop’s `127.0.0.1` unless `adb reverse` is set. See `02-how-to-run.md`.

## Design

Port tokens from `public/assets/css/tokens.css` and `docs/study/DESIGN_SYSTEM.md` into `app/lib/theme/tokens.dart` when we scaffold. Jungle primary `#3D7432` / `hsl(110 40% 33%)`, paper/ink, Nunito + DM Sans, Lucide-equivalent icons — not a new palette. Change tokens on web first.

## After docs (not this pass)

1. `flutter create` under `app/` (Android, minSdk 26).
2. Shell + JWT session + role-based tabs.
3. Resident report/adopt, then rescuer cases.
4. Learning / messages / notifications.

## Open (do not decide in code yet)

- Offline report queue (study allows async on bad network)
- Google Sign-In on device (`POST /api/v1/auth/google` exists; device wiring is **OPEN**)
- Push (FCM) vs poll — study wants “real time”; web uses EventSource, not push
- Map widget (`flutter_map` + OSM to match Leaflet, vs Google Maps)
- Whether resident **web** stays long-term or mobile becomes the community surface (both can coexist; API is shared)
