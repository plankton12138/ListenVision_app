# 修复歌单"播放全部"功能实施计划

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**目标:** 修复歌单详情页"播放全部"功能，使其能正确更新播放列表为歌单内容

**架构:** 问题在于 `addToQueueOnline` 方法只将音频添加到内部队列（`_onlineQueue`），不更新统一播放列表（`_playlist`）。需要修改添加逻辑，使所有歌曲都能添加到统一播放列表。

**技术栈:**
- Flutter Provider 状态管理
- UnifiedPlaylistManager 统一播放列表管理
- OnlinePlayable 在线音频实体

---

## 任务 1: 添加 AudioProvider 的公开方法

**文件:**
- 修改: `frontend_flutter/lib/presentation/providers/audio/audio_provider.dart:842-847`

**步骤 1: 阅读现有方法**

在 `audio_provider.dart` 的第 842-847 行查看 `addToQueueOnline` 方法：

```dart
Future<void> addToQueueOnline(Audio audio) async {
  AppLogger.info('AudioProvider', '添加在线音频到队列: ${audio.title}');
  final proxyUrl = _buildProxyUrl(audio.id);
  _onlineQueue.add(proxyUrl);
  notifyListeners();
}
```

**步骤 2: 添加新方法 `addToPlaylistOnline`**

在 `addToQueueOnline` 方法后添加新方法：

```dart
/// 添加在线音频到统一播放列表（不立即播放）
///
/// 将在线音频添加到播放列表末尾，但不立即播放。
/// 与 addToQueueOnline 不同，此方法会更新统一播放列表。
///
/// 参数:
/// - [audio] 要添加的在线音频
Future<void> addToPlaylistOnline(Audio audio) async {
  AppLogger.info('AudioProvider', '添加在线音频到播放列表: ${audio.title}');

  // 构建代理 URL
  final proxyUrl = _buildProxyUrl(audio.id);

  // 创建在线可播放对象
  final playable = OnlinePlayable.fromAudio(audio, proxyUrl);

  // 添加到播放列表（不立即播放）
  await _playlistManager.add(playable, playImmediately: false);

  // 同步状态
  await _playlistManager.save();
  _syncPlaylistProviders();
  notifyListeners();
}
```

**步骤 3: 运行分析验证语法**

运行: `flutter analyze lib/presentation/providers/audio/audio_provider.dart`
预期: 无错误

**步骤 4: 提交**

```bash
git add frontend_flutter/lib/presentation/providers/audio/audio_provider.dart
git commit -m "feat(audio): add addToPlaylistOnline method for updating unified playlist"
```

---

## 任务 2: 修改 _playPlaylistItem 方法

**文件:**
- 修改: `frontend_flutter/lib/presentation/pages/playlist_detail_page.dart:690-712`

**步骤 1: 定位修改位置**

找到 `_playPlaylistItem` 方法中处理在线歌曲的 `else` 分支（约第 690-712 行）：

```dart
} else {
  // 在线歌曲播放逻辑
  final audio = Audio.fromDto({
    'bvid': item.bvid,
    'title': item.title ?? item.bvid,
    'artist': item.artist,
    'cover': item.coverUrl,
    'duration': item.duration,
  });

  AppLogger.info('PlaylistDetailPage', autoPlay ? '播放在线歌曲: ${audio.title}' : '添加在线歌曲到队列: ${audio.title}');

  if (autoPlay) {
    // audioProvider 会自动构建代理 URL
    await audioProvider.playOnlineAudio(
      audio: audio,
    );
  } else {
    // 仅添加到播放列表，不播放
    // 使用 addToQueueOnline 方法添加在线音频到队列
    await audioProvider.addToQueueOnline(audio);
  }
}
```

**步骤 2: 修改 autoPlay=false 时的处理**

将 `addToQueueOnline` 调用改为 `addToPlaylistOnline`：

```dart
} else {
  // 仅添加到播放列表，不播放
  // 使用 addToPlaylistOnline 添加到统一播放列表
  await audioProvider.addToPlaylistOnline(audio);
}
```

**步骤 3: 运行分析验证语法**

运行: `flutter analyze lib/presentation/pages/playlist_detail_page.dart`
预期: 无错误

**步骤 4: 提交**

```bash
git add frontend_flutter/lib/presentation/pages/playlist_detail_page.dart
git commit -m "fix(playlist): use addToPlaylistOnline in _playPlaylistItem to update unified playlist"
```

---

## 任务 3: 手动测试验证

**测试步骤:**

1. **启动应用**
   ```bash
   cd frontend_flutter
   flutter run
   ```

