import '../../core/utils/app_logger.dart';
import '../../models/play_history.dart';
import '../api/backend_api_client.dart';

/// 播放历史仓库
///
/// 负责播放历史相关的数据操作
class PlayHistoryRepository {
  final BackendApiClient _apiClient;

  PlayHistoryRepository({BackendApiClient? apiClient})
      : _apiClient = apiClient ?? BackendApiClient();

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
      return historyJson
              ?.map((json) => PlayHistory.fromDto(json as Map<String, dynamic>))
              .toList() ??
          [];
    } catch (e) {
      AppLogger.error('PlayHistoryRepository', '获取播放历史失败: $e');
      return [];
    }
  }

  /// 添加播放历史
  Future<bool> addPlayHistory({
    required String bvid,
    int? progress,
  }) async {
    try {
      await _apiClient.addPlayHistory(
        bvid: bvid,
        progress: progress,
      );
      AppLogger.debug('PlayHistoryRepository', '添加播放历史: $bvid');
      return true;
    } catch (e) {
      AppLogger.error('PlayHistoryRepository', '添加播放历史失败: $e');
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
