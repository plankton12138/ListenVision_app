# Test Coverage Enhancement Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 提升项目测试覆盖率从当前的后端30%/前端25% 到目标70%

**Architecture:** 采用 TDD 驱动开发，优先覆盖核心业务逻辑，使用 Mock 隔离外部依赖

**Tech Stack:**
- **后端**: Jest 30.2.0 + better-sqlite3 (内存数据库)
- **前端**: Flutter Test + Mockito (待添加)

---

## Phase 1: 后端核心功能测试 (Priority: HIGH)

### Task 1.1: 认证服务测试 (authService)

**Files:**
- Create: `listen-vision_api/tests/services/authService.test.js`
- Reference: `listen-vision_api/services/authService.js`
- Reference: `tests/services/userService.test.js` (测试模式参考)

**Step 1: 创建测试文件框架**

```javascript
// tests/services/authService.test.js
const authService = require('../../services/authService');

// Mock 数据库
jest.mock('../../config/database', () => {
  const Database = require('better-sqlite3');
  const db = new Database(':memory:');

  db.exec(`
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL UNIQUE,
      email TEXT NOT NULL UNIQUE,
      password TEXT NOT NULL
    )
  `);

  return db;
});

const db = require('../../config/database');

describe('认证服务测试', () => {
  beforeEach(() => {
    db.exec('DELETE FROM users');
  });
});
```

**Step 2: 运行测试验证框架**

Run: `cd listen-vision_api && pnpm test tests/services/authService.test.js`
Expected: PASS (0 tests)

**Step 3: 添加用户登录测试**

```javascript
describe('authenticateUser()', () => {
  beforeEach(() => {
    const bcrypt = require('bcryptjs');
    const hashedPassword = bcrypt.hashSync('password123', 10);
    db.prepare('INSERT INTO users (username, email, password) VALUES (?, ?, ?)')
      .run('testuser', 'test@example.com', hashedPassword);
  });

  test('正确密码应返回用户信息', async () => {
    const result = await authService.authenticateUser('testuser', 'password123');
    expect(result).toHaveProperty('id');
    expect(result.username).toBe('testuser');
  });

  test('错误密码应返回 null', async () => {
    const result = await authService.authenticateUser('testuser', 'wrongpassword');
    expect(result).toBeNull();
  });

  test('不存在的用户应返回 null', async () => {
    const result = await authService.authenticateUser('nonexistent', 'password123');
    expect(result).toBeNull();
  });
});
```

**Step 4: 运行测试验证**

Run: `cd listen-vision_api && pnpm test tests/services/authService.test.js`
Expected: PASS (3 tests)

**Step 5: 提交**

```bash
git add listen-vision_api/tests/services/authService.test.js
git commit -m "test(auth): add authService unit tests"
```

---

### Task 1.2: 认证控制器测试 (authController)

**Files:**
- Create: `listen-vision_api/tests/controllers/authController.test.js`
- Modify: `listen-vision_api/controllers/authController.js` (如需要添加辅助方法)
- Reference: `tests/middleware/auth.test.js` (Mock 模式参考)

**Step 1: 创建测试文件框架**

```javascript
// tests/controllers/authController.test.js
const authService = require('../../services/authService');
const emailService = require('../../services/emailService');

// Mock 服务
jest.mock('../../services/authService');
jest.mock('../../services/emailService');

const authController = require('../../controllers/authController');

describe('认证控制器测试', () => {
  let mockReq, mockRes, mockNext;

  beforeEach(() => {
    mockReq = {
      body: {},
      user: null
    };
    mockRes = {
      status: jest.fn().mockReturnValue(mockRes),
      json: jest.fn().mockReturnValue(mockRes)
    };
    mockNext = jest.fn();

    jest.clearAllMocks();
  });
});
```

**Step 2: 运行测试验证框架**

Run: `cd listen-vision_api && pnpm test tests/controllers/authController.test.js`
Expected: PASS (0 tests)

**Step 3: 添加注册测试**

