# QWEN.md - ListenVision 项目上下文

## 项目概述

**ListenVision** 是一个基于 Bilibili API 的跨平台音频获取与播放应用，采用 **Flutter 前端 + Node.js 后端** 架构。

### 核心特色
- 🎯 **灵活账号体系** - 邮箱注册登录，可选绑定 B 站账号
- 🔓 **游客模式** - 未登录用户也能搜索、播放 B 站音频、导入本地音频
- 🔐 **安全认证** - JWT Token + 服务端 AES-256-CBC 加密存储 Cookie
- 🌍 **跨平台** - Android、Web、Windows、Linux、macOS
- 🎵 **本地/在线播放** - 支持 M4A/MP3/FLAC 元数据
- 📋 **歌单管理** - 创建、编辑、收藏歌单，"我喜欢"系统歌单
- 📥 **智能下载** - 多线程下载、断点续传、后台下载
- 🛡️ **本地优先架构** - 数据本地优先存储，网络异步同步
- 🎨 **Material Design** - 支持深色模式

---

## 技术栈

### 前端 (Flutter)
| 组件 | 技术 |
|------|------|
| **框架** | Flutter 3.38.5 (Dart 3.10.4) |
| **架构** | Clean Architecture + MVVM + Riverpod 3 |
| **状态管理** | flutter_riverpod ^3.1.0 + riverpod_annotation |
| **路由** | go_router ^17.1.0 |
| **数据库** | sqflite ^2.4.2 (移动端) / sqflite_common_ffi ^2.3.5 (桌面端) |
| **网络** | dio ^5.8.0+1 |
| **音频播放** | audioplayers ^6.4.0 + audio_session ^0.2.1 |
| **元数据** | audio_metadata_reader ^1.4.2 + metadata_god ^1.1.0 |
| **错误处理** | dartz ^0.10.1 (Either 泛型) |
| **代码生成** | freezed ^3.2.3 + json_serializable + build_runner |

### 后端 (Node.js)
| 组件 | 技术 |
|------|------|
| **框架** | Express ^5.1.0 |
| **数据库** | better-sqlite3 ^12.6.2 (SQLite) |
| **认证** | bcrypt ^5.1.1 + jsonwebtoken ^9.0.3 |
| **加密** | AES-256-CBC (Cookie 加密) |
| **邮件** | nodemailer ^7.0.3 |
| **日志** | winston ^3.19.0 |
| **限流** | express-rate-limit ^8.2.1 |
| **文档** | swagger-jsdoc + swagger-ui-express |

---

## 项目结构

