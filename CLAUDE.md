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

---

## 项目状态

```
MVVM 重构:  ██████████████████████░░  90% (Phase 9/10)

Phase 0:  ✅ 骨架搭建
Phase 1:  ✅ Models 层迁移
Phase 2:  ✅ Services 层构建
Phase 3:  ✅ 数据层构建
Phase 4:  ✅ 核心 ViewModels (Auth)
Phase 5:  ✅ 播放器 ViewModels
Phase 6:  ✅ 其他 ViewModels
Phase 7:  ✅ Views 迁移与解耦
Phase 8:  ✅ Widgets 更新
Phase 9:  ⏳ 清理与收尾
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
# 查看后端日志
Get-Content "A:\Projects\Projects_ListenVison\listen-vision_api\logs\combined.log" -Tail 50
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
services/      # 有状态服务（AudioPlayerService, MetadataService）
viewmodels/    # StateNotifier 状态管理
views/         # 纯 UI 渲染（ConsumerWidget）
core/          # 基础设施（常量、网络、存储）
```

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
