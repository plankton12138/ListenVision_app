import 'dart:convert';

import '../../core/utils/app_logger.dart';
import '../../models/play_history.dart';
import '../../models/sync_queue.dart';
import '../api/backend_api_client.dart';
import '../database/app_database.dart';
import '../database/sync_queue_dao.dart';

/// 播放历史仓库
///
/// 负责播放历史相关的数据操作
/// 支持本地优先模式：网络操作失败时加入同步队列
class PlayHistoryRepository {
  final BackendApiClient _apiClient;
  final SyncQueueDao _syncDao;

  /// 本地优先模式：true = 仅网络操作失败时加入队列，false = 直接抛出错误
  final bool localOnlyMode;

  PlayHistoryRepository({
    BackendApiClient? apiClient,
    SyncQueueDao? syncDao,
    this.localOnlyMode = false,
  })  : _apiClient = apiClient ?? BackendApiClient(),
        _syncDao = syncDao ?? SyncQueueDao(AppDatabase.instance);

  // ==================== 播放历史操作 ====================

  /// 获取播放历史列表
  Future<List<PlayHistory>> getPlayHistory({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final data = await _apiClient.getPlayHistory(
        page: page,
        pageSize: pageSize,
      );
      final historyJson = data['history'] as List?;
      AppLogger.debug('PlayHistoryRepository', '从服务器获取播放历史: ${historyJson?.length}条');
      final history = historyJson
              ?.map((json) {
                // 打印原始数据以便调试
                final rawJson = json as Map<String, dynamic>;
                AppLogger.debug('PlayHistoryRepository', '原始数据: bvid=${rawJson['bvid']}, title=${rawJson['title']}, artist=${rawJson['artist']}, cover_url=${rawJson['cover_url']}');
                final item = PlayHistory.fromDto(rawJson);
                AppLogger.debug('PlayHistoryRepository', '解析播放历史: ${item.audio.id} - ${item.audio.title} - ${item.audio.artist}');
                return item;
              })
              .toList() ??
          [];
      AppLogger.info('PlayHistoryRepository', '获取播放历史成功: ${history.length}条');
      return history;
    } catch (e) {
      AppLogger.error('PlayHistoryRepository', '获取播放历史失败: $e');
      return [];
    }
  }

  /// 添加播放历史（带同步重试）
  Future<bool> addPlayHistory({
    required String bvid,
    String? title,
    String? artist,
    int? duration,
    String? coverUrl,
    int? progress,
  }) async {
    try {
      await _apiClient.addPlayHistory(
        bvid: bvid,
        title: title,
        artist: artist,
        duration: duration,
        coverUrl: coverUrl,
        progress: progress,
      );
      AppLogger.debug('PlayHistoryRepository', '添加播放历史: $bvid - $title');
      return true;
    } catch (e) {
      AppLogger.error('PlayHistoryRepository', '添加播放历史失败: $e');

      // 本地优先模式：加入同步队列
      if (localOnlyMode) {
        try {
          final syncData = <String, dynamic>{
            if (title != null) 'title': title,
            if (artist != null) 'artist': artist,
            if (duration != null) 'duration': duration,
            if (coverUrl != null) 'coverUrl': coverUrl,
            if (progress != null) 'progress': progress,
          };
          final syncTask = SyncTask(
            type: SyncType.playHistory,
            bvid: bvid,
            data: syncData.isNotEmpty ? jsonEncode(syncData) : null,
            status: SyncStatus.pending,
            createdAt: DateTime.now(),
          );
          await _syncDao.insert(syncTask);
          AppLogger.info('PlayHistoryRepository', '添加播放历史已加入同步队列: $bvid');
          return true;
        } catch (syncError) {
          AppLogger.error('PlayHistoryRepository', '加入同步队列失败: $syncError');
        }
      }
      return false;
    }
  }

  /// 更新播放历史
  Future<bool> updatePlayHistory({
    required String id,
    int? progress,
  }) async {
    try {
      await _apiClient.updatePlayHistory(
        id: id,
        progress: progress,
      );
      AppLogger.debug('PlayHistoryRepository', '更新播放历史: $id');
      return true;
    } catch (e) {
      AppLogger.error('PlayHistoryRepository', '更新播放历史失败: $e');
      return false;
    }
  }

  /// 删除播放历史
  Future<bool> deletePlayHistory(String id) async {
    try {
      await _apiClient.deletePlayHistory(id);
      AppLogger.info('PlayHistoryRepository', '删除播放历史: $id');
      return true;
    } catch (e) {
      AppLogger.error('PlayHistoryRepository', '删除播放历史失败: $e');
      return false;
    }
  }

  /// 清空所有播放历史
  Future<bool> clearAllHistory() async {
    try {
      // 需要后端支持清空所有历史
      // 暂时通过获取所有ID然后逐个删除
      final histories = await getPlayHistory(pageSize: 1000);
      for (final history in histories) {
        if (history.id.isNotEmpty) {
          await deletePlayHistory(history.id);
        }
      }
      AppLogger.info('PlayHistoryRepository', '清空所有播放历史');
      return true;
    } catch (e) {
      AppLogger.error('PlayHistoryRepository', '清空播放历史失败: $e');
      return false;
    }
  }
}
