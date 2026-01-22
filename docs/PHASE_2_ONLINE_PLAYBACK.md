# Phase 2: 在线播放功能实施计划

> **创建日期**: 2026-01-22
> **最后更新**: 2026-01-22（阶段重排）
>
> **目标**: 实现完整的在线音频播放功能，打通搜索、推荐、歌单到播放器的数据流
>
> **依赖**: Phase 1 (后端B站API) 完成 ✅
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

**前端状态** ❌ 数据流断裂
| 组件 | 当前能力 | 问题 |
|------|---------|------|
| `AudioProvider` | `DeviceFileSource` only | 只能播本地文件 |
| 播放列表类型 | `List<LocalAudio>` | 无法存储在线音频 |
| `BilibiliProvider` | 可获取 `streamUrl` | 但无法传给播放器 |
| `Audio` 实体 | 有 `streamUrl` 字段 | 播放器未使用 |

### 核心问题

```
┌────────────────────────────────────────────────────────────────────┐
│                      当前数据流断裂点                               │
├────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  用户点击搜索结果 → BilibiliProvider.getAudioStream(bvid)          │
│       ↓                                                              │
│  后端返回: { baseUrl: "https://...", duration: 180 }                │
│       ↓                                                              │
│  ❌ 断裂点：AudioProvider 只接受 DeviceFileSource(filePath)          │
│       但在线音频需要 UrlSource(url)                                  │
│                                                                      │
└────────────────────────────────────────────────────────────────────┘
```

### 影响

- ❌ 搜索结果无法播放
- ❌ 推荐内容无法播放
- ❌ 歌单功能不可用（只能添加不能播放）
- ❌ 播放历史无法记录在线音频

---

## 二、解决方案设计

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
│                        目标架构                                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    用户交互层                              │   │
│  │  搜索页面 │ 发现页面 │ 歌单详情 │ 播放历史                 │   │
│  └──────────────────────────────────────────────────────────┘   │
│                         │ 点击播放                                │
│                         ▼                                        │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              BilibiliProvider (数据获取)                   │   │
│  │  getAudioStream(bvid) → { streamUrl, duration }           │   │
│  └──────────────────────────────────────────────────────────┘   │
│                         │                                        │
│                         ▼                                        │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │               AudioProvider (统一播放器)                   │   │
│  │  ┌────────────────────────────────────────────────┐       │   │
│  │  │         PlayableAudio (统一接口)                │       │   │
│  │  │  • id, title, artist, duration, albumArt       │       │   │
│  │  │  • getSource(): Source (多态)                  │       │   │
│  │  └────────────────────────────────────────────────┘       │   │
│  │              ▲                ▲                             │   │
│  │              │                │                             │   │
│  │    LocalPlayable      OnlinePlayable                     │   │
│  │    DeviceFileSource    UrlSource(代理URL)                  │   │
│  └──────────────────────────────────────────────────────────┘   │
│                         │                                        │
│                         ▼                                        │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              audioplayers (播放引擎)                       │   │
│  │  play(DeviceFileSource | UrlSource)                       │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 三、实施步骤

### 阶段1：创建统一播放接口

**文件**: `frontend_flutter/lib/domain/entities/playable_audio.dart` (新建)

**内容**:
```dart
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

/// 可播放音频统一接口
///
/// 支持本地文件和在线音频流的多态设计
abstract class PlayableAudio {
  String get id;
  String get title;
  String? get artist;
  int? get duration;
  Uint8List? get albumArt;

  /// 获取音频源（多态）
  Source getSource();

  /// 是否为在线音频
  bool get isOnline;
}

/// 本地可播放音频
class LocalPlayable extends PlayableAudio {
  final String filePath;
  @override
  final String id;
  @override
  final String title;
  @override
  final String? artist;
  @override
  final int? duration;
  @override
  Uint8List? albumArt;

  LocalPlayable({
    required this.filePath,
    required this.id,
    required this.title,
    this.artist,
    this.duration,
    this.albumArt,
  });

  @override
  Source getSource() => DeviceFileSource(filePath);

  @override
  bool get isOnline => false;
}

/// 在线可播放音频
class OnlinePlayable extends PlayableAudio {
  final String bvid;
  final String originalUrl;  // B站原始URL
  final String proxyUrl;     // 后端代理URL
  final String? coverUrl;
  @override
  final String id;
  @override
  final String title;
  @override
  final String? artist;
  @override
  final int? duration;
  @override
  Uint8List? albumArt;

  OnlinePlayable({
    required this.bvid,
    required this.originalUrl,
    required this.proxyUrl,
    this.coverUrl,
    required this.id,
    required this.title,
    this.artist,
    this.duration,
    this.albumArt,
  });

  @override
  Source getSource() => UrlSource(proxyUrl);

  @override
  bool get isOnline => true;
}
```