```javascript
describe('register()', () => {
  test('成功注册应返回 201 和 token', async () => {
    mockReq.body = {
      username: 'newuser',
      email: 'new@example.com',
      password: 'password123'
    };

    authService.registerUser.mockResolvedValue({
      user: { id: 1, username: 'newuser', email: 'new@example.com' },
      token: 'mock-jwt-token'
    });

    await authController.register(mockReq, mockRes, mockNext);

    expect(mockRes.status).toHaveBeenCalledWith(201);
    expect(mockRes.json).toHaveBeenCalledWith({
      success: true,
      data: {
        user: { id: 1, username: 'newuser', email: 'new@example.com' },
        token: 'mock-jwt-token'
      }
    });
  });

  test('用户名已存在应返回 400', async () => {
    mockReq.body = {
      username: 'existing',
      email: 'new@example.com',
      password: 'password123'
    };

    authService.registerUser.mockRejectedValue(new Error('用户名已存在'));

    await authController.register(mockReq, mockRes, mockNext);

    expect(mockRes.status).toHaveBeenCalledWith(400);
    expect(mockRes.json).toHaveBeenCalledWith({
      success: false,
      error: '用户名已存在'
    });
  });
});
```

**Step 4: 运行测试验证**

Run: `cd listen-vision_api && pnpm test tests/controllers/authController.test.js`
Expected: PASS (2 tests)

**Step 5: 提交**

```bash
git add listen-vision_api/tests/controllers/authController.test.js
git commit -m "test(auth): add authController unit tests"
```

---

### Task 1.3: B站服务测试 (bilibiliService)

**Files:**
- Create: `listen-vision_api/tests/services/bilibiliService.test.js`
- Reference: `listen-vision_api/services/bilibiliService.js`

**Step 1: 创建测试文件（使用 Mock 避免真实 API 调用）**

```javascript
// tests/services/bilibiliService.test.js
const axios = require('axios');
const bilibiliService = require('../../services/bilibiliService');

// Mock axios
jest.mock('axios');

describe('B站服务测试', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('getVideoInfo()', () => {
    test('应返回视频信息', async () => {
      const mockResponse = {
        data: {
          code: 0,
          data: {
            bvid: 'BV1xx411c7mD',
            title: '测试视频',
            owner: { name: '测试UP主', mid: 12345 },
            pic: 'http://example.com/cover.jpg',
            cid: 123456
          }
        }
      };

      axios.get.mockResolvedValue(mockResponse);

      const result = await bilibiliService.getVideoInfo('BV1xx411c7mD');

      expect(result).toHaveProperty('title', '测试视频');
      expect(result).toHaveProperty('bvid', 'BV1xx411c7mD');
      expect(axios.get).toHaveBeenCalledWith(
        expect.stringContaining('BV1xx411c7mD')
      );
    });

    test('API 错误应抛出异常', async () => {
      axios.get.mockRejectedValue(new Error('Network error'));

      await expect(
        bilibiliService.getVideoInfo('BV1xx411c7mD')
      ).rejects.toThrow();
    });
  });

  describe('getAudioStream()', () => {
    test('应返回音频流URL', async () => {
      const mockResponse = {
        data: {
          code: 0,
          data: {
            dash: {
              audio: [
                {
                  id: 30216,
                  baseUrl: 'http://example.com/audio.m4s',
                  bandwidth: 132000,
                  codecs: 'mp4a.40.2'
                }
              ]
            }
          }
        }
      };

      axios.get.mockResolvedValue(mockResponse);

      const result = await bilibiliService.getAudioStream('BV1xx411c7mD', 123456);

      expect(result).toHaveProperty('url');
      expect(result.codecs).toBe('mp4a.40.2');
    });
  });
});
```

**Step 2: 运行测试验证**

Run: `cd listen-vision_api && pnpm test tests/services/bilibiliService.test.js`
Expected: PASS (3 tests)

**Step 3: 提交**

```bash
git add listen-vision_api/tests/services/bilibiliService.test.js
git commit -m "test(bilibili): add bilibiliService unit tests with mocked API"
```

