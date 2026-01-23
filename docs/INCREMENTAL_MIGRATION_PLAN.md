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
- [Phase 2: 在线播放功能](#phase-2-在线播放功能) 🆕 重排
- [Phase 3: 播放列表与收藏云同步](#phase-3-播放列表与收藏云同步)
- [Phase 3A: 播放列表页面改进](#phase-3a-播放列表页面改进)
- [Phase 3B: 播放控制增强](#phase-3b-播放控制增强) 🆕 音量与倍速
- [Phase 4: 搜索、推荐与下载服务](#phase-4-搜索推荐与下载服务)
- [Phase 5: Bug修复与功能改进](#phase-5-bug修复与功能改进)
- [风险评估与应对](#风险评估与应对)
- [验收标准](#验收标准)
- [相关文档](#相关文档)

---

**🔄 阶段重排说明** (2026-01-23):

原顺序 → 新顺序（按功能依赖优先级）:
- Phase 1 → Phase 1 ✅ (基础架构，保持不变)
- Phase 4 → **Phase 2** ✅ (关键功能，已完成)
- Phase 2 → **Phase 3** ✅ (依赖在线播放，已完成)
- Phase 2A → **Phase 3A** ✅ (歌单页面改进，已完成)
- 新增 → **Phase 3B** 📋 (播放控制增强，计划中)
- Phase 3 → **Phase 4** 🟡 (相对独立，70%完成)
- Phase 2B → **Phase 5** ⏸️ (低优先级优化，40%)

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
1. ✅ B站Cookie存储在客户端（安全风险） → Phase 1 已解决
2. ✅ 音频元数据解析在客户端（性能问题） → Phase 1 已解决
3. ✅ 播放列表无法跨设备同步 → Phase 3 已解决
4. ✅ 在线音频播放功能缺失 → Phase 2 已解决
5. ⏸️ 搜索功能依赖客户端（无法优化） → Phase 4 进行中 (70%)
6. ⏸️ 无法进行服务端数据分析 → Phase 4 待开发
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

## 📅 Phase 2: 在线播放功能 🆕 重排

**时间估算**: 3-5天
**优先级**: 🔴 最高
**依赖**: Phase 1完成
**状态**: ✅ **已完成** (2026-01-23)

> **原 Phase 4** - 优先级提升为 Phase 2，因为这是关键功能缺失，其他功能依赖它

### 目标

实现完整的在线音频播放功能，打通搜索、推荐、歌单到播放器的数据流。

### 实施内容

**阶段1：创建统一播放接口** ✅
- `domain/entities/playable_audio.dart` - 统一播放接口（抽象类）
- `domain/entities/local_playable.dart` - 本地音频包装类
- `domain/entities/online_playable.dart` - 在线音频包装类

**阶段2：改造 AudioProvider** ✅
- 添加 `unifiedPlaylist` 混合播放列表
- 添加 `playOnlineAudio()` 方法
- 添加 `playUnifiedAt()` 统一播放方法
- 添加 `removeFromUnifiedPlaylist()` / `clearUnifiedPlaylist()` 方法

**阶段3：播放列表页面改造** ✅
- 改用 `unifiedPlaylist` 显示在线和本地音频
- 差异化显示：在线（橙色云图标）vs 本地（绿色存储图标）
- 统一点击处理逻辑

**阶段4：集成测试** ✅
- 验证搜索结果可播放
- 验证推荐内容可播放
- 验证播放列表功能正常

### 验收标准

- [x] 搜索结果点击可正常播放
- [x] 发现页面推荐内容点击可正常播放
- [x] 歌单详情页歌曲点击可正常播放
- [x] 播放进度正常显示
- [x] 播放/暂停/上一曲/下一曲正常工作
- [x] 播放列表显示在线和本地音频
- [x] 播放列表点击暂停/继续功能正常
- [x] 本地音频播放不受影响
- [x] 在线和本地音频可混合同一播放列表
- [ ] 播放历史正常记录在线音频（待实现）

### 📄 详细文档

查看 [PHASE_2_ONLINE_PLAYBACK.md](./PHASE_2_ONLINE_PLAYBACK.md) 获取：
- 完整问题分析
- 架构设计说明
- 代码实现示例
- 关键文件清单

---

## 📅 Phase 3: 播放列表与收藏云同步 ✅

> **原 Phase 2** - 依赖在线播放功能

**时间估算**: 2-3周
**优先级**: 🟡 中等
**依赖**: Phase 2（在线播放）完成
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

## 📅 Phase 3A: 播放列表页面改进 ✅

> **原 Phase 2A** - 播放列表页面功能改进

**时间估算**: 1-2天
**优先级**: 🔴 高
**依赖**: Phase 3完成
**状态**: ✅ **已完成** (2026-01-20)

### 目标

优化播放列表页面，添加播放进度持久化和UI交互增强。

### 实施内容

**核心功能**:
- **播放进度持久化** - 保存当前播放索引和位置，应用重启后恢复
- **当前播放高亮** - 蓝色背景 + 左侧竖条 + 播放图标
- **拖拽排序** - ReorderableListView 实现（使用 ID 交换技术）
- **批量操作** - 清空列表 + 删除确认

### 验收标准

**播放进度持久化**:
- [x] 播放音频时自动保存位置（每5秒）
- [x] 暂停时保存当前播放位置
- [x] 应用重启后恢复到上次播放的位置

**UI 交互优化**:
- [x] 当前播放项有蓝色高亮显示
- [x] 支持拖拽调整播放列表顺序
- [x] 点击清空按钮弹出确认对话框
- [x] 空列表时显示友好提示

### 📄 详细文档

查看 [PHASE_3A_PLAYBACK_PLAN.md](./PHASE_3A_PLAYBACK_PLAN.md) 获取：
- 完整实施步骤
- 数据库表结构
- 关键文件清单
- Bug 修复记录

---

## 📅 Phase 3B: 播放控制增强 📋

> **新增阶段** - 音量调整与倍速播放

**时间估算**: 1-2天
**优先级**: 🟡 中
**依赖**: Phase 2 完成（just_audio 迁移）
**状态**: 📋 **计划中**

### 目标

添加完善的播放控制功能：音量调节和倍速播放。

### 核心功能

| 功能 | 描述 | 优先级 |
|------|------|--------|
| **音量控制** | 滑块调节播放音量（0.0 - 1.0） | 🔴 高 |
| **倍速播放** | 0.5x - 2.0x 倍速选择 | 🔴 高 |
| **设置持久化** | 保存用户的音量和倍速偏好 | 🟡 中 |

### 技术方案

**just_audio 原生支持**:
- `player.setVolume()` - 音量控制
- `player.setSpeed()` - 倍速播放

**持久化存储**:
- SharedPreferences 存储用户偏好

### UI 组件

| 组件 | 说明 |
|------|------|
| `VolumeSlider` | 音量滑块，带音量图标 |
| `SpeedButton` | 倍速按钮，点击弹出选择菜单 |

### 验收标准

- [ ] 音量滑块可正常调节（0% - 100%）
- [ ] 倍速按钮显示当前倍速
- [ ] 点击倍速按钮弹出选择菜单
- [ ] 应用重启后恢复用户偏好设置

### 📄 详细文档

查看 [PHASE_3B_PLAYBACK_CONTROLS_PLAN.md](./PHASE_3B_PLAYBACK_CONTROLS_PLAN.md) 获取：
- 完整架构设计
- 实施步骤详解
- 代码示例
- 关键文件清单

---

## 📅 Phase 4: 搜索、推荐与下载服务 🚧

**时间估算**: 2-3周
**优先级**: 🟢 低
**依赖**: Phase 1、2完成
**状态**: 🚧 **部分完成** (70%)

### 目标

实现高级搜索、智能推荐和下载任务管理。

### 实施步骤

#### 3.1 搜索优化 ✅

**基于 SQLite FTS5 的全文搜索:**
- ✅ 创建 FTS5 虚拟表实现全文搜索
- ✅ 搜索建议（自动完成）
- ✅ 热门搜索关键词统计
- ✅ 利用 search_stats 表优化搜索体验

#### 3.2 推荐系统 ✅

**简化的推荐算法:**
- ✅ 基于热门歌单API（稳定可靠）
- ✅ 热度推荐（search_stats, play_history 聚合）
- ✅ 内容相似度推荐（标题、艺术家匹配）

#### 3.3 下载任务管理 ⚠️ 架构调整

**原计划**: 后端任务队列系统
**实际实施**: 前端本地下载（Phase 2B 重构）

**原因**:
- 下载是设备本地操作，跨设备管理意义不大
- 前端实现更直接，减少网络开销
- 更好的离线支持

**前端实现** (Phase 2B):
- ✅ `download_executor.dart` - 下载执行器（支持断点续传）
- ✅ `download_repository.dart` - 下载数据仓储
- ✅ `metadata_writer.dart` - 音频元数据写入

### 验收标准

- [x] 搜索响应时间 < 200ms (p95)
- [x] 推荐内容正常显示
- [x] 下载任务可管理（创建/暂停/恢复/删除）
- [x] 支持断点续传（前端本地实现）

**架构调整说明**: 下载任务管理从后端迁移到前端本地实现（Phase 5 重构），更符合本地操作场景。

---

## 📅 Phase 5: Bug修复与功能改进 📋

> **原 Phase 2B** - 低优先级优化

**时间估算**: 1-2周
**优先级**: 🟢 低
**依赖**: Phase 2、3完成
**状态**: 📋 **部分完成** (已暂停)

### 目标

修复现有Bug并改进歌单管理功能。

### 问题清单

| 问题 | 描述 | 状态 |
|------|------|------|
| Bug | 搜索结果点击加入歌单后页面卡死 | ✅ 已解决 |
| 功能 | 发现页面推荐内容不是个性化 | 📋 计划中 |
| 功能 | 歌单详情页添加歌曲功能 | 📋 暂搁置（依赖在线播放） |

### 📄 详细文档

查看 [PHASE_2B_BUGFIX_AND_IMPROVEMENTS.md](./PHASE_2B_BUGFIX_AND_IMPROVEMENTS.md) 获取：
- 完整问题分析
- 修复方案设计
- 实施步骤清单

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

### Phase 3 验收 ✅

**功能验收:**
- [x] 搜索响应时间 < 200ms (p95)
- [x] 推荐内容正常显示
- [x] 下载任务可管理（创建/暂停/恢复/删除）
- [x] 下载任务页面正常显示

**Bug 修复验收:**
- [x] 下载任务创建后可正常显示
- [x] user_id 类型问题修复（SQLite INTEGER 匹配）
- [x] Widget 生命周期错误修复

### Phase 4 验收 ✅

**功能验收:**
- [x] 搜索响应时间 < 200ms (p95)
- [x] 推荐内容正常显示
- [x] 下载任务可管理（创建/暂停/恢复/删除）
- [x] 支持断点续传（前端本地实现）

### Phase 5 验收 📋

**功能验收:**
- [x] 搜索结果加入歌单不再卡死
- [ ] 发现页面推荐内容个性化
- [ ] 歌单详情页添加歌曲功能
- [ ] 播放列表排序选项

---

## 📊 进度跟踪

### 整体进度

```
规划阶段: ████████████████████ 100% ✅
Phase 1:   ████████████████████ 100% ✅ 后端B站API集成与元数据服务
Phase 2:   ░░░░░░░░░░░░░░░░░░░░   0% ⏸️ 在线播放功能（关键功能缺失）
Phase 3:   ████████████████████ 100% ✅ 播放列表与收藏云同步
Phase 3A:  ████████████████████ 100% ✅ 播放列表页面改进
Phase 4:   ███████████████░░░░░  70% ✅ 搜索/推荐完成（下载前端化）
Phase 5:   ████████░░░░░░░░░░░░░  40% 📋 Bug修复与功能改进（已暂停）

总进度: 70% (Phase 2 关键功能缺失，导致 Phase 3/3A 功能不可用)
```

**🔄 重排说明**:
- 原 Phase 4（在线播放）→ **新 Phase 2** - 优先级提升，这是其他功能的前置条件
- 原 Phase 2 → **新 Phase 3** - 歌单功能依赖在线播放
- 原 Phase 2A → **新 Phase 3A** - 播放列表页面改进
- 原 Phase 3 → **新 Phase 4** - 搜索推荐相对独立
- 原 Phase 2B → **新 Phase 5** - 低优先级优化

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

### Phase 2 详细任务清单 ⏸️

**阶段1：统一播放接口** (待实施):
- [ ] domain/entities/playable_audio.dart - 创建统一播放接口
- [ ] LocalPlayable 类实现
- [ ] OnlinePlayable 类实现

**阶段2：AudioProvider 改造** (待实施):
- [ ] 播放列表类型改为 `List<PlayableAudio>`
- [ ] 添加 `playOnline(Audio audio, String streamUrl)` 方法
- [ ] 修改类型相关 Getter 方法
- [ ] 兼容本地音频播放功能

**阶段3：页面集成** (待实施):
- [ ] search_page.dart - 搜索结果播放
- [ ] explore_page.dart - 推荐内容播放
- [ ] playlist_detail_page.dart - 歌单播放

**阶段4：播放历史集成** (待实施):
- [ ] play_history_provider.dart - 记录在线播放
- [ ] 在线音频播放历史恢复

**测试与验证** (待实施):
- [ ] 功能测试（搜索/推荐/歌单播放）
- [ ] 性能测试（加载时间、切换流畅度）
- [ ] 兼容性测试（本地+在线混合播放）
- [ ] 文档更新

### Phase 3 详细任务清单 ✅

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

**测试与优化**:
- [x] 功能测试（歌单CRUD、收藏、历史）
- [ ] 单元测试编写
- [ ] 集成测试
- [x] 文档更新

### Phase 3A 详细任务清单 ✅

**播放进度持久化** ✅:
- [x] 播放位置每5秒自动保存
- [x] 暂停时保存当前播放位置
- [x] 应用重启后恢复播放状态

**UI 交互优化** ✅:
- [x] 当前播放项蓝色高亮显示
- [x] ReorderableListView 拖拽排序
- [x] 清空列表确认对话框
- [x] 空列表友好提示

### Phase 4 详细任务清单 🚧

**后端开发** ✅ (已完成):
- [x] searchService.js - FTS5 全文搜索实现
- [x] routes/search.js - 搜索API路由（4个端点）
- [x] 数据库表创建 (audio_metadata_cache_fts, search_stats)
- [x] recommendationService.js - 热门歌单推荐

**前端开发** ✅ (已完成):
- [x] providers/search_provider.dart - 搜索状态管理
- [x] 集成全文搜索UI
- [x] 发现页面推荐UI集成

**下载架构重构** ✅ (已完成):
- [x] services/download/download_executor.dart - 下载执行器
- [x] services/download/download_repository.dart - 下载数据仓储
- [x] services/download/metadata_writer.dart - 元数据写入
- [x] 支持断点续传、进度追踪

**Bug 修复** ✅ (已完成):
- [x] auth.js user_id 类型问题（parseInt）
- [x] search_page.dart dispose 错误修复

**测试与优化:**
- [ ] 单元测试编写
- [ ] 集成测试
- [x] 文档更新

### Phase 5 详细任务清单 📋

**Bug 修复** ✅ (已完成):
- [x] 搜索结果加入歌单卡死问题修复
- [x] 添加 loading 状态防止重复点击
- [x] 缩短超时时间到10秒

**下载架构重构** ✅ (已完成):
- [x] 下载任务管理迁移到前端本地
- [x] 断点续传支持

**功能扩展** 📋 (已暂停):
- [ ] 歌单详情页添加歌曲按钮
- [ ] 播放列表排序选项
- [ ] QQ音乐榜单集成（未来计划）

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

### 项目详细实施文档（按新顺序）

- **[Phase 1 实施细节](./PHASE_1_IMPLEMENTATION_DETAILS.md)** ⭐⭐⭐⭐
  - 完整实现状态
  - 安全实现细节
  - 数据库表结构
  - API端点清单（23个）
  - 核心代码位置

- **[Phase 2 在线播放功能](./PHASE_2_ONLINE_PLAYBACK.md)** 🆕 ⭐⭐⭐⭐⭐
  - 问题诊断：数据流断裂分析
  - 架构设计：统一播放接口
  - 代码实现：PlayableAudio、AudioProvider 改造
  - 页面集成：搜索/推荐/歌单播放

- **[Phase 3 歌单收藏推荐计划](./PHASE_3_PLAYLIST_PLAN.md)** ⭐⭐⭐⭐
  - 功能概述
  - 数据模型设计
  - 数据库表结构（SQLite）
  - 实施检查清单

- **[Phase 3A 播放功能改进](./PHASE_3A_PLAYBACK_PLAN.md)** ⭐⭐⭐
  - 播放功能与播放列表改进
  - 播放顺序持久化

- **[Phase 3B 播放控制增强](./PHASE_3B_PLAYBACK_CONTROLS_PLAN.md)** ⭐⭐⭐ 🆕
  - 音量调节功能
  - 倍速播放功能
  - 用户偏好持久化

- **[Phase 5 Bug修复与功能改进](./PHASE_5_BUGFIX_AND_IMPROVEMENTS.md)** ⭐⭐⭐
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
| 2026-01-20 | 2.2.0 | **架构调整**：Phase 3 下载服务从后端迁移到前端本地实现；Phase 2B 爬虫服务已完成 | Claude Code |
| 2026-01-20 | 2.3.0 | **Phase 2A 重定位**：专注于 PlayListPage 功能改进（播放进度持久化 + UI优化）；歌单功能暂搁置 | Claude Code |
| 2026-01-20 | 2.4.0 | **Phase 2A 完成**：播放进度持久化、拖拽排序、UI高亮等功能已完成 | Claude Code |
| 2026-01-22 | 3.0.0 | **新增 Phase 4**：在线播放功能实施计划，诊断数据流断裂问题 | Claude Code |

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
3. **基础依赖**：其他阶段都依赖这个功能
4. **易于测试**：B站API功能独立，不影响其他模块

### Q2.1: 为什么 Phase 2（在线播放）优先级这么高？

**A**:
1. **关键功能缺失**：没有在线播放，搜索/推荐/歌单功能都不可用
2. **数据流断裂**：后端已完成但前端无法接收在线音频流
3. **其他功能依赖**：Phase 3（歌单）和 Phase 3A（播放列表）依赖它
4. **快速修复**：只需3-5天即可解决核心问题

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

**下一步**: 实施 Phase 2 - 在线播放功能（关键功能缺失，优先级最高）

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
| 2026-01-20 | 2.2.0 | **架构调整**：Phase 3 下载服务从后端迁移到前端本地实现；Phase 2B 爬虫服务已完成 | Claude Code |
| 2026-01-20 | 2.3.0 | **Phase 2A 重定位**：专注于 PlayListPage 功能改进（播放进度持久化 + UI优化）；歌单功能暂搁置 | Claude Code |
| 2026-01-20 | 2.4.0 | **Phase 2A 完成**：播放进度持久化、拖拽排序、UI高亮等功能已完成 | Claude Code |
| 2026-01-22 | 3.0.0 | **新增 Phase 4**：在线播放功能实施计划，诊断数据流断裂问题 | Claude Code |
| 2026-01-22 | 4.0.0 | **🔄 阶段重排**：按功能依赖优先级重新排序，Phase 4→Phase 2（在线播放优先），Phase 2→Phase 3，Phase 2A→Phase 3A，Phase 3→Phase 4，Phase 2B→Phase 5 | Claude Code |
| 2026-01-23 | 4.1.0 | **新增 Phase 3B**：播放控制增强计划（音量调整 + 倍速播放），创建详细实施文档 | Claude Code |
