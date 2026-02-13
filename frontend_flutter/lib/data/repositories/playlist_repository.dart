import 'dart:convert';

import '../../core/utils/app_logger.dart';
import '../../models/playlist.dart';
import '../../models/sync_queue.dart';
import '../../core/network/api_client.dart';
import '../database/app_database.dart';
import '../database/playlist_dao.dart';
import '../database/sync_queue_dao.dart';

/// 歌单仓库
///
/// 负责歌单相关的数据操作
/// 支持本地优先模式：网络操作失败时加入同步队列
class PlaylistRepository {
  final ApiClient _apiClient;
  final SyncQueueDao _syncDao;
  final PlaylistDao _playlistDao;

  /// 本地优先模式：true = 仅网络操作失败时加入队列，false = 直接抛出错误
  final bool localOnlyMode;

  PlaylistRepository({
    ApiClient? apiClient,
    SyncQueueDao? syncDao,
    PlaylistDao? playlistDao,
    this.localOnlyMode = false,
  })  : _apiClient = apiClient ?? ApiClient(),
        _syncDao = syncDao ?? SyncQueueDao(AppDatabase.instance),
        _playlistDao = playlistDao ?? PlaylistDao(AppDatabase.instance);

  // ==================== 歌单操作 ====================

  /// 获取用户歌单列表
  Future<List<Playlist>> getUserPlaylists({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final data = await _apiClient.getUserPlaylists(
        page: page,
        pageSize: pageSize,
      );
      final playlistsJson = data['playlists'] as List?;
      return playlistsJson
              ?.map((json) => Playlist.fromDto(json as Map<String, dynamic>))
              .toList() ??
          [];
    } catch (e) {
      AppLogger.error('PlaylistRepository', '获取歌单列表失败: $e');
      rethrow;
    }
  }

  /// 获取歌单详情
  Future<PlaylistDetail> getPlaylistDetail(String id) async {
    try {
      final data = await _apiClient.getPlaylistDetail(id);
      return PlaylistDetail.fromDto(data);
    } catch (e) {
      AppLogger.error('PlaylistRepository', '获取歌单详情失败: $e');
      rethrow;
    }
  }

  /// 获取歌单项
  Future<List<PlaylistItem>> getPlaylistItems(String id) async {
    try {
      final data = await _apiClient.getPlaylistItems(id);
      final itemsJson = data['items'] as List?;
      return itemsJson
              ?.map((json) => PlaylistItem.fromDto(json as Map<String, dynamic>))
              .toList() ??
          [];
    } catch (e) {
      AppLogger.error('PlaylistRepository', '获取歌单项失败: $e');
      rethrow;
    }
  }

  /// 创建歌单（带同步重试）
  Future<Playlist?> createPlaylist({
    required String name,
    String? description,
    String? coverUrl,
  }) async {
    try {
      final data = await _apiClient.createPlaylist(
        name: name,
        description: description,
        coverUrl: coverUrl,
      );
      AppLogger.info('PlaylistRepository', '创建歌单成功: $name');
      return Playlist.fromDto(data);
    } catch (e) {
      AppLogger.error('PlaylistRepository', '创建歌单失败: $e');

      // 本地优先模式：加入同步队列
      if (localOnlyMode) {
        try {
          // 创建临时 ID 用于标识
          final tempId = 'local_${DateTime.now().millisecondsSinceEpoch}';
          final syncTask = SyncTask(
            type: SyncType.createPlaylist,
            playlistId: tempId,
            data: jsonEncode({
              'name': name,
              'description': description,
              'coverUrl': coverUrl,
            }),
            status: SyncStatus.pending,
            createdAt: DateTime.now(),
          );
          await _syncDao.insert(syncTask);
          AppLogger.info('PlaylistRepository', '创建歌单已加入同步队列: $name');
        } catch (syncError) {
          AppLogger.error('PlaylistRepository', '加入同步队列失败: $syncError');
        }
      }
      rethrow;
    }
  }

