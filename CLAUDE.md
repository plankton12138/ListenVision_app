# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Communication Language Preference

**请使用中文回复用户。**

When working in this repository:
- **THINK** in English for reasoning and problem-solving
- **RESPOND** in Chinese for all user-facing communication
- Code comments and technical documentation can remain in English unless the user specifically requests Chinese

## Learning Mode

**重要：这是一个学习驱动的开发环境。**

在创建和修改代码时，必须遵循以下原则：

1. **解释每个决策的理由** - 不要只给出解决方案，要解释为什么选择这个方案
2. **提供技术知识补充** - 当涉及新的编程概念、API、框架特性时，提供清晰的说明
3. **教学式对话** - 鼓励用户提问，确保用户理解代码背后的原理
4. **标注关键知识点** - 在代码注释或说明中标注值得注意的技术细节
5. **保持项目框架可见性** - 任何操作前明确当前所处位置、涉及的模块、数据流向

**示例格式：**
```
我建议使用 X 方案，原因是：
- [技术理由 1]
- [技术理由 2]

涉及的知识点：
- [概念 A]：解释...
- [概念 B]：解释...

当前项目位置：
├── [模块 A] 当前所在
│   └── → [模块 B] 本次修改目标
数据流：[用户输入] → [处理层] → [数据层] → [响应]
```

## 工作偏好

**重要：遵循用户的工作方式偏好。**

1. **总结报告格式**
   - ✅ 完成阶段工作后用**对话形式**总结
   - ✅ 不要自动创建总结文档（如 DOCS_UPDATE_SUMMARY.md）
   - ✅ 只有用户明确要求时才生成详细的总结报告文档

2. **避免多余工作**
   - ✅ 专注完成用户明确要求的任务
   - ✅ 不要主动创建额外的文档或文件
   - ✅ 保持简洁高效的工作流程

3. **回答风格偏好** ⭐
   - ✅ **优先展示设计思路和结构**，而不是具体代码
   - ✅ **指向核心代码位置**（file_path:line_number），而非完整代码块
   - ✅ 先讲"为什么这样设计"，再讲"如何实现"

4. **工作文档优先** ⭐⭐
   - ✅ **工作时必须先参考项目文档**，包括所有 `docs/` 目录下的 Markdown 文件
   - ✅ 任何修改前先查阅阶段文档（`PHASE_*.md`）了解上下文
   - ✅ 完成任务后提示用户更新相关文档
   - ✅ 保持文档与代码实现同步

5. **外部工具使用限制** ⭐⭐⭐
   - ⚠️ **使用以下工具前必须先询问用户**：
     - `WebSearch` - 网络搜索
     - `WebFetch` / `webReader` - 网页读取
     - MCP 工具（如 `mcp__github__*`）- 开源仓库相关
   - ✅ 优先使用本地资源（本地文档、本地代码）
   - ✅ 本地资源无法满足时，再请求使用外部工具

**回答格式模板**：
```
【设计思路】
└─ 为什么这样设计

【架构结构】
└─ 各组件如何协作

【核心代码位置】
└─ file_path:line_number - 说明
```

**示例**：
```
✅ 好的做法：
   完成修改 → 对话形式简要总结 → 等待用户下一步指示

❌ 避免的做法：
   完成修改 → 创建详细总结文档 → 生成报告 → 等待用户
```

## 当前项目状态 🔄

### 架构迁移进行中

**当前阶段**: **Phase 1** - B站API集成与元数据服务迁移

**迁移进度**:
```
规划阶段: ████████████████████ 100% ✅
Phase 1:   ██████████████░░░░░░   70% ✅ 后端完成，Flutter端待开始
Phase 2:   ░░░░░░░░░░░░░░░░░░░░   0%    等待Phase 1完成
Phase 3:   ░░░░░░░░░░░░░░░░░░░░   0%    等待Phase 2完成

总进度: 25% (后端B站API服务已完成)
```

**Phase 1 目标**:
- ✅ 将B站API调用从Flutter端迁移到服务端
- ✅ 实现音频元数据缓存机制
- ✅ 提升安全性（Cookie服务端管理）
- ✅ 降低客户端负担

**相关文档**:
- 📄 [渐进式架构迁移计划](./docs/INCREMENTAL_MIGRATION_PLAN.md) - 完整的3阶段实施计划

