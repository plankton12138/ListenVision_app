# 🎵 ListenVision

> 一个基于 Bilibili API 的跨平台音频获取与播放应用

[![Flutter](https://img.shields.io/badge/Flutter-3.38.5-blue)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10.4-blue)](https://dart.dev)
[![Node.js](https://img.shields.io/badge/Node.js-Express-green)](https://nodejs.org)
[![SQLite](https://img.shields.io/badge/SQLite-better--sqlite3-orange)](https://sqlite.org)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## 📖 项目简介

**ListenVision** 是一个功能完整的跨平台音频应用,专注于为用户提供便捷的音频内容获取、播放和管理体验。通过集成 Bilibili API,用户可以搜索、下载、播放 B站 的音频内容(包括音乐、播客、曲艺等)。

### 核心特色

- 🎯 **灵活的账号体系** - 支持邮箱注册登录,可选绑定 B站 账号获取个性化推荐
- 🔓 **游客模式** - 未登录用户也能搜索、下载、播放本地音频
- 🔐 **安全的认证机制** - JWT Token + 服务端AES-256-CBC加密存储 Cookie
- 🌍 **跨平台支持** - Android、iOS、Web、Windows、Linux、macOS 全覆盖
- 🎵 **本地音频播放** - 支持导入本地音频文件并管理播放列表,支持 M4A/MP3/FLAC 元数据
 - 📥 **智能下载管理** - 支持多线程下载、断点续传、后台下载
 - 🎨 **Material Design** - 简洁优雅的用户界面,支持深色模式
- 🏗️ **Clean Architecture** - 清晰的分层架构,易于维护和测试

---

## 🏗️ 项目架构

ListenVision 采用 **Clean Architecture** 设计原则,遵循清晰的分层架构:

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer (表现层)                │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Pages     │  │  Providers  │  │      Widgets        │  │
│  │  (页面)      │  │  (状态管理)  │  │      (组件)         │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└────────────────────────┬────────────────────────────────────┘
                         │ 调用
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                      Domain Layer (领域层)                   │
│  ┌─────────────┐  ┌─────────────────────────────────────┐  │
│  │  Entities   │  │            Repositories             │  │
│  │   (实体)     │  │            (仓储接口)               │  │
│  │             │  │   定义"做什么",不管"怎么做"          │  │
│  └─────────────┘  └─────────────────────────────────────┘  │
└────────────────────────┬────────────────────────────────────┘
                         │ 实现
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                     Data Layer (数据层)                      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │DataSources  │  │  Managers   │  │   Repositories      │  │
│  │ (数据源)     │  │  (管理器)    │  │   (仓储实现)        │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    Core Layer (核心层)                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │    DI       │  │  Network    │  │      Utils          │  │
│  │ (依赖注入)   │  │  (网络)     │  │      (工具)         │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### 数据流示例 (以"下载音频"为例)

```
用户点击下载按钮
        │
        ▼
┌─────────────────┐
│   DownloadPage  │  ← "我想下载这个视频!"
│   (表现层页面)   │
└────────┬────────┘
         │ 调用 Provider
         ▼
┌─────────────────────┐
│  DownloadManager    │  ← "收到!我来协调下载流程"
│  (表现层 Provider)  │
└────────┬────────────┘
         │ 调用 Repository 接口
         ▼
┌─────────────────────┐
│ DownloadRepository  │  ← "开始下载任务"
│     (领域层接口)     │    定义有哪些操作
└────────┬────────────┘
         │ 实现接口
         ▼
┌─────────────────────┐
│DownloadRepositoryImpl│ ← "具体怎么存,我来搞定"
│   (数据层实现)       │    SQLite 操作
└────────┬────────────┘
         │
         ├──→ 读写数据库 (DownloadLocalDataSource)
         └──→ 执行下载 (DownloadExecutor)
```

### 技术栈

#### 前端 (Flutter)
- **框架**: Flutter 3.38.5 (Dart 3.10.4)
- **架构**: Clean Architecture (Core/Domain/Data/Presentation)
- **状态管理**: Provider ^6.1.4
- **路由**: go_router ^14.8.1
- **数据库**: sqflite ^2.4.2 (移动端) / sqflite_common_ffi ^2.3.5 (桌面端)
- **网络**: dio ^5.8.0+1
- **音频播放**: audioplayers ^6.x + audio_session ^0.2.1
- **元数据**: metadata_god ^0.5.2+1 (支持 M4A/MP3/FLAC)
- **错误处理**: dartz ^0.10.1 (Either 泛型)
 - **网络监测**: AdaptiveNetworkManager (当前暂停运行)

#### 后端 (Node.js)
- **框架**: Express ^5.1.0
- **数据库**: better-sqlite3 ^12.6.0 (嵌入式SQLite)
- **认证**: bcrypt ^5.1.1 + JWT
- **加密**: AES-256-CBC (Cookie 加密存储)
- **B站API**: WBI签名、QR码登录、元数据缓存
- **邮件**: nodemailer ^7.0.3
- **跨域**: cors ^2.8.5

---

## 🚀 快速开始

### 前置要求

- Flutter SDK >= 3.38.5
- Dart SDK >= 3.10.4
- Node.js >= 18.0

### 1. 克隆项目

```bash
git clone https://github.com/yourusername/Projects_ListenVison.git
cd Projects_ListenVison
```

### 2. 后端设置

```bash
# 进入后端目录
cd listen-vision_api

# 安装依赖
npm install

# 启动服务器（数据库文件将自动创建于 data/listenvision.db）
node index.js
```

后端服务将运行在 `http://localhost:3000`

### 3. 前端设置

```bash
# 进入前端目录
cd frontend_flutter

# 获取依赖
flutter pub get

# 运行应用 (需要连接设备/模拟器)
flutter run

# 构建特定平台
flutter build apk          # Android APK
flutter build ios          # iOS
flutter build web          # Web
flutter build windows      # Windows
flutter build linux        # Linux
flutter build macos        # macOS
```

---

## 📂 项目结构

```
Projects_ListenVison/
├── frontend_flutter/              # Flutter 前端应用
│   ├── lib/
│   │   ├── main.dart             # 应用入口
│   │   ├── core/                 # Clean Architecture - 核心层
│   │   │   ├── base/             # 基类 (BaseEntity, BaseProvider)
│   │   │   ├── constants/        # 常量 (API, Storage)
│   │   │   ├── di/               # 依赖注入 (ServiceFactory)
│   │   │   ├── errors/           # 错误定义 (Exceptions, Failures)
│   │   │   ├── network/          # 网络层 (DioProvider)
│   │   │   └── utils/            # 工具函数
│   │   │       ├── dialog_helper.dart
│   │   │       ├── file_picker_helper.dart
│   │   │       ├── metadata_writer.dart
│   │   │       ├── permission_helper.dart
│   │   │       └── ...
│   │   ├── domain/               # Clean Architecture - 领域层
│   │   │   ├── entities/         # 领域实体
│   │   │   │   ├── audio.dart              # 在线音频实体
│   │   │   │   ├── local_audio.dart        # 本地音频实体
│   │   │   │   ├── download_task.dart      # 下载任务实体
│   │   │   │   ├── user.dart               # 用户实体
│   │   │   │   ├── playlist.dart           # 歌单实体
│   │   │   │   ├── play_history.dart       # 播放历史实体
│   │   │   │   ├── recommendation.dart     # 推荐实体
│   │   │   │   ├── platform_account.dart   # 平台账号实体
│   │   │   │   ├── platform_types.dart     # 平台类型枚举
│   │   │   │   ├── domain_types.dart       # 领域类型定义
│   │   │   │   └── models_export.dart      # 统一导出
│   │   │   ├── repositories/     # 仓储接口 (抽象)
│   │   │   │   ├── auth_repository.dart
│   │   │   │   ├── bilibili_repository.dart
│   │   │   │   ├── download_repository.dart
│   │   │   │   ├── play_history_repository.dart
│   │   │   │   ├── playlist_repository.dart
│   │   │   │   └── search_repository.dart
│   │   │   └── usecases/         # 用例 (可选)
│   │   ├── data/                 # Clean Architecture - 数据层
│   │   │   ├── datasources/      # 数据源
│   │   │   │   ├── local/        # 本地数据源
│   │   │   │   │   ├── download_local_datasource.dart
│   │   │   │   │   └── auth_local_datasource.dart
│   │   │   │   └── remote/       # 远程数据源
│   │   │   │       ├── bilibili_remote_datasource.dart
│   │   │   │       ├── bilibili_api_datasource.dart
│   │   │   │       ├── auth_remote_datasource.dart
│   │   │   │       ├── playlist_remote_datasource.dart
│   │   │   │       ├── play_history_remote_datasource.dart
│   │   │   │       └── search_remote_datasource.dart
│   │   │   ├── managers/         # 管理器
│   │   │   │   ├── playlist_manager.dart
│   │   │   │   └── download_executor.dart
│   │   │   └── repositories/     # 仓储实现
│   │   │       ├── auth_repository_impl.dart
│   │   │       ├── bilibili_repository_impl.dart
│   │   │       ├── download_repository_impl.dart
│   │   │       ├── play_history_repository_impl.dart
│   │   │       ├── playlist_repository_impl.dart
│   │   │       └── search_repository_impl.dart
│   │   └── presentation/         # Clean Architecture - 表现层
│   │       ├── pages/            # 页面
│   │       │   ├── home_page.dart
│   │       │   ├── login_page.dart
│   │       │   ├── register_page.dart
│   │       │   ├── search_page.dart
│   │       │   ├── play_list_page.dart
│   │       │   ├── backend_download_page.dart
│   │       │   ├── download_list_page.dart
│   │       │   ├── settings_page.dart
│   │       │   └── ...
│   │       ├── providers/        # 状态管理 (按功能分目录)
│   │       │   ├── auth/         # 认证状态管理
│   │       │   ├── audio/        # 音频播放状态管理
│   │       │   │   ├── audio_provider.dart
│   │       │   │   └── audio_player_provider.dart
│   │       │   ├── bilibili/     # B站功能状态管理
│   │       │   │   ├── bilibili_provider.dart
│   │       │   │   ├── cache_provider.dart
│   │       │   │   └── qr_login_provider.dart
│   │       │   ├── playlist/     # 歌单状态管理
│   │       │   ├── search/       # 搜索状态管理
│   │       │   ├── download/     # 下载状态管理
│   │       │   │   └── download_manager.dart
│   │       │   ├── play_history/ # 播放历史状态管理
│   │       │   ├── theme/        # 主题状态管理
│   │       │   └── ...
│   │       ├── routes/           # 路由配置
│   │       │   └── router.dart
│   │       └── widgets/          # 可复用组件
│   │           ├── my_drawer.dart
│   │           └── ...
│   ├── assets/                   # 资源文件
│   ├── pubspec.yaml              # 依赖配置
│   └── README.md                 # 前端文档
│
├── listen-vision_api/            # Node.js 后端服务
│   ├── index.js                  # 主服务器文件
│   ├── services/
│   │   ├── bilibiliService.js    # B站API集成
│   │   ├── audioService.js       # 音频元数据服务
│   │   ├── playlistService.js    # 歌单管理服务
│   │   ├── playHistoryService.js # 播放历史服务
│   │   ├── recommendationService.js # 推荐服务
│   │   └── searchService.js      # FTS5全文搜索
│   ├── routes/
│   │   ├── bilibili.js           # B站API路由
│   │   ├── audio.js              # 音频API路由
│   │   ├── playlists.js          # 歌单API路由
│   │   ├── history.js            # 历史API路由
│   │   ├── recommendations.js    # 推荐API路由
│   │   └── search.js             # 搜索API路由
│   ├── config/
│   │   └── database.js           # 数据库配置
│   ├── middleware/
│   │   └── rateLimiter.js        # 请求限流中间件
│   ├── package.json              # 依赖配置
│   └── README.md                 # 后端文档
│
├── docs/                         # 项目文档
│   ├── AUDIO_PLAYER_FIX_PLAN.md       # 音频播放器综合修复方案（2026-01-23 完成）
│   ├── PHASE_5_BUGFIX_AND_IMPROVEMENTS.md  # Phase 5 Bug修复与改进
│   ├── PHASE_2_ONLINE_PLAYBACK.md           # Phase 2 在线播放功能（已完成）
│   ├── PHASE_3_PLAYLIST_PLAN.md             # Phase 3 播放列表云同步
│   ├── PHASE_3A_PLAYBACK_PLAN.md            # Phase 3A 播放列表页面改进
│   ├── INCREMENTAL_MIGRATION_PLAN.md        # 渐进式架构迁移计划
│   └── PHASE_1_IMPLEMENTATION_DETAILS.md    # Phase 1 实施细节
│
├── bilibili-API-collect/         # B站API文档 (本地克隆)
├── PRD.md                        # 产品需求文档
├── CLAUDE.md                     # Claude Code 指导文档
├── AGENTS.md                     # Agent 开发指南
└── README.md                     # 本文件
```

---

## 🎯 核心功能

### 已实现功能 ✅

#### 未登录用户（游客模式）
- ✅ 本地音频导入与播放
- ✅ 搜索音频内容音频到本地
- ✅ 播放
- ✅ 下载列表管理
- ✅ 音频播放控制 (播放/暂停/上一曲/下一曲/进度条)
- ✅ 深色模式切换
- ✅ 文件浏览与选择
- ✅ 跳转到原内容页面（B站）
- ✅ 视频章节/选集/分P 跳转支持
- ✅ 音频元数据显示（封面、标题、艺术家）

#### 登录用户

**账号管理**：
- ✅ 邮箱注册（需邮箱验证）
- ✅ 用户名/密码登录
- ✅ 忘记密码（邮箱验证码找回）

**歌单与收藏** (Phase 2)：
- ✅ 创建/编辑/删除歌单
- ✅ "我喜欢"收藏歌单（系统歌单）
- ✅ 添加/移除歌单项
- ⏸️ 收藏功能（暂时关闭）
- ✅ 播放历史记录与清空
- ✅ 歌单详情查看
- ✅ **在线音频播放** (2026-01-23 完成)
- ✅ **歌单排序功能** (2026-01-24 新增)
- ✅ **添加歌曲到歌单** (2026-01-24 新增)
- ✅ **歌单排序功能** (2026-01-24 新增)
- ✅ **添加歌曲到歌单** (2026-01-24 新增)

**发现与推荐** (Phase 2)：
- ✅ 热门歌单推荐
- ✅ 热歌榜单
- ✅ 个性化推荐内容
- ✅ 登录访问控制（需要登录才能访问）
- ✅ **在线音频播放功能** (2026-01-23 完成)

**可选 - Bilibili 账号绑定** (Phase 1)：
- ✅ Bilibili 二维码登录
- ✅ 账号绑定与解绑
- ✅ 服务端加密 Cookie 存储 (AES-256-CBC)
- ✅ 获取 B站 推荐内容
- ✅ 设置页面优化

#### 后端服务
- ✅ 用户注册/登录（JWT 认证）
- ✅ 邮箱验证码服务
- ✅ 密码找回功能
- ⏸️ 收藏管理 API（前端暂时关闭入口）
- ✅ 歌单管理 API (Phase 2)
- ✅ 播放历史 API (Phase 2)
- ✅ 推荐内容 API (Phase 2)
- ✅ **在线音频播放 API** (Phase 2 - 2026-01-23 完成)
  - ✅ 获取音频流URL (`GET /api/bilibili/audio/:bvid`)
  - ✅ 音频流代理 (`GET /api/bilibili/proxy/audio`)
  - ✅ 图片代理 (`GET /api/bilibili/proxy/image`)
  - ✅ 音频格式转换（FFmpeg m4s → MP3）
  - ✅ **歌单排序API** (2026-01-24 新增) - `PUT /api/playlists/:id/sort` (支持按标题/艺术家/添加时间等排序)
- ✅ 全文搜索 API (Phase 3 - FTS5)
- ✅ CORS 跨域支持
- ✅ 请求限流中间件
- ✅ SQLite 数据库（better-sqlite3）
- ✅ B站API集成（QR登录、视频信息、音频流）(Phase 1)
- ✅ 音频元数据缓存服务 (Phase 1)
- ✅ 资源代理服务（解决B站防盗链）(Phase 1)

### 架构迁移状态 ✅

**前端 Clean Architecture 迁移完成 (100%)**:
- ✅ Core 层：基类、常量、错误定义、网络层、依赖注入
- ✅ Domain 层：实体 (LocalAudio, DownloadTask, User, Playlist 等)
- ✅ Domain 层：仓储接口 (Repository Interfaces)
- ✅ Data 层：数据源 (Remote/Local DataSources)
- ✅ Data 层：仓储实现 (Repository Implementations)
- ✅ Data 层：管理器 (Managers)
- ✅ Presentation 层：Provider 状态管理（按功能分目录）
- ✅ 已删除旧目录：models/, services/, theme/

### 规划中功能 🚧

已完成：
- ✅ **在线流式播放 (边下边播)** - Phase 2 已完成
- ✅ **播放控制增强** (2026-01-24) - 音量/倍速控制、歌单排序、在线封面异步加载

待实现：
- 🎵 音频可视化 (波形图/频谱图)
- 🎨 简易音频剪辑功能
- 🌐 多语言支持
- 🎵 音乐平台推荐扩展（QQ音乐榜单）
- 📝 播放列表导入/导出
- 🔄 多线程下载优化
- 🔄 播放队列跨设备同步

---

## 📚 文档索引

- **[PRD.md](./PRD.md)** - 产品需求文档
- **[CLAUDE.md](./CLAUDE.md)** - Claude Code 开发指导文档
- **[AGENTS.md](./AGENTS.md)** - Agent 开发指南
- **[docs/INCREMENTAL_MIGRATION_PLAN.md](./docs/INCREMENTAL_MIGRATION_PLAN.md)** - 渐进式架构迁移计划
- **[docs/PHASE_2_ONLINE_PLAYBACK.md](./docs/PHASE_2_ONLINE_PLAYBACK.md)** - Phase 2 在线播放功能（已完成）
- **[docs/AUDIO_PLAYER_FIX_PLAN.md](./docs/AUDIO_PLAYER_FIX_PLAN.md)** - 音频播放器修复方案（已完成）
- **[frontend_flutter/README.md](./frontend_flutter/README.md)** - 前端详细文档
- **[listen-vision_api/README.md](./listen-vision_api/README.md)** - 后端详细文档

---

## 🔐 认证架构

### 混合账号体系

ListenVision 采用 **传统账号 + 可选平台绑定** 的混合认证模式。

详见项目文档中的认证架构章节。

---

## 🛠️ 开发指南

### 代码规范

- **语言**: 代码注释使用英文,用户文档使用中文
- **命名**: 遵循 Dart 官方命名规范
- **架构**: 遵循 Clean Architecture 原则
- **状态管理**: 使用 Provider 模式
- **错误处理**: 使用 dartz 的 Either 泛型

### 提交规范

```bash
# 功能开发
git commit -m "feat: 添加音频可视化功能"

# Bug 修复
git commit -m "fix: 修复下载进度不更新的问题"

# 文档更新
git commit -m "docs: 更新 README 安装说明"

# 代码重构
git commit -m "refactor: 重构 API 服务层"
```

### 测试

```bash
# 运行单元测试
flutter test

# 代码分析
flutter analyze
```

---

## 📄 开源协议

本项目采用 [MIT License](LICENSE) 开源协议。

---

## 🙏 致谢

- [Bilibili API Collect](https://github.com/SocialSisterYi/bilibili-API-collect) - B站 API 文档
- [Flutter](https://flutter.dev/) - 跨平台 UI 框架
- [Provider](https://pub.dev/packages/provider) - 状态管理
- [Express](https://expressjs.com/) - Node.js Web 框架

---

## 📞 联系方式

- **问题反馈**: [GitHub Issues](https://github.com/yourusername/Projects_ListenVison/issues)
- **邮件**: planktontian@qq.com

---

<div align="center">

**如果觉得这个项目有帮助,请给个 ⭐️ Star 支持一下!**

Made with ❤️ by ListenVision Team

</div>
