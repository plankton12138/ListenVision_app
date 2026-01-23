# Phase 2: 在线播放功能实施计划

> **创建日期**: 2026-01-22
> **最后更新**: 2026-01-23（实施完成）
>
> **目标**: 实现完整的在线音频播放功能，打通搜索、推荐、歌单到播放器的数据流
>
> **依赖**: Phase 1 (后端B站API) 完成 ✅
>
> **状态**: ✅ **已完成**
>
> **🔄 阶段重排说明**: 原 **Phase 4** 已重排为 **Phase 2**，因为这是关键功能缺失，其他功能（歌单/历史/推荐）都依赖在线播放能力

---

## 一、问题概述

### 当前状态诊断

**后端状态** ✅ 完整实现
| 功能 | API端点 | 服务层 | 状态 |
|------|---------|--------|------|
| 获取音频流URL | `GET /api/bilibili/audio/:bvid` | `bilibiliService.getAudioStream()` | ✅ |
| 音频流代理 | `GET /api/bilibili/proxy/audio` | `bilibiliController.proxyAudioStream()` | ✅ |
| 图片代理 | `GET /api/bilibili/proxy/image` | `bilibiliController.proxyImage()` | ✅ |
| 元数据缓存 | `audio_metadata_cache` 表 | SQLite | ✅ |

**前端状态** ✅ 已完成
| 组件 | 当前能力 | 状态 |
|------|---------|------|
| `AudioProvider` | `just_audio` + 混合播放列表 | ✅ |
| `PlayableAudio` | 统一播放接口 | ✅ |
| `LocalPlayable` | 本地音频包装类 | ✅ |
| `OnlinePlayable` | 在线音频包装类 | ✅ |
| `unifiedPlaylist` | 混合播放列表 | ✅ |
| `playOnlineAudio` | 在线播放方法 | ✅ |
| 播放列表页面 | 混合显示在线/本地 | ✅ |

### 影响范围

| 功能 | 状态 |
|------|------|
| 搜索结果播放 | ✅ |
| 推荐内容播放 | ✅ |
| 歌单播放 | ✅ |
| 播放历史记录 | ⏸️ 待实现 |
| 混合播放列表 | ✅ |

---

## 二、已实施方案

### 为什么需要后端代理？

```
直接播放B站音频流（❌ 不可行）:
  Flutter → UrlSource("https://upos-sz-mirrorcoso...m4s")
             ↓
          B站CDN检测到非合法Referer
             ↓
          返回 403 Forbidden

通过后端代理（✅ 可行）:
  Flutter → UrlSource("http://localhost:3000/api/bilibili/proxy/audio?url=...")
             ↓
          后端转发请求（带正确Referer和Cookie）
             ↓
          B站CDN返回音频流
             ↓
          后端透传给Flutter
             ↓
          播放成功
```

### 架构设计

```
┌─────────────────────────────────────────────────────────────────┐
│                        已实现架构                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    用户交互层                              │   │
│  │  搜索页面 │ 发现页面 │ 歌单详情 │ 播放列表                 │   │
│  └──────────────────────────────────────────────────────────┘   │
│                         │ 点击播放                                │
│                         ▼                                        │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │               AudioProvider (统一播放器)                   │   │
│  │  ┌────────────────────────────────────────────────┐       │   │
│  │  │         PlayableAudio (统一接口)                │       │   │
│  │  │  • id, title, artist, duration, coverUrl        │       │   │
│  │  │  • audioSource: AudioSource (多态)              │       │   │
│  │  │  • isOnline: bool                              │       │   │
│  │  └────────────────────────────────────────────────┘       │   │
│  │              ▲                ▲                             │   │
│  │              │                │                             │   │
│  │    LocalPlayable      OnlinePlayable                     │   │
│  │    AudioSource.file    AudioSource.uri(代理URL)             │   │
│  └──────────────────────────────────────────────────────────┘   │
│                         │                                        │
│                         ▼                                        │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │         just_audio (播放引擎) + media_kit (Windows)        │   │
│  │  • Android/iOS: just_audio native                          │   │
│  │  • Windows: just_audio_media_kit + MPV                    │   │
│  └──────────────────────────────────────────────────────────┘   │
│                         │                                        │
│                         ▼                                        │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              后端代理 (解决B站防盗链)                      │   │
│  │  /api/bilibili/proxy/audio?url=...                        │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 三、已实施方案

### 阶段1：创建统一播放接口 ✅

**文件**: `frontend_flutter/lib/domain/entities/`

| 文件 | 说明 |
|------|------|
| `playable_audio.dart` | 统一播放接口（抽象类） |
| `local_playable.dart` | 本地音频包装类 |
| `online_playable.dart` | 在线音频包装类 |

**核心接口**:
```dart
abstract class PlayableAudio {
  String get id;
  String get title;
  String? get artist;
  String? get coverUrl;
  Uint8List? get coverData;
  int? get duration;
  bool get isOnline;
  AudioSource get audioSource;  // just_audio 的 AudioSource
  String get url;
  String get shareableUrl;
  Map<String, dynamic> toMap();
}
```

---

### 阶段2：改造 AudioProvider ✅

**文件**: `frontend_flutter/lib/presentation/providers/audio/audio_provider.dart`

**核心改动**:

1. **混合播放列表**
```dart
List<LocalAudio> _playlist = [];           // 本地音频（数据库持久化）
List<PlayableAudio> _unifiedPlaylist = []; // 统一播放列表（内存）
int _currentIndex = -1;
```

2. **在线播放方法**
```dart
Future<void> playOnlineAudio({
  required Audio audio,
  String? streamUrl,
  String? proxyUrl,
}) async {
  // 构建代理URL
  proxyUrl ??= _buildProxyUrl(streamUrl);

  // 设置在线状态
  _isCurrentOnline = true;
  _currentOnlineAudio = audio;

  // 创建 OnlinePlayable 并添加到统一播放列表
  final playable = OnlinePlayable.fromAudio(audio, proxyUrl);
  await _addPlayableToPlaylist(playable, playImmediately: true);

  // 播放
  await _playPlayable(playable);
}
```

3. **统一播放方法（供播放列表页面使用）**
```dart
Future<void> playUnifiedAt(int index) async {
  if (_currentIndex == index) {
    await togglePlayPause();  // 点击当前项：暂停/继续
    return;
  }
  await _playUnifiedAtIndex(index);  // 点击其他项：播放
}
```

4. **播放列表管理**
```dart
Future<void> removeFromUnifiedPlaylist(int index);
Future<void> clearUnifiedPlaylist();
```

---

### 阶段3：播放列表页面改造 ✅

**文件**: `frontend_flutter/lib/presentation/pages/play_list_page.dart`

**核心改动**:

1. **使用统一播放列表**
```dart
final playlist = provider.unifiedPlaylist;  // 替代 provider.playlist
```

2. **差异化显示**
```dart
// 在线音频：橙色云图标 + 网络封面
if (playable.isOnline) {
  Icon(Icons.cloud_circle, color: Colors.orange)
  CachedNetworkImage(imageUrl: playable.coverUrl)
}

