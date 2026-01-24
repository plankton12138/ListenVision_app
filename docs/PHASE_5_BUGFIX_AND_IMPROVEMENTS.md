# Phase 5: Bug修复与功能改进计划

> **创建日期**: 2026-01-19
> **最后更新**: 2026-01-23（修复音频叠加和启动闪退问题，增强Range请求支持）
>
> **目标**: 修复现有Bug并改进播放列表和推荐功能
>
> **依赖**: Phase 2、3 完成（在线播放、歌单系统）
>
> **状态**: ✅ Phase 2 在线播放已完成，Phase 5 Bug修复已完成（just_audio 迁移 + 格式转换）
>
> **🔄 阶段重排说明**: 原 **Phase 2B** 已重排为 **Phase 5**，调整为低优先级优化阶段
>
> **✅ 重要更新**:
> - Phase 2 在线播放功能已于 2026-01-22 基本完成实现，核心数据流已打通
> - 2026-01-23 修复音频叠加和启动闪退问题，增强HTTP Range请求支持

---

## 一、问题概述

### 当前项目进度仪表盘

| 阶段 | 功能模块 | 状态 | 进度 | 备注 |
|------|---------|------|------|------|
| | **Phase 1** | B站API集成、后端服务 | ✅ 已完成 | 100% | QR登录、元数据缓存、资源代理 |
| | **Phase 2** | **在线播放功能** | ✅ **已完成** | **100%** | 统一播放接口、数据流已打通 |
| | **Phase 3** | 播放列表与收藏云同步 | ✅ 已完成 | 100% | 后端API完整实现 |
| | **Phase 3A** | 播放列表页面改进 | ✅ 已完成 | 100% | 进度持久化、拖拽排序 |
| | **Phase 4** | 搜索推荐、下载服务 | 🚧 部分完成 | 70% | 搜索推荐完成，下载已迁移前端 |
| | **Phase 5** | Bug修复与功能改进 | ✅ 已完成 | 100% | just_audio迁移、Range支持、音频叠加修复 |

**总体进度**: 92% 🔥

### Phase 2 在线播放功能完成确认 ✅

| 功能点 | 实现文件 | 状态 |
|-------|---------|------|
| 统一播放接口 | `domain/entities/playable_audio.dart` | ✅ |
| 在线播放实现 | `domain/entities/online_playable.dart` | ✅ |
| AudioProvider 改造 | `presentation/providers/audio/audio_provider.dart` | ✅ |
| playOnlineAudio 方法 | `audio_provider.dart:458` | ✅ |
| 代理URL构建 | `_buildProxyUrl()` | ✅ |
| 统一播放列表 | `_unifiedPlaylist` | ✅ |
| 搜索页面连接 | `presentation/pages/search_page.dart` | ✅ |
| 发现页面连接 | `presentation/pages/explore_page.dart` | ✅ |
| 歌单详情连接 | `presentation/pages/playlist_detail_page.dart` | ✅ |

---

## 二、问题概述

| 问题类型 | 描述 | 用户期望 | 优先级 | 状态 |
|---------|------|---------|--------|------|
| Bug | 搜索结果点击加入歌单后页面卡死 | 正常添加并给予反馈 | 🔴 高 | ✅ 已解决 |
| Bug | 音频播放器加载状态异常 | 只在需要时显示加载状态 | 🔴 高 | ✅ 已解决（just_audio迁移） |
| 功能 | 发现页面榜单内容单一 | 未来接入QQ音乐榜单 | 🟢 低 | 📋 计划中 |
| 功能 | 播放列表功能匮乏 | 添加变更播放顺序和添加歌曲功能 | 🟡 中 | ⏸️ 待实施 |
| 架构 | 下载任务管理依赖后端 | 前端本地化实现，减少网络开销 | 🟡 中 | ✅ 已完成 |

---

## 二、问题1.5：音频播放器加载状态异常 🔴

### 2.1 问题描述

