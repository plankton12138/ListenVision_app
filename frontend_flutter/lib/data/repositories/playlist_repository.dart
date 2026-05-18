import '../../core/utils/app_logger.dart';
import '../../models/playlist.dart';
import '../database/app_database.dart';
import '../database/playlist_dao.dart';

/// 歌单仓库
///
/// 负责歌单相关的本地数据操作
class PlaylistRepository {
  final PlaylistDao _playlistDao;

  PlaylistRepository({
    PlaylistDao? playlistDao,
  }) : _playlistDao = playlistDao ?? PlaylistDao(AppDatabase.instance);

  // ==================== 歌单详情 ====================

  /// 获取歌单详情（本地）
  Future<PlaylistDetail> getPlaylistDetail(String id) async {
    try {
      final idInt = int.tryParse(id) ?? 0;
      final playlistMap = await _playlistDao.getPlaylistById(idInt);
      if (playlistMap == null) {
        throw Exception('歌单不存在: $id');
      }
      final playlist = Playlist.fromDto(playlistMap);
      final itemsMap = await _playlistDao.getPlaylistItems(idInt);
      final items = itemsMap.map((m) {
        return PlaylistItem(
          id: m['id']?.toString(),
          playlistId: id,
          bvid: m['source_id'] as String? ?? m['bvid'] as String? ?? '',
          title: m['title'] as String?,
          artist: m['artist'] as String?,
          duration: m['duration'] as int?,
          coverUrl: m['cover_url'] as String?,
          localPath: m['local_path'] as String?,
          position: m['position'] as int? ?? 0,
          addedAt: m['added_at'] != null
              ? DateTime.tryParse(m['added_at'] as String)
              : null,
        );
      }).toList();
      return PlaylistDetail(playlist: playlist, items: items);
    } catch (e) {
      AppLogger.error('PlaylistRepository', '获取歌单详情失败: $e');
      rethrow;
    }
  }

  /// 从歌单中移除歌曲（本地）
  Future<bool> removePlaylistItem({
    required String playlistId,
    required String bvid,
  }) async {
    try {
      final idInt = int.tryParse(playlistId) ?? 0;
      final db = await AppDatabase.instance.database;
      final trackMaps = await db.query(
        'tracks',
        where: 'source_id = ?',
        whereArgs: [bvid],
        limit: 1,
      );
      if (trackMaps.isEmpty) {
        AppLogger.warn('PlaylistRepository', '未找到歌曲: $bvid');
        return false;
      }
      final trackId = trackMaps.first['id'] as int;
      await _playlistDao.removeItemFromPlaylist(idInt, trackId);
      AppLogger.info('PlaylistRepository', '移除歌单项成功: $bvid from $playlistId');
      return true;
    } catch (e) {
      AppLogger.error('PlaylistRepository', '移除歌单项失败: $e');
      return false;
    }
  }

  /// 更新歌单（本地）
  Future<Playlist?> updatePlaylist({
    required String id,
    String? name,
    String? description,
    String? coverUrl,
  }) async {
    try {
      final idInt = int.tryParse(id) ?? 0;
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (description != null) data['description'] = description;
      if (coverUrl != null) data['cover_url'] = coverUrl;
      await _playlistDao.updatePlaylist(idInt, data);
      final updated = await _playlistDao.getPlaylistById(idInt);
      AppLogger.info('PlaylistRepository', '更新歌单成功: $id');
      return updated != null ? Playlist.fromDto(updated) : null;
    } catch (e) {
      AppLogger.error('PlaylistRepository', '更新歌单失败: $e');
      rethrow;
    }
  }

  /// 删除歌单（本地）
  Future<bool> deletePlaylist(String id) async {
    try {
      final idInt = int.tryParse(id) ?? 0;
      await _playlistDao.deletePlaylist(idInt);
      AppLogger.info('PlaylistRepository', '删除歌单成功: $id');
      return true;
    } catch (e) {
      AppLogger.error('PlaylistRepository', '删除歌单失败: $e');
      rethrow;
    }
  }

  // ==================== 本地歌单读取 ====================

  /// 获取用户歌单列表（等同于本地用户歌单）
  Future<List<Playlist>> getUserPlaylists() async {
    return getLocalUserPlaylists();
  }

  /// 获取歌单项（本地）
  Future<List<PlaylistItem>> getPlaylistItems(String id) async {
    try {
      final idInt = int.tryParse(id) ?? 0;
      final itemsMap = await _playlistDao.getPlaylistItems(idInt);
      return itemsMap.map((m) {
        return PlaylistItem(
          id: m['id']?.toString(),
          playlistId: id,
          bvid: m['source_id'] as String? ?? m['bvid'] as String? ?? '',
          title: m['title'] as String?,
          artist: m['artist'] as String?,
          duration: m['duration'] as int?,
          coverUrl: m['cover_url'] as String?,
          localPath: m['local_path'] as String?,
          position: m['position'] as int? ?? 0,
          addedAt: m['added_at'] != null
              ? DateTime.tryParse(m['added_at'] as String)
              : null,
        );
      }).toList();
    } catch (e) {
      AppLogger.error('PlaylistRepository', '获取歌单项失败: $e');
      return [];
    }
  }