---

### Task 1.4: 认证路由测试 (auth routes)

**Files:**
- Create: `listen-vision_api/tests/routes/auth.test.js`
- Reference: `listen-vision_api/routes/auth.js`

**Step 1: 创建集成测试框架**

```javascript
// tests/routes/auth.test.js
const request = require('supertest');
const express = require('express');
const authRoutes = require('../../routes/auth');

// Mock 中间件和服务
jest.mock('../../middleware/auth');
jest.mock('../../services/authService');

const app = express();
app.use(express.json());
app.use('/api/auth', authRoutes);

describe('认证路由集成测试', () => {
  describe('POST /api/auth/register', () => {
    test('成功注册应返回 201', async () => {
      const response = await request(app)
        .post('/api/auth/register')
        .send({
          username: 'testuser',
          email: 'test@example.com',
          password: 'password123'
        });

      expect(response.status).toBe(201);
      expect(response.body).toHaveProperty('success', true);
    });
  });

  describe('POST /api/auth/login', () => {
    test('成功登录应返回 200 和 token', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          username: 'testuser',
          password: 'password123'
        });

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('token');
    });
  });
});
```

**Step 2: 运行测试验证**

Run: `cd listen-vision_api && pnpm test tests/routes/auth.test.js`
Expected: PASS (2 tests)

**Step 3: 提交**

```bash
git add listen-vision_api/tests/routes/auth.test.js
git commit -m "test(auth): add auth routes integration tests"
```

---

## Phase 2: 前端核心功能测试 (Priority: HIGH)

### Task 2.1: 添加 Mockito 依赖

**Files:**
- Modify: `frontend_flutter/pubspec.yaml`

**Step 1: 添加 mockito 依赖**

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.0
  mockito: ^5.4.0
  mocktail: ^1.0.0
```

**Step 2: 安装依赖**

Run: `cd frontend_flutter && flutter pub get`
Expected: 依赖安装成功

**Step 3: 提交**

```bash
git add frontend_flutter/pubspec.yaml frontend_flutter/pubspec.lock
git commit -m "test: add mockito and mocktail dependencies"
```

---

### Task 2.2: 用户 Provider 测试 (userProvider/authProvider)

**Files:**
- Create: `frontend_flutter/test/providers/auth/auth_provider_test.dart`
- Reference: `frontend_flutter/lib/presentation/providers/auth/auth_provider.dart`

**Step 1: 创建测试文件**

```dart
// test/providers/auth/auth_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:demo/presentation/providers/auth/auth_provider.dart';
import 'package:demo/domain/repositories/auth_repository.dart';
import 'package:mocktail/mocktail.dart';