// 本地音频：绿色存储图标 + 内嵌封面
else {
  Icon(Icons.storage, color: Colors.green)
  Image.memory(playable.coverData)
}
```

3. **统一点击处理**
```dart
onTap: () => provider.playUnifiedAt(index),
```

---

## 四、关键文件清单

### 新建文件 ✅

| 文件 | 说明 |
|------|------|
| `domain/entities/playable_audio.dart` | 统一播放接口（抽象类） |
| `domain/entities/local_playable.dart` | 本地音频包装类 |
| `domain/entities/online_playable.dart` | 在线音频包装类 |

### 修改文件 ✅

| 文件 | 改动说明 |
|------|----------|
| `presentation/providers/audio/audio_provider.dart` | 添加 `unifiedPlaylist`、`playOnlineAudio`、`playUnifiedAt` 等方法 |
| `presentation/pages/play_list_page.dart` | 改用 `unifiedPlaylist`，支持混合显示在线/本地音频 |
| `pubspec.yaml` | 添加 `just_audio`、`audio_session`、`just_audio_media_kit` 依赖 |

---

## 五、验收标准

### 功能验收 ✅

- [x] 搜索结果点击可正常播放
- [x] 发现页面推荐内容点击可正常播放
- [x] 歌单详情页歌曲点击可正常播放
- [x] 播放进度正常显示
- [x] 播放/暂停/上一曲/下一曲正常工作
- [x] 播放列表显示在线和本地音频
- [x] 播放列表点击暂停/继续功能正常
- [ ] 播放历史正常记录在线音频

### 性能验收 ✅

- [x] 音频加载时间 < 3秒
- [x] 播放切换无卡顿
- [x] 后端代理正常工作

### 兼容性验收 ✅

- [x] 本地音频播放不受影响
- [x] 在线和本地音频可混合同一播放列表
- [x] 播放列表支持删除在线/本地音频
- [ ] 应用重启后可恢复在线播放状态（待实现）

---

## 六、知识点说明

1. **just_audio**: Flutter 音频播放库，提供 `AudioSource` 统一接口
2. **media_kit**: Windows 平台后端，使用 MPV 播放器
3. **多态设计**: 使用抽象类 `PlayableAudio` 实现本地和在线音频的统一接口
4. **URL代理**: 后端代理解决B站防盗链问题
5. **状态管理**: Provider 模式下跨组件的状态同步

---

## 七、遇到的问题与解决

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| MPV 无法播放 M4S 流 | B站 M4S 格式需要特定 headers | 使用后端代理，添加 Referer 和 User-Agent |
| 播放列表索引不同步 | `playOnlineAudio` 和 `loadAudio` 各自管理索引 | 添加 `playUnifiedAt(index)` 统一方法 |
| 在线音频不显示在播放列表 | 播放列表只显示 `LocalAudio` | 改用 `unifiedPlaylist` 和 `PlayableAudio` |

---

## 八、进度跟踪

| 阶段 | 任务 | 状态 | 完成日期 |
|------|------|------|----------|
| 阶段1 | 创建统一播放接口 | ✅ 完成 | 2026-01-22 |
| 阶段2 | 改造 AudioProvider | ✅ 完成 | 2026-01-22 |
| 阶段3 | 播放列表页面改造 | ✅ 完成 | 2026-01-23 |
| 阶段4 | 在线播放功能测试 | ✅ 完成 | 2026-01-23 |
| 待实现 | 播放历史记录在线音频 | ⏸️ 待开始 | |
| 待实现 | 应用重启恢复在线播放状态 | ⏸️ 待开始 | |

---

*本文档由 Claude Code 生成 | 创建: 2026-01-22 | 更新: 2026-01-23*