```
listen-vision-audio-app/
├── frontend_flutter/              # Flutter 前端应用
│   ├── lib/
│   │   ├── main.dart             # 应用入口
│   │   ├── core/                 # 核心层 (网络/存储/工具)
│   │   │   ├── config/           # 环境配置
│   │   │   ├── constants/        # 常量
│   │   │   ├── errors/           # 错误定义
│   │   │   ├── network/          # DioClient, ApiClient, Endpoints
│   │   │   ├── storage/          # 本地存储
│   │   │   └── utils/            # AppLogger, 权限工具
│   │   ├── data/                 # 数据层
│   │   │   ├── api/              # API 客户端 (兼容层)
│   │   │   ├── database/         # SQLite DAO
│   │   │   ├── repositories/     # Repository 实现
│   │   │   └── sync/             # SyncWorker, 下载完整性
│   │   ├── models/               # DTO / Entity / Freezed 模型
│   │   ├── presentation/         # 表现层
│   │   │   ├── routes/           # go_router 路由
│   │   │   ├── theme/            # 主题
│   │   │   ├── utils/            # UI 辅助
│   │   │   ├── viewmodels/       # Riverpod ViewModel
│   │   │   │   ├── auth/         # 认证相关
│   │   │   │   ├── discovery/    # 发现相关
│   │   │   │   ├── library/      # 资源库相关
│   │   │   │   ├── player/       # 播放器相关
│   │   │   │   ├── settings/     # 设置相关
│   │   │   │   └── system/       # 系统相关
│   │   │   ├── views/            # 页面
│   │   │   └── widgets/          # 组件
│   │   ├── services/             # 有状态服务 (音频播放/元数据)
│   │   └── app.dart              # 应用根组件
│   ├── test/                     # 单元测试
│   ├── integration_test/         # 集成测试
│   └── pubspec.yaml              # 依赖配置
│
├── listen-vision_api/            # Node.js 后端服务
│   ├── index.js                  # 应用入口
│   ├── config/                   # 配置 (数据库/JWT/Swagger)
│   ├── controllers/              # 控制器 (请求/响应适配)
│   ├── middleware/               # 认证/日志/限流/错误处理
│   ├── routes/                   # API 路由 (/api/v1/*)
│   ├── services/                 # 业务逻辑
│   ├── tests/                    # Jest 测试
│   ├── utils/                    # 日志/响应工具
│   └── package.json              # 依赖配置
│
├── docs/                         # 项目文档
│   ├── PRD.md                    # 产品需求文档
│   ├── guides/                   # 开发指南
│   ├── plans/                    # 开发计划
│   └── reports/                  # 报告
│
├── references/                   # 参考文档
│   └── bilibili-API-collect/     # B 站 API 文档 (本地克隆)
│
├── README.md                     # 项目说明
├── CLAUDE.md                     # Claude Code 指南
├── AGENTS.md                     # Agent 开发指南
└── QWEN.md                       # 本文件
```

---

## 构建与运行

### 环境要求
- **Node.js**: >=24.13.0 <25.0.0 (固定版本，better-sqlite3 需要)
- **Flutter**: >=3.38.5 (Dart >=3.10.4)

### 后端设置

```bash
cd listen-vision_api

# 安装依赖
pnpm install

# 配置环境变量
cp .env.example .env
# 编辑 .env，设置 JWT_SECRET 等

# 启动服务器 (数据库文件将创建于 data/listenvision.db)
node index.js

# 运行测试
pnpm test                    # 所有测试
pnpm test:watch              # 监视模式
pnpm test:coverage           # 覆盖率报告

# 停止服务器 (PowerShell)
Get-Process node | Stop-Process -Force
```

后端服务运行在 `http://localhost:3000`
- API 文档：`http://localhost:3000/api-docs`
- 健康检查：`GET /health`

### 前端设置

```bash
cd frontend_flutter

# 获取依赖
flutter pub get

# 运行应用 (需要连接设备/模拟器)
flutter run

# 代码生成 (Riverpod/Freezed/JSON)
flutter pub run build_runner build --delete-conflicting-outputs

# 构建特定平台
flutter build apk          # Android APK
flutter build ios          # iOS
flutter build web          # Web
flutter build windows      # Windows
flutter build linux        # Linux
flutter build macos        # macOS

# 运行测试
flutter test                           # 所有测试
flutter test test/providers/...        # 单文件
flutter test --coverage                # 覆盖率

# 代码分析
flutter analyze
dart fix --apply
```

---

## API 端点

所有 API 以 `/api/v1` 为前缀：

```
# 认证
POST   /api/v1/auth/register
POST   /api/v1/auth/login
GET    /api/v1/auth/me

# 用户
GET    /api/v1/users/me

# 歌单
GET    /api/v1/playlists
POST   /api/v1/playlists
GET    /api/v1/playlists/:id
PUT    /api/v1/playlists/:id
DELETE /api/v1/playlists/:id

# B 站
GET    /api/v1/bilibili/video/:bvid
GET    /api/v1/bilibili/audio/:bvid
GET    /api/v1/bilibili/proxy/audio/:bvid
GET    /api/v1/bilibili/search
POST   /api/v1/bilibili/qrcode
POST   /api/v1/bilibili/qrcode/check

# 搜索
GET    /api/v1/search
GET    /api/v1/search/history

# 播放历史
GET    /api/v1/history
POST   /api/v1/history
DELETE /api/v1/history

# 推荐
GET    /api/v1/recommendations

# 网易云
GET    /api/v1/netease/playlist/:id
GET    /api/v1/netease/search
```

