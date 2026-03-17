# CLAUDE.md

**请使用中文回复用户。**

---

## 开发环境

- **OS**: Windows 11 24H2
- **Shell**: PowerShell（优先用 PowerShell 命令）
- **Node.js**: 24.13.0（固定版本，better-sqlite3 需要）
- **Flutter**: 3.38.5 (Dart 3.10.4)

---

## 项目结构

```
Projects_ListenVison/
├── references/                # 参考文档
│   ├── bilibili-API-collect/ # B站API文档（本地克隆）
│   └── riverpod/             # Riverpod官方文档（本地克隆）
├── frontend_flutter/          # Flutter应用
│   └── lib/
│       ├── core/              # 基础设施（常量、错误、网络）
│       │   └── network/       # 网络层
│       │       ├── api_client.dart      # ✅ 统一 API 客户端
│       │       ├── dio_client.dart      # Dio 单例
│       │       └── endpoints.dart       # ✅ API 端点常量
│       ├── models/            # 轻量实体
│       │   ├── dto/           # ✅ DTO 层（API 响应/请求）
│       │   │   └── api_dto.dart
│       │   └── entities/      # 业务实体
│       ├── data/              # 数据层
│       │   ├── api/           # API 客户端（遗留，逐步迁移）
│       │   ├── database/      # SQLite DAO
│       │   ├── repositories/  # Repository 实现
│       │   └── sync/          # 网络同步重试机制
│       ├── services/          # 有状态服务（音频播放、元数据）
│       └── presentation/      # UI层
│           ├── viewmodels/    # StateNotifier 状态管理
│           ├── views/         # 页面
│           ├── widgets/       # 组件
│           └── providers.dart # Riverpod providers 统一定义
└── listen-vision_api/        # Node.js后端
    ├── middleware/           # 认证、限流、错误处理
    ├── routes/               # API路由
    ├── controllers/          # 控制器（统一响应格式）
    ├── services/             # 业务逻辑（使用 logger）
    ├── utils/                # 工具函数
    │   ├── logger.js         # Winston 日志
    │   └── response.js       # 统一响应工具
    └── config/               # 数据库配置
```

---

## 工作规范

### 工具选择
- 📖 读取文件 → `Read` 工具
- 🔍 搜索内容 → `Grep` 工具
- 📁 查找文件 → `Glob` 工具
- ⚡ 命令前缀 → `powershell -Command "..."`

### 外部工具限制
**使用前必须询问**: WebSearch, WebFetch, MCP工具
**优先使用**: 本地文档、本地代码、references/bilibili-API-collect

### 回答风格
- 优先展示设计思路，而非完整代码
- 指向核心代码位置 (`file_path:line_number`)
- 先讲"为什么"，再讲"如何实现"
- 完成工作后对话形式总结，不要自动创建文档

### 计划制定规范

**所有实施计划必须遵循以下规范**：

| 规范 | 说明 |
|------|------|
| **文件路径必须具体** | 所有修改/新建的文件必须标注完整路径（如 `frontend_flutter/lib/presentation/viewmodels/system/download_viewmodel.dart`） |
| **新建目录需提醒** | 涉及新建目录时必须明确提醒用户确认 |
| **优先扩展现有文件** | 功能扩展优先在现有文件中添加，而非新建 |
| **遵循现有架构** | ViewModel 使用 `@riverpod` 注解，在各自文件中定义 provider |
| **providers.js 不存实现** | `presentation/providers.dart` 仅用于导出，不存放 provider 实现 |

**当前项目架构**：
```
presentation/
├── viewmodels/         # StateNotifier 状态管理
│   ├── auth/           # 认证相关
│   ├── player/         # 播放器相关
│   ├── library/        # 资源库相关
│   ├── discovery/      # 发现相关
│   └── system/         # 系统相关（下载、主题等）
├── views/              # 页面
├── widgets/            # 组件
└── providers.dart      # 统一导出（不存放实现）
```

**原则**：不要新建目录，优先扩展现有文件。

---

## 项目状态