**知识说明**:
- **渐进式迁移**: 逐步将业务逻辑从客户端迁移到服务端，每个Phase独立可测试、可回滚
- **为什么迁移**: 当前90%业务逻辑在Flutter端，导致无法跨设备同步、安全性低、难以优化

---

## Repository Overview

This workspace contains three projects:

1. **bilibili-API-collect** - B站API文档参考（本地克隆）
2. **frontend_flutter** - Flutter移动应用
3. **listen-vision_api** - Node.js后端API服务器

### 开发环境 ⭐

- **操作系统**: Windows 11 24H2
- **Shell**: PowerShell（优先使用PowerShell命令）
- **IDE**: VSCode + Claude Code

**命令规范**:
- ✅ 使用 PowerShell 命令（如 `Get-ChildItem`, `Move-Item`, `Test-Path`）
- ❌ 避免使用 Bash/Linux 命令（如 `ls`, `mv`, `rm`）

### Authentication Architecture

**ListenVision uses a hybrid authentication system:**

1. **Primary Account System** (Required for full features)
   - Email/password registration
   - Traditional user accounts
   - JWT token authentication
   - Stored in MySQL database
   - Password hashing with bcrypt (10 rounds)

2. **Platform Binding** (Optional, for enhanced features)
   - Bilibili account linking via QR code
   - Encrypted Cookie storage (flutter_secure_storage)
   - Access to platform-specific features (recommendations, UP主 updates)
   - Independent from primary account
   - Can be unbound at any time

3. **Guest Mode** (No login required)
   - Search and download audio
   - Play local audio files
   - Basic playback controls
   - No account creation needed

---

## 1. bilibili-API-collect（B站API文档参考）

**Location:** `A:\Projects\Projects_ListenVison\bilibili-API-collect\`

**说明**: 这是 [SocialSisterYi/bilibili-API-collect](https://github.com/SocialSisterYi/bilibili-API-collect) 项目的本地克隆，用于开发时查阅B站API文档。

### 重要使用原则 ⭐

**在需要查询B站API时**:
1. ✅ **优先使用本地文档** - 直接读取本项目的 Markdown 文件
2. ❌ **不要使用网页搜索** - 除非本地文档无法满足需求
3. ✅ **使用 Read/Grep 工具** - 在本地文档中搜索相关API

### 文档结构

```
bilibili-API-collect/
├── docs/                    # API文档（Markdown格式）
│   ├── login/              # 登录相关API（QR码登录等）
│   ├── video/              # 视频相关API
│   ├── audio/              # 音频相关API
│   ├── user/               # 用户相关API
│   ├── search/             # 搜索相关API
│   └── ...
└── grpc_api/               # gRPC API协议定义
```

### 常用PowerShell命令

```powershell
# 查看文档目录
Get-ChildItem "A:\Projects\Projects_ListenVison\bilibili-API-collect\docs"

# 搜索包含特定关键词的文档
Select-String -Path "A:\Projects\Projects_ListenVison\bilibili-API-collect\docs\*" -Pattern "qrcode"

# 读取特定文档
Get-Content "A:\Projects\Projects_ListenVison\bilibili-API-collect\docs\login\login_action\QR.md"
```

### 重要提醒 ⚠️

- **开源协议**: CC-BY-NC 4.0（仅限非商业使用）
- **脱敏要求**: 上传代码时删除 `SESSDATA`、`bili_jct` 等 Cookie
- **频率限制**: 建议每分钟请求次数 < 60次

---

## 2. frontend_flutter (ListenVision App)

**Location:** `A:\Projects\Projects_ListenVison\frontend_flutter\`

**Technology Stack:**
- Flutter 3.38.5 (Dart 3.10.4)
- Provider state management
- go_router for navigation
- SQLite for local database (sqflite)
- Cross-platform: Android, iOS, Web, Windows, Linux, macOS

### Development Commands

```bash
# Navigate to project directory
cd frontend_flutter

# Get dependencies
flutter pub get

# Run the app (connected device/emulator required)
flutter run

# Build for specific platform
flutter build apk           # Android APK
flutter build ios           # iOS
flutter build web           # Web
flutter build windows       # Windows
flutter build linux         # Linux
flutter build macos         # macOS

# Run tests
flutter test

# Analyze code
flutter analyze