**用户反馈** (2026-01-22):
- 点击播放后显示"加载中"或"缓冲中"状态，即使播放已经开始
- **本地音频也会显示加载状态**（不应该发生）
- 在线音频拖动进度后会持续"缓冲中"，需要手动暂停再播放才能恢复
- 点击暂停按钮会进入"缓冲中"状态（错误的状态转换）

### 2.2 根本原因分析

**【audioplayers 包的局限性】**

| 特性 | audioplayers | just_audio | 说明 |
|------|--------------|------------|------|
| PlayerState 枚举 | `playing`, `paused`, `stopped`, `completed` | 额外包含 `buffering` | audioplayers 缺少专门的缓冲状态 |
| 缓冲检测 | 通过状态变化推断 | 直接监听 `buffering` | 需要额外的逻辑判断 |
| 流媒体支持 | 基础 | 优秀 | just_audio 对在线流支持更好 |
| Windows 支持 | ✅ 完整支持 | ❌ 已停止维护 | Windows 平台选择限制 |

**【代码层面的问题】**

| 文件 | 行号 | 问题 |
|------|------|------|
| `lib/presentation/providers/audio/audio_provider.dart` | 162-203 | `_updatePlayState` 通过 `playing → paused` 转换推断缓冲，无法区分用户主动暂停 |
| `lib/presentation/providers/audio/audio_provider.dart` | 363-383 | `togglePlayPause` 没有正确设置状态标志 |
| `lib/presentation/providers/audio/audio_provider.dart` | 388-417 | `seek` 后没有尝试恢复播放状态 |
| `lib/presentation/widgets/controls_panel.dart` | 50-85 | `isLoading` getter 逻辑依赖不准确的状态判断 |

### 2.3 已尝试的修复方案

**方案1：添加 `_userPaused` 标志** (部分成功)
```dart
// 区分用户主动暂停和缓冲暂停
bool _userPaused = false;

void togglePlayPause() async {
  if (_isPlaying) {
    _userPaused = true;  // 标记用户主动暂停
    _isBuffering = false;
    await _player.pause();
  }
}
```

**方案2：只为在线音频检测缓冲状态**
```dart
void _updatePlayState(PlayerState state) {
  if (_isCurrentOnline) {
    // 只对在线音频检测缓冲
    if (wasPlaying && state == PlayerState.paused && !_userPaused && !_isSeeking) {
      _isBuffering = true;
    }
  }
  // 本地音频不检测缓冲
}
```

**方案3：seek 后尝试恢复播放**
```dart
Future<void> seek(Duration position) async {
  final wasPlaying = _isPlaying;
  // ...
  await _player.seek(position);
  if (wasPlaying && _player.state == PlayerState.paused) {
    await _player.resume();
  }
}
```

**修复结果**: 部分问题仍然存在，需要更根本的解决方案。

### 2.4 推荐的解决方案

#### 方案A：简化加载状态逻辑（短期）

**设计思路**: 移除所有自动缓冲检测，只在明确的加载操作时显示加载状态。

**需要修改**:
1. `isLoading` getter - 改为基于明确的加载事件
2. 移除 `_updatePlayState` 中的缓冲推断逻辑
3. 只在 `playOnlineAudio`、`seek` 等明确操作时设置加载状态

**优点**: 简单、可控、不会误判
**缺点**: 无法显示真实的网络缓冲状态

#### 方案B：迁移到 just_audio 插件（推荐）

**设计思路**: 使用 `just_audio` 插件，它有专门的 `buffering` 状态。

**优点**:
- ✅ 有专门的 `ProcessingState.buffering` 状态
- ✅ 更好的流媒体支持
- ✅ 更精确的状态管理

**缺点**:
- ❌ Windows 平台支持已被废弃
- ❌ 需要大量代码重构
- ❌ API 更复杂

**迁移工作量估算**:
| 模块 | 修改量 | 说明 |
|------|--------|------|
| AudioProvider | 中等 | 状态监听逻辑重写 |
| 控制面板 | 小 | 适配新的状态类型 |
| 错误处理 | 中等 | just_audio 的异常体系不同 |

#### 方案C：后端音频格式转换

