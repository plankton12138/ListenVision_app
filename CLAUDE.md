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
Phase 5:  ████████░░░░░░░░░░░░░  40% 质量优化
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

## 相关文档

- 📄 [渐进式架构迁移计划](./docs/INCREMENTAL_MIGRATION_PLAN.md)
- 📄 [Phase实施细节](./docs/PHASE_*.md)
