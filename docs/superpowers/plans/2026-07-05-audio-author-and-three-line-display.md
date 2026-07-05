# 音频作者属性与三行展示 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为音频新增 `albumTitle` 字段，实现主页三行展示（分集名/视频标题/UP主）

**Architecture:**
- 新增 `albumTitle` 字段于所有相关数据模型（Audio、LocalAudio、PlaylistItem、DownloadTask 等）
- 下载流程透传 albumTitle，写入文件元数据的 `album` 标签
- 主页 AudioInfo 改为三行布局
- `PlayableAudio` 接口和 `PlaybackState` 新增对应字段透传

**Tech Stack:** Dart 3.11, Flutter 3.41, freezed, Riverpod, metadata_god

## Global Constraints

- 所有模型类需运行 `build_runner` 重新生成 freezed/gson 代码
- `albumTitle` 在 `Audio.fromDto` 中从 API `title` 字段映射
- 分P下载文件名从 `{视频标题} - {分集名}` 改为 `{分集名}`
- 已有数据库记录 `albumTitle = null`，兼容显示

---

### Task 1: 模型层 — 所有数据模型新增 albumTitle 字段

**Files:**
- Modify: `frontend_flutter/lib/models/audio.dart`
- Modify: `frontend_flutter/lib/models/local_audio.dart`
- Modify: `frontend_flutter/lib/models/playable_audio.dart`
- Modify: `frontend_flutter/lib/models/online_playable.dart`
- Modify: `frontend_flutter/lib/models/local_playable.dart`
- Modify: `frontend_flutter/lib/models/playlist.dart` (PlaylistItem)
- Modify: `frontend_flutter/lib/models/download_task.dart`

**Interfaces:**
- Produces: `Audio.albumTitle` (String?), `LocalAudio.albumTitle` (String?), `PlayableAudio.albumTitle` (String?), `OnlinePlayable.albumTitle` (String?), `LocalPlayable.albumTitle` (String?), `PlaylistItem.albumTitle` (String?), `DownloadTask.albumTitle` (String?)

- [ ] **Step 1: Audio — 新增 albumTitle + fromDto/toDto**

```dart
// lib/models/audio.dart — 在 factory Audio 的构造函数中新增
String? albumTitle,    // 视频标题（分P音频的父标题，用于主页副标题行）

// Audio.fromDto() 中映射（放在 title 之后）
albumTitle: safeString(json['album_title'] ?? json['albumTitle']),

// Audio.toDto() 中序列化
if (albumTitle != null) 'album_title': albumTitle,
```

- [ ] **Step 2: LocalAudio — 新增 albumTitle + copyWith/toMap/fromMap**

```dart
// lib/models/local_audio.dart
class LocalAudio {
  final String? albumTitle;  // ← 新增

  LocalAudio({
    ...
    this.albumTitle,
  });

  LocalAudio copyWith({
    ...
    String? albumTitle,
  }) {
    return LocalAudio(
      ...
      albumTitle: albumTitle ?? this.albumTitle,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      ...
      if (albumTitle != null) 'albumTitle': albumTitle,
    };
  }

  factory LocalAudio.fromMap(Map<String, dynamic> map) {
    return LocalAudio(
      ...
      albumTitle: map['albumTitle'] as String?,
    );
  }
}
```

- [ ] **Step 3: PlayableAudio 接口 — 新增 albumTitle getter**

```dart
// lib/models/playable_audio.dart
abstract class PlayableAudio {
  String get id;
  String? get albumTitle;  // ← 新增
  String get title;
  String? get artist;
  ...
}
```

- [ ] **Step 4: OnlinePlayable — 实现 albumTitle**

```dart
// lib/models/online_playable.dart
@override
String? get albumTitle => _audio.albumTitle;
```

- [ ] **Step 5: LocalPlayable — 新增 albumTitle + fromMap**

```dart
// lib/models/local_playable.dart
@override
String? get albumTitle => _audio.albumTitle;

// factory LocalPlayable.fromPlaylistItem 也需要传递
```

- [ ] **Step 6: PlaylistItem (playlist.dart) — 新增 albumTitle**

```dart
// lib/models/playlist.dart — PlaylistItem
const factory PlaylistItem({
  ...
  String? albumTitle,  // ← 新增
  ...
}) = _PlaylistItem;

// fromDto 中解析
albumTitle: safeString(json['album_title'] ?? json['albumTitle']),
```