```
MVVM 重构:       ███████████████████████  100% (Phase 9/10) ✅
本地优先架构:    ███████████████████████  100% (Phase 9/9) ✅
发现搜索改进:    ████████████░░░░░░░░░░░░  60% (Phase 3/5) 🟡

--- MVVM 重构进度 (已完成 2026-02-05) ---
Phase 0:  ✅ 骨架搭建
Phase 1:  ✅ Models 层迁移
Phase 2:  ✅ Services 层构建
Phase 3:  ✅ 数据层构建
Phase 4:  ✅ 核心 ViewModels (Auth)
Phase 5:  ✅ 播放器 ViewModels
Phase 6:  ✅ 其他 ViewModels
Phase 7:  ✅ Views 迁移与解耦
Phase 8:  ✅ Widgets 更新
Phase 9:  ✅ 清理与收尾

**MVVM 重构完成日期**: 2026-02-05

--- 本地优先架构进度 (已完成 2026-02-06) ---
Phase 1:  ✅ 数据库层重构 (2026-02-05)
Phase 2:  ✅ Repository 层重构 (2026-02-05)
Phase 3:  ✅ 下载队列机制 (2026-02-05)
Phase 4:  ✅ 下载 UI 重构 (2026-02-05)
Phase 5:  ✅ 网络同步重试 (2026-02-06)
Phase 6:  ✅ 已合并到 Riverpod 3 迁移 (2026-02-06)
Phase 7:  ✅ 断点续传功能 (2026-02-06)
Phase 8:  ✅ UI 集成与同步状态显示 (2026-02-06)
Phase 9:  ✅ 收藏同步与 Worker 自动启动 (2026-02-06) ← **今日完成**

**本地优先架构完成日期**: 2026-02-06

--- 发现搜索改进进度 (2026-02-06) ---
Phase 1:  ✅ 搜索分页功能 (2026-02-05)
Phase 2:  ✅ 搜索结果操作菜单 (2026-02-05)
Phase 3:  ✅ 发现页面重构 (2026-02-06)
Phase 4:  ✅ 歌单详情页面 (2026-02-06)
Phase 5:  ✅ 批量导入改进 (2026-02-06)

**发现搜索改进完成日期**: 2026-02-06

--- 媒体播放改进 (2026-03-12) ---
Phase 1:  ✅ B站视频字幕支持 (2026-03-12)
```

---

## 测试覆盖

### 后端测试 (264 tests passing)
- `tests/controllers/authController.test.js` - 22 tests
- `tests/services/bilibiliService.test.js` - 25 tests
- `tests/services/playlistService.test.js` - 60 tests
- `tests/services/playHistoryService.test.js` - 49 tests
- `tests/services/audioService.test.js` - 48 tests
- 覆盖率阈值: 70%

### 前端测试 (178 tests created)
- `test/providers/auth/auth_provider_test.dart` - 30+ tests
- `test/providers/search/search_provider_test.dart` - 47 tests
- `test/providers/player/playback_controller_test.dart` - 59 tests
- `test/providers/favorites/playlist_provider_test.dart` - 42 tests

### 运行测试
```powershell
# 后端
cd listen-vision_api
pnpm test                   # 运行所有测试
pnpm test:coverage           # 覆盖率报告

# 前端
cd frontend_flutter
flutter pub get              # 首次运行需安装依赖
flutter test                 # 运行所有测试
flutter test --coverage     # 覆盖率报告
```

---

## 常用命令

### 后端
```powershell
cd listen-vision_api
pnpm install
node index.js              # 启动
pnpm test                   # 测试
Get-Process node | Stop-Process -Force  # 停止
```

### 前端
```bash
cd frontend_flutter
flutter pub get
flutter run
flutter analyze
```

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

## 第三方平台 API 文档

### B站 API

**优先使用本地文档** `references/bilibili-API-collect/docs/`，而非网页搜索。

核心文档：
- 登录: `references/bilibili-API-collect/docs/login/login_action/QR.md`
- 视频: `references/bilibili-API-collect/docs/video/video_info.md`
- 音频: `references/bilibili-API-collect/docs/audio/audio_stream.md`

### QQ音乐 API

**官方文档**: https://developer.y.qq.com/docs/openid#/overview

> 用于未来 QQ 音乐平台接入开发，包含 OpenID 认证、音乐搜索、播放等功能。

---

## Riverpod 状态管理

**文档**: [RIVERPOD_GUIDE.md](./docs/RIVERPOD_GUIDE.md)

**本地参考文档**: `references/riverpod/` (官方仓库克隆)

核心概念：
- `@riverpod` 注解 + `build_runner` 代码生成
- `StateNotifier` 模式管理可变状态
- `ref.watch` 监听状态，`ref.read` 读取一次
- `freezed` 定义不可变状态类

---

## 认证架构

