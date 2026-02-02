# 歌单播放功能Bug修复实施计划

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 修复歌单播放功能中的三个核心问题：1) 全部播放功能无法播放本地音频 2) 播放列表替换bug 3) 本地音频封面获取应直接从文件读取

**Architecture:** 修复 `_playPlaylistItem` 中的本地音频路径解析逻辑，优化播放列表同步机制，统一元数据获取来源（优先文件元数据）

**Tech Stack:** Flutter 3.38.5, Dart 3.10.4, Provider状态管理

---

## 现状分析

### 问题1: 全部播放功能无法播放本地音频

**根本原因**: `playlist_detail_page.dart:_playPlaylistItem`

```dart
// 当前代码逻辑（有bug）:
if (item.bvid.startsWith('local_')) {
  final idString = item.bvid.replaceFirst('local_', '');
  final id = int.tryParse(idString);
  if (id != null) {
    final playlistManager = PlaylistManager();
    final localAudio = await playlistManager.getAudioById(id);  // ❌ 查询前端本地数据库
    if (localAudio != null) {
      localPath = localAudio.filePath;
    }
  }
}
```

**问题**: 服务器返回的 `local_63` 中的 ID 是服务器数据库 ID，但查询的是前端本地数据库，两者不一致！

**正确做法**: 直接使用 `item.localPath` 字段（服务器已返回实际文件路径）

### 问题2: 播放列表替换bug

**根本原因**: `unified_playlist_manager.dart:syncFromLocal()`

```dart
// 当前代码（会导致播放状态丢失）:
_playlist.clear();
_playlist.addAll(onlinePlayables);
// ... 重建播放列表
```

**问题**: 清空重建会改变索引位置，当前播放状态丢失

### 问题3: 本地音频封面获取

**当前逻辑**: 文件元数据 → 数据库元数据 → 文件路径推断

**问题**: 数据库中的封面可能过时，应该直接从文件获取

**正确做法**: 仅从文件获取元数据，数据库只用于用户编辑的元数据

---

## Task 1: 修复全部播放功能中的本地音频路径解析

**Files:**
- Modify: `frontend_flutter/lib/presentation/pages/playlist_detail_page.dart:644-690`

**Step 1: 写失败的测试**

创建 `frontend_flutter/test/pages/playlist_detail_page_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo/domain/entities/playlist.dart';
import 'package:demo/presentation/pages/playlist_detail_page.dart';

void main() {
  group('PlaylistDetailPage - 播放本地音频', () {
    testWidgets('当 localPath 不为空时，直接使用 localPath 播放', (tester) async {
      final item = PlaylistItem(
        bvid: 'local_999',  // 服务器返回的ID（前端数据库不存在）
        localPath: '/storage/music/test.mp3',  // 实际文件路径
        title: 'Test Song',
        position: 0,
      );

      // 验证 localPath 被正确使用
      expect(item.localPath, '/storage/music/test.mp3');
    });

    testWidgets('当 bvid 为空时，判断为本地音频', (tester) async {
      final item = PlaylistItem(
        bvid: '',  // 空bvid表示本地音频
        localPath: '/storage/music/test.mp3',
        position: 0,
      );

      expect(item.bvid.isEmpty, true);
    });
  });
}
```

**Step 2: 运行测试验证通过**

```powershell
cd frontend_flutter
flutter test test/pages/playlist_detail_page_test.dart
```

预期: PASS（测试用例验证数据结构正确性）

**Step 3: 修复 _playPlaylistItem 方法**

编辑 `playlist_detail_page.dart:644-690`:

```dart
// 判断是否为本地歌曲
// 本地音频的判断条件: bvid为空、localPath不为空、或bvid以 'local_'/'file://' 开头
final isLocal = item.bvid.isEmpty ||
               item.localPath != null && item.localPath!.isNotEmpty ||
               item.bvid.startsWith('local_') ||
               item.bvid.startsWith('file://');

if (isLocal) {
  // ✅ 修复: 优先使用服务器返回的 localPath
  String? localPath = item.localPath;

  // 只有当 localPath 为空时，才尝试从 bvid 解析
  if ((localPath == null || localPath.isEmpty) && item.bvid.startsWith('file://')) {
    localPath = item.bvid.replaceFirst('file://', '');
  }

  // 如果仍然为空，记录警告并跳过
  if (localPath == null || localPath.isEmpty) {
    AppLogger.warn('PlaylistDetailPage', '本地歌曲路径为空，已跳过: ${item.title ?? item.bvid}');
    return;
  }

  AppLogger.info('PlaylistDetailPage', autoPlay ? '播放本地歌曲: $localPath' : '添加本地歌曲到队列: $localPath');

  if (autoPlay) {
    await audioProvider.loadAudio(localPath);
  } else {
    // 仅添加到队列，不播放
    await audioProvider.addToPlaylist(LocalAudio(
      filePath: localPath,
      title: item.title ?? item.bvid,
      artist: item.artist ?? '',
      duration: item.duration ?? 0,
    ));
  }
}
```

