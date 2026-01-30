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
├── bilibili-API-collect/     # B站API文档（本地克隆）
├── frontend_flutter/          # Flutter应用
│   └── lib/
│       ├── core/              # 基础设施（常量、错误、网络）
│       ├── domain/           # 实体 + 仓储接口
│       ├── data/             # 数据源 + 仓储实现
│       └── presentation/     # 页面 + Provider + 路由
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
**优先使用**: 本地文档、本地代码、bilibili-API-collect

### 回答风格
- 优先展示设计思路，而非完整代码
- 指向核心代码位置 (`file_path:line_number`)
- 先讲"为什么"，再讲"如何实现"
- 完成工作后对话形式总结，不要自动创建文档

---

## 项目状态

```
Phase 1:  ████████████████████ 100% ✅ B站API集成
Phase 2:  ████████████████████ 100% ✅ 在线播放
Phase 3:  ████████████████████ 100% ✅ 歌单收藏
Phase 4:  ███████████████░░░░░  70% 🟡 搜索推荐
Phase 5:  ████████████░░░░░░░░  65% 🟡 质量优化
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

**优先使用本地文档** `bilibili-API-collect/docs/`，而非网页搜索。

核心文档：
- 登录: `docs/login/login_action/QR.md`
- 视频: `docs/video/video_info.md`
- 音频: `docs/audio/audio_stream.md`

---

## 认证架构

1. **主账号** (Email/Password + JWT)
2. **平台绑定** (B站QR码，Cookie加密存储)
3. **游客模式** (本地播放，无需登录)

---

## Clean Architecture (已100%完成)

```
domain/      # 业务规则（实体、仓储接口）
data/        # 数据操作（数据源、仓储实现）
presentation/ # UI（页面、Provider、路由）
core/        # 基础设施（常量、错误、网络）
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

- 📄 [渐进式架构迁移计划](./docs/INCREMENTAL_MIGRATION_PLAN.md)
- 📄 [Phase实施细节](./docs/PHASE_*.md)
