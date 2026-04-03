# ListenVision Copilot Instructions

> Music streaming app — Flutter frontend (`frontend_flutter/`) + Python backend (`listen-vision-api-python/`).
> Target dev environment: Windows 11 24H2 / PowerShell. Flutter 3.38.5 / Dart 3.10.4.

## Build, test, and lint commands

### Backend (`listen-vision-api-python`)

```powershell
cd listen-vision-api-python
uv run uvicorn app.main:app     # Start server
Get-Process python -ErrorAction SilentlyContinue | Stop-Process -Force  # Stop server
```

```powershell
# All tests
uv run pytest tests/ -v

# Single test file
uv run pytest tests/test_auth.py -v

# By name pattern
uv run pytest tests/ -k "test_login" -v

# Coverage
uv run pytest tests/ -v --cov=app
```

### Frontend (`frontend_flutter`)

```powershell
cd frontend_flutter
flutter pub get
flutter run
# After editing any @riverpod / @freezed annotated files:
dart run build_runner build --delete-conflicting-outputs
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
flutter test test/viewmodels/player/playback_viewmodel_test.dart

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
├── services/            # AudioPlayerService, MetadataService,
│                        # DownloadIntegrityService
└── presentation/
    ├── viewmodels/      # One file per feature domain; @riverpod annotations
    │   ├── auth/
    │   ├── player/      # playback_viewmodel.dart — unified playback state
    │   ├── library/
    │   ├── discovery/
    │   └── system/
    ├── views/
    ├── widgets/
    │   └── common/      # network_status_listener.dart
    ├── utils/           # error_ui_handler.dart
    └── providers.dart   # Re-exports only — no implementations here

listen-vision-api-python/app/
├── main.py              # FastAPI app entry, mounts routers
├── api/routes/          # Domain split: auth, playlists, history, search,
│                        # recommendations, bilibili
├── services/            # Business logic + database operations
├── db/                  # Database models, repositories
├── models/              # Pydantic schemas
├── schemas/             # Request/response schemas
└── utils/               # Helpers, logger, security
```

### Backend request flow

1. `main.py` wires CORS, JSON parser, request logger → routers under `/api/v1`.
2. Route handlers validate request using Pydantic schemas.
3. Services own business rules and DB access (SQLAlchemy async).
4. All responses use standardized JSON format.

### Frontend data flow

1. `main.dart` — initializes `AppLogger`, storage permissions, SQLite (`sqflite_common_ffi` on desktop), shared storage, and restores JWT token.
2. `app.dart` — binds UI root; watches `authTokenProvider` → syncs token into `DioClient`; wraps root with `NetworkStatusListener`.
3. ViewModels (`presentation/viewmodels/**`) — `@riverpod` annotated, hold `AsyncValue` state, call repositories.
4. Repositories (`data/repositories/`) — local-first: write SQLite first, enqueue sync task second.
5. `DownloadIntegrityService` — scans downloaded files on launch, every 30 min, and before each playback; marks missing files as not-downloaded.
6. API layer: `ApiClient` (`core/network/api_client.dart`) + endpoint constants (`core/network/endpoints.dart`).

## Key conventions

### General

- **API versioning**: all backend endpoints are prefixed `/api/v1`.
- **Never use** `print()` (Dart) or `console.log()` (Python).
- **Frontend logging**: `AppLogger.debug/info/warn/error(...)`.
- **Backend logging**: Python logger from `app/utils/logger.py`.
- **Local docs first**: use `references/bilibili-API-collect/docs/` before any web search for Bilibili API work.

### Frontend — Riverpod

- Annotate with `@riverpod` (lowercase for functions, `@Riverpod` for classes).
- Run `build_runner` after any annotation change to regenerate `*.g.dart`.
- `ref.watch` for reactive subscriptions; `ref.read` inside callbacks / one-shot actions.
- Define providers in their own files under `presentation/viewmodels/`; `providers.dart` is **export-only**.

### Frontend — playback

- `PlaybackViewModel` — unified playback state management (play/pause/seek/next/previous).
- Audio engine: **audioplayers** ^6.4.0 (Windows stability).
- `AudioPlaybackState` enum abstracts audioplayers library details.

### Frontend — error UI

Use `ErrorUIHandler` (`presentation/utils/error_ui_handler.dart`) for all user-facing feedback:
- `showError` / `showSuccess` / `showWarning` / `showInfo` / `showToast`
- `showErrorDialog` / `showConfirmDialog` / `showInputDialog`
- `tryAsync` / `trySync` — safe wrappers that surface errors through the handler.

### Frontend — network status

`NetworkStatusListener` (wraps app root) auto-shows snackbar on disconnect/reconnect.
`networkStatusProvider` exposes `NetworkStatus` (wifi / mobile / ethernet / vpn / none).

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
| Backend | Python | ^3.11 |
| Backend | FastAPI | ^0.115.0 |
| Backend | Database | SQLAlchemy async + aiosqlite |
| Backend | Auth | PyJWT + bcrypt |
| Backend | Logging | Python logging module |

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