1. **主账号** (Email/Password + JWT)
2. **平台绑定** (B站QR码，Cookie加密存储)
3. **游客模式** (本地播放，无需登录)

---

## 架构设计 (轻量 MVVM + Riverpod)

```
models/        # 轻量实体（Audio, Playlist, User 等）
data/          # 数据层（API客户端、Repository实现）
  ├── database/   # SQLite DAO (TrackDao, DownloadTaskDao, SyncQueueDao)
  └── sync/       # 网络同步重试机制 (SyncWorker)
services/      # 有状态服务（AudioPlayerService, MetadataService）
viewmodels/    # StateNotifier 状态管理
views/         # 纯 UI 渲染（ConsumerWidget）
core/          # 基础设施（常量、网络、存储）
```

---

## API 标准化与代码质量改进

**实现日期**: 2026-02-12

### 改进内容

| 类别 | 改进项 | 状态 |
|------|--------|------|
| **后端** | Console.log → Winston logger | ✅ 完成 |
| **后端** | 统一响应格式 (successResponse/errorResponse) | ✅ 完成 |
| **后端** | 移除冗余代码 (conversionTracker 导出) | ✅ 完成 |
| **前端** | 创建 DTO 层 (`models/dto/`) | ✅ 完成 |
| **前端** | 统一端点常量 (`core/network/endpoints.dart`) | ✅ 完成 |
| **前端** | 重构统一 API 客户端 (`core/network/api_client.dart`) | ✅ 完成 |
| **前端** | ViewModel 使用 Provider 单例 | 🟡 部分完成 |

### 后端改进

**日志标准化**:
- 所有 `console.log` 替换为 `logger.info/debug/warn/error`
- 结构化日志输出，包含上下文信息
- 敏感信息自动脱敏

**响应格式统一**:
```javascript
// 成功响应
successResponse(res, data, '操作成功');

// 错误响应  
errorResponse(res, '错误信息', 400);
```

**涉及文件**:
- `listen-vision_api/index.js`
- `listen-vision_api/routes/v1.js`
- `listen-vision_api/routes/bilibili.js`
- `listen-vision_api/services/emailService.js`
- `listen-vision_api/controllers/bilibiliController.js`
- `listen-vision_api/controllers/neteaseController.js`

### 前端改进

**DTO 层** (`models/dto/api_dto.dart`):
- `ApiResponse<T>` - 统一 API 响应包装
- `LoginRequestDto/LoginResponseDto` - 认证相关
- `BilibiliQRCodeDto/BilibiliVideoDto` - B站相关
- `NeteasePlaylistDto/NeteaseSongDto` - 网易云相关

**端点常量** (`core/network/endpoints.dart`):
```dart
// 认证
Endpoints.Auth.login
Endpoints.Auth.register

// B站
Endpoints.Bilibili.video(bvid)
Endpoints.Bilibili.search

// 网易云
Endpoints.Netease.playlistDetail(id)
Endpoints.Netease.search
```

**统一 API 客户端** (`core/network/api_client.dart`):
```dart
// 使用 Provider 获取单例
final apiClient = ref.watch(apiClientProvider);

// 调用 API
final data = await apiClient.getBilibiliRecommendations();
final user = await apiClient.login(request);
```

### 迁移指南

**旧代码**:
```dart
// 不推荐：直接创建 API 客户端实例
final apiClient = BackendApiClient();
```

**新代码**:
```dart
// 推荐：使用 Provider 单例
final apiClient = ref.watch(apiClientProvider);
```

---

## 本地优先同步机制

**实现日期**: 2026-02-06

### 核心原则

1. **本地优先**：所有写操作先更新本地数据库，UI 立即响应
2. **异步同步**：网络操作放入同步队列，由 SyncWorker 后台处理
3. **失败重试**：最多重试 3 次，间隔 30 秒
4. **持久化**：App 重启后自动恢复未完成的同步任务

### 数据流

```
用户操作
   │
   ├─→ 立即更新本地数据库 ──→ UI 刷新
   │
   └─→ 加入同步队列 ──→ SyncWorker ──→ 网络同步
                              │
                              ├─ 成功 → 清除任务
                              ├─ 失败 → 重试（最多3次）
                              └─ 超过重试次数 → 标记为最终失败
```

### 支持的同步操作

- 收藏/取消收藏 (`SyncType.favorite/unfavorite`)
- 播放历史 (`SyncType.playHistory`)
- 歌单项操作 (`SyncType.addPlaylistItem/removePlaylistItem`)
- 歌单管理 (`SyncType.createPlaylist/updatePlaylist/deletePlaylist`)