# Generate app icons (uses flutter_launcher_icons)
flutter pub run flutter_launcher_icons
```

### Architecture

The app follows a modular architecture with clear separation of concerns:

**Entry Point:** `lib/main.dart`
- Initializes Providers (ThemeController, AudioProvider, AuthProvider)
- Sets up database factory for desktop platforms (Windows/Linux/macOS use sqflite_ffi)
- Handles first-launch permission requests

**Core Modules:**

- **`providers/`** - State management with Provider pattern
  - `audio_provider.dart` - Audio playback state
  - `auth_provider.dart` - User authentication state
  - `theme_provider.dart` - Theme management

- **`routes/`** - Navigation configuration using go_router

- **`services/`** - Business logic and external integrations
  - `api_service.dart` - API communication
  - `download_manager.dart` - File download management
  - `file_picker.dart` - File selection

- **`ui/`** - User interface components

- **`models/`** - Data models and entities

- **`utils/`** - Utility functions and helpers

- **`config/`** - Configuration files

- **`constants/`** - App-wide constants

- **`exceptions/`** - Custom exception classes

- **`theme/`** - App theming

### Key Dependencies

- **provider** (^6.1.4) - State management
- **go_router** (^14.8.1) - Declarative routing
- **audioplayers** (^6.4.0) - Audio playback
- **sqflite** (^2.4.2) - SQLite database (mobile)
- **sqflite_common_ffi** (^2.3.5) - SQLite for desktop
- **dio** (^5.8.0+1) - HTTP client
- **file_picker** (^10.1.1) - File selection
- **permission_handler** (^12.0.0+1) - Runtime permissions
- **flutter_secure_storage** (^9.0.0) - Secure storage
- **qr_flutter** (^4.1.0) - QR code generation
- **flutter_captcha** (^1.0.0) - CAPTCHA verification

### Development Environment
- **Flutter SDK**: 3.38.5 (stable channel)
- **Dart SDK**: 3.10.4
- **IDE**: VSCode + Claude Code
- **Version Control**: Git
- **Operating System**: Windows 11 24H2
- **Visual Studio**: Professional 2026 (for Windows desktop builds)

### Flutter Doctor Summary
```
✓ Flutter (Channel stable, 3.38.5)
✓ Windows Version (Windows 11 24H2)
✗ Android toolchain - develop for Android devices (Android SDK not installed)
✗ Chrome - develop for the web (Use Edge instead)
✓ Visual Studio - develop Windows apps (Professional 2026)
✓ Connected device (2 available)
  • Windows (desktop) - windows-x64
  • Edge (web) - web-javascript
```

### Platform-Specific Notes

**Desktop Platforms (Windows/Linux/macOS):**
- Uses `databaseFactoryFfi` from `sqflite_common_ffi` for SQLite
- File storage paths differ from mobile platforms

**Mobile Platforms (Android/iOS):**
- Uses native `sqflite` package
- Requires runtime permissions (storage, etc.)

**Web:**
- Some features may not work (e.g., native file system access)

### Current TODO Features

From the README, these features are planned or in progress:
- ✅ Backend management system
- ✅ Login password recovery verification
- ✅ Registration CAPTCHA verification
- ✅ Search/download optimization
- API refactoring and cookie management
- Playlist creation
- Playlist improvement
- Multi-threaded downloads
- Online streaming playback
- Progressive download (play while downloading)
- Audio visualization
- Logging system
- Multi-language support
- Audio favorites feature
- Music platform recommendation integration

---

## 3. listen-vision_api (Backend API Server)

**Location:** `A:\Projects\listen-vision_api\`

**Technology Stack:**
- Node.js with Express
- better-sqlite3 (SQLite) for database
- JWT authentication
- bcrypt password hashing
- CORS enabled
- Jest for testing

**当前状态**: 🔄 **Phase 1开发中** - 正在实现B站API集成服务

### Development Commands

```powershell
# 进入项目目录
Set-Location "A:\Projects\Projects_ListenVison\listen-vision_api"

# 安装依赖
npm install

# 启动服务器
node index.js

# 运行测试
npm test

# 运行测试（监视模式）
npm run test:watch

# 运行测试（覆盖率报告）
npm run test:coverage

