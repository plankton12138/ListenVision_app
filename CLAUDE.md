# CLAUDE.md

**请使用中文回复用户。**

---

## 开发环境

| 项目 | 版本 |
|------|------|
| OS | Windows 11 24H2 |
| Shell | PowerShell（优先用 PowerShell 命令） |
| Flutter | 3.38.5 (Dart 3.10.4) |

---

## 项目结构

```
listen-vision-audio-app/
├── references/                    # 参考文档
│   ├── bilibili-API-collect/     # B站API文档（本地克隆）
│   └── riverpod/                 # Riverpod官方文档（本地克隆）
└── frontend_flutter/              # Flutter 前端（纯前端架构）
    └── lib/
        ├── core/                  # 基础设施（常量、网络、存储）
        ├── models/                # 数据模型（实体）
        ├── data/                  # 数据层（DAO、Repository）
        ├── services/              # 有状态服务（播放器、B站API、认证）
        └── presentation/          # UI 层（ViewModel、View、Widget）
```

> **无后端架构**：App 直接调用 B站 REST API，所有数据存储在本地 SQLite。

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

---

## 常用命令

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
3. **本地优先**：所有数据存储在本地 SQLite，无云端同步

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

## 代码规范

### 日志记录
- **前端**：AppLogger 单例（DEBUG/INFO/WARN/ERROR 四级）

### 开发原则
1. 所有用户操作必须记录日志
2. 关键业务流程必须有开始/结束日志
3. 禁止提交临时调试代码（console.log）和 TODO 注释
4. 敏感信息（password/token）必须脱敏处理

---

## 认证架构

B站 QR 码登录（可选），Cookie 加密存储在 `flutter_secure_storage`。无需注册/登录，全部功能本地可用。

---

## 第三方平台 API 文档

### B站python库
**优先使用本地文档** `\references\bilibili-api-python

---

## 相关文档

- 📄 [Riverpod 使用指南](docs\guides\RIVERPOD_GUIDE.md)
- 📄 [日志记录规范](docs\guides\LOGGING_STANDARDS.md)
- 📄 [代码注释规范](docs\guides\CODE_COMMENT_STANDARDS.md)

---

## 架构决策记录

- **[2026-05-18]** 删除 Python 后端，纯前端架构：BilibiliApiService 直连 B站 REST API，BilibiliAuthService 管理 QR 码登录，FfmpegService (ffmpeg_kit_flutter) 音频格式转换。
- **[2026-03-22]** 播放器架构重构：定义 `AudioPlaybackState` 抽象枚举，Service 层封装 audioplayers 库细节，ViewModel 只依赖抽象状态。
- **[2026-02-16]** 文件完整性检测：启动扫描 + 30分钟轮询 + 播放前验证的三层机制（`DownloadIntegrityService`）。