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
│       ├── models/            # 轻量实体（原 domain/entities）
│       ├── data/              # 数据层（API客户端、Repository）
│       │   ├── database/       # SQLite DAO
│       │   ├── repositories/   # Repository 实现
│       │   └── sync/           # 网络同步重试机制
│       ├── services/          # 有状态服务（音频播放、元数据）
│       └── presentation/      # UI层
│           ├── viewmodels/    # StateNotifier 状态管理
│           ├── views/         # 页面
│           ├── widgets/       # 组件
│           └── providers.dart # Riverpod providers 统一定义
└── listen-vision_api/        # Node.js后端
    ├── middleware/           # 认证、限流、错误处理
    ├── routes/               # API路由
    ├── controllers/          # 控制器
    ├── services/             # 业务逻辑
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

## B站API文档

**优先使用本地文档** `references/bilibili-API-collect/docs/`，而非网页搜索。

核心文档：
- 登录: `references/bilibili-API-collect/docs/login/login_action/QR.md`
- 视频: `references/bilibili-API-collect/docs/video/video_info.md`
- 音频: `references/bilibili-API-collect/docs/audio/audio_stream.md`

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