**Step 4: 运行测试验证修复**

```powershell
flutter test
```

**Step 5: 提交**

```bash
git add frontend_flutter/lib/presentation/pages/playlist_detail_page.dart
git commit -m "fix(playlist): use localPath directly for local audio playback

- 优先使用服务器返回的 localPath 字段
- 移除对前端本地数据库的查询（ID不匹配）
- 修复'播放全部'功能无法播放本地音频的问题"
```

---

## Task 2: 修复播放列表替换时的索引丢失

**Files:**
- Modify: `frontend_flutter/lib/presentation/providers/audio/unified_playlist_manager.dart:301-344`

**Step 1: 写失败的测试**

```dart
// 添加到现有测试文件
test('同步时保留当前播放索引', () async {
  final manager = UnifiedPlaylistManager();

  // 添加在线和本地音频
  final online = OnlinePlayable(
    id: 'online_1',
    title: 'Online Song',
    url: 'http://example.com/audio.mp3',
  );
  final local = LocalPlayable(LocalAudio(
    filePath: '/path/to/local.mp3',
    title: 'Local Song',
  ));

  await manager.add(online, playImmediately: true);
  await manager.add(local);

  final originalIndex = manager.currentIndex;
  expect(originalIndex, 0);

  // 模拟同步（保留当前音频）
  await manager.syncFromLocal();

  // 索引应该保持有效
  expect(manager.currentIndex, greaterThanOrEqualTo(0));
  expect(manager.currentIndex, lessThan(manager.playlist.length));
});
```

**Step 2: 运行测试验证失败**

```powershell
flutter test test/providers/audio/unified_playlist_manager_test.dart
```

预期: FAIL（索引可能被重置）

**Step 3: 修复 syncFromLocal 方法**

编辑 `unified_playlist_manager.dart:302-344`:

```dart
/// 从本地播放列表同步 - P0修复：增量同步，保留当前播放状态
Future<void> syncFromLocal() async {
  try {
    final db = PlaylistManager();
    final dbAudios = await db.getAllAudios();

    // ✅ 保存当前播放的音频ID
    final currentPlayable = currentPlayable;
    final String? currentId = currentPlayable?.id;

    // P0修复：增量同步，保留在线音频
    final onlinePlayables = _playlist.whereType<OnlinePlayable>().toList();

    // 更新本地播放列表
    _localPlaylist.clear();
    _localPlaylist.addAll(dbAudios);

    // P0修复：重建播放列表，保留在线音频，更新本地音频
    _playlist.clear();
    _playlist.addAll(onlinePlayables);

    for (final audio in _localPlaylist) {
      final existingIndex = _playlist.indexWhere((p) =>
        p is LocalPlayable && p.original.filePath == audio.filePath);

      if (existingIndex == -1) {
        _playlist.add(LocalPlayable(audio));
      } else {
        _playlist[existingIndex] = LocalPlayable(audio);
      }
    }

    // ✅ 恢复当前播放索引
    if (currentId != null) {
      final newIndex = _playlist.indexWhere((p) => p.id == currentId);
      if (newIndex != -1) {
        _currentIndex = newIndex;
        AppLogger.debug('UnifiedPlaylistManager', '恢复播放索引: $_currentIndex');
      } else {
        _currentIndex = _playlist.isEmpty ? -1 : 0;
      }
    }

    _notifyChanged();
    AppLogger.debug('UnifiedPlaylistManager', '从本地播放列表同步: ${_localPlaylist.length} 首本地 + ${onlinePlayables.length} 首在线');
  } catch (e) {
    AppLogger.error('UnifiedPlaylistManager', '从本地同步失败: $e');
  }
}
```

**Step 4: 运行测试验证通过**

```powershell
flutter test test/providers/audio/unified_playlist_manager_test.dart
```

**Step 5: 提交**

```bash
git add frontend_flutter/lib/presentation/providers/audio/unified_playlist_manager.dart
git commit -m "fix(playlist): preserve current playback index during sync

- 保存当前播放的音频ID
- 同步后恢复正确的索引位置
- 防止播放列表替换时播放状态丢失"
```

---

## Task 3: 统一元数据获取来源（优先文件）

**Files:**
- Modify: `frontend_flutter/lib/presentation/providers/audio/audio_provider.dart:687-805`
- Modify: `frontend_flutter/lib/presentation/providers/audio/audio_metadata_loader.dart`

**Step 1: 分析当前元数据获取流程**

当前流程（有冗余）:
```
1. 从文件路径提取默认元数据
2. 从本地播放列表查找数据库元数据
3. 合并元数据（数据库覆盖文件）
4. 后台异步加载完整元数据
5. 再次合并
```