# 停止Node进程
Get-Process node | Stop-Process -Force
```

### Architecture

**Main File:** `index.js`

**当前架构** (分层设计):
```
├── middleware/          # 中间件层
│   ├── auth.js         # JWT认证
│   ├── errorHandler.js # 错误处理
│   └── rateLimiter.js  # 请求限流
├── routes/             # 路由层
│   ├── auth.js         # 认证路由
│   ├── users.js        # 用户管理
│   └── favorites.js    # 收藏管理
├── controllers/        # 控制器层
│   ├── authController.js
│   ├── userController.js
│   └── favoriteController.js
├── services/           # 服务层（业务逻辑）
│   ├── userService.js
│   ├── emailService.js
│   └── favoriteService.js
├── utils/              # 工具函数
│   ├── logger.js       # Winston日志
│   └── response.js     # 统一响应格式
└── tests/              # 单元测试
    ├── setup.js        # 测试环境配置
    ├── config/         # 配置测试
    ├── middleware/     # 中间件测试
    └── services/       # 服务层测试
```

**Phase 1 新增架构** (开发中):
```
├── services/
│   ├── bilibiliService.js    ← 新增：B站API集成
│   └── audioService.js        ← 新增：音频元数据管理
├── routes/
│   ├── bilibili.js            ← 新增
│   └── audio.js               ← 新增
├── controllers/
│   ├── bilibiliController.js  ← 新增
│   └── audioController.js     ← 新增
└── models/
    └── BilibiliAccount.js     ← 新增：数据模型
```

**核心组件:**

- **Express Server** - REST API框架
- **better-sqlite3** - SQLite 数据库（同步 API，高性能）
- **Authentication System:**
  - JWT tokens for authentication
  - bcrypt with 10 salt rounds for password hashing
- **CORS Middleware** - 跨域资源共享
- **Winston Logger** - 日志管理系统
- **Jest** - 单元测试框架

**数据库配置:**
```javascript
// 使用 SQLite 作为数据存储
// 数据库文件: listen-vision_api/data/listenvision.db
// 支持外键约束、事务处理
// 测试时使用内存数据库 (:memory:)
```

**Key Dependencies:**
- **express** (^5.1.0) - Web framework
- **better-sqlite3** (^12.6.0) - SQLite database (synchronous API)
- **bcrypt** (^5.1.1) & **bcryptjs** (^3.0.2) - Password hashing
- **jsonwebtoken** (^9.0.3) - JWT authentication
- **cors** (^2.8.5) - CORS middleware
- **nodemailer** (^7.0.3) - Email sending
- **dotenv** (^16.5.0) - Environment variables
- **winston** (^3.19.0) - 日志管理
- **swagger-jsdoc** (^6.2.8) - API documentation
- **swagger-ui-express** (^5.0.1) - API UI
- **jest** (^30.2.0) - Testing framework (dev)

### API Endpoints

**已实现的端点:**
- `POST /api/auth/register` - 用户注册
- `POST /api/auth/login` - 用户登录
- `GET /api/auth/me` - 获取当前用户信息
- `POST /api/auth/send-code` - 发送验证码
- `POST /api/auth/verify-code` - 验证验证码
- `POST /api/auth/reset-password` - 重置密码
- `GET /api/users` - 获取所有用户
- `PUT /api/users/:id` - 更新用户
- `GET /api/favorites` - 获取收藏列表
- `POST /api/favorites` - 添加收藏
- `DELETE /api/favorites/:id` - 删除收藏
- `GET /health` - 健康检查
- `GET /api-docs` - Swagger API文档

**Phase 1 新增端点** (开发中):
- `POST /api/bilibili/qrcode` - 获取QR码登录凭证
- `POST /api/bilibili/qrcode/check` - 检查QR码登录状态
- `DELETE /api/bilibili/unbind` - 解绑B站账号
- `GET /api/bilibili/status` - 获取绑定状态
- `GET /api/bilibili/video/:bvid` - 获取视频信息
- `GET /api/bilibili/audio/:bvid` - 获取音频流URL
- `GET /api/bilibili/uploader/:mid` - 获取UP主视频列表
- `GET /api/audio/search` - 搜索B站音频
- `GET /api/audio/metadata/:bvid` - 获取缓存的元数据

### Security Notes

**安全特性:**
- ✅ 使用bcrypt进行密码哈希（10轮加密）
- ✅ JWT-based认证
- ✅ CORS已启用用于跨域请求
- ✅ 请求限流（防止API滥用）
- ✅ 参数验证（express-validator）
- ✅ 统一错误处理（不暴露敏感信息）
- ⚠️ 数据库凭证应移至环境变量

**Phase 1 安全增强:**
- 🔒 Cookie加密存储（AES-256-CBC）
- 🔒 B站API请求限流
- 🔒 敏感信息日志脱敏

---

## Project Relationships

**frontend_flutter** (Flutter app) and **listen-vision_api** (Node.js backend) form the ListenVision application stack:
- Flutter app communicates with the Express backend API
- Backend manages SQLite database for user data and authentication
- Flutter app handles audio playback, downloads, and UI

**bilibili-API-collect** is a completely separate project for API documentation and is not related to the ListenVision app.

---

## Development Workflow

### Windows PowerShell 环境

**在Windows环境下开发时，优先使用PowerShell命令**：

```powershell
# 查看目录结构
Get-ChildItem -Path "A:\Projects\Projects_ListenVison" -Directory