// Mock classes
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('AuthProvider', () {
    late AuthProvider authProvider;
    late MockAuthRepository mockRepository;

    setUp(() {
      mockRepository = MockAuthRepository();
      authProvider = AuthProvider(repository: mockRepository);
    });

    tearDown(() {
      authProvider.dispose();
    });

    group('初始化状态', () {
      test('初始状态应该是未登录', () {
        expect(authProvider.isLoggedIn, false);
        expect(authProvider.user, isNull);
        expect(authProvider.isLoading, false);
      });

      test('初始 errorMessage 应该为空', () {
        expect(authProvider.errorMessage, isEmpty);
      });
    });

    group('登录', () {
      test('成功登录应更新状态', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password123';
        when(() => mockRepository.login(email: email, password: password))
          .thenAnswer((_) async => (
            token: 'test-token',
            user: (id: 1, username: 'testuser', email: email)
          ));

        // Act
        await authProvider.login(email, password);

        // Assert
        expect(authProvider.isLoggedIn, true);
        expect(authProvider.user?.username, 'testuser');
        expect(authProvider.errorMessage, isEmpty);
      });

      test('登录失败应设置错误信息', () async {
        // Arrange
        when(() => mockRepository.login(email: any(named: 'email'), password: any(named: 'password')))
          .thenThrow(Exception('登录失败'));

        // Act
        await authProvider.login('test@example.com', 'wrong');

        // Assert
        expect(authProvider.isLoggedIn, false);
        expect(authProvider.errorMessage, isNotEmpty);
      });
    });

    group('登出', () {
      test('登出应清除用户状态', () async {
        // 先设置登录状态
        when(() => mockRepository.logout())
          .thenAnswer((_) async => unit);

        // Act
        await authProvider.logout();

        // Assert
        expect(authProvider.isLoggedIn, false);
        expect(authProvider.user, isNull);
      });
    });
  });
}
```

**Step 2: 运行测试验证**

Run: `cd frontend_flutter && flutter test test/providers/auth/auth_provider_test.dart`
Expected: PASS (5 tests)

**Step 3: 提交**

```bash
git add frontend_flutter/test/providers/auth/auth_provider_test.dart
git commit -m "test(auth): add AuthProvider unit tests"
```

---

### Task 2.3: 搜索 Provider 测试 (searchProvider)

**Files:**
- Create: `frontend_flutter/test/providers/search/search_provider_test.dart`
- Reference: `frontend_flutter/lib/presentation/providers/search/search_provider.dart`

**Step 1: 创建测试文件**

```dart
// test/providers/search/search_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:demo/presentation/providers/search/search_provider.dart';
import 'package:demo/domain/entities/audio.dart';
import 'package:mocktail/mocktail.dart';

class MockBilibiliRepository extends Mock implements BilibiliRepository {}

void main() {
  group('SearchProvider', () {
    late SearchProvider searchProvider;
    late MockBilibiliRepository mockRepository;

    setUp(() {
      mockRepository = MockBilibiliRepository();
      searchProvider = SearchProvider(repository: mockRepository);
    });

    tearDown(() {
      searchProvider.dispose();
    });

    group('搜索状态', () {
      test('初始状态应为空', () {
        expect(searchProvider.results, isEmpty);
        expect(searchProvider.isLoading, false);
        expect(searchProvider.query, isEmpty);
      });
    });

    group('搜索视频', () {
      test('成功搜索应返回结果', () async {
        // Arrange
        const query = '测试搜索';
        final mockResults = [
          const Audio(
            id: 'BV1xx411c7mD',
            title: '测试视频1',
            artist: 'UP主1',
            duration: 180,
          ),
          const Audio(
            id: 'BV1yy411c7mE',
            title: '测试视频2',
            artist: 'UP主2',
            duration: 240,
          ),
        ];

        when(() => mockRepository.searchVideos(query))
          .thenAnswer((_) async => mockResults);

        // Act
        await searchProvider.search(query);

        // Assert
        expect(searchProvider.results.length, 2);
        expect(searchProvider.results.first.title, '测试视频1');
        expect(searchProvider.query, query);
        expect(searchProvider.isLoading, false);
      });

      test('搜索失败应设置错误信息', () async {
        // Arrange
        when(() => mockRepository.searchVideos(any()))
          .thenThrow(Exception('搜索失败'));

        // Act
        await searchProvider.search('测试');

        // Assert
        expect(searchProvider.results, isEmpty);
        expect(searchProvider.errorMessage, '搜索失败');
      });
    });

    group('清除搜索', () {
      test('clearSearch 应重置状态', () async {
        // 先设置一些结果
        when(() => mockRepository.searchVideos(any()))
          .thenAnswer((_) async => []);
        await searchProvider.search('测试');

        // Act
        searchProvider.clearSearch();

        // Assert
        expect(searchProvider.results, isEmpty);
        expect(searchProvider.query, isEmpty);
      });
    });
  });
}
```

**Step 2: 运行测试验证**

Run: `cd frontend_flutter && flutter test test/providers/search/search_provider_test.dart`
Expected: PASS (5 tests)

**Step 3: 提交**

```bash
git add frontend_flutter/test/providers/search/search_provider_test.dart
git commit -m "test(search): add SearchProvider unit tests"
```

---

### Task 2.4: 播放器 Cubit 测试 (playerCubit)

**Files:**
- Create: `frontend_flutter/test/providers/player/player_cubit_test.dart`
- Reference: `frontend_flutter/lib/presentation/providers/player/player_cubit.dart`

**Step 1: 创建测试文件**

```dart
// test/providers/player/player_cubit_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:demo/presentation/providers/player/player_cubit.dart';
import 'package:demo/presentation/providers/player/player_state.dart';
import 'package:demo/domain/entities/audio.dart';
import 'package:mocktail/mocktail.dart';