---

## 开发规范

### 代码风格

#### 前端 (Dart)

**导入顺序**:
```dart
// 1. Dart SDK
import 'dart:async';
import 'dart:io';

// 2. Flutter SDK
import 'package:flutter/material.dart';

// 3. 外部包 (字母顺序)
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 4. 内部包
import 'package:listenvision/core/network/dio_client.dart';

// 5. 相对导入
import '../../models/dto/api_dto.dart';
import '../utils/app_logger.dart';

// 6. 生成文件 (part)
part 'xxx.g.dart';
part 'xxx.freezed.dart';
```

**命名规范**:
- 文件：`snake_case.dart`
- 类：`PascalCase`
- 变量/函数：`camelCase`
- 私有成员：`_` 前缀

**Riverpod 模式**:
```dart
@riverpod
class Auth extends _$Auth {
  @override
  AuthState build() => const AuthState.initial();
  
  Future<void> login(String email, String password) async {
    // 实现
  }
}
```

**状态类 (freezed)**:
```dart
@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial() = _Initial;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.authenticated({required User user}) = _Authenticated;
  const factory AuthState.error({required String message}) = _Error;
}
```

**错误处理**:
```dart
return asyncValue.when(
  loading: () => const CircularProgressIndicator(),
  error: (err, stack) => Text('Error: $err'),
  data: (data) => DataView(data: data),
);
```

#### 后端 (Node.js)

**命名规范**:
- 文件：`camelCase.js`
- 类：`PascalCase`
- 常量：`SCREAMING_SNAKE_CASE`

**JSDoc**:
```javascript
/**
 * Fetch video info from Bilibili API
 * @param {string} bvid - Video BV ID
 * @returns {Promise<Object>} Video information
 */
async function getVideoInfo(bvid) { }
```

### 日志规范

**前端**: 使用 `AppLogger` (DEBUG/INFO/WARN/ERROR)
```dart
AppLogger.info('Auth', '登录成功: ${user.email}');
AppLogger.error('Auth', '登录失败', error: e, stackTrace: stack);
```

**后端**: 使用 Winston logger
```javascript
logger.info('用户登录成功', { userId: user.id });
logger.error('登录失败', { error: e.message });
```

**禁止**: `console.log()`, `print()` 直接输出

### 本地优先同步机制

所有写操作遵循以下流程：
1. **立即更新本地数据库** - UI 即时响应
2. **加入同步队列** - SyncWorker 后台处理
3. **网络同步重试** - 最多 3 次，间隔 30 秒
4. **持久化** - App 重启后恢复未完成任务

```
用户操作
   │
   ├─→ 本地数据库 ──→ UI 刷新
   │
   └─→ 同步队列 ──→ SyncWorker ──→ 网络
                              │
                              ├─ 成功 → 清除任务
                              ├─ 失败 → 重试 (最多 3 次)
                              └─ 超过次数 → 标记失败
```

---

## 测试

### 后端测试 (264 tests passing)

```bash
cd listen-vision_api

# 运行所有测试
pnpm test

# 单个文件
pnpm jest tests/services/bilibiliService.test.js

# 模式匹配
pnpm jest -t "should authenticate user"

# 覆盖率
pnpm test:coverage
```

### 前端测试 (178 tests)

```bash
cd frontend_flutter

# 运行所有测试
flutter test

# 单个文件
flutter test test/providers/auth/auth_provider_test.dart

# 覆盖率
flutter test --coverage
```

---

## 日志位置