  /// 更新歌单（带同步重试）
  Future<Playlist?> updatePlaylist({
    required String id,
    String? name,
    String? description,
    String? coverUrl,
  }) async {
    try {
      final data = await _apiClient.updatePlaylist(
        id: id,
        name: name,
        description: description,
        coverUrl: coverUrl,
      );
      AppLogger.info('PlaylistRepository', '更新歌单成功: $id');
      return Playlist.fromDto(data);
    } catch (e) {
      AppLogger.error('PlaylistRepository', '更新歌单失败: $e');

      // 本地优先模式：加入同步队列
      if (localOnlyMode) {
        try {
          final syncTask = SyncTask(
            type: SyncType.updatePlaylist,
            playlistId: id,
            data: jsonEncode({
              'name': name,
              'description': description,
              'coverUrl': coverUrl,
            }),
            status: SyncStatus.pending,
            createdAt: DateTime.now(),
          );
          await _syncDao.insert(syncTask);
          AppLogger.info('PlaylistRepository', '更新歌单已加入同步队列: $id');
        } catch (syncError) {
          AppLogger.error('PlaylistRepository', '加入同步队列失败: $syncError');
        }
      }
      rethrow;
    }
  }

  /// 删除歌单（带同步重试）
  Future<bool> deletePlaylist(String id) async {
    try {
      await _apiClient.deletePlaylist(id);
      AppLogger.info('PlaylistRepository', '删除歌单成功: $id');
      return true;
    } catch (e) {
      AppLogger.error('PlaylistRepository', '删除歌单失败: $e');

      // 本地优先模式：加入同步队列
      if (localOnlyMode) {
        try {
          final syncTask = SyncTask(
            type: SyncType.deletePlaylist,
            playlistId: id,
            status: SyncStatus.pending,
            createdAt: DateTime.now(),
          );
          await _syncDao.insert(syncTask);
          AppLogger.info('PlaylistRepository', '删除歌单已加入同步队列: $id');
          return true;
        } catch (syncError) {
          AppLogger.error('PlaylistRepository', '加入同步队列失败: $syncError');
        }
      }
      rethrow;
    }
  }

