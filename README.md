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
- 🔓 **游客模式** - 未登录用户也能搜索、在线播放 B站 音频、导入本地音频
- 🔐 **安全的认证机制** - JWT Token + 服务端 AES-256-CBC 加密存储 Cookie
- 🌍 **跨平台支持** - Android、Web、Windows 全覆盖
- 🎵 **本地/在线音频播放** - 支持导入本地音频、在线播放 B站 音频，支持 M4A/MP3/FLAC 元数据
- 📋 **歌单管理** - 创建、编辑、收藏歌单，"我喜欢"系统歌单，歌单排序
- 📥 **智能下载管理** - 支持多线程下载、断点续传、后台下载
- 💾 **本地优先架构** - 数据本地优先存储，网络异步同步，断点续传保障
- 🛡️ **文件完整性验证** - 启动自动扫描下载文件，标记缺失文件
- 📶 **网络状态监测** - 实时显示 WiFi/移动数据连接状态
- 🎨 **Material Design** - 简洁优雅的用户界面，支持深色模式
- 🏗️ **Clean Architecture** - 清晰的分层架构，易于维护和测试

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

## 🎯 核心功能

### 使用方式

#### 未登录用户（游客模式）

游客可以享受以下功能，无需注册账号：

- ✅ **本地音频导入与播放** - 选择设备中的音频文件直接播放
- ✅ **搜索音频内容** - 搜索 B站 平台的音频/视频内容
- ✅ **在线播放** - 无需下载，直接在线播放 B站 音频
- ✅ **播放列表管理** - 临时播放队列，控制播放/暂停/上一曲/下一曲
- ✅ **音频播放控制** - 进度条拖拽、循环模式切换
- ✅ **深色模式切换** - 自由切换日间/夜间主题
- ✅ **跳转到原内容页面** - 快速跳转到 B站 原视频页面
- ✅ **视频章节/选集/分P 跳转** - 支持多P视频切换
- ✅ **音频元数据显示** - 显示封面、标题、艺术家等元数据

#### 登录用户

登录后可解锁更多功能：

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

**发现与推荐**：
- ✅ 热门歌单推荐
- ✅ 热歌榜单
- ✅ 个性化推荐内容

**可选 - Bilibili 账号绑定**：
- ✅ Bilibili 二维码登录
- ✅ 账号绑定与解绑
- ✅ 获取 B站 推荐内容

### 平台差异说明

#### Web 启动注意事项

Flutter Web 启动与原生启动存在以下功能差异：

| 特性 | 原生启动 (Android/iOS/桌面) | Web 启动 |
|------|---------------------------|----------|
| **本地数据库** | ✅ SQLite (sqflite) | ❌ 不可用 |
| **用户数据** | ✅ 持久化存储 | ❌ 仅内存存储，刷新后丢失 |
| **下载记录** | ✅ 持久化存储 | ❌ 不可用 |
| **播放历史** | ✅ 持久化存储 | ❌ 仅内存存储 |
| **歌单收藏** | ✅ 持久化存储 | ❌ 仅内存存储 |
| **登录状态** | ✅ JWT Token 持久化 | ⚠️ 仅 Session 有效 |

**Web 可用功能**：
- ✅ 本地音频导入（通过 Blob URL 播放）
- ✅ 在线播放 B站 音频
- ✅ 搜索功能
- ✅ 发现页面浏览

**Web 不可用功能**：
- ❌ 音频下载（无法写入文件系统）
- ❌ 后台播放（Web 音频 API 限制）
- ❌ 本地文件扫描

**建议**：如需完整功能体验，请使用原生启动（Android/iOS/桌面端）。

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

# 播放历史
GET    /api/v1/history
POST   /api/v1/history
DELETE /api/v1/history

# 推荐内容
GET    /api/v1/recommendations
```

完整 API 文档：`http://localhost:3000/api-docs`

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

### 技术栈

#### 前端 (Flutter)
- **框架**: Flutter 3.38.5 (Dart 3.10.4)
- **架构**: Clean Architecture (Core/Domain/Data/Presentation)
- **状态管理**: Riverpod (Codegen + Freezed)
- **路由**: go_router ^14.8.1
- **数据库**: sqflite ^2.4.2 (移动端) / sqflite_common_ffi ^2.3.5 (桌面端)
- **网络**: dio ^5.8.0+1
- **音频播放**: audioplayers ^6.x + audio_session ^0.2.1
- **元数据**: metadata_god ^0.5.2+1 (支持 M4A/MP3/FLAC)
- **错误处理**: dartz ^0.10.1 (Either 泛型)

#### 后端 (Node.js)
- **框架**: Express ^5.1.0
- **数据库**: better-sqlite3 ^12.6.0 (嵌入式 SQLite)
- **认证**: bcrypt ^5.1.1 + JWT
- **加密**: AES-256-CBC (Cookie 加密存储)
- **B站API**: WBI签名、QR码登录、元数据缓存
- **邮件**: nodemailer ^7.0.3
- **跨域**: cors ^2.8.5
- **日志**: Winston

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
│   ├── middleware/               # 中间件
│   ├── routes/                   # 路由定义
│   ├── controllers/              # 控制器
│   ├── services/                 # 服务层
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
├── references/                   # 参考文档
│   └── bilibili-API-collect/     # B站API文档 (本地克隆)
│
├── PRD.md                        # 产品需求文档
├── CLAUDE.md                     # Claude Code 指导文档
├── AGENTS.md                     # Agent 开发指南
└── README.md                     # 本文件
```

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

- **NeteaseCloudMusicApi**: 本项目后端通过调用该 API 服务实现网易云音乐相关功能，包括二维码登录、用户信息获取、歌单管理、歌曲搜索等。

- **bilibili-API-collect**: 这是一个社区维护的 B站 API 文档收集项目，本项目参考该文档实现了 B站 视频信息获取、音频流代理、搜索等功能。文档仓库已作为子模块克隆到 `references/bilibili-API-collect/` 目录。

感谢以上开源项目的作者和社区贡献者！

---

## 🤝 贡献指南

1. Fork 项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

## 📧 联系方式

planktontian@163.com
