# ListenVision Copilot Instructions

> Music streaming app — Flutter frontend (`frontend_flutter/`) + Node.js backend (`listen-vision_api/`).
> Target dev environment: Windows 11 24H2 / PowerShell. Node.js 24.13.0 (fixed). Flutter 3.38.5 / Dart 3.10.4.

## Build, test, and lint commands

### Backend (`listen-vision_api`)

```powershell
cd listen-vision_api
pnpm install
node index.js                           # Start server
Get-Process node | Stop-Process -Force  # Stop server
```

```powershell
# All tests
pnpm test

# Single test file
pnpm jest tests\controllers\authController.test.js

# By name pattern
pnpm jest -t "should authenticate user"

# Coverage (threshold: 70% branches/functions/lines/statements)
pnpm test:coverage
```

### Frontend (`frontend_flutter`)

```powershell
cd frontend_flutter
flutter pub get
flutter run
# After editing any @riverpod / @freezed annotated files:
flutter pub run build_runner build --delete-conflicting-outputs
```

```powershell
# Lint / static checks
flutter analyze
dart fix --apply
```

```powershell
# All tests
flutter test

# Single test file
flutter test test\providers\auth\auth_provider_test.dart

# Coverage
flutter test --coverage
```

## High-level architecture

```
frontend_flutter/lib/
├── core/
│   ├── errors/          # AppError, exceptions.dart (incl. ValidationException)
│   ├── network/         # api_client.dart, dio_client.dart, endpoints.dart,
│   │                    # network_status_provider.dart
│   ├── models/          # network_status.dart
│   └── utils/           # error_handler.dart
├── models/
│   ├── dto/             # api_dto.dart — ApiResponse<T>, LoginRequestDto, etc.
│   └── entities/        # Audio, Playlist, User, SyncQueue …
├── data/
│   ├── database/        # SQLite DAOs (TrackDao, DownloadTaskDao, SyncQueueDao)
│   ├── repositories/    # TrackRepository, PlaylistRepository …
│   └── sync/            # SyncWorker, sync_worker_provider.dart,
│                        # download_integrity_provider.dart
├── services/            # AudioPlayerService, MetadataService,
│                        # DownloadIntegrityService
└── presentation/
    ├── viewmodels/      # One file per feature domain; @riverpod annotations
    │   ├── auth/
    │   ├── player/      # queue_viewmodel.dart — local-first playAt()
    │   ├── library/
    │   ├── discovery/
    │   └── system/
    ├── views/
    ├── widgets/
    │   └── common/      # network_status_listener.dart
    ├── utils/           # error_ui_handler.dart
    └── providers.dart   # Re-exports only — no implementations here

listen-vision_api/
├── index.js             # Middleware wiring + mounts routes/v1.js at /api/v1
├── routes/v1.js         # Domain split: auth, playlists, history, search,
│                        # recommendations, bilibili, netease, audio
├── controllers/         # catchAsync + AppError; call successResponse/errorResponse
├── services/            # Business logic + better-sqlite3 prepared statements
├── middleware/          # auth.js, errorHandler.js, logger.js, rateLimiter.js
└── utils/
    ├── logger.js        # Winston (error/warn/info/debug)
    └── response.js      # successResponse, errorResponse, paginatedResponse
```

### Backend request flow

1. `index.js` wires CORS, JSON parser, request logger, rate limiting → `routes/v1.js`.
2. Controllers validate/adapt request-response using `catchAsync` + `AppError`.
3. Services own business rules and DB access (better-sqlite3 prepared statements).
4. All responses use `utils/response.js` helpers.

### Frontend data flow

1. `main.dart` — initializes `AppLogger`, storage permissions, SQLite (`sqflite_common_ffi` on desktop), shared storage, and restores JWT token.
2. `app.dart` — binds UI root; watches `authTokenProvider` → syncs token into `DioClient`; wraps root with `NetworkStatusListener`.
3. ViewModels (`presentation/viewmodels/**`) — `@riverpod` annotated, hold `AsyncValue` state, call repositories.
4. Repositories (`data/repositories/`) — local-first: write SQLite first, enqueue `SyncWorker` task second.
5. `SyncWorker` (`data/sync/sync_worker.dart`) — background worker, 30 s interval, max 3 retries per task.
6. `DownloadIntegrityService` — scans downloaded files on launch, every 30 min, and before each playback; marks missing files as not-downloaded.
7. API layer: `ApiClient` (`core/network/api_client.dart`) + endpoint constants (`core/network/endpoints.dart`).