**设计思路**: 在后端使用 FFmpeg 将 B站音频流从 `.m4s` 转换为 `.mp3` 格式。

**当前问题**: B站音频流是 `.m4s` 格式（分片 MP4），Windows Media Foundation 不支持。

**实现方式**:
```javascript
// listen-vision_api/services/audioService.js
const ffmpeg = require('fluent-ffmpeg');

async function convertAudioStream(inputStream) {
  return new Promise((resolve, reject) => {
    ffmpeg(inputStream)
      .format('mp3')
      .audioBitrate(128)
      .on('end', () => resolve())
      .on('error', (err) => reject(err))
      .pipe(outputStream);
  });
}
```

**优点**: 格式兼容性更好
**缺点**: 增加服务器负载、转换延迟

### 2.5 待实施步骤

1. **立即**: 参考 [AUDIO_PLAYER_FIX_PLAN.md](./AUDIO_PLAYER_FIX_PLAN.md) 实施综合修复方案
   - 方案 A: 迁移到 just_audio（彻底解决状态检测问题）
   - 方案 B: 后端音频格式转换（解决 m4s 兼容性问题）
2. **短期**: 按计划文档执行前端迁移（1周）
3. **中期**: 按计划文档执行后端改造（1周）

### 2.6 关键文件清单

| 文件 | 操作 | 优先级 | 状态 |
|------|------|--------|------|
| `docs/AUDIO_PLAYER_FIX_PLAN.md` | 新建 - 综合修复方案 | 🔴 高 | ✅ 已创建 |
| `pubspec.yaml` | 修改 - 添加 just_audio 依赖 | 🔴 高 | ⏸️ 待开始 |
| `presentation/providers/audio/audio_provider.dart` | 重写 - just_audio 实现 | 🔴 高 | ⏸️ 待开始 |
| `presentation/widgets/controls_panel.dart` | 修改 - 适配新状态 | 🔴 高 | ⏸️ 待开始 |
| `presentation/widgets/audio_info.dart` | 修改 - 封面显示 | 🟡 中 | ⏸️ 待开始 |
| `core/constants/api_constants.dart` | 修改 - 格式配置 | 🟡 中 | ⏸️ 待开始 |
| `services/audioService.js` | 新建 - 格式转换服务 | 🔴 高 | ⏸️ 待开始 |
| `routes/bilibili.js` | 修改 - 代理路由 | 🔴 高 | ⏸️ 待开始 |

---

## 二、问题1：搜索结果加入歌单后页面卡死 ✅

### 2.1 问题描述（已解决）

这是一个典型的异步操作缺少状态管理导致的问题。根本原因：
- 没有loading状态，用户可能重复点击
- API超时设置30秒，如果后端无响应会长时间等待
- 同步IO操作可能阻塞UI线程

**【核心代码位置】**
| 文件 | 行号 | 问题 |
|------|------|------|
| `frontend_flutter/lib/ui/pages/search_page.dart` | 262-301 | 没有loading状态，可能多次点击 |
| `frontend_flutter/lib/providers/playlist_provider.dart` | 238-274 | `_saveFavoritesToLocal()` 同步IO阻塞 |
| `frontend_flutter/lib/services/api_service.dart` | 212-219 | 30秒超时无取消机制 |

### 2.2 修复方案

#### 方案1：添加loading状态
```dart
// search_page.dart
bool _isAddingToPlaylist = false;

onPressed: _isAddingToPlaylist ? null : () async {
  _isAddingToPlaylist = true;
  notifyListeners();

  try {
    await playlistProvider.addItem(...);
  } finally {
    _isAddingToPlaylist = false;
    notifyListeners();
  }
}
```

#### 方案2：使用Isolate执行耗时操作
```dart
// playlist_provider.dart
import 'dart:async';

Future<PlaylistItem?> addItem(...) async {
  // 使用 compute 将耗时操作放到隔离线程
  await compute(_saveToLocal, item);
}
```

#### 方案3：添加超时提示
```dart
// api_service.dart
.timeout(
  const Duration(seconds: 10),
  onTimeout: () => throw TimeoutException('请求超时，请检查网络连接'),
)
```

