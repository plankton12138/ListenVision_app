---
name: update-all-docs
description: 更新所有项目文档 (CLAUDE.md, README.md, 阶段文档等)，确保文档与代码实现一致
---

# Update All Project Docs

更新所有项目文档，包括 `CLAUDE.md`、`README.md`、`docs/` 下的阶段文档等。

## 触发时机

当用户说以下类似话语时，此技能自动激活：
- "更新所有文档"
- "更新项目文档"
- "docs are outdated"
- "更新阶段文档"
- "update all docs"

## 工作流程

### 1. 全面检查实现状态

检查以下目录和文件：

| 检查项 | 路径 |
|--------|------|
| 后端服务 | `listen-vision_api/services/` |
| 后端控制器 | `listen-vision_api/controllers/` |
| 后端路由 | `listen-vision_api/routes/` |
| 前端服务 | `frontend_flutter/lib/services/` |
| 阶段文档 | `docs/*.md` |
| 根文档 | `CLAUDE.md`, `README.md` |

### 2. 识别需要更新的内容

| 检查项 | 说明 |
|--------|------|
| 数据库技术 | SQLite vs MySQL vs PostgreSQL |
| 已实现功能 | 对比文档与代码 |
| API 端点 | 验证路由文件 |
| 进度百分比 | 更新各阶段完成度 |
| 过度设计功能 | 识别并移除文档中未实现的复杂功能 |

### 3. 更新文件清单

根据实际变化更新：

| 文件 | 更新内容 |
|------|----------|
| `CLAUDE.md` | 进度、技术栈、当前阶段状态 |
| `README.md` | 技术栈描述、功能列表、项目结构 |
| `docs/PHASE_1_IMPLEMENTATION_DETAILS.md` | 实施细节、API 端点、代码位置 |
| `docs/INCREMENTAL_MIGRATION_PLAN.md` | 迁移计划状态（如需要） |

### 4. 更新原则

**移除过度设计** (文档中存在但代码未实现)：
- Redis 缓存系统
- 灰度发布/AB 测试
- 熔断器模式
- 集群部署
- 分布式追踪

**保留实用功能**：
- Cookie 加密 (AES-256-CBC)
- SQLite 数据库
- WBI 签名机制
- 元数据缓存
- JWT 认证

**添加知识说明**：
- 技术概念解释 (AES-256、CBC、IV、WBI 等)
- 代码位置引用 (file_path:line_number)

### 5. 完成后确认

输出修改摘要，询问是否创建 git commit。

## 示例输出格式

```
项目文档更新完成！

修改摘要：
┌─────────────────────────────────────────────┐
│ CLAUDE.md                                    │
│ - Phase 1 进度: 70% → 100%                   │
│ - 总进度: 25% → 35%                          │
├─────────────────────────────────────────────┤
│ README.md                                    │
│ - 数据库: MySQL → SQLite                     │
│ - 移除 Redis 相关描述                         │
├─────────────────────────────────────────────┤
│ docs/PHASE_1_IMPLEMENTATION_DETAILS.md       │
│ - 重写为 ~370 行（原 ~1150 行）              │
│ - 添加技术知识点说明                          │
└─────────────────────────────────────────────┘

是否创建 git commit？
```

## 注意事项

- 更新前先读取各文件，了解现有结构
- 保持文档简洁实用的风格
- 中文回复用户，技术术语保持英文
- 如仅需更新 CLAUDE.md，使用 `update-claude-md` 技能更高效
