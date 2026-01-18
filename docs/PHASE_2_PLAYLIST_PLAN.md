# Phase 2: 歌单、收藏、推荐功能实施计划

> **创建日期**: 2026-01-18
>
> **目标**: 实现歌单系统、收藏功能、个人推荐和播放历史
>
> **设计决策** (已与用户确认):
> - 收藏作为"我喜欢"特殊系统歌单
> - 混合存储模式（游客本地，登录用户云端同步）
> - UI统一展示，播放队列作为"正在播放"特殊歌单
> - 推荐内容：热门榜单 + 个性化推荐 + 分区内容

---

## 一、功能概述

| 功能 | 当前状态 | 目标状态 |
|------|----------|----------|
| 歌单创建/管理 | ❌ 无 | ✅ 完整CRUD + 云同步 |
| 收藏功能 | ⚠️ 后端有，前端未集成 | ✅ 集成到"我喜欢"歌单 |
| 个人推荐 | ❌ explore_page.dart 空白 | ✅ 热门/个性化/分区推荐 |
| 播放历史 | ⚠️ 仅有搜索历史 | ✅ 完整播放记录 |
| 播放列表 | ✅ 本地SQLite | ✅ 扩展为多歌单系统 |

---

## 二、数据模型设计

### 歌单分类

```
系统歌单 (type='system'):
├── favorites (我喜欢) - 用户收藏
└── now_playing (正在播放) - 当前播放队列

用户歌单 (type='user'):
└── 用户自建的普通歌单
```

### 后端数据库表 (SQLite)

#### 1. playlists 表
```sql
CREATE TABLE IF NOT EXISTS playlists (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  cover_url TEXT,
  type TEXT DEFAULT 'user',           -- 'system' | 'user'
  system_type TEXT,                   -- 'favorites' | 'now_playing' | null
  is_public INTEGER DEFAULT 0,
  play_count INTEGER DEFAULT 0,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now')),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

#### 2. playlist_items 表
```sql
CREATE TABLE IF NOT EXISTS playlist_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  playlist_id INTEGER NOT NULL,
  bvid TEXT NOT NULL,
  title TEXT,
  artist TEXT,
  duration INTEGER,
  cover_url TEXT,
  position INTEGER NOT NULL DEFAULT 0,
  added_at TEXT DEFAULT (datetime('now')),
  FOREIGN KEY (playlist_id) REFERENCES playlists(id) ON DELETE CASCADE,
  UNIQUE(playlist_id, bvid)
);
```

#### 3. play_history 表
```sql
CREATE TABLE IF NOT EXISTS play_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER,
  bvid TEXT NOT NULL,
  title TEXT,
  artist TEXT,
  duration INTEGER,
  cover_url TEXT,
  played_at TEXT DEFAULT (datetime('now')),
  progress INTEGER DEFAULT 0,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

---

## 三、API端点设计

### 歌单管理 (`/api/playlists`)

| 方法 | 端点 | 说明 | 认证 |
|------|------|------|------|
| GET | `/api/playlists` | 获取用户所有歌单 | 必需 |
| POST | `/api/playlists` | 创建新歌单 | 必需 |
| GET | `/api/playlists/:id` | 获取歌单详情+items | 必需 |
| PUT | `/api/playlists/:id` | 更新歌单信息 | 必需 |
| DELETE | `/api/playlists/:id` | 删除歌单 | 必需 |
| POST | `/api/playlists/:id/items` | 添加音频到歌单 | 必需 |
| DELETE | `/api/playlists/:id/items/:bvid` | 从歌单移除音频 | 必需 |
| PUT | `/api/playlists/:id/items/reorder` | 调整歌单项顺序 | 必需 |

### 收藏快捷端点
| 方法 | 端点 | 说明 |
|------|------|------|
| POST | `/api/playlists/favorites/toggle` | 切换收藏状态 |
| GET | `/api/playlists/favorites/check/:bvid` | 检查是否已收藏 |

### 播放历史 (`/api/history`)

