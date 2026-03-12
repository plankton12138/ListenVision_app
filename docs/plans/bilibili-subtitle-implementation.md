# B站视频字幕获取功能实现方案

**创建日期**: 2026-03-12
**范围**: 仅 B站在线播放视频的 CC 字幕获取与展示
**状态**: ✅ 后端已完成，✅ 前端已完成

---

## 一、背景与目标

当前项目支持 B站视频在线播放（提取音频流），但没有任何字幕/歌词展示能力。B站视频大量配有 AI 生成的 CC 字幕（中文/英文），可以作为音频播放时的文本辅助展示。

**目标**：在播放 B站视频音频时，获取并展示同步字幕，支持自动滚动、当前行高亮。

---

## 二、数据源分析

### 2.1 B站字幕获取流程

字幕获取分两步：

**第一步 — 获取字幕列表**

调用 Player API，返回该视频可用的字幕列表（含语言、URL）：

```
GET https://api.bilibili.com/x/player/wbi/v2?bvid={bvid}&cid={cid}
```

- 需要 WBI 签名（`w_rid` + `wts` 参数）
- 需要登录 Cookie 才能拿到字幕列表（未登录返回空数组）
- 项目已有 WBI 签名机制（`signWbi()`）和 Cookie 管理

响应中的字幕结构：
```json
{
  "subtitle": {
    "subtitles": [
      {
        "lan": "zh-Hans",
        "lan_doc": "中文（简体）",
        "subtitle_url": "//aisubtitle.hdslb.com/bfs/subtitle/xxx.json?auth_key=..."
      },
      {
        "lan": "en-US",
        "lan_doc": "英语（美国）",
        "subtitle_url": "//aisubtitle.hdslb.com/bfs/subtitle/yyy.json?auth_key=..."
      }
    ]
  }
}
```

参考文档：`references/bilibili-API-collect/docs/video/player.md`

**第二步 — 获取字幕内容**

直接请求 `subtitle_url` 获取 JSON 字幕文件：

```
GET https://aisubtitle.hdslb.com/bfs/subtitle/xxx.json?auth_key=...
```

字幕 JSON 格式（B站标准）：
```json
{
  "body": [
    { "from": 0.0, "to": 3.5, "content": "大家好" },
    { "from": 3.5, "to": 7.2, "content": "今天我们来聊一聊" },
    { "from": 7.2, "to": 12.0, "content": "这个话题" }
  ]
}
```

- `from`/`to`: 秒数（浮点），标记字幕的起止时间
- `content`: 字幕文本
- 无需额外认证（URL 已含 auth_key）

### 2.2 关键前置条件

| 条件 | 现状 | 说明 |
|------|------|------|
| bvid | ✅ 已有 | 视频标识，播放时已知 |
| cid | ✅ 已有 | `getVideoInfo()` 已返回 `cid` 字段 |
| WBI 签名 | ✅ 已有 | `signWbi()` 方法已实现 |
| 用户 Cookie | ✅ 已有 | 登录绑定后已存储加密 Cookie |
| 字幕获取 | ❌ 未实现 | 需新增 |

### 2.3 限制与注意事项

- **必须登录**：未登录用户无法获取字幕列表（`subtitles` 为空数组）
- **非所有视频都有字幕**：仅部分视频有 AI 生成或人工上传的字幕
- **subtitle_url 有有效期**：`auth_key` 有过期时间，不宜长期缓存 URL 本身，应缓存字幕内容
- **多语言**：同一视频可能有多个语言的字幕

---

## 三、后端实现方案

### 3.1 新增方法 — `bilibiliService.js`

**文件**: `listen-vision_api/services/bilibiliService.js`

新增 `getVideoSubtitles(bvid, userId)` 方法：

