# AGENTS.md - Agent Development Guide

This file provides essential information for agentic coding assistants working on this repository.

---

## Build / Lint / Test Commands

### Backend (Node.js - Express + better-sqlite3)
**Location:** `listen-vision_api/`

```bash
# Installation
npm install

# Development
node index.js                    # Start server (default port 3000)
Get-Process node | Stop-Process -Force  # Stop server (Windows PowerShell)

# Testing
npm test                        # Run all tests
npm run test:watch             # Watch mode
npm run test:coverage          # Coverage report

# Run single test file
jest tests/services/userService.test.js
jest tests/middleware/auth.test.js

# Run tests matching pattern
jest -t "test name"           # By test name
jest --testNamePattern="login"  # By pattern

# Database location
# Development: listen-vision_api/data/listenvision.db
# Testing: In-memory database (:memory:)
```

**Backend Architecture:**
```
middleware/    → routes/  → controllers/  → services/  → database (better-sqlite3)
(CORS/Rate Limiter/Auth)    (Request/Response)  (Business Logic)  (Prepared Statements)
```

### Frontend (Flutter)
**Location:** `frontend_flutter/`

```bash
# Installation
flutter pub get

# Development
flutter run                     # Run on connected device/emulator
flutter build apk               # Android
flutter build ios               # iOS
flutter build web               # Web
flutter build windows           # Windows
flutter build linux             # Linux
flutter build macos             # macOS

# Testing & Analysis
flutter test                    # Run all tests
flutter test test/widget_test.dart  # Run specific test file
flutter analyze                 # Static analysis
flutter doctor                  # Check environment

# Hot Reload
r                              # Hot reload while running
R                              # Hot restart
```

**Desktop Database:**
- Windows/Linux/macOS uses `sqflite_common_ffi` with `databaseFactoryFfi`
- Mobile uses native `sqflite`
- Initialize in `main.dart` before `runApp()`

---

## Code Style Guidelines

### Backend (Node.js)

**1. Architecture Pattern - MVC with Services**
```javascript
// routes/auth.js (End points)
router.post('/register', register);

// controllers/authController.js (Request/Response)
const register = catchAsync(async (req, res) => {
  const user = await userService.registerUser(...);
  return successResponse(res, user, '注册成功', 201);
});

// services/userService.js (Business Logic)
const registerUser = async (username, password, email) => {
  // Business logic + database operations
  return result;
};
```

**2. SQL Best Practices - Pre-compiled Statements**
```javascript
// ✅ CORRECT: Prepare at module load, reuse
const stmt = {
  userById: db.prepare('SELECT * FROM users WHERE id = ?'),
  insertUser: db.prepare('INSERT INTO users (name) VALUES (?)')
};

const user = stmt.userById.get(userId);
stmt.insertUser.run(username);

// ❌ AVOID: Direct queries every time
db.prepare('SELECT * FROM users WHERE id = ?').get(id);
```

**3. Error Handling - Unified Approach**
```javascript
// Use AppError for operational errors
throw new AppError('用户不存在', 404);

// Wrap async routes with catchAsync
const login = catchAsync(async (req, res) => {
  // This will auto-catch errors and pass to errorHandler
});

// Custom error middleware handles:
// - AppError (operational)
// - JWT errors (JsonWebTokenError, TokenExpiredError)
// - SQLite errors (ER_DUP_ENTRY, ER_NO_REFERENCED_ROW_2)
```

**4. Response Format - Consistent**
```javascript
// Success
successResponse(res, data, 'message', 201);
// => { success: true, message: '...', data: {...} }

// Error
throw new AppError('error message', 400);
// => { success: false, error: 'error message' }

// Paginated
paginatedResponse(res, items, total, page, pageSize);
// => { success: true, data: [...], pagination: {...} }
```

**5. Password Security**
```javascript
// bcrypt with 10 rounds
const hashedPassword = await bcrypt.hash(password, 10);
const isMatch = await bcrypt.compare(password, user.password);
```

**6. Logging**
```javascript
const { logger } = require('../utils/logger');
logger.info('Info message');
logger.error('Error message', err);

// Use Winston (configured in utils/logger.js)
// Logs to: logs/combined.log, logs/error.log
```

**7. JWT Authentication**
```javascript
// Middleware
const { auth } = require('../middleware/auth');
router.get('/protected', auth, handler);

// Access user
const userId = req.user.id;  // Attached by auth middleware
```

