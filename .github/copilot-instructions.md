# ListenVision Copilot Instructions

## Build, test, and lint commands

### Backend (`listen-vision_api`)

```powershell
cd listen-vision_api
pnpm install
node index.js
```

```powershell
# All tests
pnpm test

# Single test file
pnpm jest tests\controllers\authController.test.js

# Run tests by name pattern
pnpm jest -t "should authenticate user"

# Coverage
pnpm test:coverage
```

### Frontend (`frontend_flutter`)

```powershell
cd frontend_flutter
flutter pub get
flutter run
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
flutter test test\services\audio_player_service_test.dart

# Coverage
flutter test --coverage
```

## High-level architecture

This repository has two main apps:

- Flutter client in `frontend_flutter/`
- Node.js API server in `listen-vision_api/`

### Backend request flow (Express v1 API)

1. `index.js` wires middleware (CORS, JSON parser, request logger, rate limiting) and mounts `routes/v1.js` at `/api/v1`.
2. `routes/v1.js` splits domains (`auth`, `playlists`, `history`, `search`, `recommendations`, `bilibili`, `netease`, `audio`).
3. Controllers validate/adapt request/response (`controllers/*.js`), typically using `catchAsync` + `AppError`.
4. Services (`services/*.js`) own business rules and database access (better-sqlite3 prepared statements).
5. Response shape is standardized through `utils/response.js` (`successResponse`, `errorResponse`, `paginatedResponse`).

### Frontend flow (Riverpod + local-first data)

1. `main.dart` initializes logger, storage permission handling, DB factory for desktop, shared storage, and token restore.
2. `app.dart` binds UI root and listens `authTokenProvider` to sync token into `DioClient`.
3. Presentation layer uses Riverpod ViewModels under `lib/presentation/viewmodels/**` and exports through `lib/presentation/providers.dart`.
4. Data access is local-first via SQLite DAOs/repositories in `lib/data/database/` and `lib/data/repositories/`.
5. Network sync is decoupled through `sync_queue` + `SyncWorker` (`lib/data/sync/sync_worker.dart`) with periodic retry processing.
6. Unified API calls should go through `lib/core/network/api_client.dart` + endpoint constants in `lib/core/network/endpoints.dart`.

## Key conventions in this codebase

- **API versioning**: all backend endpoints are under `/api/v1`.
- **Logging**:
  - Frontend: use `AppLogger`.
  - Backend: use Winston logger from `utils/logger.js`.
  - Do not use `print()` or `console.log()`.
- **Frontend provider organization**:
  - Implement providers in dedicated files under `presentation/viewmodels/**`.
  - Keep `presentation/providers.dart` as export-only (no provider implementations).
- **Riverpod pattern**:
  - Prefer `@riverpod`/`@Riverpod` annotation with generated files (`*.g.dart`).
  - Use `ref.watch` for reactive dependencies and `ref.read` in callbacks/one-off actions.
- **Local-first write pattern**:
  - Persist locally first (SQLite), then enqueue sync tasks.
  - `SyncWorker` retries queued operations in background (default interval: 30s, max retries controlled by queue fields).
- **Backend controller pattern**:
  - Throw `AppError` for business/validation errors.
  - Use standardized response helpers instead of raw `res.json(...)` shapes.
- **API client usage**:
  - Prefer `apiClientProvider` / `ApiClient` in `core/network/api_client.dart`.
  - Keep endpoint strings centralized in `core/network/endpoints.dart`.
- **Reference docs priority**:
  - Prefer local docs under `references/bilibili-API-collect/docs/` for Bilibili integration work.