class MockAudioRepository extends Mock implements AudioRepository {}

void main() {
  group('PlayerCubit', () {
    late PlayerCubit playerCubit;
    late MockAudioRepository mockRepository;

    setUp(() {
      mockRepository = MockAudioRepository();
      playerCubit = PlayerCubit(repository: mockRepository);
    });

    tearDown(() {
      playerCubit.close();
    });

    group('初始状态', () {
      test('应为 PlayerInitial', () {
        expect(playerCubit.state, isA<PlayerInitial>());
      });
    });

    group('加载音频', () {
      test('成功加载应进入 PlayerReady 状态', () async {
        // Arrange
        const audio = Audio(
          id: 'test-id',
          title: '测试歌曲',
          artist: '测试歌手',
          duration: 200,
        );

        when(() => mockRepository.loadAudio(any()))
          .thenAnswer((_) async => unit);

        // Act
        await playerCubit.loadAudio(audio);

        // Assert
        expect(playerCubit.state, isA<PlayerReady>());
        expect((playerCubit.state as PlayerReady).audio, audio);
      });
    });

    group('播放控制', () => {
      test('播放/暂停应切换状态', () {
        // Arrange
        const audio = Audio(
          id: 'test-id',
          title: '测试歌曲',
          duration: 200,
        );

        // Act
        playerCubit.play(audio);
        expect(playerCubit.state, isA<PlayerPlaying>());

        playerCubit.pause();
        expect(playerCubit.state, isA<PlayerPaused>());
      });
    });
  });
}
```

**Step 2: 运行测试验证**

Run: `cd frontend_flutter && flutter test test/providers/player/player_cubit_test.dart`
Expected: PASS (4 tests)

**Step 3: 提交**

```bash
git add frontend_flutter/test/providers/player/player_cubit_test.dart
git commit -m "test(player): add PlayerCubit unit tests"
```

---

## Phase 3: 中优先级功能测试 (Priority: MEDIUM)

### Task 3.1: 歌单服务测试 (playlistService)

**Files:**
- Create: `listen-vision_api/tests/services/playlistService.test.js`
- Reference: `listen-vision_api/services/playlistService.js`

**Step 1: 创建歌单服务测试**

```javascript
// tests/services/playlistService.test.js
jest.mock('../../config/database', () => {
  const Database = require('better-sqlite3');
  const db = new Database(':memory:');

  db.exec(`
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL UNIQUE
    );
    CREATE TABLE playlists (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      name TEXT NOT NULL,
      description TEXT,
      created_at TEXT DEFAULT (datetime('now')),
      FOREIGN KEY (user_id) REFERENCES users(id)
    );
    CREATE TABLE playlist_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      playlist_id INTEGER NOT NULL,
      audio_id TEXT NOT NULL,
      position INTEGER NOT NULL,
      FOREIGN KEY (playlist_id) REFERENCES playlists(id)
    );
  `);

  return db;
});

const db = require('../../config/database');
const playlistService = require('../../services/playlistService');

