# AGENTS.md

Guidelines for AI coding agents working in this repository.

---


## 日志位置

| 类型 | 位置 |
|------|------|
| 前端 | `C:\Users\<用户>\Documents\logs\` |
| 后端 | `listen-vision_api/logs/` |

```powershell
# 查看前端日志（获取最新200行）
$env:USERNAME = "23104"  # 替换为实际用户名
Get-Content "C:\Users\$env:USERNAME\Documents\logs\app-$(Get-Date -Format 'yyyy-MM-dd').log" -Tail 200

# 或查看今天的日志
Get-ChildItem "C:\Users\$env:USERNAME\Documents\logs\" | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | Get-Content -Tail 100

# 查看后端日志
Get-Content "A:\Projects\listen-vision-audio-app\listen-vision_api\logs\combined.log" -Tail 100
```

---

## B站API文档

**优先使用本地文档** `references/bilibili-API-collect/docs/`，而非网页搜索。

核心文档：
- 登录: `references/bilibili-API-collect/docs/login/login_action/QR.md`
- 视频: `references/bilibili-API-collect/docs/video/video_info.md`
- 音频: `references/bilibili-API-collect/docs/audio/audio_stream.md`

---

## Project Overview

Music streaming app with **Flutter frontend** (`frontend_flutter/`) and **Node.js backend** (`listen-vision_api/`). Platform: Windows 11, PowerShell preferred.

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

---

## Key Conventions

### Local-First Sync
1. **Writes to local DB first** - UI updates immediately
2. **Network queued** - SyncWorker retries (max 3 attempts)
3. **Sensitive data** - Never log passwords/tokens

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

---

## References

- `docs/guides/RIVERPOD_GUIDE.md` - Riverpod usage
- `docs/guides/LOGGING_STANDARDS.md` - Logging standards
- `docs/guides/CODE_COMMENT_STANDARDS.md` - Comment standards
- `references/bilibili-API-collect/docs/` - Bilibili API docs
