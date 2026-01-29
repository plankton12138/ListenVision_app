# ListenVision 项目修整路线图与实施开发文档

本文件提供前后端统一的修整路线图与可执行实施计划，覆盖目标、阶段、任务拆分、验收标准、资源投入与风险控制。

---

## 1. 目标与范围

**前端（Flutter）**
- 优化 Provider 依赖链，降低初始化复杂度
- 解决 `build_runner` 代码生成同步问题
- 替换模板测试，补充真实用例

**后端（Node/Express）**
- 移除 SQLite 与 MySQL 错误处理逻辑不一致
- 日志脱敏（密码、Token、个人信息）
- 统一日志输出，清除 `console.log`

---

## 2. 路线图总览

| 阶段 | 优先级 | 状态 | 目标 | 关键输出 |
| --- | --- | --- | --- | --- |
| **P0** | 紧急 | ✅ 已完成 | 安全与基础修复 | 错误处理校准、日志脱敏、工具链一致性 |
| **P1** | 高 | ✅ 已完成 | 质量提升 | Provider 链重构、测试替换、API 文档同步、路由守卫 |
| **P2** | 中 | ⏸️ 待执行 | 自动化与持续演进 | CI/Lint 收紧、集成测试、性能评估 |

**P0 完成日期**: 2026-01-27
**P1 完成日期**: 2026-01-27
**P0 Commit**: `73eb7e1` - fix(p0): 后端日志脱敏与SQLite错误处理适配 / 前端Provider配置重构
**P1 Commit**: 待提交 - fix(p1): Provider依赖链优化/测试替换/路由守卫/Swagger文档

---

## 3. 分阶段实施计划

### P0：基础设施与安全修复（1–2 周）✅ 已完成

**目标**：消除安全隐患与环境不一致问题。

**后端任务（BE）**
1. ✅ 移除 `errorHandler` 中 MySQL 错误码（SQLite 环境不匹配）
2. ✅ 日志脱敏：禁止记录密码、token 等敏感字段
3. ✅ 替换 `console.log` → 统一日志组件（index.js, database.js）

**前端任务（FE）**
1. ✅ 统一 `build_runner`/Freezed 版本，消除生成冲突
2. ✅ Provider 配置重构：提取 `ProviderConfig` 类，简化 main.dart

**交付物**
- ✅ 修复后的错误处理模块（SQLite 错误码）
- ✅ 日志脱敏策略与实现（`redactObject` 函数）
- ✅ 统一的代码生成流程说明
- ✅ `lib/core/di/provider_config.dart` 新文件

**验收标准**
- ✅ `errorHandler` 不包含 MySQL 错误码
- ✅ 日志中无明文密码/token
- ✅ `flutter pub run build_runner build` 成功无冲突

**实施详情**：
| 文件 | 修改内容 |
|------|----------|
| `middleware/errorHandler.js` | 移除 MySQL 错误码，添加 `SQLITE_CONSTRAINT` 处理，新增 `redactObject` 脱敏函数 |
| `utils/logger.js` | 导出增强，支持解构导入 |
| `index.js` | 所有 `console.log` 替换为 `logger.info/error/debug` |
| `config/database.js` | 修复 logger 导入路径，SQL verbose 日志集成 |
| `lib/core/di/provider_config.dart` | 新建：封装所有 Provider 依赖注入配置 |
| `lib/main.dart` | 简化：从 ~250 行减少至 ~90 行 |

---

### P1：架构解耦与质量提升（2–4 周）✅ 已完成

**目标**：降低耦合并建立真实测试价值。

**前端任务（FE）**
1. ✅ 重构 Provider 依赖链，目标：层级≤3
2. ✅ 替换模板 `widget_test.dart`，新增真实业务测试
3. ✅ GoRouter 路由参数与守卫规则整理

**后端任务（BE）**
1. ✅ Swagger 文档与接口行为同步
2. ✅ 控制器异常处理统一封装（格式已统一）

**交付物**
- ✅ Provider 重构方案与实现（依赖链 4层→2层）
- ✅ 核心业务单测（10个 ThemeController 测试）
- ✅ 更新后的 API 文档（search.js, recommendations.js）
- ✅ 路由守卫与 404 页面

**验收标准**
- ✅ Provider 注入深度≤3（实际达成 2 层）
- ✅ 核心业务测试全部通过（10/10）
- ✅ Swagger 文档与接口行为一致

**实施详情**：
| 文件 | 修改内容 |
|------|----------|
| `lib/presentation/providers/audio/audio_provider.dart` | 移除 PlayHistoryProvider 依赖，直接使用 HTTP 记录历史 |
| `lib/core/di/provider_config.dart` | AudioProvider 改为 ChangeNotifierProvider，移除 ProxyProvider |
| `lib/presentation/routes/router.dart` | 添加 AppRoutes 常量、登录守卫、歌单详情路由、404 处理 |
| `lib/presentation/pages/not_found_page.dart` | 新建：404 错误页面 |
| `test/widget_test.dart` | 替换模板测试为 ThemeController 单元测试（10个） |
| `routes/search.js` | 添加 @swagger 注释（6个端点） |
| `routes/recommendations.js` | 添加 @swagger 注释（7个端点） |

---

### P2：持续性与自动化（4 周+）

**目标**：建立防回归机制。

**前端任务（FE）**
1. 建立 UI 集成测试（登录/搜索等关键路径）
2. Lint 规则强化（analysis_options.yaml）
3. 网络质量监测策略恢复（维护期结束后评估）

**后端任务（BE）**
1. 数据访问层抽象，为未来扩展数据库预留接口
2. 限流策略压测，形成性能基准

**交付物**
- CI 检查脚本
- 代码风格指南
- 性能评估报告

**验收标准**
- Lint 无告警
- CI 自动通过
- 限流性能满足需求

---

## 4. 资源规划与投入

| 任务 | 建议角色 | 预计人天 | 依赖 |
| --- | --- | --- | --- |
| 错误处理与日志修复 | 后端 | 3 | 无 |
| Provider 重构 | 前端架构 | 5 | P0 完成 |
| 测试建设 | 前/后端 | 4 | 无 |
| 自动化/CI | DevOps | 2 | 环境就绪 |

---

## 5. 风险与应对

| 风险 | 影响 | 应对 |
| --- | --- | --- |
| 重构引发功能回归 | 高 | 分阶段替换 + 单测保障 |
| 生成代码冲突 | 中 | 统一 Flutter/Dart SDK 版本 |
| 日志泄露 | 高 | 日志脱敏 + 安全扫描 |

---

## 6. 验收检查点

- **CP1（P0 完成）**：`error_handler` 无 MySQL 错误码 ✅
- **CP2（P0 完成）**：日志中无敏感字段 ✅
- **CP2+（P0 新增）**：Provider 配置提取到独立类 ✅
- **CP3（P1 完成）**：核心用例测试覆盖 ✅
- **CP4（P1 完成）**：Provider 层级≤3 ✅（实际 2 层）
- **CP5（P2 完成）**：CI 预检查与 Lint 完全通过 ⏸️
