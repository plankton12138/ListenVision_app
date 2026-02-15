# 修复收藏功能问题计划

## 问题分析

### 问题 1: 收藏保存元数据失败
**根本原因**: tracks 表在 V6 数据库升级后已移除 `position` 和 `playlist_id` 列，但 `CachedTrack.toMap()` 方法仍尝试写入这两个字段。

**错误日志**:
```
table tracks has no column named position
```

### 问题 2: 收藏歌单 UI 风格差异
**根本原因**: 收藏歌单详情页 (`playlist_detail_page.dart`) 与本地音乐歌单 (`local_music_playlist_page.dart`) 风格不一致：
- 收藏歌单: 120x120 封面、CustomScrollView、两个并排按钮
- 本地音乐: 80x80 封面、Column、全宽单个按钮

---

## 修复方案

### 问题 1 修复

**修改文件**: `frontend_flutter/lib/models/cached_track.dart`

在 `toMap()` 方法中移除 `position` 和 `playlist_id` 字段的写入：

```dart
// 第 185-195 行附近，移除 position 和 playlist_id 的写入
Map<String, dynamic> toMap() {
  return {
    'id': id,
    'sourceId': sourceId,
    'sourceType': sourceType,
    'title': title,
    'artist': artist,
    'album': album,
    'duration': duration,
    'coverUrl': coverUrl,
    'bvid': bvid,
    'uploader': uploader,
    'uploaderMid': uploaderMid,
    'playCount': playCount,
    'localPath': localPath,
    'isDownloaded': isDownloaded,
    'isFavorite': isFavorite,
    'localPlayCount': localPlayCount,
    'lastPlayedAt': lastPlayedAt?.toIso8601String(),
    'addedAt': addedAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'syncedAt': syncedAt?.toIso8601String(),
    'createdAt': createdAt?.toIso8601String(),
    // 移除: 'position': position,
    // 移除: 'playlistId': playlistId,
  };
}
```

### 问题 2 修复

**修改文件**: `frontend_flutter/lib/presentation/views/library/playlist_detail_page.dart`

将收藏歌单详情页改为与本地音乐歌单 (`local_music_playlist_page.dart`) 一致的 UI 风格：

| 特性 | 收藏歌单 (当前) | 本地音乐歌单 (目标) |
|------|----------------|-------------------|
| **封面尺寸** | 120x120 | 80x80 |
| **布局结构** | CustomScrollView + SliverToBoxAdapter | Column + Container |
| **播放按钮** | 两个并排按钮 (Expanded) | 单个全宽按钮 (minimumSize: double.infinity) |
| **列表** | SliverList | ListView.builder |

修改内容：
1. 将封面尺寸从 120x120 改为 80x80
2. 将 `CustomScrollView` 改为普通 `Column`
3. 将两个并排按钮改为单个全宽按钮

---

## 验证方法

1. **问题 1 验证**:
   - 重新启动应用
   - 尝试收藏一首歌
   - 检查日志中是否还有 "table tracks has no column named position" 错误

2. **问题 2 验证**:
   - 对比收藏歌单详情页与本地音乐歌单详情页的 UI
   - 确认风格一致（封面尺寸 80x80、全宽按钮等）