### 相关文件

- [models/sync_queue.dart](frontend_flutter/lib/models/sync_queue.dart) - 数据模型
- [data/database/sync_queue_dao.dart](frontend_flutter/lib/data/database/sync_queue_dao.dart) - 数据访问
- [data/sync/sync_worker.dart](frontend_flutter/lib/data/sync/sync_worker.dart) - 同步工作器
- [data/sync/sync_worker_provider.dart](frontend_flutter/lib/data/sync/sync_worker_provider.dart) - Provider

---

## 代码规范

### 日志记录
- **后端**：使用 Winston logger，支持 error/warn/info/debug 四级
- **前端**：使用 AppLogger 单例，支持 DEBUG/INFO/WARN/ERROR 四级
- **规范文档**：[LOGGING_STANDARDS.md](./docs/LOGGING_STANDARDS.md)

### 代码注释
- **后端**：使用 JSDoc 标准注释函数和类
- **前端**：使用 DartDoc 标准注释类和函数
- **规范文档**：[CODE_COMMENT_STANDARDS.md](./docs/CODE_COMMENT_STANDARDS.md)

### 开发原则
1. 所有用户操作必须记录日志（UI层点击 + Provider层触发）
2. 关键业务流程必须有开始/结束日志
3. 复杂算法必须有详细注释说明
4. 禁止提交临时调试代码（console.log）和 TODO 注释
5. 敏感信息（password/token）必须脱敏处理

---

## 相关文档


- 📄 [Riverpod 使用指南](./docs/RIVERPOD_GUIDE.md)
- 📄 [日志记录规范](./docs/LOGGING_STANDARDS.md)
- 📄 [代码注释规范](./docs/CODE_COMMENT_STANDARDS.md)

---

## 长期记忆

### 项目决策记录

- **[2026-02-16]** 文件系统监听方案变更：放弃 `FileSystemEntity.watch()` 方案，改用启动扫描 + 定期轮询 + 播放前验证的三层检测机制。
  - **原因**: `FileSystemEntity.watch()` 在移动端支持不完整，不可靠。
  - **新方案**: `DownloadIntegrityService` 提供启动全量扫描、30分钟轮询、播放前验证的三层保障。
  - **相关文件**: `docs/plans/file-system-watcher-implementation.md`

### 架构合规性修复 - 第一阶段完成

**完成日期**: 2026-02-16

#### 已完成功能

1. **文件系统完整性验证** (P0)
   - ✅ 实现 `DownloadIntegrityService` 服务
   - ✅ 启动时全量扫描（验证所有已下载文件）
   - ✅ 30分钟定期增量检查
   - ✅ 自动标记缺失文件为未下载状态
   - ✅ 通过 Provider 集成到应用启动流程

2. **本地优先播放策略** (P0)
   - ✅ 修改 `QueueViewModel.playAt()` 方法
   - ✅ 播放前检查本地文件存在性
   - ✅ 本地可用时优先使用本地文件
   - ✅ 本地不可用时自动回退到网络播放
   - ✅ 增强 `TrackRepository` 支持文件验证方法

#### 新增文件

- `lib/services/download_integrity_service.dart` - 下载完整性服务
- `lib/data/sync/download_integrity_provider.dart` - 下载完整性 Provider

#### 修改文件

- `lib/data/database/track_dao.dart` - 添加 `markAsNotDownloaded`, `batchUpdateDownloadStatus`, `getRecentlyDownloadedTracks` 方法
- `lib/data/repositories/track_repository.dart` - 添加 `getLocalPath`, `validateLocalFile`, `batchMarkAsNotDownloaded` 方法
- `lib/presentation/viewmodels/player/queue_viewmodel.dart` - 修改 `playAt()` 实现本地优先播放逻辑
- `lib/app.dart` - 集成 `downloadIntegrityServiceProvider`

### 架构合规性修复 - 第二阶段完成

**完成日期**: 2026-02-16

#### 已完成功能

1. **增强 ErrorUIHandler** (P1)
   - ✅ 新增 `showSuccess` - 成功提示（绿色）
   - ✅ 新增 `showWarning` - 警告提示（橙色）
   - ✅ 新增 `showInfo` - 信息提示（蓝色）
   - ✅ 新增 `showToast` - 轻量级提示
   - ✅ 新增 `showErrorDialog` - 错误对话框
   - ✅ 新增 `showConfirmDialog` - 确认对话框
   - ✅ 新增 `showInputDialog` - 输入对话框
   - ✅ 新增 `tryAsync`/`trySync` - 安全执行封装
   - ✅ 新增网络错误/权限错误专用提示方法
   - ✅ 添加 `ValidationException` 到异常体系

