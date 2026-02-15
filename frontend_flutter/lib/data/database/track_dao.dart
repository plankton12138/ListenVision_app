import '../../core/utils/app_logger.dart';
import '../../core/utils/local_track_id.dart';
import '../../models/audio.dart';
import '../../models/cached_track.dart';
import '../../models/local_audio.dart';
import 'app_database.dart';

/// Track 数据访问对象
///
/// 提供对 tracks 表的 CRUD 操作，是 Repository 层的数据源。
/// 所有方法返回 CachedTrack 实体或原始 Map，由上层决定如何转换。
class TrackDao {
  final AppDatabase _db;

  TrackDao(this._db);

  // ==================== 插入/更新 ====================

  /// 插入或更新 Track（UPSERT）
  ///
  /// 如果 track 已存在（根据 source_id 判断），则更新；否则插入。
  /// 返回 Track 的数据库 ID。
  Future<int> insertOrUpdate(CachedTrack track) async {
    final map = track.toMapForInsert();
    return await _db.insertOrUpdateTrack(map);
  }

  /// 批量插入或更新
  ///
  /// 用于搜索结果批量缓存到本地。
  Future<List<int>> insertOrUpdateBatch(List<CachedTrack> tracks) async {
    final ids = <int>[];
    for (final track in tracks) {
      final id = await insertOrUpdate(track);
      ids.add(id);
    }
    return ids;
  }

  // ==================== 查询 ====================

  /// 根据 ID 获取 Track
  Future<CachedTrack?> getById(int id) async {
    final map = await _db.getTrackById(id);
    if (map == null) return null;
    return CachedTrack.fromMap(map);
  }

  /// 根据 source_id 获取 Track
  ///
  /// 这是最常用的查询方式，因为 source_id 是业务层面的唯一标识
  /// （如 BVID 或本地文件路径）。
  Future<CachedTrack?> getBySourceId(String sourceId) async {
    final map = await _db.getTrackBySourceId(sourceId);
    if (map == null) return null;
    return CachedTrack.fromMap(map);
  }

  /// 根据 BVID 获取 Track（B站音频专用）
  Future<CachedTrack?> getByBvid(String bvid) async {
    return await getBySourceId(bvid);
  }

  /// 获取所有 Tracks
  Future<List<CachedTrack>> getAll() async {
    final maps = await _db.getAllTracks();
    return maps.map((m) => CachedTrack.fromMap(m)).toList();
  }

  /// 获取已下载的 Tracks
  Future<List<CachedTrack>> getDownloadedTracks() async {
    final maps = await _db.getDownloadedTracks();
    return maps.map((m) => CachedTrack.fromMap(m)).toList();
  }

  /// 获取收藏的 Tracks
  Future<List<CachedTrack>> getFavoriteTracks() async {
    final maps = await _db.getFavoriteTracks();
    return maps.map((m) => CachedTrack.fromMap(m)).toList();
  }

  /// 搜索 Tracks
  ///
  /// 在标题和艺术家字段中搜索关键词。
  Future<List<CachedTrack>> search(String keyword) async {
    if (keyword.isEmpty) return [];
    final maps = await _db.searchTracks(keyword);
    return maps.map((m) => CachedTrack.fromMap(m)).toList();
  }

  /// 检查 Track 是否存在
  Future<bool> exists(String sourceId) async {
    final track = await getBySourceId(sourceId);
    return track != null;
  }

  /// 检查是否已下载
  Future<bool> isDownloaded(String sourceId) async {
    final track = await getBySourceId(sourceId);
    return track?.isDownloaded ?? false;
  }

  // ==================== 更新 ====================

  /// 更新 Track
  Future<void> update(CachedTrack track) async {
    await _db.updateTrack(track.id, track.toMap());
  }

  /// 切换收藏状态
  Future<void> toggleFavorite(int id, bool isFavorite) async {
    await _db.toggleTrackFavorite(id, isFavorite);
    AppLogger.info('TrackDao', '切换收藏: id=$id, isFavorite=$isFavorite');
  }

  Future<void> markAsDownloaded(int id, String localPath) async {
    await _db.markTrackAsDownloaded(id, localPath);
    AppLogger.info('TrackDao', '标记为已下载: id=$id, path=$localPath');
  }

  /// 更新最后播放时间
  Future<void> updateLastPlayed(int id) async {
    await _db.updateTrack(id, {
      'last_played_at': DateTime.now().toIso8601String(),
      'local_play_count': 1, // 这里需要累加，实际应该在 Repository 层处理
    });
  }

  /// 增加本地播放次数
  Future<void> incrementPlayCount(int id) async {
    final track = await getById(id);
    if (track == null) return;
    
    await _db.updateTrack(id, {
      'local_play_count': track.localPlayCount + 1,
      'last_played_at': DateTime.now().toIso8601String(),
    });
  }

  // ==================== 删除 ====================

  /// 删除 Track
  Future<void> delete(int id) async {
    await _db.deleteTrack(id);
    AppLogger.info('TrackDao', '删除 Track: $id');
  }

  /// 根据 source_id 删除
  Future<void> deleteBySourceId(String sourceId) async {
    final track = await getBySourceId(sourceId);
    if (track != null) {
      await delete(track.id);
    }
  }

  // ==================== 转换方法 ====================

  /// 从 Audio 创建并保存 Track
  ///
  /// 用于搜索结果转换为本地缓存。
  Future<CachedTrack> saveFromAudio(Audio audio) async {
    final existing = await getBySourceId(audio.id);
    if (existing != null) {
      // 已存在，返回现有的
      return existing;
    }

    final track = CachedTrack.fromAudio(audio);
    final id = await insertOrUpdate(track);
    
    // 重新获取以获取完整数据（包括创建时间等）
    final saved = await getById(id);
    return saved!;
  }

  /// 从 LocalAudio 创建并保存 Track
  ///
  /// 用于本地音乐导入。
  Future<CachedTrack> saveFromLocalAudio(LocalAudio localAudio) async {
    final localId = localIdFromPath(localAudio.filePath);

    final existing = await getBySourceId(localId);
    if (existing != null) {
      // 已存在，可能需要更新
      return existing;
    }

    final track = CachedTrack.fromLocalAudio(localAudio);
    final id = await insertOrUpdate(track);

    final saved = await getById(id);
    return saved!;
  }

  // ==================== 统计 ====================

  /// 获取 Track 总数
  Future<int> getCount() async {
    final stats = await _db.getStats();
    return stats['tracks'] ?? 0;
  }

  /// 获取已下载数量
  Future<int> getDownloadedCount() async {
    final tracks = await getDownloadedTracks();
    return tracks.length;
  }

  /// 获取收藏数量
  Future<int> getFavoriteCount() async {
    final tracks = await getFavoriteTracks();
    return tracks.length;
  }
}