describe('歌单服务测试', () => {
  beforeEach(() => {
    db.exec('DELETE FROM playlist_items');
    db.exec('DELETE FROM playlists');
    db.exec('DELETE FROM users');
  });

  describe('createPlaylist()', () => {
    test('应创建新歌单', async () => {
      const userId = db.prepare('INSERT INTO users (username) VALUES (?)').run('testuser').lastInsertRowid;

      const playlist = await playlistService.createPlaylist(userId, '我的歌单', '测试描述');

      expect(playlist).toHaveProperty('id');
      expect(playlist.name).toBe('我的歌单');
      expect(playlist.description).toBe('测试描述');
    });
  });

  describe('getPlaylistsByUserId()', () => {
    test('应返回用户的所有歌单', async () => {
      const userId = db.prepare('INSERT INTO users (username) VALUES (?)').run('testuser').lastInsertRowid;

      await playlistService.createPlaylist(userId, '歌单1');
      await playlistService.createPlaylist(userId, '歌单2');

      const playlists = playlistService.getPlaylistsByUserId(userId);

      expect(playlists).toHaveLength(2);
      expect(playlists[0].name).toBe('歌单1');
      expect(playlists[1].name).toBe('歌单2');
    });
  });

  describe('addAudioToPlaylist()', () => {
    test('应添加音频到歌单', async () => {
      const userId = db.prepare('INSERT INTO users (username) VALUES (?)').run('testuser').lastInsertRowid;
      const playlist = await playlistService.createPlaylist(userId, '测试歌单');

      await playlistService.addAudioToPlaylist(playlist.id, 'BV123456', 0);

      const items = db.prepare('SELECT * FROM playlist_items WHERE playlist_id = ?').all(playlist.id);
      expect(items).toHaveLength(1);
      expect(items[0].audio_id).toBe('BV123456');
    });
  });
});
```

**Step 2: 运行测试验证**

Run: `cd listen-vision_api && pnpm test tests/services/playlistService.test.js`
Expected: PASS (3+ tests)

**Step 3: 提交**

```bash
git add listen-vision_api/tests/services/playlistService.test.js
git commit -m "test(playlist): add playlistService unit tests"
```

---

### Task 3.2: 播放历史服务测试 (playHistoryService)

**Files:**
- Create: `listen-vision_api/tests/services/playHistoryService.test.js`
- Reference: `listen-vision_api/services/playHistoryService.js`

**Step 1: 创建播放历史服务测试**

```javascript
// tests/services/playHistoryService.test.js
jest.mock('../../config/database', () => {
  const Database = require('better-sqlite3');
  const db = new Database(':memory:');

  db.exec(`
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL UNIQUE
    );
    CREATE TABLE play_history (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      audio_id TEXT NOT NULL,
      title TEXT NOT NULL,
      artist TEXT,
      duration INTEGER,
      played_at TEXT DEFAULT (datetime('now')),
      progress INTEGER DEFAULT 0,
      FOREIGN KEY (user_id) REFERENCES users(id)
    );
  `);

  return db;
});

const db = require('../../config/database');
const playHistoryService = require('../../services/playHistoryService');