| 类型 | 位置 |
|------|------|
| 前端 | `C:\Users\<user>\Documents\logs\` |
| 后端 | `listen-vision_api/logs/` |

**查看日志 (PowerShell)**:
```powershell
# 前端日志 (最新 200 行)
Get-Content "C:\Users\$env:USERNAME\Documents\logs\app-$(Get-Date -Format 'yyyy-MM-dd').log" -Tail 200

# 后端日志
Get-Content "listen-vision_api\logs\combined.log" -Tail 100
```

---

## 第三方 API 文档

### Bilibili API

**优先使用本地文档**: `references/bilibili-API-collect/docs/`

核心文档：
- 登录：`docs/login/login_action/QR.md`
- 视频：`docs/video/video_info.md`
- 音频：`docs/audio/audio_stream.md`

### QQ 音乐 API

**官方文档**: https://developer.y.qq.com/docs/openid#/overview

---

## 架构设计

### Clean Architecture 分层

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│  Pages / Providers(Riverpod) / Widgets  │
└────────────────────┬────────────────────┘
                     │ 调用
                     ▼
┌─────────────────────────────────────────┐
│           Domain Layer                  │
│  Entities / Repositories(接口)          │
└────────────────────┬────────────────────┘
                     │ 实现
                     ▼
┌─────────────────────────────────────────┐
│            Data Layer                   │
│  DataSources / Managers / Repositories  │
└────────────────────┬────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────┐
│            Core Layer                   │
│  DI / Network / Utils                   │
└─────────────────────────────────────────┘
```

### 关键设计决策

1. **本地优先** - 所有数据优先存储本地，网络异步同步
2. **Riverpod 3** - 使用 `@riverpod` 注解 + 代码生成
3. **providers.dart 仅导出** - Provider 实现在各自文件定义
4. **统一 API 客户端** - 通过 `ApiClient` 封装所有后端调用
5. **DTO 层** - API 请求/响应使用 DTO 转换

---

## 平台差异

### Web vs 原生启动

| 特性 | 原生启动 | Web 启动 |
|------|----------|----------|
| **本地数据库** | ✅ SQLite | ❌ 不可用 |
| **用户数据** | ✅ 持久化 | ❌ 仅内存 |
| **下载记录** | ✅ 持久化 | ❌ 不可用 |
| **播放历史** | ✅ 持久化 | ❌ 仅内存 |
| **歌单收藏** | ✅ 持久化 | ❌ 仅内存 |
| **本地音频** | ✅ 文件访问 | ⚠️ Blob URL |
| **后台播放** | ✅ 支持 | ❌ 限制 |

**建议**: 完整功能体验使用原生启动 (Android/iOS/桌面端)。

---

## 相关文档

- 📄 [README.md](README.md) - 项目总览
- 📄 [PRD.md](docs/PRD.md) - 产品需求文档
- 📄 [CLAUDE.md](CLAUDE.md) - Claude Code 指南
- 📄 [AGENTS.md](AGENTS.md) - Agent 开发指南
- 📄 [后端 README](listen-vision_api/README.md) - 后端架构说明
- 📄 [前端 README](frontend_flutter/README.md) - 前端开发指南

---

## 快速参考

### 常用命令速查

```bash
# 后端
cd listen-vision_api
pnpm install && node index.js
pnpm test

# 前端
cd frontend_flutter
flutter pub get && flutter run
flutter pub run build_runner build --delete-conflicting-outputs
flutter test
flutter analyze

# 停止后端 (PowerShell)
Get-Process node | Stop-Process -Force
```

### 关键文件位置

```
# 前端核心
frontend_flutter/lib/main.dart              # 入口
frontend_flutter/lib/app.dart               # 根组件
frontend_flutter/lib/core/network/          # 网络层
frontend_flutter/lib/data/database/         # 数据库
frontend_flutter/lib/presentation/viewmodels/ # ViewModel

# 后端核心
listen-vision_api/index.js                  # 入口
listen-vision_api/routes/v1.js              # API 路由
listen-vision_api/services/                 # 业务逻辑
listen-vision_api/middleware/               # 中间件
```