```javascript
/**
 * 获取视频字幕列表及内容
 * @param {string} bvid - 视频 BV 号
 * @param {number} userId - 用户 ID（用于获取绑定的 Cookie）
 * @returns {Promise<Object>} { subtitles: [{ lan, lan_doc, lines }] }
 */
const getVideoSubtitles = async (bvid, userId) => {
  // 1. 获取视频 cid
  const videoInfo = await getVideoInfo(bvid);
  const cid = videoInfo.cid;

  // 2. 获取用户 Cookie
  const cookie = getUserCookie(userId); // 已有方法
  if (!cookie) {
    throw new Error('需要绑定B站账号才能获取字幕');
  }

  // 3. 调用 Player API（WBI 签名）获取字幕列表
  const wbiKey = await getWbiKey();
  const params = signWbi({ bvid, cid }, wbiKey);
  const queryString = new URLSearchParams(params).toString();
  const playerUrl = `https://api.bilibili.com/x/player/wbi/v2?${queryString}`;

  const playerData = await httpGet(playerUrl, {
    Cookie: cookie,
    Referer: 'https://www.bilibili.com',
  });

  if (playerData.code !== 0) {
    throw new Error(playerData.message || '获取字幕信息失败');
  }

  const subtitleList = playerData.data?.subtitle?.subtitles || [];
  if (subtitleList.length === 0) {
    return { bvid, cid, subtitles: [] };
  }

  // 4. 获取字幕内容（优先中文，回退第一个）
  const results = [];
  for (const sub of subtitleList) {
    const subtitleUrl = sub.subtitle_url.startsWith('//')
      ? `https:${sub.subtitle_url}`
      : sub.subtitle_url;

    const subtitleData = await httpGet(subtitleUrl);
    results.push({
      lan: sub.lan,
      lan_doc: sub.lan_doc,
      lines: (subtitleData.body || []).map(line => ({
        from: line.from,
        to: line.to,
        content: line.content,
      })),
    });
  }

  return { bvid, cid, subtitles: results };
};
```

**关键设计决策**：
- 一次请求返回所有可用语言的字幕内容，避免前端多次请求
- 由后端代理字幕 URL 请求，携带正确的 Cookie 和 Referer
- 复用已有的 `getVideoInfo` 获取 cid、`getWbiKey` + `signWbi` 做签名

### 3.2 新增方法 — `bilibiliController.js`

**文件**: `listen-vision_api/controllers/bilibiliController.js`

```javascript
/**
 * 获取视频字幕
 * GET /api/v1/bilibili/subtitle/:bvid
 */
const getSubtitle = catchAsync(async (req, res) => {
  const { bvid } = req.params;
  if (!bvid) {
    return errorResponse(res, '缺少 bvid 参数', 400);
  }

  const userId = req.user?.id;
  if (!userId) {
    return errorResponse(res, '需要登录才能获取字幕', 401);
  }

  const result = await bilibiliService.getVideoSubtitles(bvid, userId);
  successResponse(res, result, '获取字幕成功');
});
```

### 3.3 新增路由 — `bilibili.js`

**文件**: `listen-vision_api/routes/bilibili.js`

```javascript
// 获取视频字幕
router.get('/subtitle/:bvid', authMiddleware, bilibiliController.getSubtitle);
```

**完整 API 定义**：

```
GET /api/v1/bilibili/subtitle/:bvid

Headers:
  Authorization: Bearer <token>

Response 200:
{
  "success": true,
  "data": {
    "bvid": "BV1xx411c7mD",
    "cid": 123456,
    "subtitles": [
      {
        "lan": "zh-Hans",
        "lan_doc": "中文（简体）",
        "lines": [
          { "from": 0.0, "to": 3.5, "content": "大家好" },
          { "from": 3.5, "to": 7.2, "content": "今天我们来聊一聊" }
        ]
      },
      {
        "lan": "en-US",
        "lan_doc": "英语（美国）",
        "lines": [
          { "from": 0.0, "to": 3.5, "content": "Hello everyone" },
          { "from": 3.5, "to": 7.2, "content": "Today we'll talk about" }
        ]
      }
    ]
  },
  "message": "获取字幕成功"
}

Response 200 (无字幕):
{
  "success": true,
  "data": { "bvid": "...", "cid": 123456, "subtitles": [] },
  "message": "获取字幕成功"
}