describe('播放历史服务测试', () => {
  beforeEach(() => {
    db.exec('DELETE FROM play_history');
    db.exec('DELETE FROM users');
  });

  describe('recordPlay()', () => {
    test('应记录播放历史', async () => {
      const userId = db.prepare('INSERT INTO users (username) VALUES (?)').run('testuser').lastInsertRowid;

      await playHistoryService.recordPlay(userId, 'BV123456', '测试歌曲', '测试歌手', 200, 50);

      const history = db.prepare('SELECT * FROM play_history WHERE user_id = ?').get(userId);
      expect(history).toBeDefined();
      expect(history.audio_id).toBe('BV123456');
      expect(history.title).toBe('测试歌曲');
      expect(history.progress).toBe(50);
    });
  });

  describe('getHistoryByUserId()', () => {
    test('应返回用户播放历史（按时间倒序）', async () => {
      const userId = db.prepare('INSERT INTO users (username) VALUES (?)').run('testuser').lastInsertRowid;

      await playHistoryService.recordPlay(userId, 'BV001', '歌曲1', '歌手1', 200, 100);
      await playHistoryService.recordPlay(userId, 'BV002', '歌曲2', '歌手2', 180, 50);

      const history = playHistoryService.getHistoryByUserId(userId, 10);

      expect(history).toHaveLength(2);
      expect(history[0].audio_id).toBe('BV002'); // 最新的在前
      expect(history[1].audio_id).toBe('BV001');
    });
  });

  describe('clearHistory()', () => {
    test('应清空用户播放历史', async () => {
      const userId = db.prepare('INSERT INTO users (username) VALUES (?)').run('testuser').lastInsertRowid;

      await playHistoryService.recordPlay(userId, 'BV001', '歌曲1', '歌手1', 200);
      await playHistoryService.clearHistory(userId);

      const history = db.prepare('SELECT * FROM play_history WHERE user_id = ?').all(userId);
      expect(history).toHaveLength(0);
    });
  });
});
```

**Step 2: 运行测试验证**

Run: `cd listen-vision_api && pnpm test tests/services/playHistoryService.test.js`
Expected: PASS (3+ tests)

**Step 3: 提交**

```bash
git add listen-vision_api/tests/services/playHistoryService.test.js
git commit -m "test(history): add playHistoryService unit tests"
```

---

### Task 3.3: 收藏管理器测试 (favoriteManager)

**Files:**
- Create: `frontend_flutter/test/providers/favorites/favorite_manager_test.dart`
- Reference: `frontend_flutter/lib/presentation/providers/favorites/favorite_manager.dart`

**Step 1: 创建收藏管理器测试**

```dart
// test/providers/favorites/favorite_manager_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:demo/presentation/providers/favorites/favorite_manager.dart';
import 'package:demo/domain/entities/audio.dart';
import 'package:mocktail/mocktail.dart';

class MockPlaylistRepository extends Mock implements PlaylistRepository {}

void main() {
  group('FavoriteManager', () {
    late FavoriteManager favoriteManager;
    late MockPlaylistRepository mockRepository;

    setUp(() {
      mockRepository = MockPlaylistRepository();
      favoriteManager = FavoriteManager(repository: mockRepository);
    });

    tearDown(() {
      favoriteManager.dispose();
    });

    group('收藏操作', () => {
      test('添加收藏应成功', () async {
        // Arrange
        const audio = Audio(
          id: 'BV123456',
          title: '测试歌曲',
          artist: '测试歌手',
          duration: 200,
        );

        when(() => mockRepository.addToFavorites(any()))
          .thenAnswer((_) async => unit);

        // Act
        await favoriteManager.addFavorite(audio);

        // Assert
        verify(() => mockRepository.addToFavorites(audio)).called(1);
        expect(favoriteManager.favoriteCount, 1);
      });

      test('移除收藏应成功', () async {
        // Arrange
        const audioId = 'BV123456';

        when(() => mockRepository.removeFromFavorites(audioId))
          .thenAnswer((_) async => unit);

        // Act
        await favoriteManager.removeFavorite(audioId);

        // Assert
        verify(() => mockRepository.removeFromFavorites(audioId)).called(1);
      });

      test('检查是否已收藏', () async {
        // Arrange
        const audioId = 'BV123456';
        when(() => mockRepository.isFavorite(audioId))
          .thenAnswer((_) async => true);

        // Act
        final result = await favoriteManager.isFavorite(audioId);

        // Assert
        expect(result, true);
      });
    });

    group('获取收藏列表', () => {
      test('应返回所有收藏', () async {
        // Arrange
        final mockFavorites = [
          const Audio(id: 'BV001', title: '歌曲1', artist: '歌手1', duration: 200),
          const Audio(id: 'BV002', title: '歌曲2', artist: '歌手2', duration: 180),
        ];

        when(() => mockRepository.getFavorites())
          .thenAnswer((_) async => mockFavorites);

        // Act
        await favoriteManager.loadFavorites();

        // Assert
        expect(favoriteManager.favorites.length, 2);
        expect(favoriteManager.favorites.first.title, '歌曲1');
      });
    });
  });
}
```

**Step 2: 运行测试验证**

Run: `cd frontend_flutter && flutter test test/providers/favorites/favorite_manager_test.dart`
Expected: PASS (4+ tests)

**Step 3: 提交**

```bash
git add frontend_flutter/test/providers/favorites/favorite_manager_test.dart
git commit -m "test(favorites): add FavoriteManager unit tests"
```

---

## Phase 4: 覆盖率验证与配置

### Task 4.1: 配置覆盖率阈值

**Files:**
- Modify: `listen-vision_api/package.json`
- Create: `frontend_flutter/test/test_config.dart`

**Step 1: 更新后端 Jest 配置**

```json
// package.json
{
  "jest": {
    "testEnvironment": "node",
    "coverageThresholds": {
      "global": {
        "branches": 70,
        "functions": 70,
        "lines": 70,
        "statements": 70
      }
    },
    "testMatch": ["**/tests/**/*.test.js"],
    "collectCoverageFrom": [
      "controllers/**/*.js",
      "routes/**/*.js",
      "services/**/*.js",
      "!**/node_modules/**",
      "!**/tests/**"
    ],
    "setupFiles": ["<rootDir>/tests/setup.js"]
  }
}
```

**Step 2: 运行覆盖率检查**

Run: `cd listen-vision_api && pnpm test:coverage`
Expected: 生成覆盖率报告，目标达到 70%

**Step 3: 提交**

```bash
git add listen-vision_api/package.json
git commit -m "test(config): add 70% coverage threshold for backend"
```

---

### Task 4.2: 前端覆盖率配置

**Step 1: 创建测试配置文件**

```dart
// frontend_flutter/test/test_config.dart
import 'package:flutter_test/flutter_test.dart';