同时在 `OnlinePlayable.fromPlaylistItem` 中传递：

```dart
// lib/models/online_playable.dart
factory OnlinePlayable.fromPlaylistItem(PlaylistItem item) {
    final audio = Audio(
      ...
      albumTitle: item.albumTitle,  // ← 新增
    );
    return OnlinePlayable.fromAudio(audio, null);
}
```

- [ ] **Step 7: DownloadTask — 新增 albumTitle + copyWith/toMap/fromMap**

```dart
// lib/models/download_task.dart
class DownloadTask {
  final String? albumTitle;  // ← 新增

  const DownloadTask({
    ...
    this.albumTitle,
  });

  // copyWith 新增 albumTitle
  DownloadTask copyWith({
    ...
    String? albumTitle,
  }) {
    return DownloadTask(
      ...
      albumTitle: albumTitle ?? this.albumTitle,
    );
  }

  // fromMap 解析
  albumTitle: map['album_title'] as String?,

  // toMap 序列化
  if (albumTitle != null) 'album_title': albumTitle,
}
```

- [ ] **Step 8: 运行 build_runner 重新生成 freezed 代码**

```bash
cd frontend_flutter
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 9: 本地导入音频时映射 album 到 albumTitle**

在 `home_page.dart` 中创建 `LocalAudio` 的两处代码中，将 `metadata.album` 映射到 `albumTitle`：

```dart
// home_page.dart (Android 路径)
final localAudio = LocalAudio(
  filePath: storageKey,
  url: playableUrl,
  title: metadata.title.isNotEmpty ? metadata.title : _getFileName(storageKey),
  artist: metadata.artist.isNotEmpty ? metadata.artist : '未知艺术家',
  albumTitle: metadata.album.isNotEmpty ? metadata.album : null,  // ← 新增
  duration: metadata.duration ?? 0,
  albumArt: metadata.cover,
);

// home_page.dart (桌面路径) — 同样的修改
final localAudio = LocalAudio(
  filePath: storageKey,
  url: playableUrl,
  title: metadata.title.isNotEmpty ? metadata.title : _getFileName(storageKey),
  artist: metadata.artist.isNotEmpty ? metadata.artist : '未知艺术家',
  albumTitle: metadata.album.isNotEmpty ? metadata.album : null,  // ← 新增
  duration: metadata.duration ?? 0,
  albumArt: metadata.cover,
);
```

- [ ] **Step 10: Commit**

```bash
git add -A
git commit -m "feat: 模型层新增 albumTitle 字段

所有数据模型（Audio、LocalAudio、PlaylistItem、DownloadTask等）
新增 albumTitle 字段用于存储分P视频的父标题。
PlayableAudio 接口及实现类同步扩展。
本地导入音频时将文件 album 标签映射到 albumTitle。"
```

---

### Task 2: 下载流程 — 透传 albumTitle 并修改文件名

**Files:**
- Modify: `frontend_flutter/lib/services/bilibili_downloader.dart`
- Modify: `frontend_flutter/lib/services/metadata_writer.dart`
- Modify: `frontend_flutter/lib/data/repositories/download_repository.dart`
- Modify: `frontend_flutter/lib/presentation/views/discovery/search_page.dart` (下载部分)

**Interfaces:**
- Consumes: `DownloadTask.albumTitle` (String?), `AudioMetadata.album` → 写入标签
- Produces: 下载文件元数据中 album 标签 = 视频标题

- [ ] **Step 1: BilibiliDownloader.download() — 接收 albumTitle 参数并修改逻辑**

```dart
// lib/services/bilibili_downloader.dart
class BilibiliDownloader {
  Future<DownloadResult> download({
    required String bvid,
    int? cid,
    required String saveDir,
    required String fileName,
    String? albumTitle,  // ← 新增参数：视频标题（分P使用）
    AudioOutputFormat? format,
    void Function(int percent, String stage)? onProgress,
  }) async {
    // ... 下载逻辑不变 ...

    // 元数据写入：根据是否有 albumTitle 决定写入方式
    final metadataTitle = albumTitle != null ? fileName : title;  // 分P：fileName=分集名；单P：title=视频标题
    final metadataAlbum = albumTitle;  // 分P：视频标题；单P：null

    final metadataResult = await MetadataWriter.writeMetadata(
      filePath: m4aPath,
      metadata: AudioMetadata(
        title: metadataTitle,
        artist: artist,
        album: metadataAlbum,  // ← 视频标题写入 album 标签
        coverFile: coverFile,
      ),
    );
  }
}
```

> **注**：`fileName` 参数在调用处已经是分集名（Task 2 Step 3 中修改），所以直接用作元数据 title。

- [ ] **Step 2: MetadataWriter — album 参数支持可空**

```dart
// lib/services/metadata_writer.dart — AudioMetadata 新增 album 字段
class AudioMetadata {
  final String title;
  final String artist;
  final String? album;      // ← 新增：视频标题（写入文件 album 标签）
  final File? coverFile;

