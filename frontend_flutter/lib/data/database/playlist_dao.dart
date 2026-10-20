import '../../core/utils/app_logger.dart';
import 'app_database.dart';

/// Playlist 数据访问对象
///
/// 提供对 playlists 和 playlist_items 表的 CRUD 操作。
/// 支持本地歌单缓存和多对多关系管理。
class PlaylistDao {
  final AppDatabase _db;

  PlaylistDao(this._db);

  // ==================== Playlists CRUD ====================

  /// 插入歌单
  Future<int> insertPlaylist(Map<String, dynamic> playlist) async {
    final db = await _db.database;

    playlist['created_at'] ??= DateTime.now().toIso8601String();
    playlist['updated_at'] = DateTime.now().toIso8601String();

    final id = await db.insert('playlists', playlist);
    AppLogger.info('PlaylistDao', '插入歌单: $id - ${playlist['name']}');
    return id;
  }

  /// 根据 ID 获取歌单
  Future<Map<String, dynamic>?> getPlaylistById(int id) async {
    final db = await _db.database;
    final maps = await db.query(
      'playlists',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isNotEmpty ? maps.first : null;
  }

  /// 根据 server_id 获取歌单
  Future<Map<String, dynamic>?> getPlaylistByServerId(String serverId) async {
    final db = await _db.database;
    final maps = await db.query(
      'playlists',
      where: 'server_id = ?',
      whereArgs: [serverId],
      limit: 1,
    );
    return maps.isNotEmpty ? maps.first : null;
  }

  /// 获取所有歌单
  Future<List<Map<String, dynamic>>> getAllPlaylists() async {
    final db = await _db.database;
    return await db.query('playlists', orderBy: 'updated_at DESC');
  }

  /// 获取系统歌单
  Future<List<Map<String, dynamic>>> getSystemPlaylists() async {
    final db = await _db.database;
    return await db.query(
      'playlists',
      where: 'type = ?',
      whereArgs: ['system'],
      orderBy: 'created_at ASC',
    );
  }

  /// 获取用户歌单
  Future<List<Map<String, dynamic>>> getUserPlaylists() async {
    final db = await _db.database;
    return await db.query(
      'playlists',
      where: 'type = ?',
      whereArgs: ['user'],
      orderBy: 'updated_at DESC',
    );
  }

  /// 根据系统类型获取歌单
  Future<Map<String, dynamic>?> getSystemPlaylistByType(
    String systemType,
  ) async {
    final db = await _db.database;
    final maps = await db.query(
      'playlists',
      where: 'system_type = ?',
      whereArgs: [systemType],
      limit: 1,
    );
    return maps.isNotEmpty ? maps.first : null;
  }

  /// 更新歌单
  Future<void> updatePlaylist(int id, Map<String, dynamic> data) async {
    final db = await _db.database;
    data['updated_at'] = DateTime.now().toIso8601String();
    await db.update('playlists', data, where: 'id = ?', whereArgs: [id]);
    AppLogger.info('PlaylistDao', '更新歌单: $id');
  }

  /// 删除歌单
  ///
  /// 会级联删除歌单项（由外键约束自动处理）
  Future<void> deletePlaylist(int id) async {
    final db = await _db.database;
    await db.delete('playlists', where: 'id = ?', whereArgs: [id]);
    AppLogger.info('PlaylistDao', '删除歌单: $id');
  }

  /// 从服务器数据插入或更新歌单（UPSERT）
  Future<int> upsertPlaylistFromServer(Map<String, dynamic> serverData) async {
    final serverId = serverData['server_id'] as String?;
    if (serverId == null) {
      throw ArgumentError('server_id 不能为空');
    }

    // 检查是否已存在
    final existing = await getPlaylistByServerId(serverId);
    if (existing != null) {
      // 更新
      final id = existing['id'] as int;
      await updatePlaylist(id, serverData);
      return id;
    } else {
      // 插入
      return await insertPlaylist(serverData);
    }
  }

  // ==================== Playlist Items CRUD ====================

  /// 添加歌曲到歌单
  Future<int> addItemToPlaylist(
    int playlistId,
    int trackId,
    int position,
  ) async {
    final db = await _db.database;

    final id = await db.insert('playlist_items', {
      'playlist_id': playlistId,
      'track_id': trackId,
      'position': position,
      'added_at': DateTime.now().toIso8601String(),
    });

    AppLogger.info('PlaylistDao', '添加歌曲到歌单: 歌单=$playlistId, Track=$trackId');

    // 更新歌单的 item_count
    await _updatePlaylistItemCount(playlistId);

    return id;
  }

  /// 获取歌单的所有歌曲
  Future<List<Map<String, dynamic>>> getPlaylistItems(int playlistId) async {
    final db = await _db.database;

    // 联表查询，获取完整的 track 信息
    return await db.rawQuery(
      '''
      SELECT
        pi.id, pi.playlist_id, pi.position, pi.added_at,
        t.id as track_id, t.source_id, t.source_type, t.title, t.artist,
        t.album, t.duration, t.cover_url, t.bvid, t.local_path,
        t.is_downloaded, t.is_favorite
      FROM playlist_items pi
      INNER JOIN tracks t ON pi.track_id = t.id
      WHERE pi.playlist_id = ?
      ORDER BY pi.position ASC
    ''',
      [playlistId],
    );
  }

  /// 从歌单移除歌曲
  Future<void> removeItemFromPlaylist(int playlistId, int trackId) async {
    final db = await _db.database;
    await db.delete(
      'playlist_items',
      where: 'playlist_id = ? AND track_id = ?',
      whereArgs: [playlistId, trackId],
    );

    AppLogger.info('PlaylistDao', '从歌单移除歌曲: 歌单=$playlistId, Track=$trackId');

    // 更新歌单的 item_count
    await _updatePlaylistItemCount(playlistId);
  }

  /// 更新歌单项位置
  Future<void> updateItemPosition(int itemId, int newPosition) async {
    final db = await _db.database;
    await db.update(
      'playlist_items',
      {'position': newPosition},
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  /// 批量更新歌单项位置（用于重排序）
  Future<void> reorderPlaylistItems(
    int playlistId,
    List<Map<String, dynamic>> items,
  ) async {
    final db = await _db.database;

    await db.transaction((txn) async {
      final batch = txn.batch();
      for (var i = 0; i < items.length; i++) {
        batch.update(
          'playlist_items',
          {'position': i},
          where: 'id = ? AND playlist_id = ?',
          whereArgs: [items[i]['id'], playlistId],
        );
      }
      await batch.commit(noResult: true);
    });

    AppLogger.info('PlaylistDao', '重排序歌单项: 歌单=$playlistId, ${items.length}项');
  }

  /// 清空歌单
  Future<void> clearPlaylist(int playlistId) async {
    final db = await _db.database;
    await db.delete(
      'playlist_items',
      where: 'playlist_id = ?',
      whereArgs: [playlistId],
    );

    AppLogger.info('PlaylistDao', '清空歌单: $playlistId');

    // 更新歌单的 item_count
    await _updatePlaylistItemCount(playlistId);
  }

  /// 同步歌单项到本地
  ///
  /// 完全替换歌单的所有项（用于从服务器同步）
  Future<void> syncPlaylistItems(
    int playlistId,
    List<Map<String, dynamic>> items,
  ) async {
    final db = await _db.database;

    await db.transaction((txn) async {
      // 1. 清空现有项
      await txn.delete(
        'playlist_items',
        where: 'playlist_id = ?',
        whereArgs: [playlistId],
      );

      // 2. 插入新项
      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        await txn.insert('playlist_items', {
          'playlist_id': playlistId,
          'track_id': item['track_id'],
          'position': i,
          'added_at': item['added_at'] ?? DateTime.now().toIso8601String(),
        });
      }
    });

    AppLogger.info('PlaylistDao', '同步歌单项: 歌单=$playlistId, ${items.length}项');

    // 更新歌单的 item_count
    await _updatePlaylistItemCount(playlistId);
  }

  // ==================== 辅助方法 ====================

  /// 更新歌单的歌曲数量
  Future<void> _updatePlaylistItemCount(int playlistId) async {
    final db = await _db.database;

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM playlist_items WHERE playlist_id = ?',
      [playlistId],
    );

    final count = result.first['count'] as int? ?? 0;

    await db.update(
      'playlists',
      {'item_count': count, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [playlistId],
    );
  }

  /// 检查歌曲是否在歌单中
  Future<bool> isTrackInPlaylist(int playlistId, int trackId) async {
    final db = await _db.database;
    final result = await db.query(
      'playlist_items',
      where: 'playlist_id = ? AND track_id = ?',
      whereArgs: [playlistId, trackId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  /// 获取歌单统计
  Future<Map<String, int>> getStats() async {
    final db = await _db.database;

    final playlistResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM playlists',
    );
    final itemResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM playlist_items',
    );

    return {
      'playlists': playlistResult.first['count'] as int? ?? 0,
      'items': itemResult.first['count'] as int? ?? 0,
    };
  }
}
