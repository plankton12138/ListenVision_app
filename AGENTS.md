# AGENTS.md

Guidelines for AI coding agents working in this repository.

---

## Development Environment

- **OS**: Windows 11 24H2
- **Shell**: PowerShell (preferred)
- **Node.js**: 24.13.0 (fixed, required by better-sqlite3)
- **Flutter**: 3.38.5 (Dart 3.10.4)

---

## Project Overview

Music streaming app with **Flutter frontend** (`frontend_flutter/`) and **Node.js backend** (`listen-vision_api/`).

### Project Structure

```
Projects_ListenVison/
├── references/                # Reference docs
│   ├── bilibili-API-collect/ # Bilibili API docs (local clone)
│   └── riverpod/             # Riverpod docs (local clone)
├── frontend_flutter/          # Flutter app
│   └── lib/
│       ├── core/              # Infrastructure (constants, errors, network)
│       ├── models/            # Lightweight entities
│       ├── data/              # Data layer (API clients, Repository)
│       │   ├── database/       # SQLite DAO
│       │   ├── repositories/   # Repository implementations
│       │   └── sync/           # Network sync retry mechanism
│       ├── services/          # Stateful services (audio, metadata)
│       └── presentation/      # UI layer
│           ├── viewmodels/    # StateNotifier state management
│           ├── views/         # Pages
│           ├── widgets/       # Components
│           └── providers.dart # Riverpod providers export
└── listen-vision_api/        # Node.js backend
    ├── middleware/           # Auth, rate limiting, error handling
    ├── routes/               # API routes (v1)
    ├── controllers/          # Controllers
    ├── services/             # Business logic
    └── config/               # Database config
```

---

## Build Commands

### Backend
```powershell
cd listen-vision_api
pnpm install
node index.js                           # Start server
Get-Process node | Stop-Process -Force  # Stop server
```

### Frontend
```powershell
cd frontend_flutter
flutter pub get
flutter run
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## Test Commands

### Backend (Jest)
```powershell
cd listen-vision_api
pnpm test                                    # All tests
pnpm jest tests/services/bilibiliService.test.js  # Single file
pnpm jest -t "should authenticate user"      # Pattern match
pnpm test:coverage                           # With coverage
```

### Frontend
```powershell
cd frontend_flutter
flutter test                                             # All tests
flutter test test/providers/auth/auth_provider_test.dart # Single file
flutter test --coverage
```

---

## Lint Commands

```powershell
cd frontend_flutter
flutter analyze
dart fix --apply
```

---

## Code Style

### Frontend (Dart)

**Imports Order**: Dart SDK → Flutter SDK → External packages (alphabetical) → Internal packages → Relative imports → Generated files (`part`)

**Naming**: Files `snake_case.dart`, Classes `PascalCase`, Variables/Functions `camelCase`, Private members `_` prefix

**Riverpod Pattern**:
```dart
@riverpod
class Auth extends _$Auth {
  @override
  AuthState build() => const AuthState.initial();
  Future<void> login(String email, String password) async { }
}
```

**State Classes (freezed)**:
```dart
@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial() = _Initial;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.authenticated({required User user}) = _Authenticated;
  const factory AuthState.error({required String message}) = _Error;
}
```

**Error Handling**:
```dart
return asyncValue.when(
  loading: () => const CircularProgressIndicator(),
  error: (err, stack) => Text('Error: $err'),
  data: (data) => DataView(data: data),
);
```

### Backend (Node.js)

**Naming**: Files `camelCase.js`, Classes `PascalCase`, Constants `SCREAMING_SNAKE_CASE`

**JSDoc**:
```javascript
/**
 * Fetch video info from Bilibili API
 * @param {string} bvid - Video BV ID
 * @returns {Promise<Object>} Video information
 */
async function getVideoInfo(bvid) { }
```

---

## Architecture

### Frontend: `lib/core/`, `models/`, `data/`, `services/`, `presentation/` (viewmodels/, views/, widgets/)

### Backend: `controllers/`, `middleware/`, `routes/`, `services/`, `tests/`

### Tech Stack

**Frontend**: Flutter 3.38.5, Riverpod 3, go_router, sqflite, dio, audioplayers, freezed

**Backend**: Express 5, better-sqlite3, bcrypt, JWT, AES-256-CBC, nodemailer

**API Version**: v1 (`/api/v1` prefix)

---

## Key Conventions

### Local-First Sync
1. **Writes to local DB first** - UI updates immediately
2. **Network queued** - SyncWorker retries (max 3 attempts, 30s interval)
3. **Sensitive data** - Never log passwords/tokens
4. **Persistence** - Unfinished sync tasks resume on app restart

### Logging
- **Frontend**: `AppLogger` (DEBUG/INFO/WARN/ERROR)
- **Backend**: `winston` logger
- **Never use**: `console.log()`, `print()`

### Comments
- Explain **why**, not **what**
- No `TODO`/`FIXME`/`HACK` in commits
- JSDoc (backend) / DartDoc (frontend) for public APIs

### Provider Rules
1. Define in own files under `viewmodels/`
2. `providers.dart` is exports only
3. `ref.watch()` for reactive dependencies; `ref.read()` in callbacks
4. First param of `@riverpod` must be `Ref`

### Planning Rules
- **File paths must be specific** - Always include full path
- **Prefer extending existing files** - Avoid creating new directories
- **Follow existing architecture** - Use `@riverpod` annotation pattern

---

## Log Locations

| Type | Location |
|------|----------|
| Frontend | `C:\Users\<user>\Documents\logs\` |
| Backend | `listen-vision_api/logs/` |

```powershell
# View frontend logs (last 200 lines)
Get-Content "C:\Users\$env:USERNAME\Documents\logs\app-$(Get-Date -Format 'yyyy-MM-dd').log" -Tail 200

# View today's frontend log
Get-ChildItem "C:\Users\$env:USERNAME\Documents\logs\" | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | Get-Content -Tail 100

# View backend logs
Get-Content "A:\Projects\listen-vision-audio-app\listen-vision_api\logs\combined.log" -Tail 100
```

---

## Third-Party Platform API Docs

### Bilibili API

**Use local docs first**: `references/bilibili-API-collect/docs/`

Key documents:
- Login: `references/bilibili-API-collect/docs/login/login_action/QR.md`
- Video: `references/bilibili-API-collect/docs/video/video_info.md`
- Audio: `references/bilibili-API-collect/docs/audio/audio_stream.md`

### QQ Music API

**Official docs**: https://developer.y.qq.com/docs/openid#/overview

> For future QQ Music platform integration, including OpenID auth, music search, and playback.

---

## Auth Architecture

1. **Main account** (Email/Password + JWT)
2. **Platform binding** (Bilibili QR code, encrypted cookie storage)
3. **Guest mode** (Local playback, no login required)

---

## References

- `docs/guides/RIVERPOD_GUIDE.md` - Riverpod usage
- `docs/guides/LOGGING_STANDARDS.md` - Logging standards
- `docs/guides/CODE_COMMENT_STANDARDS.md` - Comment standards
- `references/bilibili-API-collect/docs/` - Bilibili API docs
- `CLAUDE.md` - Detailed development guide
- `README.md` - Project overview and features
