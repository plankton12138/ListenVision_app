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
- 🔐 **安全的认证机制** - JWT Token + 系统级加密存储(Keychain/Keystore)
- 🌍 **跨平台支持** - Android、iOS、Web、Windows、Linux、macOS 全覆盖
- 🎵 **本地音频播放** - 支持导入本地音频文件并管理播放列表
- 📥 **智能下载管理** - 支持多线程下载、断点续传、后台下载
- 🎨 **Material Design** - 简洁优雅的用户界面,支持深色模式

---

## 🏗️ 项目架构

ListenVision 采用前后端分离架构:

```
┌─────────────────────────────────────────────────────────────┐
│                      ListenVision 架构                       │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────────┐         ┌──────────────────┐         │
│  │  Flutter 前端    │◄────────┤  Node.js 后端    │         │
│  │  (frontenf_flutter)        │  (listen-vision_api)        │
│  │                  │         │                  │         │
│  │  • UI/UX         │  REST   │  • 用户认证      │         │
│  │  • 音频播放      │  API    │  • 数据管理      │         │
│  │  • 下载管理      │         │  • 邮件服务      │         │
│  │  • 本地数据库    │         │  • API 代理      │         │
│  └────────┬─────────┘         └────────┬─────────┘         │
│           │                            │                     │
│           │ SQLite                     │ SQLite             │
│           │ (本地数据)                  │ (服务端数据)        │
│           │                            │                     │
│  ┌────────▼─────────┐         ┌────────▼─────────┐         │
│  │  System Keychain │         │   Bilibili API   │         │
│  │  (加密 Cookie)   │         │   (音频资源)      │         │
│  └──────────────────┘         └──────────────────┘         │
└─────────────────────────────────────────────────────────────┘
```

### 技术栈

#### 前端 (Flutter)
- **框架**: Flutter 3.38.5 (Dart 3.10.4)
- **状态管理**: Provider ^6.1.4
- **路由**: go_router ^14.8.1
- **数据库**: sqflite ^2.4.2 (移动端) / sqflite_common_ffi ^2.3.5 (桌面端)
- **网络**: dio ^5.8.0+1
- **音频播放**: audioplayers ^6.4.0
- **加密存储**: flutter_secure_storage ^9.0.0
- **二维码**: qr_flutter ^4.1.0

#### 后端 (Node.js)
- **框架**: Express ^5.1.0
- **数据库**: better-sqlite3 ^12.6.0 (嵌入式SQLite)
- **认证**: bcrypt ^5.1.1 + JWT
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
cd frontenf_flutter

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
├── frontenf_flutter/              # Flutter 前端应用
│   ├── lib/
│   │   ├── main.dart             # 应用入口
│   │   ├── models/               # 数据模型
│   │   │   ├── audio_model.dart
│   │   │   ├── bilibili_account.dart
│   │   │   ├── platform_account.dart
│   │   │   └── user_model.dart
│   │   ├── providers/            # 状态管理
│   │   │   ├── audio_provider.dart
│   │   │   ├── auth_provider.dart
│   │   │   └── theme_provider.dart
│   │   ├── services/             # 业务服务
│   │   │   ├── api_service.dart
│   │   │   ├── download_manager.dart
│   │   │   ├── secure_storage_service.dart
│   │   │   └── file_picker.dart
│   │   ├── routes/               # 路由配置
│   │   ├── ui/                   # 用户界面
│   │   │   ├── pages/            # 页面
│   │   │   └── components/       # 组件
│   │   ├── theme/                # 主题配置
│   │   ├── config/               # 配置文件
│   │   ├── constants/            # 常量定义
│   │   ├── utils/                # 工具函数
│   │   └── exceptions/           # 异常类
│   ├── assets/                   # 资源文件
│   └── pubspec.yaml              # 依赖配置
│
├── listen-vision_api/            # Node.js 后端服务
│   ├── index.js                  # 主服务器文件
│   ├── package.json              # 依赖配置
│   └── node_modules/             # 依赖包
│
├── docs/                         # 项目文档 (可选)
├── PRD.md                        # 产品需求文档
├── CLAUDE.md                     # Claude Code 指导文档
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