/// 测试覆盖率配置
class TestConfig {
  /// 目标覆盖率百分比
  static const int coverageTarget = 70;

  /// 需要测试的核心模块
  static const List<String> coreModules = [
    'providers/auth',
    'providers/player',
    'providers/search',
    'providers/favorites',
  ];

  /// 允许跳过测试的模块列表
  static const List<String> skipModules = [
    'presentation/pages', // UI 页面通过手动测试
  ];
}
```

**Step 2: 运行前端覆盖率**

Run: `cd frontend_flutter && flutter test --coverage`
Expected: 生成 `coverage/lcov.info` 文件

**Step 3: 提交**

```bash
git add frontend_flutter/test/test_config.dart
git commit -m "test(config): add test configuration for frontend"
```

---

## Phase 5: 最终验证

### Task 5.1: 运行所有测试

**Step 1: 后端完整测试**

Run: `cd listen-vision_api && pnpm test:coverage`

**Step 2: 前端完整测试**

Run: `cd frontend_flutter && flutter test --coverage`

**Step 3: 验证覆盖率目标**

- 后端覆盖率 >= 70%
- 前端覆盖率 >= 70%

**Step 4: 提交最终配置**

```bash
git add .
git commit -m "test: achieve 70% coverage target for both backend and frontend"
```

---

## 附录 A: 测试运行命令速查

### 后端
```bash
cd listen-vision_api
pnpm test                  # 运行所有测试
pnpm test:watch            # 监视模式
pnpm test:coverage         # 覆盖率报告
pnpm test tests/services/authService.test.js  # 单个文件
```

### 前端
```bash
cd frontend_flutter
flutter test               # 运行所有测试
flutter test --coverage    # 覆盖率报告
flutter test test/providers/auth/auth_provider_test.dart  # 单个文件
```

---

## 附录 B: Mock 模式参考

### 后端 Mock 数据库
```javascript
jest.mock('../../config/database', () => {
  const Database = require('better-sqlite3');
  const db = new Database(':memory:');
  db.exec('CREATE TABLE ...');
  return db;
});
```

### 前端 Mock Repository
```dart
class MockAuthRepository extends Mock implements AuthRepository {}
when(() => mock.login(email: any(), password: any()))
  .thenAnswer((_) async => (token: 'xxx', user: ...));
```

---

**Estimated Total Tests Added:**
- Backend: ~50 tests
- Frontend: ~40 tests
- **Total: ~90 new tests**