  AudioMetadata({
    required this.title,
    required this.artist,
    this.album,             // ← 新增
    this.coverFile,
  });
}
```

并在 `writeMetadata` 中使用：

```dart
await MetadataGod.writeMetadata(
  file: filePath,
  metadata: Metadata(
    title: metadata.title,
    artist: metadata.artist,
    album: metadata.album,           // ← 传递 album（视频标题）
    picture: picture,
  ),
);
```

> **注意**：去掉原来的 `album: metadata.album ?? 'Bilibili'`，因为 `album` 参数变为可选（null 表示不写 album 标签）。

- [ ] **Step 3: search_page.dart — 下载分P时传递 albumTitle**

```dart
// lib/presentation/views/discovery/search_page.dart

// 分P下载
final page = pages[i];
await downloadNotifier.addDownload(
  bvid: bvid,
  cid: page.cid,
  savePath: savePath,
  title: page.title,           // ← 改为分集名（不再拼成 "视频标题 - 分集名"）
  albumTitle: title,            // ← 新增：视频标题
  artist: artist,
  coverUrl: coverUrl,
);
```

同时修改文件名生成：

```dart
// 修改前
final pageTitle = '$title - ${page.title}';
final sanitizedTitle = pageTitle.replaceAll(...);

// 修改后
final sanitizedTitle = page.title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
```

- [ ] **Step 4: DownloadViewModel.addDownload() — 传递 albumTitle**

```dart
// lib/presentation/viewmodels/system/download_viewmodel.dart
// addDownload 方法新增 albumTitle 参数
Future<void> addDownload({
  required String bvid,
  int? cid,
  required String savePath,
  required String title,
  String? albumTitle,   // ← 新增
  String? artist,
  String? coverUrl,
}) async {
  final task = DownloadTask(
    ...
    title: title,
    albumTitle: albumTitle,  // ← 新增
    ...
  );
  ...
}
```

- [ ] **Step 5: DownloadRepository — 透传 albumTitle 到 BilibiliDownloader**

```dart
// lib/data/repositories/download_repository.dart
// _downloadWithBilibiliDownloader 中：
final result = await downloader.download(
  bvid: task.bvid!,
  cid: task.cid,
  saveDir: saveDir,
  fileName: fileName,
  albumTitle: task.albumTitle,  // ← 新增
  format: format,
  onProgress: (percent, stage) { ... },
);
```

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat: 下载流程支持 albumTitle

修改 BilibiliDownloader 接收 albumTitle 参数并写入文件
album 标签。分P下载文件名改为仅分集名，搜索页下载调用
传递视频标题作为 albumTitle。"
```

---

### Task 3: 播放状态与 UI — 三行展示

**Files:**
- Modify: `frontend_flutter/lib/presentation/viewmodels/player/playback_viewmodel.dart`
- Modify: `frontend_flutter/lib/presentation/widgets/audio_info.dart`
- Modify: `frontend_flutter/lib/presentation/views/discovery/search_page.dart` (播放部分)

**Interfaces:**
- Consumes: `PlayableAudio.albumTitle`
- Produces: `PlaybackState.albumTitle`, UI 三行布局

- [ ] **Step 1: PlaybackState 新增 albumTitle + _updatePlayableState 透传**

```dart
// lib/presentation/viewmodels/player/playback_viewmodel.dart
const factory PlaybackState({
  ...
  @Default('未知标题') String title,
  String? albumTitle,               // ← 新增
  @Default('未知艺术家') String artist,
  ...
}) = _PlaybackState;

// _updatePlayableState() 中透传
void _updatePlayableState(PlayableAudio playable, {int index = -1}) {
    state = state.copyWith(
      currentPlayable: playable,
      title: playable.title,
      albumTitle: playable.albumTitle,  // ← 新增
      artist: playable.artist ?? '未知艺术家',
      ...
    );
}
```

