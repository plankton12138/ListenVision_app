# 🎵 ListenVision

> 一个基于 Bilibili API 的跨平台音频获取与播放应用

[![Flutter](https://img.shields.io/badge/Flutter-3.38.5-blue)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10.4-blue)](https://dart.dev)
[![Node.js](https://img.shields.io/badge/Node.js-24.13.0-green)](https://nodejs.org)
[![SQLite](https://img.shields.io/badge/SQLite-better--sqlite3-orange)](https://sqlite.org)
[![API Version](https://img.shields.io/badge/API-v1-blueviolet)](listen-vision_api/README.md)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## 📖 项目简介

**ListenVision** 是一个功能完整的跨平台音频应用，专注于为用户提供便捷的音频内容获取、播放和管理体验。通过集成 Bilibili API，用户可以搜索、下载、播放 B站 的音频内容（包括音乐、播客、曲艺等）。

### 核心特色

- 🎯 **灵活的账号体系** - 支持邮箱注册登录，可选绑定 B站 账号获取个性化推荐
- 🔓 **游客模式** - 未登录用户也能搜索、下载、播放本地音频
- 🔐 **安全的认证机制** - JWT Token + 服务端 AES-256-CBC 加密存储 Cookie
- 🌍 **跨平台支持** - Android、iOS、Web、Windows、Linux、macOS 全覆盖
- 🎵 **本地音频播放** - 支持导入本地音频文件并管理播放列表，支持 M4A/MP3/FLAC 元数据
- 📥 **智能下载管理** - 支持多线程下载、断点续传、后台下载
- 🎨 **Material Design** - 简洁优雅的用户界面，支持深色模式
- 🏗️ **Clean Architecture** - 清晰的分层架构，易于维护和测试
- 🔄 **API 版本控制** - 统一的 v1 API 版本管理

---

## 🏗️ 项目架构

ListenVision 采用 **Clean Architecture** 设计原则，遵循清晰的分层架构：

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
│  │             │  │   定义"做什么"，不管"怎么做"          │  │
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

### 数据流示例（以"下载音频"为例）

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
- **API 版本**: v1 (`/api/v1`)
- **音频播放**: audioplayers ^6.x + audio_session ^0.2.1
- **元数据**: metadata_god ^0.5.2+1 (支持 M4A/MP3/FLAC)
- **错误处理**: dartz ^0.10.1 (Either 泛型)

#### 后端 (Node.js)
- **框架**: Express ^5.1.0
- **API 版本**: v1 (`/api/v1`)
- **数据库**: better-sqlite3 ^12.6.0 (嵌入式 SQLite)
- **认证**: bcrypt ^5.1.1 + JWT
- **加密**: AES-256-CBC (Cookie 加密存储)
- **B站API**: WBI签名、QR码登录、元数据缓存
- **音频处理**: 后端已移除（迁移至前端，使用 metadata_god）
- **邮件**: nodemailer ^7.0.3
- **跨域**: cors ^2.8.5

---

## 🚀 快速开始

### 前置要求

- Flutter SDK >= 3.38.5
- Dart SDK >= 3.10.4
- Node.js >= 24.13.0
- FFmpeg (用于后端音频转换)

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
pnpm install

# 配置环境变量
cp .env.example .env
# 编辑 .env 文件，设置 JWT_SECRET 等配置

# 启动服务器（数据库文件将自动创建于 data/listenvision.db）
node index.js
```

后端服务将运行在 `http://localhost:3000`

API 文档: `http://localhost:3000/api-docs`

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
│   │   │   ├── config/           # 配置 (AppConfig, API 版本)
│   │   │   ├── constants/        # 常量 (API, Storage)
│   │   │   ├── di/               # 依赖注入 (ServiceFactory)
│   │   │   ├── errors/           # 错误定义 (Exceptions, Failures)
│   │   │   ├── network/          # 网络层 (DioProvider, ApiClient)
│   │   │   └── utils/            # 工具函数
│   │   ├── domain/               # Clean Architecture - 领域层
│   │   │   ├── entities/         # 领域实体
│   │   │   ├── repositories/     # 仓储接口 (抽象)
│   │   │   └── usecases/         # 用例 (可选)
│   │   ├── data/                 # Clean Architecture - 数据层
│   │   │   ├── datasources/      # 数据源 (Local/Remote)
│   │   │   ├── managers/         # 管理器
│   │   │   └── repositories/     # 仓储实现
│   │   └── presentation/         # Clean Architecture - 表现层
│   │       ├── pages/            # 页面
│   │       ├── providers/        # 状态管理 (按功能分目录)
│   │       ├── routes/           # 路由配置
│   │       └── widgets/          # 可复用组件
│   ├── assets/                   # 资源文件
│   ├── pubspec.yaml              # 依赖配置
│   └── README.md                 # 前端文档
│
├── listen-vision_api/            # Node.js 后端服务
│   ├── index.js                  # 应用入口文件
│   ├── config/                   # 配置文件
│   │   ├── database.js           # 数据库配置
│   │   ├── jwt.js                # JWT 配置
│   │   └── swagger.js            # API 文档配置
│   ├── middleware/               # 中间件
│   │   ├── auth.js               # JWT 认证
│   │   ├── errorHandler.js       # 错误处理
│   │   ├── logger.js             # HTTP 请求日志
│   │   ├── rateLimiter.js        # 请求限流
│   │   └── validator.js          # 参数验证
│   ├── routes/                   # 路由定义
│   │   ├── v1.js                 # v1 API 路由统一入口
│   │   ├── auth.js               # 认证路由
│   │   ├── users.js              # 用户路由
│   │   ├── playlists.js          # 歌单路由
│   │   ├── bilibili.js           # B站 API 路由
│   │   ├── audio.js              # 音频服务路由
│   │   ├── search.js             # 搜索路由
│   │   ├── history.js            # 播放历史路由
│   │   └── recommendations.js    # 推荐路由
│   ├── controllers/              # 控制器
│   │   ├── authController.js
│   │   ├── playlistController.js
│   │   ├── bilibiliController.js
│   │   └── audioController.js
│   ├── services/                 # 服务层
│   │   ├── audio/                # 音频服务模块
│   │   │   ├── index.js          # 统一入口
│   │   │   ├── conversionService.js    # 音频转换
│   │   │   ├── metadataService.js      # 元数据缓存
│   │   │   └── searchHistoryService.js # 搜索历史
│   │   ├── userService.js
│   │   ├── playlistService.js
│   │   ├── bilibiliService.js
│   │   └── searchService.js
│   ├── utils/                    # 工具函数
│   ├── data/                     # 数据存储目录
│   └── README.md                 # 后端文档
│
├── docs/                         # 项目文档
│   ├── plans/                    # 开发计划
│   ├── CODE_COMMENT_STANDARDS.md # 代码注释规范
│   ├── LOGGING_STANDARDS.md      # 日志规范
│   └── ...
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
- ✅ 搜索音频内容
- ✅ 下载音频到本地
- ✅ 播放列表管理
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

**歌单与收藏**：
- ✅ 创建/编辑/删除歌单
- ✅ "我喜欢"收藏歌单（系统歌单）
- ✅ 添加/移除歌单项
- ✅ 歌单排序（按标题/艺术家/添加时间等）
- ✅ 播放历史记录与清空
- ✅ 歌单详情查看
- ✅ 在线音频播放

**发现与推荐**：
- ✅ 热门歌单推荐
- ✅ 热歌榜单
- ✅ 个性化推荐内容

**可选 - Bilibili 账号绑定**：
- ✅ Bilibili 二维码登录
- ✅ 账号绑定与解绑
- ✅ 服务端加密 Cookie 存储 (AES-256-CBC)
- ✅ 获取 B站 推荐内容

#### 后端服务 (API v1)
- ✅ 用户注册/登录（JWT 认证）
- ✅ 邮箱验证码服务
- ✅ 密码找回功能
- ✅ 歌单管理 API (`/api/v1/playlists`)
- ✅ 播放历史 API (`/api/v1/history`)
- ✅ 推荐内容 API (`/api/v1/recommendations`)
- ✅ 在线音频播放 API (`/api/v1/bilibili/audio/:bvid`)
- ✅ 音频流代理 (`/api/v1/bilibili/proxy/audio/:bvid`)
- ✅ 音频格式转换（FFmpeg m4s → MP3/AAC）
- ✅ 音频元数据缓存服务
- ✅ 全文搜索 API (`/api/v1/search`)
- ✅ B站 API 集成（QR登录、视频信息、音频流）
- ✅ 资源代理服务（解决B站防盗链）
- ✅ CORS 跨域支持
- ✅ 请求限流中间件
- ✅ SQLite 数据库（better-sqlite3）

---

## 🔌 API 版本

当前 API 版本：**v1**

所有 API 端点均以 `/api/v1` 为前缀：

```
# 认证
POST   /api/v1/auth/register
POST   /api/v1/auth/login
GET    /api/v1/auth/me

# 歌单
GET    /api/v1/playlists
POST   /api/v1/playlists
GET    /api/v1/playlists/:id
PUT    /api/v1/playlists/:id
DELETE /api/v1/playlists/:id

# B站
GET    /api/v1/bilibili/video/:bvid
GET    /api/v1/bilibili/audio/:bvid
GET    /api/v1/bilibili/proxy/audio/:bvid
GET    /api/v1/bilibili/search

# 搜索
GET    /api/v1/search
GET    /api/v1/search/history

# 更多端点详见 API 文档
```

完整 API 文档：`http://localhost:3000/api-docs`

---

## 📚 开发文档

- [后端 API 文档](listen-vision_api/README.md) - 后端架构和 API 说明
- [前端开发文档](frontend_flutter/README.md) - Flutter 开发指南
- [代码注释规范](docs/CODE_COMMENT_STANDARDS.md) - 注释标准
- [日志规范](docs/LOGGING_STANDARDS.md) - 日志记录规范
- [Claude Code 指导](CLAUDE.md) - AI 开发助手指南

### 第三方平台 API 文档

- **B站 API**: `references/bilibili-API-collect/docs/` (本地克隆)
- **QQ音乐 API**: https://developer.y.qq.com/docs/openid#/overview (官方文档)

---

## 🙏 致谢与依赖项目

本项目依赖以下开源项目和 API 服务：

### 第三方 API 服务

| 平台 | 项目 | 链接 | 用途 |
|------|------|------|------|
| **网易云音乐** | NeteaseCloudMusicApi | https://gitee.com/Hua-lanni/NeteaseCloudMusicApi.git | 网易云音乐 API 服务，用于 QR 登录、歌单获取、搜索等功能 |
| **Bilibili** | bilibili-API-collect | https://github.com/SocialSisterYi/bilibili-API-collect | B站 API 文档收集项目，用于视频信息、音频流、搜索等接口开发 |

### 特别说明

- **NeteaseCloudMusicApi**: 本项目后端通过调用该 API 服务实现网易云音乐相关功能，包括二维码登录、用户信息获取、歌单管理、歌曲搜索等。该项目由社区维护，提供了网易云音乐 Web API 的封装。

- **bilibili-API-collect**: 这是一个社区维护的 B站 API 文档收集项目，本项目参考该文档实现了 B站 视频信息获取、音频流代理、搜索等功能。文档仓库已作为子模块克隆到 `references/bilibili-API-collect/` 目录。

感谢以上开源项目的作者和社区贡献者！

---

## 🤝 贡献指南

1. Fork 项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

---

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

---

## 📧 联系方式

planktontian@163.com