### 2.3 验收标准
- [ ] 点击"加入歌单"后显示loading状态
- [ ] 网络请求超时后显示友好提示
- [ ] 操作过程中按钮不可点击
- [ ] 操作完成后自动恢复

---

## 三、问题2：发现页面榜单扩展计划 📋

### 3.1 当前实现分析

**【架构结构】**
```
发现页面 (ExplorePage)
├── 前端层 (Flutter)
│   ├── explore_page.dart - UI页面组件
│   ├── bilibili_provider.dart - 状态管理
│   └── bilibiliApiService.dart - API调用
└── 后端层 (Node.js)
    ├── recommendations.js - 路由层
    └── recommendationService.js - 业务逻辑层
```

**【当前数据来源】**
| 功能 | 当前API | 问题 |
|------|---------|------|
| 热门歌单 | `bilibili.com/audio/music-service-c/web/menu/hit` | 非个性化 |
| 热歌榜单 | `bilibili.com/audio/music-service-c/web/menu/rank` | 非个性化 |
| 个性化推荐 | 实际调用热门歌单API | 非真正个性化 |

### 3.2 未来方案设计：QQ音乐榜单

**【设计思路】**
接入QQ音乐榜单API，为发现页面榜单Tab提供更丰富的内容来源。

**【技术选型】**
- QQ音乐开放平台 API
- 需要申请开发者密钥

### 3.3 计划实施内容

#### 功能1：QQ音乐榜单集成
- 新歌榜
- 热歌榜
- 古典榜
- 流行榜

#### 功能2：账号绑定（可选）
- 用户可绑定QQ音乐账号
- 获取个性化推荐

### 3.4 验收标准
- [ ] 发现页榜单Tab可切换来源（B站/QQ音乐）
- [ ] QQ音乐榜单数据正常展示
- [ ] 支持多种榜单类型
- [ ] 榜单数据缓存策略

---

## ~~三、问题2：发现页面推荐改为B站音乐区爬取~~ (已废弃)

> **注**: 音乐区爬虫方案已完成开发（`musicCrawlerService.js`），但前端集成已取消。未来将采用QQ音乐榜单方案替代。

**已完成**:
- ✅ `musicCrawlerService.js` - 爬虫服务实现
- ✅ 支持降级方案
- ✅ 反爬虫策略

---

## 四、问题3：播放列表功能扩展（待实施）

### 4.1 当前状态分析

**【已有功能】**
| 功能 | 状态 | 位置 |
|------|------|------|
| 拖拽排序 | ✅ 已实现 | `playlist_detail_page.dart` 使用 `ReorderableListView` |
| 添加歌曲（后端） | ✅ 已实现 | `playlistProvider.addItem()` |
| 添加歌曲（UI） | ❌ 缺失 | 歌单详情页没有入口 |

**【数据流向】**
```
用户操作
    │
    ▼
PlaylistProvider.addItem() ──────→ 后端API
    │                              │
    ▼                              ▼
本地缓存 ←──────────────────── 歌单项数据库
    │
    ▼
notifyListeners()
    │
    ▼
UI更新
```

### 4.2 功能扩展设计

#### 功能1：添加歌曲到歌单

**【UI设计】**
```
歌单详情页顶部
┌──────────────────────────────────────┐
│  歌单名称              [+ 添加歌曲]   │
├──────────────────────────────────────┤
│  歌单项列表...                        │
│                                      │
└──────────────────────────────────────┘
```

**【交互流程】**
```
1. 点击"添加歌曲"按钮
    │
    ▼
2. 显示底部抽屉（BottomSheet）
    │
    ├── 选项1：从搜索结果添加
    ├── 选项2：输入BV号添加
    └── 选项3：从历史记录添加
    │
    ▼
3. 选择歌曲
    │
    ▼
4. 确认添加
    │
    ▼
5. 显示添加成功提示
```

#### 功能2：播放列表顺序管理

**【当前实现】**
- ✅ 拖拽排序已实现
- ✅ 后端 `reorderItems` API已支持