2. **网络状态监测** (P1)
   - ✅ 添加 `connectivity_plus` 依赖
   - ✅ 实现 `NetworkStatusNotifier` 状态管理
   - ✅ 支持 WiFi/移动数据/以太网/VPN 等多种连接类型
   - ✅ 创建 `NetworkStatusListener` 全局监听组件
   - ✅ 网络断开时显示错误提示
   - ✅ 网络恢复时显示成功提示
   - ✅ 网络类型变化时显示信息提示
   - ✅ 集成到 App 顶层监听

#### 新增文件

- `lib/core/models/network_status.dart` - 网络状态模型
- `lib/core/network/network_status_provider.dart` - 网络状态 Provider
- `lib/presentation/widgets/common/network_status_listener.dart` - 网络状态监听组件
- `lib/core/errors/exceptions.dart` - 添加 `ValidationException`

#### 修改文件

- `lib/presentation/utils/error_ui_handler.dart` - 全面增强，支持多种提示类型
- `lib/core/utils/error_handler.dart` - 添加 `isValidationError` 方法
- `lib/app.dart` - 集成 `NetworkStatusListener`
- `pubspec.yaml` - 添加 `connectivity_plus: ^6.1.3`

#### 当前架构合规性状态

| 需求 | 状态 | 说明 |
|------|------|------|
| 本地优先播放策略 | ✅ 已完成 | 播放时优先检查本地文件 |
| 数据变化感知（文件监听） | ✅ 已完成 | 三层检测机制：启动扫描+轮询+播放验证 |
| 统一错误提示风格 | ✅ 已完成 | ErrorUIHandler 已全面增强，可逐步迁移现有 93 处调用 |
| 网络断链提示 | ✅ 已完成 | 实时监测网络状态，自动提示断连/恢复 |
| 双向数据同步 | ⏳ P2 | 待实现 |

### Token 刷新机制实现 - 第三阶段完成

**完成日期**: 2026-03-14

#### 问题
- API 调用返回 401（Token 过期）无法自动刷新
- 解绑 B站 时返回 401 导致解绑失败  
- token 状态存储代码有缺陷

#### 解决方案

**后端改动**:
- ✅ `config/jwt.js` - 添加 refreshToken 生成和验证方法
- ✅ `services/userService.js` - 登录和注册时返回 refreshToken
- ✅ `controllers/authController.js` - 新增 `/auth/refresh` 端点
- ✅ `routes/auth.js` - 挂载 `/auth/refresh` 路由（无需认证）

**前端改动**:
- ✅ `core/constants/storage_constants.dart` - 添加 `keyRefreshToken` 常量
- ✅ `core/storage/shared_storage_service.dart` - 添加 refresh token 存储方法
- ✅ `models/dto/api_dto.dart` - LoginResponseDto 添加 refreshToken 字段
- ✅ `core/network/dio_client.dart` - 实现 401 拦截器自动刷新 token 并重试
- ✅ `data/repositories/auth_repository.dart` - 登录和注册时保存 refresh token

#### 工作流程
```
API 请求 → DioClient → 如果 401:
  ├─ 获取本地 refreshToken
  ├─ 调用 /auth/refresh 获取新 token
  ├─ 保存新 token 到存储和 DioClient
  └─ 重试原始请求 (使用新 token)
```

#### 涉及文件
**后端**: 
- `listen-vision_api/config/jwt.js`
- `listen-vision_api/services/userService.js`
- `listen-vision_api/controllers/authController.js`
- `listen-vision_api/routes/auth.js`

**前端**:
- `frontend_flutter/lib/core/constants/storage_constants.dart`
- `frontend_flutter/lib/core/storage/shared_storage_service.dart`
- `frontend_flutter/lib/models/dto/api_dto.dart`
- `frontend_flutter/lib/core/network/dio_client.dart`
- `frontend_flutter/lib/data/repositories/auth_repository.dart`

#### 测试验证
- [ ] Token 自动刷新机制
- [ ] 并发请求时的竞态条件  
- [ ] Refresh token 过期场景
- [ ] 字幕获取（应支持未登录用户）
