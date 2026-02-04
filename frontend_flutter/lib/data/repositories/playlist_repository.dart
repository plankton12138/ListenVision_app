import '../../core/utils/app_logger.dart';
import '../../models/playlist.dart';
import '../api/backend_api_client.dart';

/// 歌单仓库
///
/// 负责歌单相关的数据操作
class PlaylistRepository {
  final BackendApiClient _apiClient;

  PlaylistRepository({BackendApiClient? apiClient})
      : _apiClient = apiClient ?? BackendApiClient();

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

  /// 创建歌单
  Future<Playlist> createPlaylist({
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
      return Playlist.fromDto(data);
    } catch (e) {
      AppLogger.error('PlaylistRepository', '创建歌单失败: $e');
      rethrow;
    }
  }

  /// 更新歌单
  Future<Playlist> updatePlaylist({
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
      return Playlist.fromDto(data);
    } catch (e) {
      AppLogger.error('PlaylistRepository', '更新歌单失败: $e');
      rethrow;
    }
  }

  /// 删除歌单
  Future<bool> deletePlaylist(String id) async {
    try {
      await _apiClient.deletePlaylist(id);
      AppLogger.info('PlaylistRepository', '删除歌单成功: $id');
      return true;
    } catch (e) {
      AppLogger.error('PlaylistRepository', '删除歌单失败: $e');
      rethrow;
    }
  }

  /// 添加歌单项
  Future<bool> addPlaylistItem({
    required String playlistId,
    required String bvid,
    int? position,
  }) async {
    try {
      await _apiClient.addPlaylistItem(
        playlistId: playlistId,
        bvid: bvid,
        position: position,
      );
      AppLogger.info('PlaylistRepository', '添加歌单项成功: $bvid -> $playlistId');
      return true;
    } catch (e) {
      AppLogger.error('PlaylistRepository', '添加歌单项失败: $e');
      rethrow;
    }
  }

  /// 删除歌单项
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

  /// 切换收藏状态
  Future<bool> toggleFavorite(String bvid) async {
    try {
      await _apiClient.toggleFavorite(bvid);
      AppLogger.info('PlaylistRepository', '切换收藏状态: $bvid');
      return true;
    } catch (e) {
      AppLogger.error('PlaylistRepository', '切换收藏失败: $e');
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
}