2. **测试场景 1: 播放全部在线歌曲**
   - 导航到包含多首在线歌曲的歌单
   - 点击"播放全部"按钮
   - **验证:**
     - 第一首歌开始播放
     - 播放列表显示所有歌单歌曲（不只是第一首）
     - 可以在播放列表中看到所有歌曲

3. **测试场景 2: 播放列表正确性**
   - 播放全部后，打开播放列表
   - **验证:**
     - 歌曲数量与歌单一致
     - 歌曲顺序正确
     - 可以点击切换歌曲

4. **测试场景 3: 下一首播放**
   - 播放全部后，等待歌曲结束或手动点击下一首
   - **验证:**
     - 自动播放歌单中的下一首歌曲
     - 播放列表索引正确更新

**预期日志输出:**
```
AudioProvider: 添加在线音频到播放列表: [歌曲名]
UnifiedPlaylistManager: 添加音频: [歌曲名], 总数: [数量]
```

---

## 任务 4: 添加单元测试（可选）

**文件:**
- 创建: `frontend_flutter/test/providers/audio/audio_provider_playlist_test.dart`

**步骤 1: 编写测试用例**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:demo/presentation/providers/audio/audio_provider.dart';
import 'package:demo/domain/entities/audio.dart';

void main() {
  group('AudioProvider.addToPlaylistOnline', () {
    late AudioProvider audioProvider;

    setUp(() {
      audioProvider = AudioProvider();
    });

    tearDown(() async {
      await audioProvider.dispose();
    });

    test('应该将在线音频添加到统一播放列表', () async {
      // Arrange
      final audio = Audio(
        id: 'BV1xx411c7mD',
        title: '测试歌曲',
      );

      // Act
      await audioProvider.addToPlaylistOnline(audio);

      // Assert
      expect(audioProvider.unifiedPlaylist.length, 1);
      expect(audioProvider.unifiedPlaylist.first.id, contains('BV1xx411c7mD'));
    });

    test('应该添加多首歌曲到播放列表', () async {
      // Arrange
      final audios = List.generate(
        3,
        (i) => Audio(id: 'BV${i}', title: '歌曲$i'),
      );

      // Act
      for (final audio in audios) {
        await audioProvider.addToPlaylistOnline(audio);
      }

      // Assert
      expect(audioProvider.unifiedPlaylist.length, 3);
    });
  });
}
```

**步骤 2: 运行测试**

运行: `flutter test test/providers/audio/audio_provider_playlist_test.dart`
预期: 测试通过

**步骤 3: 提交**

```bash
git add frontend_flutter/test/providers/audio/audio_provider_playlist_test.dart
git commit -m "test(audio): add tests for addToPlaylistOnline method"
```

---

## 任务 5: 更新文档

**文件:**
- 修改: `frontend_flutter/lib/presentation/providers/audio/audio_provider.dart:824-847`

**步骤 1: 更新 addToQueueOnline 文档注释**

将现有注释说明其用途和限制：

```dart
/// 添加到在线播放队列（内部队列，不更新播放列表UI）
///
/// 将在线音频添加到内部队列，用于快速添加播放。
/// 注意：此方法不会更新统一播放列表。
///
/// 如需添加到统一播放列表并在UI中显示，请使用 [addToPlaylistOnline]。
///
/// 参数:
/// - [audio] 要添加到队列的在线音频
Future<void> addToQueueOnline(Audio audio) async {
  ...
}
```

**步骤 2: 提交**

```bash
git add frontend_flutter/lib/presentation/providers/audio/audio_provider.dart
git commit -m "docs(audio): clarify addToQueueOnline vs addToPlaylistOnline usage"
```

---

## 任务 6: 最终验证

**验证清单:**
- [ ] `flutter analyze` 无错误
- [ ] `flutter test` 所有测试通过
- [ ] 手动测试所有场景通过
- [ ] 日志输出正常

**最终提交:**

```bash
git add .
git commit -m "fix(playlist): fix playAll to update unified playlist with all songs"
```

---

## 相关文件

| 文件 | 修改类型 | 说明 |
|------|----------|------|
| `audio_provider.dart` | 修改 | 添加 `addToPlaylistOnline` 方法 |
| `audio_provider.dart` | 修改 | 更新 `addToQueueOnline` 文档 |
| `playlist_detail_page.dart` | 修改 | 修改 `_playPlaylistItem` 使用新方法 |
| `audio_provider_playlist_test.dart` | 创建 | 新增单元测试（可选） |

---

## 执行摘要

1. **问题根因**: `addToQueueOnline` 只添加到内部队列，不更新播放列表
2. **解决方案**: 添加 `addToPlaylistOnline` 方法，将在线音频添加到统一播放列表
3. **影响范围**: 仅修改播放列表更新逻辑，不影响现有播放功能