---

### 阶段2：改造 AudioProvider

**文件**: `frontend_flutter/lib/presentation/providers/audio/audio_provider.dart` (修改)

**核心改动**:

1. **播放列表类型改为多态**
```dart
// 旧代码
List<LocalAudio> _playlist = [];

// 新代码
List<PlayableAudio> _playlist = [];
```

2. **添加在线播放方法**
```dart
/// 播放在线音频
///
/// @param audio 音频实体
/// @param streamUrl 音频流URL（从后端获取）
Future<void> playOnline(Audio audio, String streamUrl) async {
  try {
    debugPrint('【AudioProvider】准备播放在线音频: ${audio.title}');

    // 构建后端代理URL
    final baseUrl = ApiConstants.baseUrl;
    final proxyUrl = '$baseUrl/bilibili/proxy/audio?url=${Uri.encodeComponent(streamUrl)}';

    // 创建在线可播放对象
    final playable = OnlinePlayable(
      bvid: audio.id,
      originalUrl: streamUrl,
      proxyUrl: proxyUrl,
      coverUrl: audio.coverUrl,
      id: audio.id,
      title: audio.title,
      artist: audio.artist,
      duration: audio.duration,
    );

    // 添加到播放列表
    _playlist.add(playable);
    _currentIndex = _playlist.length - 1;

    // 设置音频源并播放
    _position = Duration.zero;
    _duration = Duration.zero;
    await _player.setSource(playable.getSource());
    await _player.resume();

    // 更新状态
    _title = audio.title;
    _artist = audio.artist ?? '未知艺术家';
    _isPlaying = true;

    // 启动定时保存
    _startPositionSaveTimer();

    notifyListeners();
    debugPrint('【AudioProvider】在线播放开始: ${audio.title}');
  } catch (e) {
    debugPrint('【AudioProvider】在线播放失败: $e');
    rethrow;
  }
}
```

3. **修改类型相关的Getter**
```dart
// 旧代码
LocalAudio? get currentAudio => _currentIndex >= 0 ? _playlist[_currentIndex] : null;

// 新代码
PlayableAudio? get currentAudio => _currentIndex >= 0 ? _playlist[_currentIndex] : null;

// 获取当前音频的bvid（如果是在线音频）
String? get currentBvid {
  final audio = currentAudio;
  if (audio is OnlinePlayable) {
    return audio.bvid;
  }
  return null;
}
```

---

### 阶段3：连接页面与播放器

#### 3.1 搜索页面

**文件**: `frontend_flutter/lib/presentation/pages/search_page.dart` (修改)

**改动点**:
```dart
// 在搜索结果项的 onTap 中添加
Future<void> _playAudio(Map<String, dynamic> video) async {
  final bilibiliProvider = context.read<BilibiliProvider>();
  final audioProvider = context.read<AudioProvider>();

  try {
    // 获取音频流URL
    final streamData = await bilibiliProvider.getAudioStream(video['bvid']);
    if (streamData == null || streamData['baseUrl'] == null) {
      showMySnackBar(context, '获取音频流失败', Colors.red, 2000);
      return;
    }

    // 创建Audio对象
    final audio = Audio.fromDto({
      'bvid': video['bvid'],
      'title': video['title'],
      'artist': video['author'],
      'cover': video['cover'],
      'duration': _parseDuration(video['duration']),
    });

    // 播放
    await audioProvider.playOnline(audio, streamData['baseUrl']);
  } catch (e) {
    showMySnackBar(context, '播放失败: $e', Colors.red, 2000);
  }
}
```

#### 3.2 发现页面

**文件**: `frontend_flutter/lib/presentation/pages/explore_page.dart` (修改)

**改动点**: 与搜索页面类似，在推荐内容卡片点击时调用 `_playAudio()`

#### 3.3 歌单详情页面

**文件**: `frontend_flutter/lib/presentation/pages/playlist_detail_page.dart` (修改)