**【需要增强】**
1. **自动排序选项**:
   - 按添加时间（正序/倒序）
   - 按标题字母序
   - 按艺术家字母序
   - 按播放次数

2. **批量操作**:
   - 多选模式
   - 批量删除
   - 批量移动到其他歌单

### 4.3 实施步骤

#### 步骤1：歌单详情页添加"添加歌曲"按钮
**文件**: `frontend_flutter/lib/ui/pages/playlist_detail_page.dart`

```dart
// 在 AppBar 中添加按钮
appBar: AppBar(
  title: Text(widget.playlist.name),
  actions: [
    IconButton(
      icon: Icon(Icons.add),
      onPressed: _showAddSongOptions,
    ),
    IconButton(
      icon: Icon(Icons.sort),
      onPressed: _showSortOptions,
    ),
  ],
),
```

#### 步骤2：创建添加歌曲对话框
**文件**: `frontend_flutter/lib/ui/dialogs/add_song_dialog.dart` (新建)

```dart
class AddSongDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BottomSheet(
      onClosing: () {},
      builder: (context) => Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.search),
              title: Text('从搜索结果添加'),
              onTap: () {
                Navigator.pop(context);
                // 跳转到搜索页面
              },
            ),
            ListTile(
              leading: Icon(Icons.link),
              title: Text('输入BV号添加'),
              onTap: () {
                Navigator.pop(context);
                // 显示输入框
              },
            ),
            ListTile(
              leading: Icon(Icons.history),
              title: Text('从历史记录添加'),
              onTap: () {
                Navigator.pop(context);
                // 显示历史记录选择
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

#### 步骤3：创建排序选项对话框
**文件**: `frontend_flutter/lib/ui/dialogs/sort_options_dialog.dart` (新建)

```dart
class SortOptionsDialog extends StatelessWidget {
  final int playlistId;

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Text('排序方式'),
      children: [
        SimpleDialogOption(
          child: Text('按添加时间（最新）'),
          onPressed: () => _sortPlaylist('added_at_desc'),
        ),
        SimpleDialogOption(
          child: Text('按添加时间（最早）'),
          onPressed: () => _sortPlaylist('added_at_asc'),
        ),
        SimpleDialogOption(
          child: Text('按标题（A-Z）'),
          onPressed: () => _sortPlaylist('title_asc'),
        ),
        SimpleDialogOption(
          child: Text('按艺术家（A-Z）'),
          onPressed: () => _sortPlaylist('artist_asc'),
        ),
      ],
    );
  }

  void _sortPlaylist(String sortType) {
    // 调用后端排序API
  }
}
```

#### 步骤4：后端添加排序API（可选）
**文件**: `listen-vision_api/routes/playlists.js` (修改)

```javascript
// PUT /api/playlists/:id/sort
router.put('/:id/sort', authenticateToken, async (req, res) => {
  try {
    const { sortType } = req.body; // 'added_at_desc', 'title_asc', etc.
    const result = await playlistService.sortPlaylist(req.params.id, sortType);
    res.json(result);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
```

### 4.4 验收标准
- [ ] 歌单详情页有"添加歌曲"按钮
- [ ] 点击后显示添加方式选择
- [ ] 可以通过搜索添加歌曲到歌单
- [ ] 可以输入BV号添加歌曲
- [ ] 可以从历史记录添加歌曲
- [ ] 有排序选项对话框
- [ ] 排序后结果正确显示

---

## 五、关键文件清单

### Phase 2 在线播放功能 ✅ 已完成
| 文件 | 操作 | 优先级 | 状态 |
|------|------|--------|------|
| `domain/entities/playable_audio.dart` | 新建 - 统一播放接口 | 🔴 高 | ✅ 已完成 |
| `domain/entities/online_playable.dart` | 新建 - 在线播放实现 | 🔴 高 | ✅ 已完成 |
| `domain/entities/local_playable.dart` | 新建 - 本地播放实现 | 🔴 高 | ✅ 已完成 |
| `presentation/providers/audio/audio_provider.dart` | 修改 - playOnlineAudio方法 | 🔴 高 | ✅ 已完成 |
| `presentation/pages/search_page.dart` | 修改 - 连接播放器 | 🔴 高 | ✅ 已完成 |
| `presentation/pages/explore_page.dart` | 修改 - 连接播放器 | 🔴 高 | ✅ 已完成 |
| `presentation/pages/playlist_detail_page.dart` | 修改 - 连接播放器 | 🔴 高 | ✅ 已完成 |

### 问题1.5：音频播放器加载状态修复 ✅ 已完成
| 文件 | 操作 | 优先级 | 状态 |
|------|------|--------|------|
| `presentation/providers/audio/audio_provider.dart` | 修改 - 迁移到 just_audio | 🔴 高 | ✅ 已完成 |
| `presentation/widgets/controls_panel.dart` | 修改 - 加载状态显示 | 🔴 高 | ✅ 已完成 |
| `presentation/widgets/audio_info.dart` | 修改 - 封面显示 | 🟡 中 | ✅ 已完成 |
| `pubspec.yaml` | 添加 - just_audio 依赖 | 🔴 高 | ✅ 已完成 |
| `services/audioService.js` | 新建 - FFmpeg格式转换 | 🟡 中 | ✅ 已完成 |
| `routes/bilibili.js` | 修改 - 支持format参数 | 🟡 中 | ✅ 已完成 |
| `core/utils/file_picker_helper.dart` | 修改 - 改用file_selector | 🟡 中 | ✅ 已完成 |
| `presentation/providers/audio/audio_player_provider.dart` | 删除 - 遗留代码 | 🟢 低 | ✅ 已完成 |

### 问题3：播放列表功能扩展 ⏸️ 待实施
| 文件 | 操作 | 优先级 | 状态 |
|------|------|--------|------|
| `presentation/pages/playlist_detail_page.dart` | 修改 - 添加按钮 | 🔴 高 | ⏸️ 待开始 |
| `presentation/dialogs/add_song_dialog.dart` | 新建 - 添加歌曲对话框 | 🟡 中 | ⏸️ 待开始 |
| `presentation/dialogs/sort_options_dialog.dart` | 新建 - 排序选项对话框 | 🟢 低 | ⏸️ 待开始 |
| `listen-vision_api/routes/playlists.js` | 修改 - 排序API | 🟢 低 | ⏸️ 待开始 |

### 问题2：QQ音乐榜单计划 📋 计划中
| 文件 | 操作 | 优先级 | 状态 |
|------|------|--------|------|
| `listen-vision_api/services/recommendationService.js` | 修改 - 集成QQ音乐API | 🟢 低 | 📋 计划中 |
| `listen-vision_api/routes/recommendations.js` | 修改 - 添加QQ音乐路由 | 🟢 低 | 📋 计划中 |
| `presentation/pages/explore_page.dart` | 修改 - 榜单来源切换 | 🟢 低 | 📋 计划中 |

### 已完成的历史问题 ✅
| 文件 | 操作 | 优先级 | 状态 |
|------|------|--------|------|
| `presentation/pages/search_page.dart` | 修改 - 添加loading状态 | 🔴 高 | ✅ 已完成 |
| `presentation/providers/playlist/playlist_provider.dart` | 修改 - 优化异步操作 | 🔴 高 | ✅ 已完成 |
| `core/network/dio_provider.dart` | 修改 - 缩短超时时间 | 🟡 中 | ✅ 已完成 |
| `data/managers/download_executor.dart` | 新建 - 前端下载实现 | 🔴 高 | ✅ 已完成 |
| `data/repositories/download_repository_impl.dart` | 新建 - 下载仓储实现 | 🔴 高 | ✅ 已完成 |

### 问题1.5：音频播放器加载状态异常 ✅ 已解决
| 文件 | 操作 | 优先级 | 状态 |
|------|------|--------|------|
| `lib/presentation/providers/audio/audio_provider.dart` | 迁移到 just_audio | 🔴 高 | ✅ 已完成 |
| `lib/presentation/widgets/controls_panel.dart` | 修改 - 加载状态显示 | 🔴 高 | ✅ 已完成 |
| `lib/presentation/widgets/audio_info.dart` | 修改 - 封面显示 | 🟡 中 | ✅ 已完成 |
| `pubspec.yaml` | 添加 just_audio 依赖 | 🔴 高 | ✅ 已完成 |
| `services/audioService.js` | 新建 - FFmpeg格式转换 | 🟡 中 | ✅ 已完成 |
| `routes/bilibili.js` | 添加 format 参数支持 | 🟡 中 | ✅ 已完成 |

### 问题2：QQ音乐榜单计划 📋
| 文件 | 操作 | 优先级 | 状态 |
|------|------|--------|------|
| ~~`musicCrawlerService.js`~~ | 已完成（但废弃） | - | ✅ 后端完成 |
| `recommendationService.js` | 修改 - 集成QQ音乐API | 🟢 低 | 📋 计划中 |
| `routes/recommendations.js` | 修改 - 添加QQ音乐路由 | 🟢 低 | 📋 计划中 |
| `lib/ui/pages/explore_page.dart` | 修改 - 榜单来源切换 | 🟢 低 | 📋 计划中 |

### 问题3：播放列表扩展 ⏸️
| 文件 | 操作 | 优先级 | 状态 |
|------|------|--------|------|
| `lib/ui/pages/playlist_detail_page.dart` | 修改 - 添加按钮 | 🔴 高 | ⏸️ 待实施 |
| `lib/ui/dialogs/add_song_dialog.dart` | 新建 | 🟡 中 | ⏸️ 待实施 |
| `lib/ui/dialogs/sort_options_dialog.dart` | 新建 | 🟢 低 | ⏸️ 待实施 |
| `listen-vision_api/routes/playlists.js` | 修改 - 排序API | 🟢 低 | ⏸️ 待实施 |

### 附加：下载架构重构 ✅
| 文件 | 操作 | 状态 |
|------|------|------|
| `lib/services/download/download_executor.dart` | 新建 | ✅ 已完成 |
| `lib/services/download/download_repository.dart` | 新建 | ✅ 已完成 |
| `lib/services/download/metadata_writer.dart` | 新建 | ✅ 已完成 |
| ~~`listen-vision_api/services/downloadService.js`~~ | 删除 | ✅ 已清理 |
| ~~`listen-vision_api/routes/downloads.js`~~ | 删除 | ✅ 已清理 |

---

## 六、知识点说明

1. **Flutter状态管理**: 使用 `notifyListeners()` 触发UI更新，loading状态防止重复点击
2. **异步操作优化**: 使用 `compute` 将耗时操作放到Isolate执行
3. **下载架构设计**: 前端本地化 vs 后端任务队列的权衡
4. **断点续传**: HTTP Range 请求实现分段下载
5. **临时文件策略**: 避免Windows文件锁定问题
6. **第三方API集成**: QQ音乐开放平台（未来计划）
7. **音频播放器对比**: audioplayers vs just_audio 的状态管理差异
8. **流媒体缓冲**: 网络音频缓冲状态检测的挑战

---

## 七、进度跟踪

| 问题 | 步骤 | 状态 | 完成日期 |
|------|------|------|----------|
| Phase 2 在线播放 | 创建统一播放接口 (PlayableAudio) | ✅ 已完成 | 2026-01-22 |
| Phase 2 在线播放 | 改造 AudioProvider (playOnlineAudio) | ✅ 已完成 | 2026-01-22 |
| Phase 2 在线播放 | 连接搜索页面 | ✅ 已完成 | 2026-01-22 |
| Phase 2 在线播放 | 连接发现页面 | ✅ 已完成 | 2026-01-22 |
| Phase 2 在线播放 | 连接歌单详情页 | ✅ 已完成 | 2026-01-22 |
| 问题1: 加入歌单卡死 | 添加loading状态 | ✅ 已完成 | 2026-01-20 |
| 问题1: 加入歌单卡死 | 优化异步操作 | ✅ 已完成 | 2026-01-20 |
| 问题1: 加入歌单卡死 | 缩短超时时间 | ✅ 已完成 | 2026-01-20 |
| 问题1.5: 音频播放器加载 | 创建 AUDIO_PLAYER_FIX_PLAN.md | ✅ 已完成 | 2026-01-22 |
| 问题1.5: 音频播放器加载 | 迁移到 just_audio | ✅ 已完成 | 2026-01-22 |
| 问题1.5: 音频播放器加载 | 后端音频格式转换 | ✅ 已完成 | 2026-01-22 |
| ~~问题2: 音乐区爬取~~ | ~~创建爬虫服务~~ | ✅ 已完成（废弃） | 2026-01-20 |
| 问题2: QQ音乐榜单 | 申请API密钥 | 📋 计划中 | - |
| 问题2: QQ音乐榜单 | 后端集成 | 📋 计划中 | - |
| 问题2: QQ音乐榜单 | 前端集成 | 📋 计划中 | - |
| 问题3: 播放列表扩展 | 添加"添加歌曲"按钮 | ⏸️ 待开始 | - |
| 问题3: 播放列表扩展 | 创建添加歌曲对话框 | ⏸️ 待开始 | - |
| 问题3: 播放列表扩展 | 创建排序选项对话框 | ⏸️ 待开始 | - |
| 附加: 下载架构重构 | 前端本地化实现 | ✅ 已完成 | 2026-01-20 |

---

## 八、验收标准汇总

### Phase 2 在线播放验收 ✅
- [x] 搜索结果点击可正常播放
- [x] 发现页面推荐内容点击可正常播放
- [x] 歌单详情页歌曲点击可正常播放
- [x] 统一播放接口（PlayableAudio）实现
- [x] 在线音频和本地音频可混合播放

### Bug修复验收

- [x] 搜索结果点击加入歌单不再卡死
- [x] 操作过程有loading状态反馈
- [x] 超时有友好提示
- [x] 音频播放器加载状态正常显示 ✅ (just_audio 迁移完成)
- [x] Windows 平台音频播放稳定 ✅ (格式转换完成)

### 功能改进验收
- [ ] ~~发现页面新增"音乐区"Tab~~ (已取消，改用QQ音乐方案)
- [x] ~~音乐区爬虫服务后端完成~~ (已完成但废弃)
- [ ] QQ音乐榜单集成（未来计划）
- [ ] 歌单详情页可添加歌曲
- [ ] 歌单支持多种排序方式
- [x] 下载架构重构（前端本地化）

### 文档验收
- [x] CLAUDE.md 更新完成
- [x] INCREMENTAL_MIGRATION_PLAN.md 更新完成
- [x] PHASE_5_BUGFIX_AND_IMPROVEMENTS.md 更新完成（含 Phase 2 完成状态）

---

## 九、与 Phase 2（在线播放）的关系

> **2026-01-22 更新**: Phase 2 在线播放功能**已完成实现** ✅

**Phase 2（在线播放功能）** 已于 2026-01-22 完成，现在可以继续 Phase 5 的剩余功能：

| 功能 | Phase 5 (原 2B) | Phase 2 (原 4) | 说明 |
|------|-----------------|----------------|------|
| 添加歌曲到歌单 | 📋 歌单详情页UI | ✅ 在线播放 | Phase 2 已完成，可继续 Phase 5 |
| 播放歌单歌曲 | ✅ 可播放 | ✅ 在线播放 | 数据流已打通 |
| 歌单排序 | 📋 排序对话框 | - | 独立功能，可后续实施 |

**实施顺序更新**:
1. ✅ **Phase 2 已完成** - 在线播放核心问题已解决
2. 🚧 **继续 Phase 5** - 完善歌单管理UI功能（当前阶段）
3. 📋 **歌单排序功能** - 可后续实施

**相关文档**: [Phase 2 在线播放功能](./PHASE_2_ONLINE_PLAYBACK.md)（已完成实现）

---

*本文档由 Claude Code 生成 | 创建: 2026-01-19 | 更新: 2026-01-22*