  /// 创建歌单（本地）
  Future<Playlist?> createPlaylist({
    required String name,
    String? description,
    String? coverUrl,
  }) async {
    try {
      final id = await _playlistDao.insertPlaylist({
        'name': name,
        'description': description,
        'cover_url': coverUrl,
        'type': 'user',
      });
      final playlistMap = await _playlistDao.getPlaylistById(id);
      AppLogger.info('PlaylistRepository', '创建歌单成功: $name');
      return playlistMap != null ? Playlist.fromDto(playlistMap) : null;
    } catch (e) {
      AppLogger.error('PlaylistRepository', '创建歌单失败: $e');
      rethrow;
    }
  }

  /// 添加歌单项（本地）
  Future<bool> addPlaylistItem({
    required String playlistId,
    required String bvid,
    String? title,
    String? artist,
    int? duration,
    String? coverUrl,
    int? position,
  }) async {
    try {
      final pidInt = int.tryParse(playlistId) ?? 0;
      final db = await AppDatabase.instance.database;

      // 查找或创建 track
      final trackMaps = await db.query(
        'tracks',
        where: 'source_id = ?',
        whereArgs: [bvid],
        limit: 1,
      );

      int trackId;
      if (trackMaps.isNotEmpty) {
        trackId = trackMaps.first['id'] as int;
      } else {
        trackId = await db.insert('tracks', {
          'source_id': bvid,
          'source_type': 'bilibili',
          'title': title ?? bvid,
          'artist': artist,
          'cover_url': coverUrl,
          'duration': duration ?? 0,
          'bvid': bvid,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      final pos = position ?? 0;
      await _playlistDao.addItemToPlaylist(pidInt, trackId, pos);
      AppLogger.info('PlaylistRepository', '添加歌单项成功: $bvid -> $playlistId');
      return true;
    } catch (e) {
      AppLogger.error('PlaylistRepository', '添加歌单项失败: $e');
      rethrow;
    }
  }

  /// 获取收藏列表（本地，从 tracks 表中获取 is_favorite=1 的记录）
  Future<List<PlaylistItem>> getFavorites({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final db = await AppDatabase.instance.database;
      final offset = (page - 1) * pageSize;
      final tracks = await db.query(
        'tracks',
        where: 'is_favorite = ?',
        whereArgs: [1],
        orderBy: 'updated_at DESC',
        limit: pageSize,
        offset: offset,
      );
      return tracks.map((m) {
        return PlaylistItem(
          bvid: m['source_id'] as String? ?? m['bvid'] as String? ?? '',
          title: m['title'] as String?,
          artist: m['artist'] as String?,
          duration: m['duration'] as int?,
          coverUrl: m['cover_url'] as String?,
          localPath: m['local_path'] as String?,
          position: 0,
        );
      }).toList();
    } catch (e) {
      AppLogger.error('PlaylistRepository', '获取收藏列表失败: $e');
      return [];
    }
  }

  /// 保存播放队列（本地，暂不实现服务端同步）
  Future<void> saveNowPlaying(List<PlaylistItem> items) async {
    // 本地模式下暂不实现
    AppLogger.debug('PlaylistRepository', 'saveNowPlaying: 本地模式下暂不实现');
  }

  /// 获取本地歌单列表（离线支持）
  Future<List<Playlist>> getLocalPlaylists() async {
    try {
      final maps = await _playlistDao.getAllPlaylists();
      return maps.map((m) => Playlist.fromDto(m)).toList();
    } catch (e) {
      AppLogger.error('PlaylistRepository', '获取本地歌单失败: $e');
      return [];
    }
  }

  /// 获取本地用户歌单
  Future<List<Playlist>> getLocalUserPlaylists() async {
    try {
      final maps = await _playlistDao.getUserPlaylists();
      return maps.map((m) => Playlist.fromDto(m)).toList();
    } catch (e) {
      AppLogger.error('PlaylistRepository', '获取本地用户歌单失败: $e');
      return [];
    }
  }

  /// 获取本地系统歌单
  Future<List<Playlist>> getLocalSystemPlaylists() async {
    try {
      final maps = await _playlistDao.getSystemPlaylists();
      return maps.map((m) => Playlist.fromDto(m)).toList();
    } catch (e) {
      AppLogger.error('PlaylistRepository', '获取本地系统歌单失败: $e');
      return [];
    }
  }
}