## Key conventions

### General

- **API versioning**: all backend endpoints are prefixed `/api/v1`.
- **Never use** `print()` (Dart) or `console.log()` (JS).
- **Frontend logging**: `AppLogger.debug/info/warn/error(...)`.
- **Backend logging**: `logger.debug/info/warn/error(...)` from `utils/logger.js`.
- **Local docs first**: use `references/bilibili-API-collect/docs/` before any web search for Bilibili API work.

### Frontend — Riverpod

- Annotate with `@riverpod` (lowercase for functions, `@Riverpod` for classes).
- Run `build_runner` after any annotation change to regenerate `*.g.dart`.
- `ref.watch` for reactive subscriptions; `ref.read` inside callbacks / one-shot actions.
- Define providers in their own files under `presentation/viewmodels/`; `providers.dart` is **export-only**.

### Frontend — local-first writes

```
User action → write SQLite → update UI immediately
                           → enqueue SyncWorker task → retry up to 3× (30 s interval)
```

Supported sync types: `favorite`, `unfavorite`, `playHistory`, `addPlaylistItem`, `removePlaylistItem`, `createPlaylist`, `updatePlaylist`, `deletePlaylist`.

### Frontend — playback

- `QueueViewModel.playAt()` checks local file existence first; falls back to network stream if unavailable.
- Audio engine: **audioplayers** ^6.4.0 (migrated from just_audio; Windows stability).

### Frontend — error UI

Use `ErrorUIHandler` (`presentation/utils/error_ui_handler.dart`) for all user-facing feedback:
- `showError` / `showSuccess` / `showWarning` / `showInfo` / `showToast`
- `showErrorDialog` / `showConfirmDialog` / `showInputDialog`
- `tryAsync` / `trySync` — safe wrappers that surface errors through the handler.

### Frontend — network status

`NetworkStatusListener` (wraps app root) auto-shows snackbar on disconnect/reconnect.
`networkStatusProvider` exposes `NetworkStatus` (wifi / mobile / ethernet / vpn / none).

### Backend — controllers

- Wrap async handlers with `catchAsync`.
- Throw `AppError` for business/validation errors (picked up by `errorHandler` middleware).
- Use `successResponse(res, data, message)` and `errorResponse(res, message, statusCode)` — never raw `res.json`.

### Backend — response shape

```javascript
// Success
successResponse(res, data, '操作成功');

// Error
errorResponse(res, '错误信息', 400);

// Paginated
paginatedResponse(res, items, page, pageSize, total);
```

## Tech stack versions

| Layer | Tech | Version |
|-------|------|---------|
| Frontend | Flutter / Dart | 3.38.5 / ^3.10.4 |
| Frontend | Riverpod | flutter_riverpod ^3.1.0, riverpod_generator ^4.0.0 |
| Frontend | Audio | audioplayers ^6.4.0 |
| Frontend | SQLite | sqflite ^2.4.2, sqflite_common_ffi ^2.3.5 |
| Frontend | HTTP | dio ^5.8.0+1 |
| Frontend | State freezed | freezed_annotation ^3.1.0, freezed ^3.2.3 |
| Frontend | Network status | connectivity_plus ^6.1.3 |
| Backend | Node.js | 24.13.0 (fixed — required by better-sqlite3) |
| Backend | Express | ^5.1.0 |
| Backend | SQLite | better-sqlite3 ^12.6.2 |
| Backend | Auth | jsonwebtoken ^9.0.3, bcrypt ^5.1.1 |
| Backend | Logging | winston ^3.19.0 |
| Backend | Testing | jest ^30.2.0, supertest ^7.2.2 |

## Auth architecture

1. **Main account** — Email/Password + JWT (stored in `flutter_secure_storage`)
2. **Platform binding** — Bilibili QR-code login, cookie encrypted with AES-256-CBC
3. **Guest mode** — Local playback only, no login required

## Reference docs

| Topic | Location |
|-------|----------|
| Bilibili API | `references/bilibili-API-collect/docs/` |
| Riverpod | `references/riverpod/` |
| Riverpod guide | `docs/guides/RIVERPOD_GUIDE.md` |
| Logging standards | `docs/guides/LOGGING_STANDARDS.md` |
| Comment standards | `docs/guides/CODE_COMMENT_STANDARDS.md` |