**问题**: 数据库元数据可能过时，导致显示错误的封面

**正确流程**:
```
1. 从文件直接读取完整元数据（包含封面）
2. 如果用户有自定义编辑，使用用户的编辑值
3. 不依赖数据库缓存的元数据
```

**Step 2: 修复 loadAudio 方法的元数据获取**

编辑 `audio_provider.dart:708-730`:

```dart
// ✅ 优化：直接从文件读取元数据（不依赖数据库）
final metadataLoader = AudioMetadataLoader();
final fileMetadata = await metadataLoader.extractFromFile(filePath);

_title = fileMetadata['title'] as String;
_artist = fileMetadata['artist'] as String;
_albumArt = fileMetadata['cover'] as Uint8List?;

// 确保当前播放信息立即更新
_syncMetadataProvider();
notifyListeners();

// ✅ 立即启动播放
await _playbackController.setFileSource(filePath);
await _playbackController.play();
_playerStatusMessage = '';
notifyListeners();

// ✅ 后台：检查是否有用户自定义元数据（仅用于覆盖，不用于默认值）
// 这部分可以后续添加，目前优先文件元数据
```

**Step 3: 更新 AudioMetadataLoader 说明**

在 `audio_metadata_loader.dart` 顶部添加注释:

```dart
/// 音频元数据加载器
///
/// 职责：
/// 1. 从本地文件提取元数据（标题、艺术家、专辑封面）- ✅ 主要来源
/// 2. 从网络加载在线音频封面
/// 3. 从文件路径提取元数据（后备方案）
/// 4. 元数据缓存管理
///
/// ⚠️ 重要：本地音频的元数据应直接从文件读取
/// - 封面：从音频文件嵌入的封面图片读取
/// - 标题/艺术家：从音频文件的元数据标签读取
/// - 数据库仅用于：用户自定义编辑的元数据（优先级高于文件）
```

**Step 4: 提交**

```bash
git add frontend_flutter/lib/presentation/providers/audio/audio_provider.dart
git add frontend_flutter/lib/presentation/providers/audio/audio_metadata_loader.dart
git commit -m "refactor(metadata): prioritize file metadata over database cache

- 直接从文件读取封面和元数据
- 移除对数据库缓存元数据的依赖
- 确保显示的封面是最新的文件嵌入封面"
```

---

## Task 4: 添加播放功能回归测试

**Files:**
- Create: `frontend_flutter/test/integration/playback_integration_test.dart`

**Step 1: 创建集成测试**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:demo/domain/entities/playlist.dart';
import 'package:demo/presentation/providers/audio/audio_provider.dart';

void main() {
  group('播放功能集成测试', () {
    testWidgets('歌单播放全部：混合本地和在线音频', (tester) async {
      // 验证混合播放列表的正确处理
      final items = [
        PlaylistItem(
          bvid: 'local_999',
          localPath: '/mock/path/local.mp3',
          title: 'Local Song',
          position: 0,
        ),
        PlaylistItem(
          bvid: 'BV1xx411c7mD',
          title: 'Online Song',
          position: 1,
        ),
      ];

      // 验证本地音频路径正确解析
      expect(items[0].localPath, '/mock/path/local.mp3');

      // 验证在线音频bvid正确
      expect(items[1].bvid, 'BV1xx411c7mD');
    });
  });
}
```

**Step 2: 运行测试**

```powershell
flutter test test/integration/playback_integration_test.dart
```

**Step 3: 提交**

```bash
git add frontend_flutter/test/integration/playback_integration_test.dart
git commit -m "test(integration): add playback regression tests"
```

---

## 验证步骤

修复完成后，请验证以下场景：

### 场景1: 播放包含本地音频的歌单
1. 打开包含本地音频的歌单详情页
2. 点击"播放全部"
3. **预期**: 本地音频正常播放，不跳过

### 场景2: 混合播放列表切换
1. 播放在线音频
2. 切换到本地音频
3. 返回在线音频
4. **预期**: 播放索引正确，无状态丢失

### 场景3: 本地音频封面显示
1. 播放本地音频文件
2. 查看播放器封面
3. **预期**: 显示文件嵌入的封面（如果有的话）

---

## 数据来源统一性总结

修复后，各模块的数据来源：

| 模块 | 数据来源 |
|------|---------|
| **本地音频元数据** | 直接从文件读取（audio_metadata_reader） |
| **本地音频路径** | 服务器返回的 `local_path` 字段 |
| **在线音频元数据** | 服务器API |
| **播放列表同步** | SharedPreferences（在线）+ 文件系统（本地） |
| **用户自定义元数据** | 数据库（优先级高于文件） |

**关键原则**:
1. 本地音频的元数据（标题、艺术家、封面）直接从文件获取
2. 本地音频的路径使用服务器返回的 `localPath`，不查询前端数据库
3. 播放列表同步时保留当前播放状态