Response 401:
{ "success": false, "error": "需要登录才能获取字幕" }
```

### 3.4 字幕缓存表（可选优化）

**文件**: `listen-vision_api/config/database.js`

```sql
CREATE TABLE IF NOT EXISTS subtitle_cache (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  bvid TEXT NOT NULL,
  cid INTEGER NOT NULL,
  lan TEXT NOT NULL,
  lan_doc TEXT NOT NULL,
  content TEXT NOT NULL,        -- JSON 序列化的 lines 数组
  created_at TEXT DEFAULT (datetime('now')),
  UNIQUE(bvid, lan)
);
```

缓存策略：首次获取后存入 `subtitle_cache`，后续请求直接返回缓存数据。字幕内容本身不会变化，可以长期缓存。

### 3.5 后端文件变更汇总

| 文件 | 操作 | 改动内容 |
|------|------|----------|
| `listen-vision_api/services/bilibiliService.js` | 修改 | 新增 `getVideoSubtitles()` + 导出 |
| `listen-vision_api/controllers/bilibiliController.js` | 修改 | 新增 `getSubtitle` 控制器 |
| `listen-vision_api/routes/bilibili.js` | 修改 | 新增 `GET /subtitle/:bvid` 路由 |
| `listen-vision_api/config/database.js` | 修改 | 新增 `subtitle_cache` 表（可选） |

---

## 四、前端实现方案

### 4.1 新增模型 — `models/subtitle.dart`

**文件**: `frontend_flutter/lib/models/subtitle.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'subtitle.freezed.dart';
part 'subtitle.g.dart';

/// 单条字幕行
@freezed
class SubtitleLine with _$SubtitleLine {
  const factory SubtitleLine({
    required double from,       // 起始时间（秒）
    required double to,         // 结束时间（秒）
    required String content,    // 字幕文本
  }) = _SubtitleLine;

  factory SubtitleLine.fromJson(Map<String, dynamic> json) =>
      _$SubtitleLineFromJson(json);
}

/// 单语言字幕数据
@freezed
class SubtitleTrack with _$SubtitleTrack {
  const factory SubtitleTrack({
    required String lan,        // 语言代码 (zh-Hans, en-US)
    required String lanDoc,     // 语言名称 (中文（简体）)
    required List<SubtitleLine> lines,
  }) = _SubtitleTrack;

  factory SubtitleTrack.fromJson(Map<String, dynamic> json) =>
      _$SubtitleTrackFromJson(json);
}

/// 视频字幕响应
@freezed
class SubtitleData with _$SubtitleData {
  const factory SubtitleData({
    required String bvid,
    required int cid,
    required List<SubtitleTrack> subtitles,
  }) = _SubtitleData;

  factory SubtitleData.fromJson(Map<String, dynamic> json) =>
      _$SubtitleDataFromJson(json);
}
```

### 4.2 新增端点常量

**文件**: `frontend_flutter/lib/core/network/endpoints.dart`

```dart
// Bilibili 字幕
static String bilibiliSubtitle(String bvid) => '/bilibili/subtitle/$bvid';
```

### 4.3 新增 API 客户端方法

**文件**: `frontend_flutter/lib/core/network/api_client.dart`

```dart
/// 获取B站视频字幕
Future<SubtitleData> getBilibiliSubtitle(String bvid) async {
  try {
    final response = await _dioClient.get(Endpoints.bilibiliSubtitle(bvid));
    final data = _handleResponse(response) as Map<String, dynamic>;
    AppLogger.info('ApiClient', '获取字幕成功: $bvid');
    return SubtitleData.fromJson(data);
  } catch (e) {
    AppLogger.error('ApiClient', '获取字幕失败: $e');
    rethrow;
  }
}
```

### 4.4 新增字幕 DAO（本地缓存）

**文件**: `frontend_flutter/lib/data/database/subtitle_dao.dart`

```dart
import 'dart:convert';
import 'package:sqflite/sqflite.dart';

class SubtitleDao {
  final Database _db;

  SubtitleDao(this._db);

  /// 建表语句（在 DatabaseHelper 中调用）
  static const String createTableSql = '''
    CREATE TABLE IF NOT EXISTS subtitle_cache (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      bvid TEXT NOT NULL,
      lan TEXT NOT NULL,
      lan_doc TEXT NOT NULL,
      content TEXT NOT NULL,
      created_at TEXT DEFAULT (datetime('now')),
      UNIQUE(bvid, lan)
    )
  ''';