**8. Testing Patterns**
```javascript
// Setup: In-memory database
jest.mock('../../config/database', () => {
  const Database = require('better-sqlite3');
  const db = new Database(':memory:');
  db.exec('CREATE TABLE users (...)');
  return db;
});

// Test structure
describe('UserService', () => {
  beforeEach(() => {
    db.exec('DELETE FROM users');
  });

  test('should do something', async () => {
    const result = await userService.doSomething();
    expect(result).toBe('expected');
  });
});
```

### Frontend (Dart/Flutter)

**1. State Management - Provider Pattern**
```dart
// Provider initialization (main.dart)
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AudioProvider()),
    ChangeNotifierProxyProvider<AuthProvider, PlaylistProvider>(
      create: (context) => PlaylistProvider(context.read<ApiService>()),
      update: (context, authProvider, apiService, playlistProvider) {
        // Update when dependencies change
        return playlistProvider!;
      },
    ),
  ],
)

// Provider usage (in widgets)
final audioProvider = Provider.of<AudioProvider>(context);
final audioProvider = context.watch<AudioProvider>();  // Rebuild on changes
audioProvider.loadAudio(path);  // Call methods
```

**2. Models - with fromJson/copyWith**
```dart
class User {
  final int id;
  final String username;

  User({required this.id, required this.username});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: int.parse(json['id'].toString()),
      username: json['username'].toString(),
    );
  }

  User copyWith({int? id, String? username}) {
    return User(id: id ?? this.id, username: username ?? this.username);
  }
}
```

**3. Async Initialization**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services that need async setup
  await MetadataGod.initialize();
  await SharedPreferences.getInstance();

  // Desktop database factory
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    databaseFactory = databaseFactoryFfi;
  }

  runApp(MyApp());
}
```

**4. Database - sqflite**
```dart
// Helper class pattern
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }
}
```

**5. Import Organization**
```dart
// 1. Dart SDK imports
import 'dart:async';
import 'dart:io';

// 2. Flutter/framework imports
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 3. Third-party packages
import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';

// 4. Project imports (Clean Architecture order: Core → Domain → Data → Presentation)
import 'package:demo/core/utils/logger.dart';
import 'package:demo/domain/entities/audio.dart';
import 'package:demo/domain/repositories/download_repository.dart';
import 'package:demo/data/datasources/remote/bilibili_remote_datasource.dart';
import 'package:demo/presentation/providers/download/download_manager.dart';
```

**6. Error Handling**
```dart
try {
  await operation();
} catch (e, stackTrace) {
  debugPrint('Error: $e');
  debugPrint('Stack: $stackTrace');
  rethrow;  // Let caller handle it
}
```

**7. Naming Conventions**
```dart
// Classes: PascalCase
class AudioProvider { }

// Variables/Methods: camelCase
final String userName;
void loadAudio() { }

// Private members: prefix with underscore
final AudioPlayer _player;
Future<void> _loadPlaylist() { }

// Constants: lowerCamelCase or UPPER_SNAKE_CASE
const String baseUrl = 'http://localhost:3000';
const MAX_RETRY_COUNT = 3;
```

**8. Comments & Documentation**
```dart
/// Audio playback state management
class AudioProvider extends ChangeNotifier {
  /// Load audio file and set metadata
  ///
  /// Metadata priority: file metadata > database > filename
  Future<void> loadAudio(String filePath) async {
    // Implementation
  }
}
```

**9. File Naming - Clean Architecture**
```dart
// Core Layer
lib/core/
├── constants/api_constants.dart     # API 常量
├── di/service_factory.dart          # 依赖注入
├── errors/exceptions.dart           # 异常定义
├── network/dio_provider.dart        # 网络配置
└── utils/                           # 工具函数

// Domain Layer
lib/domain/
├── entities/
│   ├── audio.dart                   # 音频实体 (Freezed)
│   ├── local_audio.dart             # 本地音频实体
│   ├── download_task.dart           # 下载任务实体
│   └── models_export.dart           # 统一导出
└── repositories/
    ├── auth_repository.dart         # 认证仓储接口
    ├── download_repository.dart     # 下载仓储接口
    └── ...

// Data Layer
lib/data/
├── datasources/
│   ├── local/download_local_datasource.dart
│   └── remote/bilibili_remote_datasource.dart
├── managers/
│   ├── playlist_manager.dart
│   └── download_executor.dart
└── repositories/
    ├── auth_repository_impl.dart
    └── download_repository_impl.dart

// Presentation Layer
lib/presentation/
├── pages/
│   ├── home_page.dart
│   └── settings_page.dart
├── providers/
│   ├── auth/auth_provider.dart
│   ├── audio/audio_provider.dart
│   ├── bilibili/bilibili_provider.dart
│   └── download/download_manager.dart
└── widgets/
    └── my_drawer.dart