# 搜索文件
Get-ChildItem -Path "A:\Projects\Projects_ListenVison" -Recurse -Filter "*.js" | Select-String -Pattern "function"

# 查看进程
Get-Process node

# 停止进程
Stop-Process -Name node -Force
```

### ListenVision 开发流程

**后端开发**:
1. 修改 `listen-vision_api/services/` 或其他文件
2. 停止现有Node进程：`Get-Process node | Stop-Process -Force`
3. 重启服务器：`node index.js`

**Flutter开发**:
1. 修改 `lib/` 目录下的文件
2. 运行 `flutter run` 测试
3. 开发过程中按 `r` 热重载

**测试**:
- 后端：`npm test`
- Flutter：`flutter test`

### B站API查询流程

**需要查询B站API时**：
1. 使用 Grep 工具在本地 `bilibili-API-collect` 文档中搜索
2. 使用 Read 工具读取相关 Markdown 文件
3. 仅在本地文档无法满足时才使用网页搜索

---

## Common Issues

### Flutter Desktop Database
- Desktop platforms require `databaseFactoryFfi` initialization
- Ensure `sqflite_common_ffi` is properly configured in `main.dart`

### API Connection
- Flutter app needs to know the backend API URL (likely in `config/` or `api_service.dart`)
- Ensure backend is running before testing Flutter app
- Check CORS settings if facing cross-origin issues

### Permission Handling
- Android requires runtime permissions (storage, etc.)
- First launch requests permissions automatically
- Use `permission_handler` package for additional permissions

---

## Additional Resources

- **Flutter Documentation:** https://flutter.dev/docs
- **Provider Package:** https://pub.dev/packages/provider
- **go_router:** https://pub.dev/packages/go_router
- **VuePress:** https://vuepress.vuejs.org/
- **Express:** https://expressjs.com/

---

## 📚 Bilibili API 参考资源

### bilibili-API-collect 项目（本地克隆）

**Location**: `A:\Projects\Projects_ListenVison\bilibili-API-collect\`

**说明**: 这是 B站API的权威文档项目，已克隆到本地，开发时优先查阅本地文档。

- **GitHub 仓库**: https://github.com/SocialSisterYi/bilibili-API-collect
- **本地路径**: `A:\Projects\Projects_ListenVison\bilibili-API-collect\`
- **开源协议**: CC-BY-NC 4.0 (仅限非商业使用)

#### 项目简介

bilibili-API-collect 是一个社区驱动的开源项目,旨在对 B站 WEB、APP、TV 等客户端中散落的 API 进行收集整理,并研究使用方法。项目采用多种研究方法:
- 黑箱法
- 控制变量法
- 代码逆向分析
- 拆包及反编译法
- 网络抓包法

#### 本地文档结构 ⭐⭐⭐⭐⭐

**使用建议**:
1. **优先使用本地文档** - 路径：`A:\Projects\Projects_ListenVison\bilibili-API-collect\docs\`
2. **使用 Grep 工具搜索** - 快速定位相关API
3. **使用 Read 工具阅读** - 查看完整的API说明和示例

**核心API文档分类**:

| 分类 | 本地路径 | 说明 |
|------|----------|------|
| **认证相关** | `docs/login/` | QR码登录、Cookie管理 |
| **视频相关** | `docs/video/` | 视频信息、播放地址 |
| **音频相关** | `docs/audio/` | 音频流、榜单 |
| **用户相关** | `docs/user/` | 用户信息、关注关系 |
| **搜索相关** | `docs/search/` | 视频/音频搜索 |

**Phase 1 常用文档**:
- QR码登录：`docs/login/login_action/QR.md`
- 视频信息：`docs/video/video_info.md`
- 音频流：`docs/audio/audio_stream.md`
- 搜索：`docs/search/search.md`

#### ListenVision 项目中的使用

**Phase 1 实现的API**:

| 功能 | API端点 | 服务层实现 |
|------|---------|-----------|
| QR码登录 | `POST /api/bilibili/qrcode` | `bilibiliService.getQRCode()` |
| 检查登录状态 | `POST /api/bilibili/qrcode/check` | `bilibiliService.checkQRLoginStatus()` |
| 视频信息 | `GET /api/bilibili/video/:bvid` | `bilibiliService.getVideoInfo()` |
| 音频流 | `GET /api/bilibili/audio/:bvid` | `bilibiliService.getAudioStream()` |
| UP主视频 | `GET /api/bilibili/uploader/:mid` | `bilibiliService.getUploaderVideos()` |
| 搜索 | `GET /api/audio/search` | `bilibiliService.searchBilibili()` |

#### API 技术规范

- **架构**: C/S 结构
- **接口类型**: REST API、gRPC、WebSocket
- **数据格式**: JSON、Protobuf、XML
- **协议**: 强制使用 HTTPS
- **签名机制**: APP 签名、WBI 签名

**知识点说明**:
- **REST API**: Representational State Transfer,一种软件架构风格
- **gRPC**: Google 开发的高性能 RPC 框架,使用 Protocol Buffers
- **Protobuf**: Protocol Buffers,Google 的数据序列化格式
- **WBI 签名**: B站 的一种请求签名验证机制,防止未授权访问

#### 重要提醒 ⚠️

**使用注意事项**:
1. ⚠️ 本项目仅用于学习和测试,请勿滥用
2. ⚠️ 禁止一切商业使用 (CC-BY-NC 4.0)
3. ⚠️ 上传信息时请脱敏,删除 `SESSDATA`、`bili_jct` 等 Cookie
4. ⚠️ 利用 API 造成不良影响与后果与项目作者无关
5. ⚠️ 项目可能随时停止开发或删档

**频率限制**:
- 建议每分钟请求次数 < 60次
- 避免高频请求同一IP
- 使用缓存减少重复请求

#### 相关社区资源

- **QQ 交流群**: 见项目 GitHub 页面
- **Telegram 群**: @bilibili_API_collect_community
- **贡献指南**: 欢迎提交 PR 和 Issue

#### 推荐相关项目

项目文档还推荐了许多基于 B站 API 的工具和应用:
- **Nemo2011/bilibili-api**: 哔哩哔哩常用 API 调用 (Python)
- **iyear/biligo**: Bilibili API SDK in Golang
- **ddiu8081/blive-message-listener**: B站直播间弹幕监听库
- **the1812/Bilibili-Evolved**: B站增强脚本

#### 在 ListenVision 开发中的应用

**为什么这个项目重要?**

ListenVision 的核心功能依赖 B站 API,而 bilibili-API-collect 提供了:
1. ✅ **完整的 API 文档** - 无需逆向工程即可使用
2. ✅ **详细的参数说明** - 请求/响应格式清晰
3. ✅ **实际示例** - 包含请求示例和响应示例
4. ✅ **定期更新** - API 变化及时更新文档
5. ✅ **社区支持** - 遇到问题可以交流讨论

**开发流程**:
```
1. 需求分析 → 2. 查阅 bilibili-API-collect → 3. 实现服务端API → 4. Flutter调用
```

**当前项目位置**:
```
ListenVision Phase 1 开发流程:
├── 后端开发
│   ├── 查阅 bilibili-API-collect 在线文档
│   ├── 在 bilibiliService.js 实现API调用
│   ├── 在 audioService.js 实现缓存逻辑
│   └── 通过REST API暴露给Flutter
└── Flutter端
    ├── 调用后端API（不再直接调用B站）
    └── 专注于UI和本地播放控制