  /// 添加歌单项（带同步重试）
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
      await _apiClient.addPlaylistItem(
        playlistId: playlistId,
        bvid: bvid,
        title: title,
        artist: artist,
        duration: duration,
        coverUrl: coverUrl,
        position: position,
      );
      AppLogger.info('PlaylistRepository', '添加歌单项成功: $bvid -> $playlistId');
      return true;
    } catch (e) {
      AppLogger.error('PlaylistRepository', '添加歌单项失败: $e');

      // 本地优先模式：加入同步队列
      if (localOnlyMode) {
        try {
          final syncTask = SyncTaskFactory.createPlaylistItemTask(
            type: SyncType.addPlaylistItem,
            playlistId: playlistId,
            bvid: bvid,
            position: position,
          );
          await _syncDao.insert(syncTask);
          AppLogger.info('PlaylistRepository', '添加歌单项已加入同步队列: $bvid');
          return true;
        } catch (syncError) {
          AppLogger.error('PlaylistRepository', '加入同步队列失败: $syncError');
        }
      }
      rethrow;
    }
  }

  /// 删除歌单项（带同步重试）
  Future<bool> removePlaylistItem({
    required String playlistId,
    required String bvid,
  }) async {
    try {
      await _apiClient.removePlaylistItem(
        playlistId: playlistId,
        bvid: bvid,
      );
      AppLogger.info('PlaylistRepository', '删除歌单项成功: $bvid from $playlistId');
      return true;
    } catch (e) {
      AppLogger.error('PlaylistRepository', '删除歌单项失败: $e');

      // 本地优先模式：加入同步队列
      if (localOnlyMode) {
        try {
          final syncTask = SyncTaskFactory.createPlaylistItemTask(
            type: SyncType.removePlaylistItem,
            playlistId: playlistId,
            bvid: bvid,
          );
          await _syncDao.insert(syncTask);
          AppLogger.info('PlaylistRepository', '删除歌单项已加入同步队列: $bvid');
          return true;
        } catch (syncError) {
          AppLogger.error('PlaylistRepository', '加入同步队列失败: $syncError');
        }
      }
      rethrow;
    }
  }

  // ==================== 收藏操作 ====================

  /// 获取收藏列表
  Future<List<PlaylistItem>> getFavorites({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final data = await _apiClient.getFavorites(
        page: page,
        pageSize: pageSize,
      );
      final itemsJson = data['items'] as List?;
      return itemsJson
              ?.map((json) => PlaylistItem.fromDto(json as Map<String, dynamic>))
              .toList() ??
          [];
    } catch (e) {
      AppLogger.error('PlaylistRepository', '获取收藏列表失败: $e');
      return [];
    }
  }

  /// 切换收藏状态（移除预检查）
  ///
  /// 返回 true 表示添加收藏，false 表示取消收藏
  /// 本地优先模式：网络失败时加入同步队列
  Future<bool> toggleFavorite(String bvid) async {
    try {
      // 直接调用后端，后端返回操作结果
      final result = await _apiClient.toggleFavorite(bvid);
      final added = result['added'] as bool? ?? false;

      AppLogger.info('PlaylistRepository', '切换收藏状态: $bvid, added=$added');
      return added;
    } catch (e) {
      AppLogger.error('PlaylistRepository', '切换收藏失败: $e');

      // 本地优先模式：加入同步队列（默认假设为收藏操作）
      if (localOnlyMode) {
        try {
          final syncTask = SyncTask(
            type: SyncType.favorite,
            bvid: bvid,
            status: SyncStatus.pending,
            createdAt: DateTime.now(),
          );
          await _syncDao.insert(syncTask);
          AppLogger.info('PlaylistRepository', '切换收藏已加入同步队列: $bvid');
          return true; // 乐观更新
        } catch (syncError) {
          AppLogger.error('PlaylistRepository', '加入同步队列失败: $syncError');
        }
      }
      rethrow;
    }
  }

  /// 检查是否已收藏
  Future<bool> isFavorite(String bvid) async {
    try {
      return await _apiClient.checkFavorite(bvid);
    } catch (e) {
      AppLogger.error('PlaylistRepository', '检查收藏状态失败: $e');
      return false;
    }
  }

  // ==================== 本地歌单读取 ====================

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

  /// 同步歌单列表到本地
  Future<void> syncPlaylistsToLocal(List<Playlist> playlists) async {
    try {
      for (final playlist in playlists) {
        await _playlistDao.upsertPlaylistFromServer(playlist.toDto());
      }
      AppLogger.info('PlaylistRepository', '同步 ${playlists.length} 个歌单到本地');
    } catch (e) {
      AppLogger.error('PlaylistRepository', '同步歌单到本地失败: $e');
      rethrow;
    }
  }

  // ==================== 播放队列同步 ====================

  /// 保存播放队列到后端
  Future<void> saveNowPlaying(List<PlaylistItem> items) async {
    try {
      final itemsData = items.map((item) => {
        'bvid': item.bvid,
        'title': item.title,
        'artist': item.artist,
        'duration': item.duration,
        'coverUrl': item.coverUrl,
      }).toList();

      await _apiClient.saveNowPlaying(itemsData);
      AppLogger.info('PlaylistRepository', '保存播放队列成功: ${items.length}个');
    } catch (e) {
      AppLogger.error('PlaylistRepository', '保存播放队列失败: $e');

      // 本地优先模式：静默处理失败
      if (localOnlyMode) {
        AppLogger.warn('PlaylistRepository', '播放队列同步失败，本地优先模式已忽略');
      } else {
        rethrow;
      }
    }
  }

  // ==================== 同步队列管理 ====================

  /// 获取同步统计
  Future<SyncQueueStats> getSyncStats() async {
    return await _syncDao.getStats();
  }

  /// 检查是否有待处理任务
  Future<bool> hasPendingSyncTasks() async {
    return await _syncDao.hasPendingTasks();
  }
}
