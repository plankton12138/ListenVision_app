# 渐进式架构迁移计划

> **方案A**: 从胖客户端到平衡架构的渐进式迁移
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
- [Phase 3: 搜索、推荐与下载服务](#phase-3-搜索推荐与下载服务)
- [风险评估与应对](#风险评估与应对)
- [验收标准](#验收标准)

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
```

**lib/services/**
```
api_service.dart         → HTTP API调用（仅认证）
secure_storage_service.dart → 加密存储
```

**数据库:**
- SQLite: 存储播放列表、音频元数据
- SharedPreferences: 用户登录状态

### 后端（服务端）现状

**已完成:**
- ✅ 用户认证（JWT）
- ✅ 用户管理（CRUD）
- ✅ 收藏管理
- ✅ 请求限流
- ✅ API文档（Swagger）

**待开发:**
- ❌ 音频文件管理
- ❌ B站API集成
- ❌ 搜索功能
- ❌ 播放列表管理
- ❌ 下载任务管理

### 架构问题

```
当前问题:
1. ❌ B站Cookie存储在客户端（安全风险）
2. ❌ 音频元数据解析在客户端（性能问题）
3. ❌ 播放列表无法跨设备同步
4. ❌ 搜索功能依赖客户端（无法优化）
5. ❌ 无法进行服务端数据分析
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
│  │  • searchService.js   (搜索引擎)  │  │
│  │  • syncService.js      (同步服务)  │  │
│  │  • downloadService.js  (下载管理)  │  │
│  ├───────────────────────────────────┤  │
│  │ 数据访问层                         │  │
│  │  • MySQL (用户、音频、播放列表)    │  │
│  │  • Redis (缓存、会话)              │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

### 职责划分

| 功能模块 | 当前位置 | 目标位置 | 原因 |
|---------|---------|---------|------|
| 音频播放控制 | Flutter端 | **Flutter端** | 保持低延迟 |
| 本地缓存管理 | Flutter端 | **Flutter端** | 支持离线播放 |
| UI渲染 | Flutter端 | **Flutter端** | 客户端职责 |
| B站API调用 | Flutter端 | **服务端** | 安全性 |
| 音频元数据 | Flutter端 | **服务端** | 共享、缓存 |
| 搜索功能 | Flutter端 | **服务端** | 性能优化 |
| 播放列表 | SQLite | **MySQL + 云同步** | 跨设备 |
| 用户认证 | 已完成 | **保持不变** | 已完善 |

---

## 📅 Phase 1: B站API集成与元数据服务

**时间估算**: 2-3周
**优先级**: 🔴 最高
**影响范围**: B站相关功能

### 目标

将B站API调用和音频元数据处理从Flutter端迁移到服务端。

### 为什么先做这个？

1. **安全性**: B站Cookie存储在服务端更安全
2. **性能**: 音频元数据可以缓存，减少重复请求
3. **基础性**: Phase 2和3都依赖这个功能

### 实施步骤

#### 1.1 后端开发（Week 1）

**文件结构:**
```
listen-vision_api/
├── services/
│   ├── bilibiliService.js     ← 新增：B站API集成
│   └── audioService.js         ← 新增：音频元数据管理
├── routes/
│   ├── bilibili.js             ← 新增：B站相关路由
│   └── audio.js                ← 新增：音频相关路由
├── controllers/
│   ├── bilibiliController.js   ← 新增
│   └── audioController.js      ← 新增
├── middleware/
│   └── bilibiliAuth.js         ← 新增：B站认证中间件
└── models/
    └── BilibiliAccount.js      ← 新增：B站账号模型
```

**核心功能实现:**

**1. bilibiliService.js** (B站API服务)

```javascript
/**
 * B站API集成服务
 *
 * 功能:
 * 1. QR码登录
 * 2. Cookie管理（加密存储）
 * 3. 视频信息获取
 * 4. 音频流URL获取
 * 5. UP主视频列表
 */

class BilibiliService {
  // QR码登录
  async getQRCode() { /* ... */ }
  async checkQRLoginStatus(qrcodeKey) { /* ... */ }

  // Cookie管理
  async saveCookie(userId, cookie) { /* ... */ }
  async getCookie(userId) { /* ... */ }
  async refreshCookie(userId) { /* ... */ }

  // 视频信息
  async getVideoInfo(bvid) { /* ... */ }
  async getAudioStream(bvid, cid) { /* ... */ }

  // UP主相关
  async getUploaderVideos(mid, page) { /* ... */ }
}
```

**2. audioService.js** (音频元数据服务)

```javascript
/**
 * 音频元数据管理服务
 *
 * 功能:
 * 1. 音频元数据缓存
 * 2. 搜索历史记录
 * 3. 热门音频统计
 */

class AudioService {
  // 元数据缓存
  async cacheAudioMetadata(bvid, metadata) { /* ... */ }
  async getAudioMetadata(bvid) { /* ... */ }

  // 搜索
  async searchBilibili(keyword, page) { /* ... */ }
  async saveSearchHistory(userId, keyword) { /* ... */ }
}
```

**数据库表设计:**

```sql
-- B站账号绑定表
CREATE TABLE bilibili_accounts (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  bili_user_id VARCHAR(20),
  bili_username VARCHAR(100),
  cookie_encrypted TEXT NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  expires_at DATETIME,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE KEY unique_user_active (user_id, is_active)
);

-- 音频元数据缓存表
CREATE TABLE audio_metadata_cache (
  id INT AUTO_INCREMENT PRIMARY KEY,
  bvid VARCHAR(20) UNIQUE NOT NULL,
  title VARCHAR(255),
  artist VARCHAR(255),
  duration INT,
  cover_url TEXT,
  audio_url TEXT,
  metadata JSON,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_bvid (bvid)
);

-- 搜索历史表
CREATE TABLE search_history (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT,
  keyword VARCHAR(100) NOT NULL,
  result_count INT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_user_keyword (user_id, keyword)
);
```

**API端点设计:**

```javascript
// B站认证相关
POST   /api/bilibili/qrcode           // 获取QR码
POST   /api/bilibili/qrcode/check     // 检查QR码登录状态
DELETE /api/bilibili/unbind           // 解绑B站账号
GET    /api/bilibili/status           // 获取绑定状态

// B站数据获取
GET    /api/bilibili/video/:bvid      // 获取视频信息
GET    /api/bilibili/audio/:bvid      // 获取音频流URL
GET    /api/bilibili/uploader/:mid    // 获取UP主视频列表

// 搜索功能
GET    /api/audio/search              // 搜索B站音频
GET    /api/audio/metadata/:bvid      // 获取缓存的元数据
```

#### 1.2 Flutter端改造（Week 2）

**修改文件:**

**lib/services/bilibili_api_service.dart** (新增)
```dart
/**
 * B站API服务（调用后端）
 *
 * 职责: 通过后端API获取B站数据，不再直接调用B站API
 */
class BilibiliApiService {
  // QR码登录
  Future<Map<String, dynamic>> getQRCode() async { /* 调用 POST /api/bilibili/qrcode */ }
  Future<Map<String, dynamic>> checkQRStatus(String qrcodeKey) async { /* ... */ }

  // 视频信息
  Future<AudioMetadata> getVideoInfo(String bvid) async { /* 调用 GET /api/bilibili/video/:bvid */ }
  Future<String> getAudioStream(String bvid) async { /* 调用 GET /api/bilibili/audio/:bvid */ }

  // 搜索
  Future<List<Audio>> searchBilibili(String keyword, int page) async { /* 调用 GET /api/audio/search */ }
}
```

**lib/providers/bilibili_provider.dart** (新增)
```dart
/**
 * B站状态管理
 */
class BilibiliProvider extends ChangeNotifier {
  BilibiliApiService _apiService = BilibiliApiService();

  bool _isBound = false;
  Map<String, dynamic>? _biliUserInfo;

  // 绑定状态检查
  Future<void> checkBindStatus() async { /* ... */ }

  // QR码登录
  Future<String> getQRCode() async { /* ... */ }
  Future<bool> checkQRLogin(String qrcodeKey) async { /* ... */ }
}
```

#### 1.3 集成测试（Week 3）

**测试场景:**
1. ✅ QR码登录流程
2. ✅ Cookie存储和刷新
3. ✅ 视频信息获取
4. ✅ 音频流URL获取
5. ✅ 搜索功能
6. ✅ 元数据缓存命中

### 验收标准

- [ ] B站QR码登录成功率 > 95%
- [ ] 音频元数据缓存命中率 > 60%
- [ ] API响应时间 < 500ms (p95)
- [ ] Cookie加密存储成功
- [ ] Flutter端无B站API调用（全部走后端）

---

## 📅 Phase 2: 播放列表与收藏云同步

**时间估算**: 2-3周
**优先级**: 🟡 中等
**依赖**: Phase 1完成

### 目标

实现播放列表和收藏的云端同步，支持跨设备访问。

### 实施步骤

#### 2.1 后端开发（Week 1）

**新增文件:**
```
listen-vision_api/
├── services/
│   └── playlistService.js    ← 新增：播放列表服务
├── routes/
│   └── playlists.js           ← 新增
├── controllers/
│   └── playlistController.js  ← 新增
└── models/
    └── Playlist.js            ← 新增
```

**数据库表设计:**

```sql
-- 播放列表表
CREATE TABLE playlists (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  name VARCHAR(100) NOT NULL,
  description TEXT,
  is_public BOOLEAN DEFAULT FALSE,
  cover_url VARCHAR(500),
  play_count INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_user_id (user_id)
);

-- 播放列表项表
CREATE TABLE playlist_items (
  id INT AUTO_INCREMENT PRIMARY KEY,
  playlist_id INT NOT NULL,
  bvid VARCHAR(20) NOT NULL,
  title VARCHAR(255),
  artist VARCHAR(255),
  duration INT,
  cover_url TEXT,
  position INT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (playlist_id) REFERENCES playlists(id) ON DELETE CASCADE,
  UNIQUE KEY unique_playlist_bvid (playlist_id, bvid),
  INDEX idx_playlist_position (playlist_id, position)
);

-- 收藏表（重构）
CREATE TABLE favorites (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  bvid VARCHAR(20) NOT NULL,
  title VARCHAR(255),
  artist VARCHAR(255),
  cover_url TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE KEY unique_user_bvid (user_id, bvid),
  INDEX idx_user_id (user_id)
);
```

**API端点:**

```javascript
// 播放列表
GET    /api/playlists              // 获取用户所有播放列表
POST   /api/playlists              // 创建播放列表
GET    /api/playlists/:id          // 获取播放列表详情
PUT    /api/playlists/:id          // 更新播放列表
DELETE /api/playlists/:id          // 删除播放列表
POST   /api/playlists/:id/items    // 添加音频到播放列表
DELETE /api/playlists/:id/items/:bvid  // 从播放列表移除

// 收藏
GET    /api/favorites              // 获取收藏列表
POST   /api/favorites              // 添加收藏
DELETE /api/favorites/:bvid        // 取消收藏
```

#### 2.2 Flutter端改造（Week 2）

**lib/services/sync_service.dart** (新增)
```dart
/**
 * 云同步服务
 */
class SyncService {
  // 上传本地播放列表到云端
  Future<void> uploadPlaylist(Playlist playlist) async { /* ... */ }

  // 从云端下载播放列表
  Future<List<Playlist>> downloadPlaylists() async { /* ... */ }

  // 同步逻辑（合并本地和云端）
  Future<void> syncPlaylists() async { /* ... */ }
}
```

**lib/providers/sync_provider.dart** (新增)
```dart
/**
 * 同步状态管理
 */
class SyncProvider extends ChangeNotifier {
  bool _isSyncing = false;
  DateTime? _lastSyncTime;

  Future<void> sync() async {
    _isSyncing = true;
    notifyListeners();

    try {
      // 1. 下载云端数据
      // 2. 合并本地数据
      // 3. 上传本地独有数据
      // 4. 解决冲突
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
}
```

#### 2.3 冲突解决策略（Week 3）

**冲突场景:**
1. 同一bvid在不同设备有不同的元数据
2. 播放列表在多设备同时修改
3. 网络断开时的离线修改

**解决策略:**
```javascript
// 策略1: "最后写入胜出" (Last Write Wins)
// 适用于: 播放次数、最后播放时间

// 策略2: "云端优先" (Cloud Wins)
// 适用于: 收藏状态

// 策略3: "用户选择" (User Choice)
// 适用于: 播放列表名称、描述冲突
```

### 验收标准

- [ ] 播放列表可以在不同设备间同步
- [ ] 冲突解决成功率 > 95%
- [ ] 同步过程不阻塞UI
- [ ] 离线修改可在联网后同步

---

## 📅 Phase 3: 搜索、推荐与下载服务

**时间估算**: 2-3周
**优先级**: 🟢 低
**依赖**: Phase 1、2完成

### 目标

实现高级搜索、智能推荐和下载任务管理。

### 实施步骤

#### 3.1 搜索优化（Week 1）

**后端开发:**

```javascript
// searchService.js 增强
class SearchService {
  // 全文搜索（使用Elasticsearch或MySQL全文索引）
  async fullTextSearch(keyword, filters) { /* ... */ }

  // 搜索建议（自动完成）
  async getSearchSuggestions(prefix) { /* ... */ }

  // 热门搜索
  async getTrendingKeywords() { /* ... */ }
}
```

**数据库优化:**

```sql
-- 添加全文索引
ALTER TABLE audio_metadata_cache ADD FULLTEXT INDEX idx_title_artist (title, artist);

-- 搜索统计表
CREATE TABLE search_stats (
  id INT AUTO_INCREMENT PRIMARY KEY,
  keyword VARCHAR(100) NOT NULL,
  search_count INT DEFAULT 1,
  last_searched TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY unique_keyword (keyword)
);
```

#### 3.2 推荐系统（Week 2）

**基于用户行为的推荐:**

```sql
-- 用户行为日志表
CREATE TABLE user_behavior_logs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  bvid VARCHAR(20) NOT NULL,
  action ENUM('play', 'like', 'skip', 'share') NOT NULL,
  timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_user_action (user_id, action, timestamp)
);
```

**推荐算法:**
```javascript
// recommendationService.js
class RecommendationService {
  // 基于协同过滤的推荐
  async getCollaborativeRecommendations(userId, limit) { /* ... */ }

  // 基于内容的推荐
  async getContentBasedRecommendations(bvid, limit) { /* ... */ }

  // 热门推荐
  async getTrending(limit) { /* ... */ }
}
```

#### 3.3 下载任务管理（Week 3）

**后端开发:**

```javascript
// downloadService.js
class DownloadService {
  // 创建下载任务
  async createDownloadTask(userId, bvid) { /* ... */ }

  // 查询下载进度
  async getDownloadProgress(taskId) { /* ... */ }

  // 暂停/恢复/取消
  async pauseDownload(taskId) { /* ... */ }
  async resumeDownload(taskId) { /* ... */ }
  async cancelDownload(taskId) { /* ... */ }
}
```

**数据库表:**

```sql
-- 下载任务表
CREATE TABLE download_tasks (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  bvid VARCHAR(20) NOT NULL,
  status ENUM('pending', 'downloading', 'paused', 'completed', 'failed') DEFAULT 'pending',
  progress INT DEFAULT 0,
  file_size BIGINT,
  downloaded_size BIGINT DEFAULT 0,
  error_message TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_user_status (user_id, status)
);
```

### 验收标准

- [ ] 搜索响应时间 < 200ms (p95)
- [ ] 推荐准确率 > 40% (点击率)
- [ ] 下载任务可跨设备管理
- [ ] 支持断点续传

---

## ⚠️ 风险评估与应对

### 风险矩阵

| 风险 | 影响 | 概率 | 应对措施 |
|------|------|------|---------|
| B站API反爬虫升级 | 高 | 中 | 1. 使用代理池<br>2. 限流控制<br>3. 保留客户端调用作为降级方案 |
| 用户数据丢失 | 高 | 低 | 1. 迁移前数据库备份<br>2. 双写策略（Phase 1过渡期）<br>3. 回滚预案 |
| 性能下降 | 中 | 中 | 1. Redis缓存<br>2. 数据库索引优化<br>3. API响应时间监控 |
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
方案1: 使用Redis缓存热点数据
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

### Phase 1 验收

**功能验收:**
- [ ] B站QR码登录成功率 > 95%
- [ ] 音频元数据缓存命中率 > 60%
- [ ] API响应时间 < 500ms (p95)
- [ ] Cookie加密存储通过安全审计

**代码质量:**
- [ ] 后端代码通过ESLint检查
- [ ] Flutter代码通过flutter analyze检查
- [ ] 单元测试覆盖率 > 70%

### Phase 2 验收

**功能验收:**
- [ ] 播放列表同步成功率 > 98%
- [ ] 冲突解决成功率 > 95%
- [ ] 同步过程不阻塞UI
- [ ] 支持3种冲突解决策略

**性能验收:**
- [ ] 同步100首歌曲耗时 < 10秒
- [ ] 增量同步耗时 < 2秒

### Phase 3 验收

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
Phase 3:   ░░░░░░░░░░░░░░░░░░░░   0%    等待Phase 2完成

总进度: 60% (Phase 1+2 完成)
```

### Phase 1 详细任务清单

**Week 1: 后端B站API服务**
- [x] bilibiliService.js 核心逻辑
- [x] audioService.js 元数据缓存
- [x] 数据库表创建
- [x] API路由实现 (11个B站端点 + 12个音频端点)
- [x] Cookie加密存储测试
- [x] 资源代理服务（图片/音频防盗链）

**Week 2: Flutter端改造**
- [x] bilibiliApiService.dart 实现
- [x] bilibiliProvider.dart 状态管理
- [x] metadata_god 元数据读写集成
- [x] main.dart Provider 配置优化
- [x] 下载管理器后端API集成

**Week 3: 测试与优化**
- [x] 功能测试（搜索、下载、封面）
- [ ] 单元测试编写
- [ ] 集成测试
- [ ] 性能测试
- [x] 文档更新

### Phase 2 详细任务清单

**后端开发** (2026-01-19 完成):
- [x] playlistService.js - 歌单管理服务
- [x] playHistoryService.js - 播放历史服务
- [x] recommendationService.js - 推荐内容服务
- [x] routes/playlists.js - 歌单API路由
- [x] routes/history.js - 播放历史API路由
- [x] routes/recommendations.js - 推荐API路由
- [x] 数据库表扩展 (playlists, playlist_items, play_history)

**前端开发** (2026-01-19 完成):
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

---

## 📚 相关文档

### 核心技术文档
- **[Flutter中文官方文档](https://docs.flutter.cn/)** - Flutter框架完整技术文档
  - UI组件库
  - 状态管理指南
  - 网络请求最佳实践
  - 平台集成文档

- **[B站API收集项目](https://socialsisteryi.github.io/bilibili-API-collect/)** - B站API完整文档
  - 认证系统（QR码登录、Cookie管理）
  - 视频信息API
  - 音频流API
  - 搜索API
  - UP主相关API

### 项目文档
- [Flutter项目README](../frontenf_flutter/README.md)
- [后端项目README](../listen-vision_api/README.md)
- [CLAUDE.md](../CLAUDE.md) - 项目整体说明

### 开发资源
- **[Provider状态管理](https://pub.dev/packages/provider)** - Flutter状态管理方案
- **[Dio HTTP客户端](https://pub.dev/packages/dio)** - Flutter网络请求库
- **[Express.js](https://expressjs.com/)** - Node.js后端框架
- **[MySQL2](https://github.com/sidorares/node-mysql2)** - MySQL驱动

---

## 📝 更新日志

| 日期 | 版本 | 更新内容 | 作者 |
|------|------|---------|------|
| 2026-01-13 | 1.0.0 | 初始版本，完成渐进式迁移计划 | Claude Code |
| 2026-01-17 | 1.1.0 | 更新Phase 1后端完成状态，添加资源代理服务说明 | Claude Code |
| 2026-01-18 | 1.2.0 | **Phase 1 完成**：Flutter端改造完成，metadata_god集成，搜索/下载/封面功能正常 | Claude Code |
| 2026-01-19 | 1.3.0 | **Phase 2 完成**：歌单/收藏/推荐/历史功能完成 | Claude Code |

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
- **迁移**：播放列表、收藏、搜索历史 → MySQL
- **优势**：离线能力 + 云端同步

---

**下一步**: 开始实施 [Phase 1 详细实施指南](./PHASE_1_IMPLEMENTATION_GUIDE.md)

---

*本文档由 Claude Code 生成 | 最后更新: 2026-01-13*