#### 登录用户
**账号管理**：
- ✅ 邮箱注册（需邮箱验证）
- ✅ 用户名/密码登录
- ✅ 忘记密码（邮箱验证码找回）

**额外功能**：
- ✅ 创建和管理歌单
- ✅ 收藏音频内容
- ✅ 查看播放历史
- ✅ 个人统计数据

**可选 - Bilibili 账号绑定**：
- ✅ Bilibili 二维码登录
- ✅ 账号绑定与解绑
- ✅ 系统级加密 Cookie 存储
- ✅ 获取 B站 推荐内容
- ✅ 查看关注 UP 主的更新

#### 后端服务
- ✅ 用户注册/登录（JWT 认证）
- ✅ 邮箱验证码服务
- ✅ 密码找回功能
- ✅ 收藏管理 API
- ✅ 歌单管理 API
- ✅ CORS 跨域支持
- ✅ SQLite 数据库（better-sqlite3）
- ✅ B站API集成（QR登录、视频信息、音频流）
- ✅ 音频元数据缓存服务
- ✅ 资源代理服务（解决B站防盗链）

### 规划中功能 🚧

- 🎵 音频可视化 (波形图/频谱图)
- 🎨 简易音频剪辑功能
- 🌐 多语言支持
- 📊 播放历史记录
- 🎵 音乐平台推荐集成
- 📝 播放列表导入/导出
- 🔄 多线程下载优化
- 🎵 在线流式播放 (边下边播)

---

## 🔐 认证架构

### 混合账号体系

ListenVision 采用 **传统账号 + 可选平台绑定** 的混合认证模式:

```
┌─────────────────────────────────────────────────────────────┐
│              ListenVision 认证流程                           │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  用户打开 App                                                │
│      │                                                       │
│      ├─→ [未登录状态] ─────────────────────────┐            │
│      │                                         │            │
│      │   ✅ 可用功能：                          │            │
│      │   • 搜索音频内容                         │            │
│      │   • 下载音频到本地                       │            │
│      │   • 本地音频播放                         │            │
│      │   • 跳转到原内容（B站）                  │            │
│      │                                         │            │
│      └─→ [点击登录] ─────────────────────────┐│            │
│                                              ││            │
│          登录方式选择                        ││            │
│                                              ││            │
│          ┌─────────────┐  ┌─────────────┐  ││            │
│          │ 邮箱密码登录 │  │ 注册新账号   │  ││            │
│          └─────────────┘  └─────────────┘  ││            │
│                  │               │          ││            │
│                  └───────┬───────┘          ││            │
│                          │                 ││            │
│                   登录成功 ✅               ││            │
│                          │                 ││            │
│      ┌───────────────────┼─────────────────┘│            │
│      │                   │                  │            │
│   [登录用户状态]          │                  │            │
│      │                   │                  │            │
│      ├─→ ✅ 额外功能：    │                  │            │
│      │   • 创建和管理歌单 │                  │            │
│      │   • 收藏音频       │                  │            │
│      │   • 查看播放历史   │                  │            │
│      │   • 个人统计       │                  │            │
│      │                   │                  │            │
│      └─→ [可选] 绑定 B站账号 ────────────────┘            │
│                          │                               │
│                      显示 B站 QR 码                       │
│                          │                               │
│                     扫码登录 B站                          │
│                          │                               │
│                   存储 Cookie (加密)                      │
│                          │                               │
│                   ✅ 获取推荐内容                         │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

**技术实现:**

**1. 主账号系统（必需）**
- JWT Token 认证
- 用户名/密码注册和登录
- 邮箱验证机制
- SQLite 数据库存储

**2. 平台绑定系统（可选）**
- 使用 `flutter_secure_storage` 实现系统级加密存储
- 支持 Android Keystore、iOS Keychain、Windows Credential Manager
- B站 Cookie 按用户 ID 隔离,登出自动清除
- 预留扩展接口支持其他平台 (网易云/QQ音乐/Spotify)

**安全特性:**
- ✅ 系统级加密存储
- ✅ JWT Token 自动刷新
- ✅ 密码 bcrypt 加密（10 轮）
- ✅ 日志中敏感信息掩码
- ✅ 防止 Cookie 泄露到 Git 仓库
- ✅ 按用户数据隔离

---

## 📚 Bilibili API 集成

本项目使用 [bilibili-API-collect](https://socialsisteryi.github.io/bilibili-API-collect/) 文档进行开发:

### API 文档资源

- **GitHub**: https://github.com/SocialSisterYi/bilibili-API-collect
- **在线文档**: https://socialsisteryi.github.io/bilibili-API-collect/
- **协议**: CC-BY-NC 4.0 (非商业使用)

### 使用的 API 端点

| 功能 | API 端点 | 说明 |
|------|---------|------|
| 二维码登录 | `/x/passport-tv-login/qrcode/auth_code` | 获取登录二维码 |
| 登录状态查询 | `/x/passport-tv-login/qrcode/poll` | 轮询登录状态 |
| 视频信息 | `/x/web-interface/view` | 获取视频详细信息 |
| 音频流地址 | `/x/player/playurl` | 获取音频下载地址 |
| 搜索 | `/x/web-interface/search/all` | 搜索视频/音频 |

> ⚠️ **注意**: 请勿滥用 API,仅用于学习和测试目的。上传信息时请注意脱敏,删除账户密码、Cookie 等敏感数据。

---

## 🛠️ 开发指南

### 代码规范

- **语言**: 代码注释使用英文,用户文档使用中文
- **命名**: 遵循 Dart 官方命名规范
- **架构**: 遵循 Flutter 官方推荐的架构模式
- **状态管理**: 使用 Provider 模式
- **日志**: 使用 `print()` 或 `debugPrint()`

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

# 运行集成测试
flutter drive --target=test_driver/app.dart

# 代码分析
flutter analyze
```

