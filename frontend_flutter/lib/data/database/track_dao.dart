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

  /// 按曲目标识批量读取；分块兼容 SQLite 的绑定参数数量限制。
  Future<Map<String, CachedTrack>> getBySourceIds(
    Iterable<String> sourceIds,
  ) async {
    final ids = sourceIds.toSet().toList();
    if (ids.isEmpty) return {};
    final db = await _db.database;
    final tracks = <String, CachedTrack>{};
    for (var start = 0; start < ids.length; start += 500) {
      final chunk = ids.sublist(start, (start + 500).clamp(0, ids.length));
      final rows = await db.query(
        'tracks',
        where: 'source_id IN (${List.filled(chunk.length, '?').join(',')})',
        whereArgs: chunk,
      );
      for (final row in rows) {
        final track = CachedTrack.fromMap(row);
        tracks[track.sourceId] = track;
      }
    }
    return tracks;
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

  /// 标记轨道为未下载状态
  Future<void> markAsNotDownloaded(String sourceId) async {
    final track = await getBySourceId(sourceId);
    if (track == null) return;

    await _db.updateTrack(track.id, {
      'is_downloaded': 0,
      'local_path': null,
      'updated_at': DateTime.now().toIso8601String(),
    });

    AppLogger.info('TrackDao', '标记为未下载: $sourceId');
  }

  /// 批量更新下载状态
  Future<void> batchUpdateDownloadStatus(
    List<String> sourceIds,
    bool downloaded,
  ) async {
    if (sourceIds.isEmpty) return;

    for (final sourceId in sourceIds) {
      final track = await getBySourceId(sourceId);
      if (track != null) {
        await _db.updateTrack(track.id, {
          'is_downloaded': downloaded ? 1 : 0,
          'local_path': downloaded ? track.localPath : null,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    }

    AppLogger.info(
      'TrackDao',
      '批量更新下载状态: ${sourceIds.length} 个轨道, downloaded=$downloaded',
    );
  }

  /// 获取最近下载的轨道
  ///
  /// [since] 指定时间之后的下载记录
  Future<List<CachedTrack>> getRecentlyDownloadedTracks({
    required DateTime since,
  }) async {
    final db = await _db.database;
    final maps = await db.query(
      'tracks',
      where: 'is_downloaded = ? AND updated_at >= ?',
      whereArgs: [1, since.toIso8601String()],
      orderBy: 'updated_at DESC',
    );
    return maps.map((m) => CachedTrack.fromMap(m)).toList();
  }

  // ==================== 在线源状态 ====================

  /// 更新在线源可用性状态
  ///
  /// 在播放时被动检测或懒检测后调用，更新 online_status 及检测时间。
  Future<void> updateOnlineStatus(String sourceId, OnlineStatus status) async {
    final track = await getBySourceId(sourceId);
    if (track == null) return;

    await _db.updateTrack(track.id, {
      'online_status': status.value,
      'last_online_check_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    AppLogger.info('TrackDao', '更新在线状态: $sourceId -> $status');
  }

  /// 获取在线状态过期的 Track（需要重新检测的）
  ///
  /// [olderThan] 指定多久未检测视为过期（默认 7 天）
  /// [onlyFavorites] 是否仅限收藏的条目
  /// [limit] 限制返回数量
  Future<List<CachedTrack>> getStaleOnlineStatusTracks({
    Duration olderThan = const Duration(days: 7),
    bool onlyFavorites = false,
    int limit = 50,
  }) async {
    final db = await _db.database;

    final conditions = <String>[
      "(last_online_check_at IS NULL OR last_online_check_at < ?)",
    ];
    final args = <dynamic>[
      DateTime.now().subtract(olderThan).toIso8601String(),
    ];

    // 只检查 B 站来源（本地文件无需在线检测）
    conditions.add("source_type = 'bilibili'");

    // 排除已标记为 unavailable 的
    conditions.add("online_status != 'unavailable'");

    if (onlyFavorites) {
      conditions.add('is_favorite = 1');
    }

    final maps = await db.query(
      'tracks',
      where: conditions.join(' AND '),
      whereArgs: args,
      orderBy: 'last_online_check_at ASC',
      limit: limit,
    );
    return maps.map((m) => CachedTrack.fromMap(m)).toList();
  }

  /// 获取已失效的 Track（online_status = unavailable）
  ///
  /// [unavailableSinceBefore] 仅返回在此时间之前标记为失效的
  Future<List<CachedTrack>> getUnavailableTracks({
    DateTime? unavailableSinceBefore,
  }) async {
    final db = await _db.database;
    final conditions = <String>["online_status = 'unavailable'"];
    final args = <dynamic>[];

    if (unavailableSinceBefore != null) {
      conditions.add('last_online_check_at IS NOT NULL');
      conditions.add('last_online_check_at < ?');
      args.add(unavailableSinceBefore.toIso8601String());
    }

    final maps = await db.query(
      'tracks',
      where: conditions.join(' AND '),
      whereArgs: args,
      orderBy: 'last_online_check_at DESC',
    );
    return maps.map((m) => CachedTrack.fromMap(m)).toList();
  }

  /// 获取过期的幽灵条目（两端都断了且超过 90 天）
  ///
  /// 用于自动清理。符合条件：online_status=unavailable + 无本地文件 + 标记时间超过 90 天。
  Future<List<CachedTrack>> getExpiredGhostTracks({
    Duration expiredAfter = const Duration(days: 90),
  }) async {
    final db = await _db.database;
    final threshold = DateTime.now().subtract(expiredAfter).toIso8601String();

    final maps = await db.query(
      'tracks',
      where: '''
      online_status = 'unavailable'
      AND (is_downloaded = 0 OR is_downloaded IS NULL)
      AND last_online_check_at IS NOT NULL
      AND last_online_check_at < ?
    ''',
      whereArgs: [threshold],
      orderBy: 'last_online_check_at ASC',
    );
    return maps.map((m) => CachedTrack.fromMap(m)).toList();
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
    // 始终将 Audio 元数据合并到数据库（Upsert），
    // 确保已有 track 也能获得更完整的 metadata（如 duration、title 等）
    final track = CachedTrack.fromAudio(audio);
    final id = await insertOrUpdate(track);

    // 重新获取以获取完整数据（包括创建时间等）
    final saved = await getById(id);
    return saved ?? track.copyWith(id: id);
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