```

---

## Common Patterns

### Database Migrations (SQLite)
```javascript
// config/database.js
db.exec(`
  CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL UNIQUE,
    email TEXT NOT NULL UNIQUE,
    password TEXT NOT NULL,
    created_at TEXT DEFAULT (datetime('now'))
  );

  CREATE INDEX idx_users_username ON users(username);
  CREATE INDEX idx_users_email ON users(email);
`);

// Enable foreign keys
db.pragma('foreign_keys = ON');
db.pragma('journal_mode = WAL');
```

### Authentication Flow
1. Register/Login → `userService` → Generate JWT token
2. Client stores token → Include in `Authorization: Bearer <token>`
3. `auth` middleware validates token → Attach `req.user`
4. Protected routes access `req.user.id`

### Bilibili API Integration
- Service: `bilibiliService.js` (Phase 1 completed)
- Uses WBI signature for requests
- QR code login for authentication
- Cookie encrypted with AES-256-CBC
- Resource proxy endpoints for anti-hotlinking

### Desktop Compatibility
```dart
// Check platform
if (Platform.isWindows) { /* Windows-specific */ }
if (Platform.isAndroid) { /* Android-specific */ }

// Database factory initialization
if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
  databaseFactory = databaseFactoryFfi;
}
```

---

## Testing Requirements

### Before Submitting Changes
- Backend: Run `npm test` and ensure all tests pass
- Frontend: Run `flutter analyze` and `flutter test`
- Check for pre-existing lint errors (don't fix unless asked)

### Running Single Test
```bash
# Backend
jest tests/services/userService.test.js

# Frontend
flutter test test/widget_test.dart
```

---

## Key Libraries & Their Uses

### Backend
- **better-sqlite3**: Synchronous SQLite API, pre-compiled statements
- **express**: Web framework, middleware, routing
- **bcryptjs**: Password hashing (10 rounds)
- **jsonwebtoken**: JWT token generation/validation
- **winston**: Structured logging
- **nodemailer**: Email sending service

### Frontend
- **provider**: State management (ChangeNotifier, ProxyProvider)
- **go_router**: Declarative routing
- **sqflite/sqflite_common_ffi**: SQLite database
- **audioplayers**: Audio playback
- **metadata_god**: Audio metadata (M4A/MP3/FLAC)
- **dio**: HTTP client
- **flutter_secure_storage**: System-level encrypted storage

---

## Development Notes

- **Language**: Code comments in English, user-facing docs in Chinese
- **Windows PowerShell**: Use PowerShell commands (`Get-ChildItem`, not `ls`)
- **Phase-based development**: Currently in Phase 2 (playlists, favorites, recommendations)
- **Bilibili API docs**: Local clone at `bilibili-API-collect/` (use Grep/Read, don't search web)
- **No type suppression**: Never use `as any`, `@ts-ignore`, or `@ts-expect-error` (Dart)

---

## Logging & Debugging

### Frontend (Flutter) App Logs

**Windows**:
- Log Directory: `C:\Users\<username>\Documents/logs`
- Current Log File: `C:\Users\<username>\Documents/logs/app-YYYY-MM-DD.log`
- Example: `C:\Users\23104\Documents/logs/app-2026-01-26.log`

**Android**:
- Log Directory: `/data/user/0/com.example.flutter_application_1/app_flutter/logs`
- Current Log File: `/data/user/0/com.example.flutter_application_1/app_flutter/logs/app-YYYY-MM-DD.log`
- Example: `/data/user/0/com.example.flutter_application_1/app_flutter/logs/app-2026-01-26.log`

### Backend (Node.js) Logs

- Combined Logs: `listen-vision_api/logs/combined.log`
- Error Logs: `listen-vision_api/logs/error.log`
- Framework: Winston logger

### Viewing Logs

**Frontend**:
```bash
# Windows: Open the log file in a text editor
notepad C:\Users\23104\Documents\logs\app-2026-01-26.log

# Android: Use adb to pull logs
adb pull /data/user/0/com.example.flutter_application_1/app_flutter/logs/app-2026-01-26.log
```

**Backend**:
```bash
# View combined logs in real-time
tail -f listen-vision_api/logs/combined.log

# View error logs
tail -f listen-vision_api/logs/error.log
```

### Log Levels

- **INFO**: General information (ℹ️)
- **DEBUG**: Debug information (🔍)
- **WARN**: Warning messages (!)
- **ERROR**: Error messages (❌)