```

**Phase 1 实施检查清单**:
- [ ] 阅读QR码登录文档
- [ ] 阅读视频信息API文档
- [ ] 阅读音频流API文档
- [ ] 阅读搜索API文档
- [ ] 实现bilibiliService.js
- [ ] 实现audioService.js
- [ ] 添加Cookie加密存储
- [ ] 添加元数据缓存
- [ ] 编写单元测试

---

## 📖 学习资源与进阶阅读

### Flutter 相关 ⭐⭐⭐

#### 官方文档（中文）- **强烈推荐**
- **[Flutter中文官方文档](https://docs.flutter.cn/)** ⭐⭐⭐⭐⭐
  - **入门指南**: 从零开始学习Flutter框架
  - **Widget目录**: 完整的UI组件库文档
  - **Cookbook**: 实用代码片段和解决方案
  - **测试与调试**: 单元测试、集成测试指南
  - **性能优化**: 性能分析和最佳实践
  - **平台集成**: Android/iOS/Web平台特定功能

- **[Dart语言指南](https://dart.cn/guides)**
  - 语言基础：语法、类型系统、异步编程
  - 核心库：集合、Stream、Future使用
  - 高级特性：元编程、反射、隔离（Isolate）

#### 状态管理
- **[Provider状态管理](https://pub.dev/packages/provider)**
  - 官方推荐的状态管理方案
  - 基于InheritedWidget封装
  - 适合中小型应用

- **[Riverpod](https://riverpod.dev/)** (可选)
  - Provider的改进版本
  - 更好的类型安全和测试支持

#### 网络与数据
- **[Dio HTTP客户端](https://pub.dev/packages/dio)**
  - 功能强大的HTTP客户端
  - 支持拦截器、请求取消、文件上传下载

#### 项目特定
- **[go_router](https://pub.dev/packages/go_router)** - 声明式路由
- **[audioplayers](https://pub.dev/packages/audioplayers)** - 音频播放
- **[sqflite](https://pub.dev/packages/sqflite)** - SQLite数据库

### 后端开发

#### Node.js生态
- **[Express.js官方文档](https://expressjs.com/)** (当前使用)
  - 路由、中间件、模板引擎
  - RESTful API最佳实践

- **[Fastify](https://www.fastify.io/)** (可考虑迁移)
  - 性能更好的Node.js框架
  - 内置JSON Schema验证

#### 数据库
- **[SQLite文档](https://www.sqlite.org/docs.html)**
  - SQL语法、索引优化
  - 事务处理、存储引擎
  - better-sqlite3 API: https://github.com/WiseLibs/better-sqlite3

- **[Redis](https://redis.io/docs/)** (推荐添加)
  - 缓存、会话管理
  - 发布订阅、消息队列

#### 最佳实践
- **[Node.js最佳实践](https://github.com/goldbergyoni/nodebestpractices)**
  - 错误处理、安全性
  - 代码风格、项目结构

### API设计

- **[REST API设计指南](https://restfulapi.net/)**
  - 资源命名、HTTP方法
  - 状态码、版本控制

- **[API安全性](https://owasp.org/www-project-api-security/)**
  - 认证授权、数据加密
  - 速率限制、输入验证

### B站开发 ⭐⭐⭐⭐⭐

#### 核心资源
- **[bilibili-API-collect 在线文档](https://socialsisteryi.github.io/bilibili-API-collect/)** ⭐⭐⭐⭐⭐
  - **登录认证**: QR码登录、Cookie管理
  - **视频信息**: 视频元数据、播放地址
  - **音频流**: 音频提取、质量选择
  - **搜索功能**: 视频/音频搜索
  - **UP主API**: 视频列表、动态更新
  - **用户系统**: 用户信息、关注关系

- **[bilibili-API-collect GitHub](https://github.com/SocialSisterYi/bilibili-API-collect)**
  - 提交Issue和PR
  - 查看源代码和示例

#### 使用技巧
1. **查阅顺序**: 先看在线文档，再查GitHub
2. **API变更**: 定期检查项目更新日志
3. **问题反馈**: 遇到API问题可提交Issue

#### 法律声明 ⚠️
- **CC-BY-NC 4.0**: 仅限非商业使用
- **数据安全**: 禁止泄露用户Cookie
- **频率限制**: 遵守B站API调用规范

### 项目架构文档

- **[渐进式架构迁移计划](./docs/INCREMENTAL_MIGRATION_PLAN.md)** ⭐⭐⭐⭐⭐
  - 当前项目架构演进路线图
  - Phase 1-3详细实施步骤
  - 风险评估和应对策略

### 开发工具

- **[VSCode](https://code.visualstudio.com/)**
  - 推荐插件：Flutter、Dart、Code Runner
- **[Git](https://git-scm.com/)**
  - 版本控制和协作

---
