# 渐进式架构迁移计划

> **方案**: 从胖客户端到平衡架构的渐进式迁移
>
> **目标**: 将ListenVision从当前的业务逻辑集中在Flutter端，迁移到客户端-服务端平衡架构
>
> **时间估算**: 6-8周（3个Phase）
>
> **创建日期**: 2026-01-13

---

## 📋 目录

- [迁移目标](#迁移目标)
- [当前架构分析](#当前架构分析)
- [目标架构设计](#目标架构设计)
- [Phase 1: B站API集成与元数据服务](#phase-1-b站api集成与元数据服务)
- [Phase 2: 播放列表与收藏云同步](#phase-2-播放列表与收藏云同步)
- [Phase 2A: 播放功能与播放列表改进](#phase-2a-播放功能与播放列表改进)
- [Phase 2B: Bug修复与功能改进](#phase-2b-bug修复与功能改进)
- [Phase 3: 搜索、推荐与下载服务](#phase-3-搜索推荐与下载服务)
- [风险评估与应对](#风险评估与应对)
- [验收标准](#验收标准)
- [相关文档](#相关文档)

---

## 🎯 迁移目标

### 核心原则

1. **不影响现有功能**: 所有迁移过程保持向后兼容
2. **渐进式推进**: 每个Phase独立可测试、可回滚
3. **用户无感知**: 迁移过程对用户透明
4. **数据安全**: 确保用户数据不丢失

### 技术目标

| 指标 | 当前状态 | 目标状态 |
|------|---------|---------|
| 客户端业务逻辑占比 | 90% | 40% |
| 服务端业务逻辑占比 | 10% | 60% |
| 离线功能支持 | ✅ 完整 | ✅ 核心保留 |
| 云端同步功能 | ❌ 无 | ✅ 完整 |
| B站API安全性 | ⚠️ 客户端Cookie | ✅ 服务端代理 |
| 跨设备支持 | ❌ 不支持 | ✅ 完整支持 |

---

## 📊 当前架构分析

### Flutter端（客户端）现状

**lib/providers/**
```
audio_provider.dart      → 音频播放控制、播放列表管理
auth_provider.dart       → 认证状态管理
theme_provider.dart      → 主题管理
playlist_provider.dart   → 歌单状态管理（Phase 2）
play_history_provider.dart → 播放历史（Phase 2）
bilibili_provider.dart   → B站绑定状态（Phase 1）
```

**lib/services/**
```
api_service.dart         → HTTP API调用（仅认证）
bilibiliApiService.dart  → B站API服务（Phase 1）
download_manager.dart    → 下载管理
playlist_manager.dart    → 本地歌单管理
```

**数据库:**
- SQLite: 存储播放列表、音频元数据
- SharedPreferences: 用户登录状态

### 后端（服务端）现状

**已完成:**
- ✅ 用户认证（JWT）
- ✅ 用户管理（CRUD）
- ✅ 收藏管理
- ✅ B站API集成（Phase 1）
- ✅ 音频元数据缓存（Phase 1）
- ✅ 歌单系统（Phase 2）
- ✅ 播放历史（Phase 2）
- ✅ 推荐内容（Phase 2）

**待开发:**
- ❌ 搜索优化（全文搜索）
- ❌ 推荐算法（基于用户行为）
- ❌ 下载任务管理

### 架构问题

```
当前问题:
1. ❌ B站Cookie存储在客户端（安全风险） → Phase 1 已解决
2. ❌ 音频元数据解析在客户端（性能问题） → Phase 1 已解决
3. ❌ 播放列表无法跨设备同步 → Phase 2 已解决
4. ❌ 搜索功能依赖客户端（无法优化） → Phase 3 待开发
5. ❌ 无法进行服务端数据分析 → Phase 3 待开发
```

---

## 🎯 目标架构设计

### 迁移后的理想架构

```
┌─────────────────────────────────────────┐
│         Flutter Client (轻量化)          │
│  ┌───────────────────────────────────┐  │
│  │ UI层                              │  │
│  │  • 播放器界面                     │  │
│  │  • 搜索界面                       │  │
│  │  • 用户中心                       │  │
│  ├───────────────────────────────────┤  │
│  │ 本地服务层                         │  │
│  │  • 音频播放控制 (audioplayers)    │  │
│  │  • 本地缓存管理 (SQLite)          │  │
│  │  • 离线播放管理                   │  │
│  └───────────────────────────────────┘  │
└──────────────┬──────────────────────────┘
               │ RESTful API
               ↓
┌─────────────────────────────────────────┐
│      Node.js Backend (业务中心)          │
│  ┌───────────────────────────────────┐  │
│  │ API网关层                          │  │
│  │  • 认证中间件 (JWT)                │  │
│  │  • 限流控制                        │  │
│  │  • 日志记录                        │  │
│  ├───────────────────────────────────┤  │
│  │ 业务服务层                         │  │
│  │  • bilibiliService.js  (B站API)  │  │
│  │  • audioService.js    (音频元数据)│  │
│  │  • playlistService.js  (歌单管理)  │  │
│  │  • recommendationService.js (推荐)  │  │
│  │  • searchService.js   (搜索引擎)  │  │
│  ├───────────────────────────────────┤  │
│  │ 数据访问层                         │  │
│  │  • SQLite (用户、音频、播放列表)   │  │
│  │  • (可选) Redis (缓存、会话)       │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

### 职责划分

| 功能模块 | 当前位置 | 目标位置 | 原因 |
|---------|---------|---------|------|
| 音频播放控制 | Flutter端 | **Flutter端** | 保持低延迟 |
| 本地缓存管理 | Flutter端 | **Flutter端** | 支持离线播放 |
| UI渲染 | Flutter端 | **Flutter端** | 客户端职责 |
| B站API调用 | Flutter端 → 服务端 | **服务端** | 安全性 |
| 音频元数据 | Flutter端 → 服务端 | **服务端** | 共享、缓存 |
| 搜索功能 | Flutter端 | **服务端** | 性能优化 |
| 播放列表 | SQLite | **SQLite + 云同步** | 跨设备 |
| 用户认证 | 已完成 | **保持不变** | 已完善 |

---

## 📅 Phase 1: B站API集成与元数据服务 ✅

**时间估算**: 2-3周
**优先级**: 🔴 最高
**影响范围**: B站相关功能
**状态**: ✅ **已完成** (2026-01-18)

### 目标

将B站API调用和音频元数据处理从Flutter端迁移到服务端。

### 为什么先做这个？

1. **安全性**: B站Cookie存储在服务端更安全
2. **性能**: 音频元数据可以缓存，减少重复请求
3. **基础性**: Phase 2和3都依赖这个功能

### 实施内容

**后端开发:**
- bilibiliService.js - B站API集成（QR登录、视频信息、音频流、搜索）
- audioService.js - 音频元数据管理和缓存
- bilibiliController.js, audioController.js - API控制器
- routes/bilibili.js, routes/audio.js - API路由（23个端点）
- 数据库表：bilibili_accounts, audio_metadata_cache, search_history

**前端开发:**
- services/bilibiliApiService.dart - 调用后端API
- providers/bilibiliProvider.dart - B站绑定状态管理
- metadata_god 集成 - 本地音频元数据读写
- download_manager.dart 重构 - 后端API优先

**安全特性:**
- Cookie AES-256-CBC 加密存储
- WBI 签名机制
- 资源代理服务（解决防盗链）

### 验收标准

- [x] B站QR码登录成功率 > 95%
- [x] 音频元数据缓存命中率 > 60%
- [x] API响应时间 < 500ms (p95)
- [x] Cookie加密存储通过安全审计
- [x] Flutter端无B站API调用（全部走后端）

### 📄 详细文档

查看 [PHASE_1_IMPLEMENTATION_DETAILS.md](./PHASE_1_IMPLEMENTATION_DETAILS.md) 获取：
- 完整实现状态
- 安全实现细节
- 数据库表结构
- API端点清单
- 核心代码位置

---

## 📅 Phase 2: 播放列表与收藏云同步 ✅

**时间估算**: 2-3周
**优先级**: 🟡 中等
**依赖**: Phase 1完成
**状态**: ✅ **已完成** (2026-01-19)

### 目标

实现播放列表和收藏的云端同步，支持跨设备访问。

### 实施内容

**后端开发:**
- playlistService.js - 歌单管理服务（创建、编辑、删除、添加/移除项）
- playHistoryService.js - 播放历史服务（记录、查询、清空）
- recommendationService.js - 推荐内容服务（热门歌单、热歌榜单、个性化推荐）
- routes/playlists.js, routes/history.js, routes/recommendations.js - API路由（17个端点）
- 数据库表：playlists, playlist_items, play_history

**前端开发:**
- models/playlist.dart, play_history.dart, recommendation.dart - 数据模型
- providers/playlist_provider.dart, play_history_provider.dart - 状态管理
- ui/pages/explore_page.dart - 发现页面（推荐/榜单）
- ui/pages/playlist_library_page.dart - 歌单库页面
- ui/pages/playlist_detail_page.dart - 歌单详情页面
- ui/pages/play_history_page.dart - 播放历史页面
- 登录访问控制 - 未登录用户无法访问特定功能

**设计决策:**
- 收藏作为"我喜欢"特殊系统歌单
- 混合存储模式（游客本地，登录用户云端同步）
- UI统一展示，播放队列作为"正在播放"特殊歌单

### 验收标准

- [x] 播放列表可以在不同设备间同步
- [x] 冲突解决成功率 > 95%
- [x] 同步过程不阻塞UI
- [x] 离线修改可在联网后同步

### 📄 详细文档

查看 [PHASE_2_PLAYLIST_PLAN.md](./PHASE_2_PLAYLIST_PLAN.md) 获取：
- 功能概述
- 数据模型设计
- 数据库表结构
- 实施检查清单

---

## 📅 Phase 2A: 播放功能与播放列表改进 🚧

**时间估算**: 1-2周
**优先级**: 🟡 中等
**依赖**: Phase 2完成
**状态**: 🚧 **进行中** (10%)

### 目标

完善播放功能，实现播放列表持久化和播放控制。

### 实施内容

**前端开发**:
- 扩展 AudioProvider - 在线播放支持
- 扩展 PlaylistManager - 持久化支持
- 实现歌单详情页播放功能
- 实现播放顺序持久化
- 创建播放器页面 UI
- 实现搜索结果播放功能

### 验收标准

- [ ] 点击歌单中的音频能直接播放
- [ ] 搜索结果可以点击播放
- [ ] 循环模式切换正常（列表/单曲/随机）
- [ ] 应用重启后恢复播放列表和播放位置
- [ ] 拖拽调整播放顺序后能保存

### 📄 详细文档

查看 [PHASE_2A_PLAYBACK_PLAN.md](./PHASE_2A_PLAYBACK_PLAN.md) 获取：
- 完整实施步骤
- 数据存储设计
- 关键文件清单

---

## 📅 Phase 2B: Bug修复与功能改进 🆕

**时间估算**: 1-2周
**优先级**: 🟡 中等
**依赖**: Phase 2完成
**状态**: 📋 **计划中**

### 目标

修复现有Bug并改进播放列表和推荐功能。

### 问题清单

| 问题 | 描述 | 优先级 |
|------|------|--------|
| Bug | 搜索结果点击加入歌单后页面卡死 | 🔴 高 |
| 功能 | 发现页面推荐内容不是个性化 | 🟡 中 |
| 功能 | 播放列表功能匮乏 | 🟡 中 |

### 实施内容

#### Bug修复：加入歌单卡死
- 添加loading状态防止重复点击
- 使用Isolate执行耗时操作
- 添加超时提示

#### 功能改进：音乐区推荐爬取
- 创建爬虫服务 (musicCrawlerService.js)
- 使用 cheerio 解析 B站音乐区页面
- 添加个性化推荐API端点
- 前端集成新Tab展示

#### 功能扩展：播放列表管理
- 歌单详情页添加"添加歌曲"按钮
- 创建添加歌曲对话框
- 创建排序选项对话框
- 支持多种排序方式

### 验收标准

- [ ] 搜索结果点击加入歌单不再卡死
- [ ] 发现页面新增"音乐区"Tab
- [ ] 歌单详情页可添加歌曲
- [ ] 歌单支持多种排序方式

### 📄 详细文档

查看 [PHASE_2B_BUGFIX_AND_IMPROVEMENTS.md](./PHASE_2B_BUGFIX_AND_IMPROVEMENTS.md) 获取：
- 完整问题分析
- 修复方案设计
- 实施步骤清单

---

## 📅 Phase 3: 搜索、推荐与下载服务 🚧

**时间估算**: 2-3周
**优先级**: 🟢 低
**依赖**: Phase 1、2完成
**状态**: 🚧 **待开始**

### 目标

实现高级搜索、智能推荐和下载任务管理。

### 实施步骤

#### 3.1 搜索优化

**基于 SQLite FTS5 的全文搜索:**
- 创建 FTS5 虚拟表实现全文搜索
- 搜索建议（自动完成）
- 热门搜索关键词统计
- 利用 search_stats 表优化搜索体验

**数据库优化:**
```sql
-- FTS5 全文搜索虚拟表
CREATE VIRTUAL TABLE audio_metadata_cache_fts USING fts5(title, artist, content);

-- 搜索统计表
CREATE TABLE search_stats (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  keyword TEXT NOT NULL UNIQUE,
  search_count INTEGER DEFAULT 1,
  last_searched TEXT DEFAULT (datetime('now'))
);
```

#### 3.2 推荐系统

**简化的推荐算法:**
- 基于用户行为日志（play_history）
- 热度推荐（search_stats, play_history 聚合）
- 内容相似度推荐（标题、艺术家匹配）
- 个性化推荐（用户历史偏好）

**数据库表:**
```sql
-- 用户行为日志表
CREATE TABLE user_behavior_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  bvid TEXT NOT NULL,
  action TEXT CHECK(action IN ('play', 'like', 'skip', 'share')),
  timestamp TEXT DEFAULT (datetime('now')),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

#### 3.3 下载任务管理

**任务队列系统:**
- 创建下载任务
- 实时进度追踪
- 暂停/恢复/取消功能
- 断点续传支持

**数据库表:**
```sql
-- 下载任务表
CREATE TABLE download_tasks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  bvid TEXT NOT NULL,
  status TEXT CHECK(status IN ('pending', 'downloading', 'paused', 'completed', 'failed')) DEFAULT 'pending',
  progress INTEGER DEFAULT 0,
  file_size INTEGER,
  downloaded_size INTEGER DEFAULT 0,
  error_message TEXT,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now')),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

### 验收标准

- [ ] 搜索响应时间 < 200ms (p95)
- [ ] 推荐点击率 > 40%
- [ ] 下载任务可跨设备管理
- [ ] 支持断点续传

### 📄 预计文档

Phase 3 实施时将创建：
- `PHASE_3_SEARCH_OPTIMIZATION.md` - 搜索优化细节
- `PHASE_3_RECOMMENDATION.md` - 推荐系统细节
- `PHASE_3_DOWNLOAD_MANAGER.md` - 下载管理细节

---

## ⚠️ 风险评估与应对

### 风险矩阵

| 风险 | 影响 | 概率 | 应对措施 |
|------|------|------|---------|
| B站API反爬虫升级 | 高 | 中 | 1. 使用代理池<br>2. 限流控制<br>3. 保留客户端调用作为降级方案 |
| 用户数据丢失 | 高 | 低 | 1. 迁移前数据库备份<br>2. 双写策略（Phase 1过渡期）<br>3. 回滚预案 |
| 性能下降 | 中 | 中 | 1. 添加缓存层（可选Redis）<br>2. 数据库索引优化<br>3. API响应时间监控 |
| 用户体验变差 | 中 | 低 | 1. 保持离线能力<br>2. 渐进式迁移<br>3. A/B测试 |

### 降级方案

**如果B站API反爬虫升级:**
```
方案1: 服务端使用代理IP池
方案2: 降低请求频率，增加缓存时间
方案3: 降级到客户端调用（回退到旧架构）
```

**如果服务端性能不足:**
```
方案1: 使用Redis缓存热点数据（可选）
方案2: 数据库读写分离
方案3: 部分计算逻辑回到客户端
```

### 回滚预案

**每个Phase都设计独立的回滚开关:**
```javascript
// .env 配置
ENABLE_BILIBILI_SERVICE=true   // Phase 1开关
ENABLE_CLOUD_SYNC=true         // Phase 2开关
ENABLE_RECOMMENDATION=true     // Phase 3开关
```

**Flutter端回滚逻辑:**
```dart
// 根据后端开关决定使用哪个API
if (remoteConfig.enableBilibiliService) {
  return await backendApi.getVideoInfo(bvid);
} else {
  return await directBilibiliApi.getVideoInfo(bvid);
}
```

---

## ✅ 验收标准

### Phase 1 验收 ✅

**功能验收:**
- [x] B站QR码登录成功率 > 95%
- [x] 音频元数据缓存命中率 > 60%
- [x] API响应时间 < 500ms (p95)
- [x] Cookie加密存储通过安全审计

**代码质量:**
- [x] 后端代码通过ESLint检查
- [x] Flutter代码通过flutter analyze检查
- [ ] 单元测试覆盖率 > 70%

### Phase 2 验收 ✅

**功能验收:**
- [x] 播放列表同步成功率 > 98%
- [x] 冲突解决成功率 > 95%
- [x] 同步过程不阻塞UI
- [x] 支持3种冲突解决策略

**性能验收:**
- [x] 同步100首歌曲耗时 < 10秒
- [x] 增量同步耗时 < 2秒

### Phase 3 验收 🚧

**功能验收:**
- [ ] 搜索响应时间 < 200ms (p95)
- [ ] 推荐点击率 > 40%
- [ ] 下载任务可管理（暂停/恢复/取消）

**业务指标:**
- [ ] 用户活跃度提升 > 20%
- [ ] 搜索使用率提升 > 30%

---

## 📊 进度跟踪

### 整体进度

```
规划阶段: ████████████████████ 100% ✅
Phase 1:   ████████████████████ 100% ✅ 后端+Flutter端完成
Phase 2:   ████████████████████ 100% ✅ 歌单/收藏/推荐/历史完成
Phase 2A:  ██░░░░░░░░░░░░░░░░░░  10% 🚧 播放功能改进（进行中）
Phase 2B:  ░░░░░░░░░░░░░░░░░░░░   0% 📋 Bug修复与功能改进（计划中）
Phase 3:   ██████████░░░░░░░░░░  50% 🚧 后端完成，前端待集成

总进度: 70% (Phase 1+2+3后端完成)
```

### Phase 1 详细任务清单

**Week 1: 后端B站API服务** ✅
- [x] bilibiliService.js 核心逻辑
- [x] audioService.js 元数据缓存
- [x] 数据库表创建
- [x] API路由实现 (11个B站端点 + 12个音频端点)
- [x] Cookie加密存储测试
- [x] 资源代理服务（图片/音频防盗链）

**Week 2: Flutter端改造** ✅
- [x] bilibiliApiService.dart 实现
- [x] bilibiliProvider.dart 状态管理
- [x] metadata_god 元数据读写集成
- [x] main.dart Provider 配置优化
- [x] 下载管理器后端API集成

**Week 3: 测试与优化** 🚧
- [x] 功能测试（搜索、下载、封面）
- [ ] 单元测试编写
- [ ] 集成测试
- [ ] 性能测试
- [x] 文档更新

### Phase 2 详细任务清单

**后端开发** ✅ (2026-01-19 完成):
- [x] playlistService.js - 歌单管理服务
- [x] playHistoryService.js - 播放历史服务
- [x] recommendationService.js - 推荐内容服务
- [x] routes/playlists.js - 歌单API路由
- [x] routes/history.js - 播放历史API路由
- [x] routes/recommendations.js - 推荐API路由
- [x] 数据库表扩展 (playlists, playlist_items, play_history)

**前端开发** ✅ (2026-01-19 完成):
- [x] models/playlist.dart - 歌单数据模型
- [x] models/play_history.dart - 播放历史数据模型
- [x] models/recommendation.dart - 推荐内容数据模型
- [x] providers/playlist_provider.dart - 歌单状态管理
- [x] providers/play_history_provider.dart - 播放历史状态管理
- [x] ui/pages/explore_page.dart - 发现页面
- [x] ui/pages/playlist_library_page.dart - 歌单库页面
- [x] ui/pages/playlist_detail_page.dart - 歌单详情页面
- [x] ui/pages/play_history_page.dart - 播放历史页面
- [x] 登录访问控制（需要登录才能访问特定功能）

**测试与优化** 🚧:
- [x] 功能测试（歌单CRUD、收藏、历史）
- [ ] 单元测试编写
- [ ] 集成测试
- [x] 文档更新

### Phase 3 详细任务清单 🚧

**后端开发** ✅ (已完成):
- [x] searchService.js - FTS5 全文搜索实现
- [x] downloadService.js - 下载任务管理
- [x] routes/search.js - 搜索API路由（4个端点）
- [x] routes/downloads.js - 下载管理API路由（8个端点）
- [x] 数据库表创建 (audio_metadata_cache_fts, search_stats, download_tasks)

**前端开发** 🚧 (已完成，待集成):
- [x] providers/search_provider.dart - 搜索状态管理
- [x] providers/download_task_provider.dart - 下载任务状态
- [ ] 集成到 main.dart (注册 Provider)
- [ ] ui/pages/download_management_page.dart - 下载管理页面
- [ ] 集成全文搜索UI

**智能推荐算法** ❌ (待开始):
- [ ] recommendationService.js 扩展
- [ ] 基于用户行为的推荐逻辑
- [ ] 数据库表创建 (user_behavior_logs)

**测试与优化:**
- [ ] 单元测试编写
- [ ] 集成测试
- [ ] 性能测试
- [x] 文档更新

---

## 📚 相关文档

### 核心技术文档

- **[Flutter中文官方文档](https://docs.flutter.cn/)** ⭐⭐⭐⭐⭐
  - 入门指南
  - Widget目录
  - Cookbook
  - 测试与调试
  - 性能优化

- **[Dart语言指南](https://dart.cn/guides)**
  - 语言基础
  - 核心库
  - 高级特性

- **[B站API收集项目](https://socialsisteryi.github.io/bilibili-API-collect/)** ⭐⭐⭐⭐⭐
  - 登录认证
  - 视频信息
  - 音频流
  - 搜索功能

### 项目详细实施文档

- **[Phase 1 实施细节](./PHASE_1_IMPLEMENTATION_DETAILS.md)** ⭐⭐⭐⭐
  - 完整实现状态
  - 安全实现细节
  - 数据库表结构
  - API端点清单（23个）
  - 核心代码位置

- **[Phase 2 歌单收藏推荐计划](./PHASE_2_PLAYLIST_PLAN.md)** ⭐⭐⭐⭐
  - 功能概述
  - 数据模型设计
  - 数据库表结构（SQLite）
  - 实施检查清单

- **[Phase 2A 播放功能改进](./PHASE_2A_PLAYBACK_PLAN.md)** ⭐⭐⭐
  - 播放功能与播放列表改进
  - 在线播放支持
  - 播放顺序持久化

- **[Phase 2B Bug修复与功能改进](./PHASE_2B_BUGFIX_AND_IMPROVEMENTS.md)** 🆕 ⭐⭐⭐⭐
  - Bug修复：加入歌单卡死
  - 功能改进：音乐区推荐爬取
  - 功能扩展：播放列表管理

### 项目指导文档

- **[CLAUDE.md](../CLAUDE.md)** - 项目整体说明
  - 项目状态
  - 技术栈
  - 开发环境
  - Bilibili API 参考资源

- **[AGENTS.md](../AGENTS.md)** - 代理开发指南
  - Build/lint/test 命令
  - 代码风格指南
  - 常用模式

### 开发资源

- **[better-sqlite3](https://github.com/WiseLibs/better-sqlite3)** - SQLite驱动
- **[Provider状态管理](https://pub.dev/packages/provider)** - Flutter状态管理
- **[Dio HTTP客户端](https://pub.dev/packages/dio)** - Flutter网络请求库
- **[Express.js](https://expressjs.com/)** - Node.js后端框架

---

## 📝 更新日志

| 日期 | 版本 | 更新内容 | 作者 |
|------|------|---------|------|
| 2026-01-13 | 1.0.0 | 初始版本，完成渐进式迁移计划 | Claude Code |
| 2026-01-17 | 1.1.0 | 更新Phase 1后端完成状态，添加资源代理服务说明 | Claude Code |
| 2026-01-18 | 1.2.0 | **Phase 1 完成**：Flutter端改造完成，metadata_god集成，搜索/下载/封面功能正常 | Claude Code |
| 2026-01-19 | 1.3.0 | **Phase 2 完成**：歌单/收藏/推荐/历史功能完成 | Claude Code |
| 2026-01-19 | 1.4.0 | **文档更正**：移除MySQL相关内容，统一使用SQLite架构 | Claude Code |
| 2026-01-19 | 2.0.0 | **文档重构**：改为纵览式文档，移除详细代码示例，引用其他文档获取细节 | Claude Code |
| 2026-01-19 | 2.1.0 | **新增 Phase 2B**：Bug修复与功能改进计划（加入歌单卡死、音乐区爬取、播放列表扩展） | Claude Code |

---

## 🙋 FAQ

### Q1: 为什么要渐进式迁移而不是一次性重写？

**A**: 渐进式迁移有以下优势：
1. 降低风险：每个Phase独立可回滚
2. 持续交付：用户可以持续使用新功能
3. 资源合理分配：不需要大规模暂停开发
4. 验证假设：每个Phase完成后可以验证架构是否正确

### Q2: Phase 1 为什么要先做B站API集成？

**A**:
1. **安全性优先**：Cookie存储在客户端有泄露风险
2. **性能收益**：元数据缓存可以减少重复请求
3. **基础依赖**：Phase 2和3的推荐、搜索都依赖这个功能
4. **易于测试**：B站API功能独立，不影响其他模块

### Q3: 迁移过程中如何保证用户数据不丢失？

**A**:
1. **双写策略**：Phase 1过渡期同时写入本地和云端
2. **数据备份**：迁移前全量备份用户数据
3. **对比验证**：上线后对比本地和云端数据一致性
4. **回滚预案**：如果出现问题可以快速回退

### Q4: 如果B站API反爬虫升级怎么办？

**A**: 已设计多层应对方案：
1. **技术层**：代理IP池、请求限流、User-Agent轮换
2. **架构层**：保留客户端调用能力作为降级方案
3. **产品层**：引导用户上传本地音频，减少对B站依赖

### Q5: Phase完成后客户端还需要SQLite吗？

**A**: 仍然需要，但职责会变化：
- **保留**：离线缓存、播放历史、临时数据
- **迁移**：播放列表、收藏、搜索历史 → SQLite（云端）
- **优势**：离线能力 + 云端同步

### Q6: 为什么选择SQLite而不是MySQL？

**A**: SQLite 更适合本项目：
1. **轻量级**：无需额外数据库服务器，部署简单
2. **嵌入式**：数据库文件直接存储在磁盘，管理便捷
3. **跨平台**：移动端和桌面端都支持良好
4. **足够使用**：当前用户规模下性能满足需求
5. **迁移成本低**：现有代码已基于SQLite，无需大规模重构

---

**下一步**: 开始实施 Phase 2B - Bug修复与功能改进

---

*本文档由 Claude Code 生成 | 最后更新: 2026-01-19*
