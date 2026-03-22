# CLAUDE.md

**请使用中文回复用户。**

---

## 开发环境

| 项目 | 版本 |
|------|------|
| OS | Windows 11 24H2 |
| Shell | PowerShell（优先用 PowerShell 命令） |
| Node.js | 24.13.0（固定版本，better-sqlite3 需要） |
| Flutter | 3.38.5 (Dart 3.10.4) |

---

## 项目结构

```
listen-vision-audio-app/
├── references/                    # 参考文档
│   ├── bilibili-API-collect/     # B站API文档（本地克隆）
│   └── riverpod/                 # Riverpod官方文档（本地克隆）
├── frontend_flutter/              # Flutter 前端（主项目）
│   └── lib/
│       ├── core/                  # 基础设施（常量、网络、存储）
│       ├── models/                # 数据模型（DTO、实体）
│       ├── data/                  # 数据层（API、DAO、Repository）
│       ├── services/              # 有状态服务（播放器、元数据）
│       └── presentation/          # UI 层（ViewModel、View、Widget）
└── listen-vision-api-python/      # Python 后端（主后端）
```

> **注意**：`listen-vision_api/`（Node.js 后端）已声明为遗留，不再主动维护。

---

## 工作规范

### 工具选择
- 📖 读取文件 → `Read` 工具
- 🔍 搜索内容 → `Grep` 工具
- 📁 查找文件 → `Glob` 工具

### 外部工具限制
- **使用前必须询问**：WebSearch, WebFetch, MCP 工具
- **优先使用**：本地文档、本地代码、`references/bilibili-API-collect`

### 回答风格
- 优先展示设计思路，而非完整代码
- 指向核心代码位置 (`file_path:line_number`)
- 先讲"为什么"，再讲"如何实现"

### 计划制定规范

| 规范 | 说明 |
|------|------|
| 文件路径必须具体 | 所有修改/新建的文件必须标注完整路径 |
| 新建目录需提醒 | 涉及新建目录时必须明确提醒用户确认 |
| 优先扩展现有文件 | 功能扩展优先在现有文件中添加，而非新建 |
| providers.dart 不存实现 | `presentation/providers.dart` 仅用于导出 |

**原则**：不要新建目录，优先扩展现有文件。

---

## 日志位置

| 类型 | 位置 |
|------|------|
| 前端 | `C:\Users\<用户>\Documents\logs\` |
| 后端 | `listen-vision-api-python/logs/` |

---

## 常用命令

### 后端
```bash
cd listen-vision-api-python
uv run uvicorn app.main:app     # 启动
uv run pytest tests/ -v         # 测试
```

### 前端
```bash
cd frontend_flutter
flutter pub get                 # 安装依赖
flutter run                     # 运行
flutter analyze                 # 静态分析
flutter test                    # 测试
dart run build_runner build --delete-conflicting-outputs  # 代码生成
```

---

## 架构设计

### 分层架构 (MVVM + Riverpod)

```
┌─────────────────────────────────────────────────┐
│  Views / Widgets                                │  ← 纯 UI 渲染
├─────────────────────────────────────────────────┤
│  ViewModels (Riverpod StateNotifier)            │  ← 状态管理、业务逻辑
├─────────────────────────────────────────────────┤
│  Services                                       │  ← 有状态服务（播放器）
├─────────────────────────────────────────────────┤
│  Data (Repository, DAO, API Client)             │  ← 数据访问
├─────────────────────────────────────────────────┤
│  Models (Entity, DTO)                           │  ← 数据模型
└─────────────────────────────────────────────────┘
```

### 核心原则

1. **分层解耦**：ViewModel 不直接依赖第三方库，通过 Service 层封装
2. **单向数据流**：UI → ViewModel → Service → 底层库
3. **本地优先**：写操作先更新本地，异步同步到网络

### Service 层封装规范

Service 层负责封装第三方库细节，ViewModel 只依赖抽象接口：

```dart
// ✅ 正确：Service 定义抽象状态枚举
enum AudioPlaybackState { playing, paused, stopped, completed, idle }

// Service 提供转换流
Stream<AudioPlaybackState> get playbackStateStream =>
    _player.onPlayerStateChanged.map(_convertPlayerState);

// ViewModel 使用抽象状态
void _onPlayerStateChanged(AudioPlaybackState state) { ... }

// ❌ 错误：ViewModel 直接依赖第三方库
import 'package:audioplayers/audioplayers.dart';
if (playerState == PlayerState.playing) { ... }
```

---

## 本地优先同步机制

### 核心原则

1. **本地优先**：所有写操作先更新本地数据库，UI 立即响应
2. **异步同步**：网络操作放入同步队列，由 SyncWorker 后台处理
3. **失败重试**：最多重试 3 次，间隔 30 秒
4. **持久化**：App 重启后自动恢复未完成的同步任务

### 数据流

```
用户操作 → 立即更新本地数据库 → UI 刷新
         ↘ 加入同步队列 → SyncWorker → 网络同步
```

---

## 代码规范

### 日志记录
- **后端**：Winston logger（error/warn/info/debug 四级）
- **前端**：AppLogger 单例（DEBUG/INFO/WARN/ERROR 四级）

### 开发原则
1. 所有用户操作必须记录日志
2. 关键业务流程必须有开始/结束日志
3. 禁止提交临时调试代码（console.log）和 TODO 注释
4. 敏感信息（password/token）必须脱敏处理

---

## 认证架构

1. **主账号** (Email/Password + JWT)
2. **平台绑定** (B站QR码，Cookie加密存储)
3. **游客模式** (本地播放，无需登录)

---

## 第三方平台 API 文档

### B站 API
**优先使用本地文档** `references/bilibili-API-collect/docs/`

### QQ音乐 API
**官方文档**: https://developer.y.qq.com/docs/openid#/overview

---

## 相关文档

- 📄 [Riverpod 使用指南](./docs/RIVERPOD_GUIDE.md)
- 📄 [日志记录规范](./docs/LOGGING_STANDARDS.md)
- 📄 [代码注释规范](./docs/CODE_COMMENT_STANDARDS.md)

---

## 架构决策记录

- **[2026-03-22]** 播放器架构重构：定义 `AudioPlaybackState` 抽象枚举，Service 层封装 audioplayers 库细节，ViewModel 只依赖抽象状态。
- **[2026-03-22]** Node.js 后端声明为遗留，主要后端迁移至 Python。
- **[2026-03-14]** Token 自动刷新机制：401 拦截器自动刷新 token 并重试。
- **[2026-02-16]** 文件完整性检测：启动扫描 + 30分钟轮询 + 播放前验证的三层机制（`DownloadIntegrityService`）。