- [ ] **Step 2: AudioInfo — 三行展示**

```dart
// lib/presentation/widgets/audio_info.dart
Widget _buildAudioInfo(BuildContext context, PlaybackState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 第1行：主标题（分集名/视频标题）
          Text(
            state.title,
            style: const TextStyle(
              fontSize: UIConstants.fontSizeMedium,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),

          // 第2行：副标题（仅分P音频）
          if (state.albumTitle != null && state.albumTitle!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                state.albumTitle!,
                style: const TextStyle(
                  fontSize: UIConstants.fontSizeSmall,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),

          const SizedBox(height: 4),

          // 第3行：作者（artist/UP主）
          Text(
            state.artist.isNotEmpty ? state.artist : '未知艺术家',
            style: const TextStyle(
              fontSize: UIConstants.fontSizeSmall,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
}
```

- [ ] **Step 3: search_page.dart — 在线分P播放时传递 albumTitle**

```dart
// lib/presentation/views/discovery/search_page.dart

// _playSingleAudio() — 单P/分P单集播放
// 新增 albumTitle 参数
Future<void> _playSingleAudio({
  required String bvid,
  required String title,
  String? albumTitle,   // ← 新增
  String? artist,
  String? coverUrl,
  int? duration,
  int? cid,
  int videos = 1,
}) async {
  final audio = Audio(
    id: bvid,
    title: title,
    albumTitle: albumTitle,  // ← 新增
    artist: artist,
    coverUrl: coverUrl,
    duration: duration,
    cid: cid,
    videos: videos,
  );
  ...
}

// _playAllPages() — 播放所有分P
// 新增 albumTitle 参数
Future<void> _playAllPages({
  required String bvid,
  required String albumTitle,  // ← 新增：视频标题
  String? artist,
  String? coverUrl,
  required List<AudioPage> pages,
  int videos = 1,
}) async {
  for (int i = 0; i < pages.length; i++) {
    final page = pages[i];
    final audio = Audio(
      id: bvid,
      title: page.title,
      albumTitle: albumTitle,  // ← 新增
      artist: artist,
      ...
    );
    ...
  }
}

// 调用处传递 albumTitle
// 在 onPlayPage 回调中：
_playSingleAudio(
  bvid: item.bvid,
  title: page.title,
  albumTitle: item.title,  // ← 新增：视频标题
  artist: item.author,
  ...
);

// 在 onPlayAll 回调中：
_playAllPages(
  bvid: item.bvid,
  albumTitle: item.title,  // ← 新增：视频标题
  artist: item.author,
  ...
);
```

- [ ] **Step 4: 运行 build_runner**

```bash
cd frontend_flutter
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 5: flutter analyze 确认无新增错误**

```bash
flutter analyze --no-fatal-infos --no-fatal-warnings
```

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat: 播放状态与UI支持 albumTitle 三行展示

PlaybackState 新增 albumTitle 字段，AudioInfo 改为
三行布局（主标题/副标题/作者）。在线分P播放时传递
视频标题作为 albumTitle。"
```

---

### Task 4（独立）: 修复启动时音乐播放状态

**背景:** 用户反馈软件启动时音乐应该是暂停状态。当前 `prepareCurrentFromQueue()` 调用 `prepareSource()` 加载音频源但不播放，但可能某些路径触发了自动播放。

- [ ] **Step 1: 定位自动播放触发点**

检查 `frontend_flutter/lib/presentation/views/player/home_page.dart:340-345` 的 `onQueueRestored` 回调路径，确认 `prepareSource` 后是否被错误地调用了 `play()`：

```dart
// home_page.dart
ref.read(queueViewModelProvider.notifier).onQueueRestored(() {
  // 仅准备音频源，不应自动播放
  ref.read(playbackViewModelProvider.notifier).prepareCurrentFromQueue();
  // 确保 isPlaying 为 false
});
```

如果 `AudioPlayerService.setSource()` 自动开始播放，需要在 `prepareSource` 之后立即 `pause()`：

```dart
// playback_viewmodel.dart — prepareSource 结束时
state = state.copyWith(isLoading: false, isPlaying: false, isPaused: true);
```

- [ ] **Step 2: 验证修复**

`flutter analyze` 通过后提交：

```bash
git add -A
git commit -m "fix: 启动时音乐处于暂停状态

确保 prepareSource 后不会自动播放，
启动恢复队列时仅准备音频源。"
```