| 方法 | 端点 | 说明 |
|------|------|------|
| GET | `/api/history` | 获取播放历史 |
| POST | `/api/history` | 记录播放 |
| DELETE | `/api/history` | 清空历史 |

### 推荐内容 (`/api/recommendations`)

| 方法 | 端点 | 说明 |
|------|------|------|
| GET | `/api/recommendations/hot-playlists` | B站热门歌单 |
| GET | `/api/recommendations/rank` | B站热歌榜单 |
| GET | `/api/recommendations/personalized` | 个性化推荐 |
| GET | `/api/recommendations/category/:tid` | 分区推荐 |

---

## 四、实施步骤

### 阶段 1: 后端开发

**关键文件**: `A:\Projects\Projects_ListenVison\listen-vision_api\`

#### 1.1 扩展数据库 (`config/database.js`)
- [ ] 添加 playlists 表
- [ ] 添加 playlist_items 表
- [ ] 添加 play_history 表
- [ ] 迁移现有 favorites 数据到新结构

#### 1.2 歌单服务 (`services/playlistService.js` - 新建)
```javascript
class PlaylistService {
  // 确保用户拥有系统歌单
  async ensureSystemPlaylists(userId)

  // 获取用户所有歌单
  async getUserPlaylists(userId)

  // 获取歌单详情（包含items）
  async getPlaylistDetail(playlistId, userId)

  // 创建歌单
  async createPlaylist(userId, name, description)

  // 更新歌单
  async updatePlaylist(playlistId, updates)

  // 删除歌单
  async deletePlaylist(playlistId, userId)

  // 添加音频到歌单
  async addItem(playlistId, bvid, metadata)

  // 从歌单移除音频
  async removeItem(playlistId, bvid)

  // 调整歌单项顺序
  async reorderItems(playlistId, itemOrders)

  // 收藏快捷方法
  async toggleFavorite(userId, bvid, metadata)
  async isFavorited(userId, bvid)

  // 保存播放队列
  async saveNowPlaying(userId, items)
  async getNowPlaying(userId)
}
```

#### 1.3 推荐服务 (`services/recommendationService.js` - 新建)
```javascript
class RecommendationService {
  // 热门歌单（B站API）
  async getHotPlaylists(page, pageSize)

  // 热歌榜单（B站API）
  async getHotRank(page, pageSize)

  // 个性化推荐（基于搜索历史）
  async getPersonalized(userId, limit)

  // 分区推荐
  async getByCategory(tid, page, pageSize)
}
```

#### 1.4 播放历史服务 (`services/playHistoryService.js` - 新建)
```javascript
class PlayHistoryService {
  async recordPlay(userId, bvid, metadata, progress)
  async getHistory(userId, limit, offset)
  async clearHistory(userId)
}
```

#### 1.5 控制器与路由
- [ ] `controllers/playlistController.js` - 新建
- [ ] `controllers/recommendationController.js` - 新建
- [ ] `controllers/playHistoryController.js` - 新建
- [ ] `routes/playlists.js` - 新建
- [ ] `routes/recommendations.js` - 新建
- [ ] `routes/history.js` - 新建
- [ ] `index.js` - 注册新路由

---

### 阶段 2: 前端数据层

**关键文件**: `A:\Projects\Projects_ListenVison\frontend_flutter\lib\`

#### 2.1 数据模型 (`models/playlist.dart` - 新建)
```dart
class Playlist {
  final int? id;
  final String name;
  final String? description;
  final String? coverUrl;
  final String type;           // 'system' | 'user'
  final String? systemType;    // 'favorites' | 'now_playing'
  final int itemCount;
  // ...
}

class PlaylistItem {
  final int? id;
  final String bvid;
  final String title;
  final String? artist;
  final int? duration;
  final String? coverUrl;
  final int position;
  // ...
}

class PlayHistoryItem {
  final String bvid;
  final String title;
  final String? artist;
  final DateTime playedAt;
  final int progress;
  // ...
}
```

#### 2.2 歌单Provider (`providers/playlist_provider.dart` - 新建)
```dart
class PlaylistProvider with ChangeNotifier {
  List<Playlist> _playlists = [];
  Playlist? _favoritesPlaylist;
  Playlist? _nowPlayingPlaylist;