**改动点**:
```dart
// 修改 _buildItemCard 的 onTap
onTap: () async {
  final bilibiliProvider = context.read<BilibiliProvider>();
  final audioProvider = context.read<AudioProvider>();

  try {
    // 获取音频流URL
    final streamData = await bilibiliProvider.getAudioStream(item.bvid);
    if (streamData == null || streamData['baseUrl'] == null) {
      showMySnackBar(context, '获取音频流失败', Colors.red, 2000);
      return;
    }

    // 创建Audio对象
    final audio = Audio(
      id: item.bvid,
      title: item.title ?? item.bvid,
      artist: item.artist,
      coverUrl: item.coverUrl,
      duration: item.duration,
    );

    // 播放
    await audioProvider.playOnline(audio, streamData['baseUrl']);
  } catch (e) {
    showMySnackBar(context, '播放失败: $e', Colors.red, 2000);
  }
},
```

---

### 阶段4：播放历史集成

**文件**: `frontend_flutter/lib/presentation/providers/play_history/play_history_provider.dart` (修改)

**改动点**: 在播放开始时记录到历史

```dart
// 在 AudioProvider 的 playOnline 方法中添加
Future<void> playOnline(Audio audio, String streamUrl) async {
  // ... 播放逻辑 ...

  // 记录播放历史
  final historyProvider = /* 获取 HistoryProvider */;
  await historyProvider.addPlayHistory(
    bvid: audio.id,
    title: audio.title,
    artist: audio.artist,
    coverUrl: audio.coverUrl,
  );
}
```

---

## 四、关键文件清单

### 新建文件

| 文件 | 说明 | 优先级 |
|------|------|--------|
| `domain/entities/playable_audio.dart` | 统一播放接口定义 | 🔴 高 |

### 修改文件

| 文件 | 说明 | 优先级 |
|------|------|--------|
| `presentation/providers/audio/audio_provider.dart` | 核心播放器改造 | 🔴 高 |
| `presentation/pages/search_page.dart` | 搜索结果播放 | 🔴 高 |
| `presentation/pages/explore_page.dart` | 推荐内容播放 | 🔴 高 |
| `presentation/pages/playlist_detail_page.dart` | 歌单播放 | 🔴 高 |
| `presentation/providers/play_history/play_history_provider.dart` | 播放历史记录 | 🟡 中 |

---

## 五、验收标准

### 功能验收

- [ ] 搜索结果点击可正常播放
- [ ] 发现页面推荐内容点击可正常播放
- [ ] 歌单详情页歌曲点击可正常播放
- [ ] 播放进度正常显示
- [ ] 播放/暂停/上一曲/下一曲正常工作
- [ ] 播放历史正常记录在线音频

### 性能验收

- [ ] 音频加载时间 < 3秒
- [ ] 播放切换无卡顿
- [ ] 后端代理无错误日志

### 兼容性验收

- [ ] 本地音频播放不受影响
- [ ] 在线和本地音频可混合同一播放列表
- [ ] 应用重启后可恢复播放状态

---

## 六、知识点说明

1. **多态设计**: 使用抽象类 `PlayableAudio` 实现本地和在线音频的统一接口
2. **URL代理**: 后端代理解决B站防盗链问题
3. **audioplayers包**: 支持 `DeviceFileSource` 和 `UrlSource` 两种音频源
4. **状态管理**: Provider模式下跨Provider的状态同步

---

## 七、风险与应对

| 风险 | 影响 | 应对措施 |
|------|------|---------|
| B站API变更 | 音频流获取失败 | 保留错误处理，提示用户重试 |
| 代理性能问题 | 播放延迟 | 考虑添加音频预加载 |
| 网络不稳定 | 播放中断 | 添加重试机制和错误恢复 |

---

## 八、进度跟踪

| 阶段 | 任务 | 状态 | 完成日期 |
|------|------|------|----------|
| 阶段1 | 创建统一播放接口 | ⏸️ 待开始 | |
| 阶段2 | 改造 AudioProvider | ⏸️ 待开始 | |
| 阶段3 | 连接搜索页面 | ⏸️ 待开始 | |
| 阶段3 | 连接发现页面 | ⏸️ 待开始 | |
| 阶段3 | 连接歌单详情页 | ⏸️ 待开始 | |
| 阶段4 | 集成播放历史 | ⏸️ 待开始 | |
| 测试 | 功能验证 | ⏸️ 待开始 | |

---

*本文档由 Claude Code 生成 | 创建: 2026-01-22*