  /// 保存字幕到缓存
  Future<void> saveSubtitle(String bvid, String lan, String lanDoc, List<Map<String, dynamic>> lines) async {
    await _db.insert(
      'subtitle_cache',
      {
        'bvid': bvid,
        'lan': lan,
        'lan_doc': lanDoc,
        'content': jsonEncode(lines),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 查询缓存的字幕
  Future<List<Map<String, dynamic>>?> getSubtitle(String bvid) async {
    final rows = await _db.query(
      'subtitle_cache',
      where: 'bvid = ?',
      whereArgs: [bvid],
    );
    if (rows.isEmpty) return null;
    return rows;
  }

  /// 删除指定视频的字幕缓存
  Future<void> deleteSubtitle(String bvid) async {
    await _db.delete('subtitle_cache', where: 'bvid = ?', whereArgs: [bvid]);
  }
}
```

### 4.5 新增字幕仓库

**文件**: `frontend_flutter/lib/data/repositories/subtitle_repository.dart`

```dart
/// 字幕仓库 — 本地优先，网络回退
class SubtitleRepository {
  final SubtitleDao _dao;
  final ApiClient _apiClient;

  SubtitleRepository(this._dao, this._apiClient);

  /// 获取字幕（本地缓存优先）
  Future<SubtitleData?> getSubtitle(String bvid) async {
    // 1. 尝试本地缓存
    final cached = await _dao.getSubtitle(bvid);
    if (cached != null && cached.isNotEmpty) {
      return _buildFromCache(bvid, cached);
    }

    // 2. 网络获取
    try {
      final data = await _apiClient.getBilibiliSubtitle(bvid);
      // 3. 存入缓存
      for (final track in data.subtitles) {
        await _dao.saveSubtitle(
          bvid,
          track.lan,
          track.lanDoc,
          track.lines.map((l) => l.toJson()).toList(),
        );
      }
      return data;
    } catch (e) {
      AppLogger.warn('SubtitleRepository', '获取字幕失败: $e');
      return null; // 字幕获取失败不影响播放
    }
  }
}
```

### 4.6 新增字幕 ViewModel

**文件**: `frontend_flutter/lib/presentation/viewmodels/player/subtitle_viewmodel.dart`

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'subtitle_viewmodel.g.dart';

/// 字幕状态
@freezed
class SubtitleState with _$SubtitleState {
  const factory SubtitleState({
    @Default(null) SubtitleData? data,           // 字幕数据
    @Default(null) SubtitleTrack? activeTrack,   // 当前激活的语言
    @Default(-1) int currentLineIndex,           // 当前高亮行索引
    @Default(false) bool isLoading,
    @Default(false) bool isVisible,              // 字幕面板是否展开
    @Default(null) String? error,
  }) = _SubtitleState;
}

@riverpod
class SubtitleViewModel extends _$SubtitleViewModel {
  @override
  SubtitleState build() => const SubtitleState();

  /// 加载字幕
  Future<void> loadSubtitle(String bvid) async {
    if (state.data?.bvid == bvid) return; // 已加载
    state = state.copyWith(isLoading: true, error: null);

    final repo = ref.read(subtitleRepositoryProvider);
    final data = await repo.getSubtitle(bvid);

    if (data != null && data.subtitles.isNotEmpty) {
      // 默认选中中文字幕，无中文则选第一个
      final defaultTrack = data.subtitles.firstWhere(
        (t) => t.lan.startsWith('zh'),
        orElse: () => data.subtitles.first,
      );
      state = state.copyWith(
        data: data,
        activeTrack: defaultTrack,
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        data: data,
        activeTrack: null,
        isLoading: false,
      );
    }
  }

  /// 根据播放进度更新当前行（由 PlayerViewModel 调用）
  void updatePosition(Duration position) {
    final track = state.activeTrack;
    if (track == null) return;

    final seconds = position.inMilliseconds / 1000.0;
    final lines = track.lines;

    // 二分查找当前行
    int index = _findCurrentLine(lines, seconds);
    if (index != state.currentLineIndex) {
      state = state.copyWith(currentLineIndex: index);
    }
  }

  /// 切换字幕语言
  void switchLanguage(String lan) {
    final track = state.data?.subtitles.firstWhere((t) => t.lan == lan);
    if (track != null) {
      state = state.copyWith(activeTrack: track, currentLineIndex: -1);
    }
  }

  /// 切换字幕显示/隐藏
  void toggleVisibility() {
    state = state.copyWith(isVisible: !state.isVisible);
  }

  /// 清除字幕（切歌时调用）
  void clear() {
    state = const SubtitleState();
  }

  /// 二分查找：找到最后一个 from <= position 且 to > position 的行
  int _findCurrentLine(List<SubtitleLine> lines, double position) {
    if (lines.isEmpty) return -1;

    int low = 0, high = lines.length - 1;
    int result = -1;

    while (low <= high) {
      int mid = (low + high) ~/ 2;
      if (lines[mid].from <= position) {
        if (lines[mid].to > position) result = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    return result;
  }
}
```

### 4.7 新增字幕 UI 组件

**文件**: `frontend_flutter/lib/presentation/widgets/player/subtitle_view.dart`

```dart
/// 字幕滚动展示组件
///
/// 功能：
/// 1. 自动跟随播放进度滚动
/// 2. 当前行高亮显示
/// 3. 点击字幕行可跳转播放位置
/// 4. 语言切换（多语言时显示切换按钮）
/// 5. 上下文显示（当前行上下各保留若干行）
class SubtitleView extends ConsumerStatefulWidget {
  @override
  ConsumerState<SubtitleView> createState() => _SubtitleViewState();
}

class _SubtitleViewState extends ConsumerState<SubtitleView> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final subtitleState = ref.watch(subtitleViewModelProvider);
    final track = subtitleState.activeTrack;

    if (track == null || track.lines.isEmpty) {
      return _buildEmptyState(subtitleState);
    }

    return Column(
      children: [
        // 语言切换栏（多语言时显示）
        if ((subtitleState.data?.subtitles.length ?? 0) > 1)
          _buildLanguageSwitcher(subtitleState),
        // 字幕列表
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: track.lines.length,
            itemBuilder: (context, index) {
              final line = track.lines[index];
              final isCurrent = index == subtitleState.currentLineIndex;
              return _buildSubtitleLine(line, isCurrent, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubtitleLine(SubtitleLine line, bool isCurrent, int index) {
    return GestureDetector(
      onTap: () => _seekTo(line.from),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Text(
          line.content,
          style: TextStyle(
            fontSize: isCurrent ? 18 : 15,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isCurrent
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
```

### 4.8 集成到播放器 — 位置同步

**文件**: `frontend_flutter/lib/presentation/viewmodels/player/player_viewmodel.dart`

在现有的 `positionStream` 监听回调中，增加字幕位置更新：

```dart
// 在 positionStream 回调中追加：
ref.read(subtitleViewModelProvider.notifier).updatePosition(position);
```

在切歌逻辑中，增加字幕加载/清除：

```dart
// 播放新曲目时
Future<void> _onTrackChanged(PlayableAudio audio) async {
  // ...existing logic...
  
  // 加载字幕（仅在线B站视频）
  if (audio is OnlinePlayable && audio.bvid != null) {
    ref.read(subtitleViewModelProvider.notifier).loadSubtitle(audio.bvid);
  } else {
    ref.read(subtitleViewModelProvider.notifier).clear();
  }
}
```

### 4.9 前端文件变更汇总

| 文件 | 操作 | 改动内容 |
|------|------|----------|
| `lib/models/subtitle.dart` | **新建** | SubtitleLine, SubtitleTrack, SubtitleData 模型 |
| `lib/core/network/endpoints.dart` | 修改 | 新增 `bilibiliSubtitle()` 端点 |
| `lib/core/network/api_client.dart` | 修改 | 新增 `getBilibiliSubtitle()` 方法 |
| `lib/data/database/subtitle_dao.dart` | **新建** | 字幕本地缓存 DAO |
| `lib/data/database/database_helper.dart` | 修改 | `onCreate` 中增加字幕表建表 |
| `lib/data/repositories/subtitle_repository.dart` | **新建** | 字幕仓库（本地优先） |
| `lib/presentation/viewmodels/player/subtitle_viewmodel.dart` | **新建** | 字幕状态管理 + 二分查找定位 |
| `lib/presentation/widgets/player/subtitle_view.dart` | **新建** | 字幕 UI 组件（滚动+高亮+跳转） |
| `lib/presentation/viewmodels/player/player_viewmodel.dart` | 修改 | 位置同步 + 切歌字幕加载 |
| `lib/presentation/providers.dart` | 修改 | 导出字幕相关 provider |

---

## 五、数据流全景

```
                    ┌─────────────────────────────┐
                    │       B站 API 服务器          │
                    │  /x/player/wbi/v2 (字幕列表) │
                    │  aisubtitle.hdslb.com (内容)  │
                    └──────────┬──────────────────┘
                               │ HTTP (带 Cookie + WBI 签名)
                    ┌──────────▼──────────────────┐
                    │   后端 Node.js (代理+缓存)    │
                    │  GET /api/v1/bilibili/       │
                    │       subtitle/:bvid         │
                    │  ┌─────────────────────┐     │
                    │  │  subtitle_cache 表   │     │
                    │  └─────────────────────┘     │
                    └──────────┬──────────────────┘
                               │ HTTP (Bearer Token)
                    ┌──────────▼──────────────────┐
                    │   前端 Flutter               │
                    │                              │
                    │  ApiClient                   │
                    │      ↓                       │
                    │  SubtitleRepository           │
                    │    ├─ SubtitleDao (本地缓存)   │
                    │    └─ ApiClient (网络获取)     │
                    │      ↓                       │
                    │  SubtitleViewModel            │
                    │    ├─ loadSubtitle()          │
                    │    ├─ updatePosition() ← 100ms│
                    │    └─ switchLanguage()        │
                    │      ↓                       │
                    │  SubtitleView (UI)            │
                    │    ├─ 自动滚动                 │
                    │    ├─ 当前行高亮               │
                    │    └─ 点击跳转                 │
                    └─────────────────────────────┘
```

---

## 六、播放器集成时序图

```
用户点击播放 B站视频
      │
      ├─→ PlayerViewModel.play(audio)
      │     ├─→ AudioPlayerService.play(streamUrl)
      │     └─→ SubtitleViewModel.loadSubtitle(bvid)
      │           │
      │           ├─→ SubtitleDao.getSubtitle(bvid)
      │           │     ├─ 命中缓存 → 直接使用
      │           │     └─ 未命中 → ApiClient.getBilibiliSubtitle(bvid)
      │           │                    │
      │           │                    └─→ 后端 /bilibili/subtitle/:bvid
      │           │                          ├─→ subtitle_cache 查缓存
      │           │                          └─→ B站 API 获取 → 存缓存 → 返回
      │           │
      │           └─→ 更新 SubtitleState (data + activeTrack)
      │
      ├─→ [每 100ms] positionStream 触发
      │     └─→ SubtitleViewModel.updatePosition(position)
      │           └─→ 二分查找 currentLineIndex → UI 更新
      │
      └─→ SubtitleView 渲染
            ├─ ListView 滚动到 currentLineIndex
            └─ 当前行高亮 + 前后行淡色
```

---

## 七、UI 交互设计

### 7.1 字幕展示位置

在播放器页面中新增字幕展示区域，有两种交互模式：

**模式 A — 播放页内嵌（推荐）**：
```
┌─────────────────────────┐
│       封面 / 唱片动画     │
├─────────────────────────┤
│   ▲ 前一句字幕（灰色）    │
│   ★ 当前字幕（高亮+大字）  │  ← 字幕区域（可滚动）
│   ▼ 下一句字幕（灰色）    │
├─────────────────────────┤
│  ◄◄   ▶/❚❚   ►►  进度条  │
│  [字幕] [语言] [列表]     │  ← 字幕开关按钮
└─────────────────────────┘
```

**模式 B — 全屏字幕页**：
- 点击封面区域切换为全屏字幕模式
- 所有字幕行居中显示，当前行放大高亮
- 类似 Apple Music 歌词全屏效果

### 7.2 交互行为

| 操作 | 行为 |
|------|------|
| 播放时 | 字幕自动滚动，当前行高亮 |
| 点击字幕行 | 跳转到该行对应的播放时间 |
| 点击「字幕」按钮 | 切换字幕显示/隐藏 |
| 点击「语言」按钮 | 弹出语言选择菜单（多语言时） |
| 切歌 | 自动清除旧字幕、加载新字幕 |
| 无字幕 | 显示「该视频暂无字幕」提示 |
| 加载中 | 显示加载指示器 |
| 未登录B站 | 显示「绑定B站账号后可查看字幕」 |

---

## 八、错误处理

| 场景 | 处理方式 |
|------|----------|
| 用户未绑定B站账号 | 字幕区域提示「绑定B站后可查看字幕」，不阻塞播放 |
| 视频无字幕 | 字幕区域提示「该视频暂无字幕」 |
| 网络请求失败 | 静默失败，不显示字幕，不影响播放 |
| subtitle_url 过期 | 后端重新请求 Player API 获取新 URL |
| 字幕数据格式异常 | 跳过异常行，显示可解析的部分 |

**核心原则**：字幕是辅助功能，任何字幕相关错误都不能影响音频播放。

---

## 九、实施阶段

### Phase 1：后端字幕 API（1 个工作单元）—— ✅ 已完成 (2026-03-12)

1. ✅ `bilibiliService.js` — 新增 `getVideoSubtitles()` 方法
2. ✅ `bilibiliController.js` — 新增 `getSubtitle` 控制器
3. ✅ `routes/bilibili.js` — 新增路由 `GET /subtitle/:bvid`
4. ✅ `config/database.js` — 新增 `subtitle_cache` 缓存表
5. ✅ 编写后端测试用例（5 个测试全部通过）

### Phase 2：前端模型与数据层（1 个工作单元）

1. `models/subtitle.dart` — 创建 freezed 模型
2. 运行 `build_runner` 生成代码
3. `endpoints.dart` — 新增端点常量
4. `api_client.dart` — 新增 API 方法
5. `subtitle_dao.dart` — 创建本地缓存 DAO
6. `database_helper.dart` — 增加建表
7. `subtitle_repository.dart` — 创建仓库

### Phase 3：字幕 ViewModel（1 个工作单元）

1. `subtitle_viewmodel.dart` — 创建 ViewModel（加载、定位、切换语言）
2. 运行 `build_runner` 生成代码
3. `player_viewmodel.dart` — 集成位置同步
4. `providers.dart` — 导出

### Phase 4：字幕 UI 与集成（1 个工作单元）

1. `subtitle_view.dart` — 创建字幕 UI 组件
2. 集成到播放器页面
3. 添加字幕开关按钮
4. 测试完整流程

### Phase 5：优化与后端缓存（可选）

1. 后端 `subtitle_cache` 表 + 缓存逻辑
2. 字幕预加载（队列中下一首自动预取）
3. 性能优化（节流字幕更新频率）

---

## 十、测试要点

### 后端测试

```javascript
// tests/services/bilibiliService.test.js
describe('getVideoSubtitles', () => {
  it('应返回字幕列表（有字幕的视频）');
  it('应返回空数组（无字幕的视频）');
  it('未绑定账号时应抛出错误');
  it('B站 API 异常时应抛出错误');
});
```

### 前端测试

```dart
// test/viewmodels/subtitle_viewmodel_test.dart
group('SubtitleViewModel', () {
  test('loadSubtitle 加载并选择中文字幕');
  test('updatePosition 正确定位当前行');
  test('updatePosition 处理边界情况（开头/结尾/空隙）');
  test('switchLanguage 切换语言');
  test('clear 清除状态');
});
```

---

## 十一、依赖与风险

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| B站 Player API 需要 WBI 签名 | 中 | 已有 `signWbi()` 实现，直接复用 |
| 字幕需要登录 Cookie | 中 | 未登录时优雅降级（提示绑定账号） |
| B站 API 可能限流 | 低 | 后端缓存 + 前端本地缓存双层保护 |
| 字幕 URL 有效期 | 低 | 缓存字幕内容而非 URL |
| 非所有视频有字幕 | 低 | UI 优雅处理空状态 |