  // 初始化
  Future<void> initialize(String? token)

  // 歌单CRUD
  Future<Playlist?> createPlaylist(String name, {String? description})
  Future<bool> updatePlaylist(int id, {String? name, String? description})
  Future<bool> deletePlaylist(int id)

  // 歌单项管理
  Future<List<PlaylistItem>> getPlaylistItems(int playlistId)
  Future<bool> addItem(int playlistId, String bvid, AudioMetadata metadata)
  Future<bool> removeItem(int playlistId, String bvid)

  // 收藏快捷方法
  Future<bool> toggleFavorite(String bvid, AudioMetadata metadata)
  bool isFavorited(String bvid)
  List<PlaylistItem> get favorites

  // 播放队列
  Future<void> saveNowPlayingQueue(List<Audio> queue)
  List<PlaylistItem> get nowPlayingQueue

  // 云同步
  Future<void> syncToCloud()
  Future<void> syncFromCloud()
}
```

#### 2.3 播放历史Provider (`providers/play_history_provider.dart` - 新建)
```dart
class PlayHistoryProvider with ChangeNotifier {
  List<PlayHistoryItem> _history = [];

  Future<void> recordPlay(String bvid, AudioMetadata metadata, {int progress = 0})
  Future<void> loadHistory()
  Future<void> clearHistory()
  Future<void> removeHistoryItem(String bvid)
}
```

#### 2.4 扩展本地存储 (`services/playlist_manager.dart`)
- [ ] 添加 local_playlists 表
- [ ] 添加 local_playlist_items 表
- [ ] 添加 local_play_history 表
- [ ] 实现本地歌单CRUD方法

#### 2.5 API服务 (`services/playlistApiService.dart` - 新建)
```dart
class PlaylistApiService {
  Future<List<Playlist>> getPlaylists()
  Future<Playlist> createPlaylist(String name, {String? description})
  Future<PlaylistDetail> getPlaylistDetail(int id)
  Future<bool> addItem(int playlistId, String bvid, Map<String, dynamic> metadata)
  // ...
}
```

---

### 阶段 3: 前端UI

#### 3.1 发现页面 (`ui/pages/explore_page.dart`)
- [ ] 未绑定时显示绑定引导
- [ ] 绑定后显示Tab切换（推荐/榜单/分区）
- [ ] 推荐Tab：个性化推荐内容
- [ ] 榜单Tab：热门歌单+热歌榜单
- [ ] 分区Tab：音乐区/翻唱/演奏等分类

#### 3.2 歌单库页面 (`ui/pages/playlist_library_page.dart` - 新建)
- [ ] 顶部创建歌单按钮
- [ ] 系统歌单区（正在播放、我喜欢）
- [ ] 用户歌单区（卡片列表）
- [ ] 长按删除/编辑

#### 3.3 歌单详情页面 (`ui/pages/playlist_detail_page.dart` - 新建)
- [ ] 歌单信息展示（名称、封面、描述）
- [ ] 歌单项列表
- [ ] 播放全部按钮
- [ ] 长按移除/调整顺序

#### 3.4 播放历史页面 (`ui/pages/play_history_page.dart` - 新建)
- [ ] 历史记录列表（倒序）
- [ ] 点击重新播放
- [ ] 滑动删除

#### 3.5 更新现有页面
- [ ] `home_page.dart` - 添加收藏按钮到播放器
- [ ] `search_page.dart` - 搜索结果添加收藏入口
- [ ] `my_drawer.dart` - 添加歌单/历史入口
- [ ] `routes/router.dart` - 注册新路由

#### 3.6 main.dart
- [ ] 注册 PlaylistProvider
- [ ] 注册 PlayHistoryProvider

---

### 阶段 4: 集成与优化

#### 4.1 播放队列持久化
- [ ] AudioProvider 播放变化时自动保存到 now_playing 歌单
- [ ] 应用启动时恢复播放队列

#### 4.2 云同步逻辑
- [ ] 登录时自动同步云端歌单
- [ ] 登出时清理本地缓存
- [ ] 冲突解决策略（最后写入胜出）

#### 4.3 错误处理
- [ ] 网络异常降级到本地存储
- [ ] 同步失败提示用户

---

## 五、关键文件清单

### 后端
| 文件 | 操作 | 说明 |
|------|------|------|
| `config/database.js` | 修改 | 添加3张新表 |
| `services/playlistService.js` | 新建 | 歌单业务逻辑 |
| `services/recommendationService.js` | 新建 | 推荐内容服务 |
| `services/playHistoryService.js` | 新建 | 播放历史服务 |
| `controllers/playlistController.js` | 新建 | 歌单控制器 |
| `controllers/recommendationController.js` | 新建 | 推荐控制器 |
| `controllers/playHistoryController.js` | 新建 | 历史控制器 |
| `routes/playlists.js` | 新建 | 歌单路由 |
| `routes/recommendations.js` | 新建 | 推荐路由 |
| `routes/history.js` | 新建 | 历史路由 |
| `index.js` | 修改 | 注册新路由 |

### 前端
| 文件 | 操作 | 说明 |
|------|------|------|
| `models/playlist.dart` | 新建 | 歌单数据模型 |
| `providers/playlist_provider.dart` | 新建 | 歌单状态管理 |
| `providers/play_history_provider.dart` | 新建 | 历史状态管理 |
| `services/playlist_manager.dart` | 修改 | 扩展本地存储 |
| `services/playlistApiService.dart` | 新建 | 歌单API调用 |
| `ui/pages/explore_page.dart` | 重写 | 推荐页面 |
| `ui/pages/playlist_library_page.dart` | 新建 | 歌单列表 |
| `ui/pages/playlist_detail_page.dart` | 新建 | 歌单详情 |
| `ui/pages/play_history_page.dart` | 新建 | 播放历史 |
| `ui/pages/home_page.dart` | 修改 | 添加收藏按钮 |
| `ui/pages/search_page.dart` | 修改 | 添加收藏入口 |
| `ui/components/my_drawer.dart` | 修改 | 添加新入口 |
| `routes/router.dart` | 修改 | 注册新路由 |
| `main.dart` | 修改 | 注册新Provider |

---

## 六、B站API参考

| 功能 | 端点 | 参数 |
|------|------|------|
| 热门歌单 | `/audio/music-service-c/web/menu/hit` | pn, ps |
| 热歌榜单 | `/audio/music-service-c/web/menu/rank` | pn, ps |
| 分区搜索 | `/x/web-interface/wbi/search/type` | search_type=video, tid=分区ID |
| 综合搜索 | `/x/web-interface/wbi/search/all/v2` | keyword |

**分区ID**: 音乐区(3)、原创音乐(28)、翻唱(31)、演奏(59)、VOCALOID(30)

---

## 七、验收标准

- [ ] 可以创建/编辑/删除歌单
- [ ] 可以从搜索结果和播放器收藏
- [ ] 收藏内容即"我喜欢"歌单
- [ ] 播放队列自动保存为"正在播放"歌单
- [ ] 发现页展示推荐内容
- [ ] 未绑定时隐藏discover或显示引导
- [ ] 播放历史记录完整
- [ ] 登录用户歌单云同步
- [ ] 游客模式本地存储正常

---

## 八、与 Phase 1 的关系

Phase 2 依赖 Phase 1 已完成的基础设施：

| Phase 1 组件 | Phase 2 用途 |
|--------------|--------------|
| `bilibiliService.js` | 获取推荐内容（热门歌单、榜单） |
| `audioService.js` | 获取音频元数据缓存 |
| `BilibiliProvider` | 检查绑定状态，决定是否显示推荐 |
| `audio_metadata_cache` 表 | 减少重复API调用 |

---

*本文档由 Claude Code 生成 | 最后更新: 2026-01-18*