---

## 🔧 配置说明

### 后端配置

**数据库配置** (`listen-vision_api/config/database.js`):
```javascript
// SQLite 数据库文件位置
const DB_PATH = path.join(__dirname, '../data/listenvision.db');
// 数据库将自动创建，无需手动配置
```

**邮件配置** (QQ 邮箱示例):
```javascript
const transporter = nodemailer.createTransport({
  host: "smtp.qq.com",
  port: 465,
  secure: true,
  auth: {
    user: "your_email@qq.com",
    pass: "your_smtp_token",  // SMTP 授权码,非密码
  },
});
```

### 前端配置

**API 地址** (`frontenf_flutter/lib/config/local_config.dart`):
```dart
class LocalConfig {
  static const String baseUrl = 'http://localhost:3000';
  // 生产环境请修改为实际服务器地址
}
```

---

## 📖 文档索引

- **[PRD.md](./PRD.md)** - 产品需求文档
- **[CLAUDE.md](./CLAUDE.md)** - Claude Code 开发指导文档
- **[frontenf_flutter/README.md](./frontenf_flutter/README.md)** - 前端详细文档 (包含 Bilibili 认证架构)

---

## 🤝 贡献指南

欢迎贡献代码、报告问题或提出建议!

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'feat: 添加某个功能'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

### 贡献规范

- 遵循现有代码风格
- 添加必要的注释和文档
- 确保代码通过 `flutter analyze`
- 测试新功能是否正常工作

---

## ❓ 常见问题

### Q: 为什么选择纯 Bilibili 绑定认证?

**A**: 传统账号系统需要用户记忆额外密码,增加使用门槛。B站 绑定认证可以:
- 降低用户注册门槛
- 减少账号管理工作
- 直接使用 B站 推荐内容
- 避免 Cookie 硬编码的安全风险

### Q: 支持哪些音频格式?

**A**:
- **播放**: MP3, FLAC, WAV, OGG, M4A 等 (基于 audioplayers)
- **下载**: 依赖 B站 提供的格式 (通常是 AAC/MP3)

### Q: 桌面平台如何使用 SQLite?

**A**: 桌面平台 (Windows/Linux/macOS) 使用 `sqflite_common_ffi` 包,需要在 `main.dart` 中初始化 `databaseFactoryFfi`。

### Q: 如何查看完整开发计划?

**A**: 查看 `frontenf_flutter/README.md`,包含 6 个阶段的详细实施计划。

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
- **邮件**: your_email@example.com

---

<div align="center">

**如果觉得这个项目有帮助,请给个 ⭐️ Star 支持一下!**

Made with ❤️ by ListenVision Team

</div>
