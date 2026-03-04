import 'dart:async';
import 'dart:io';

import '../../core/utils/app_logger.dart';
import '../../data/database/track_dao.dart';

/// 下载完整性服务
/// 负责验证已下载文件的完整性，检测外部删除的文件
/// 采用三层检测机制：启动扫描 + 定期轮询 + 播放前验证
class DownloadIntegrityService {
  final TrackDao _trackDao;
  Timer? _periodicTimer;
  bool _isRunning = false;

  DownloadIntegrityService(this._trackDao);

  /// 启动服务
  Future<void> start() async {
    if (_isRunning) return;

    AppLogger.info('DownloadIntegrityService', '启动下载完整性服务');
    _isRunning = true;

    // 启动时立即执行一次全量扫描
    await performFullScan();

    // 启动定期轮询（每30分钟）
    _periodicTimer = Timer.periodic(
      const Duration(minutes: 30),
      (_) => performIncrementalCheck(),
    );

    AppLogger.info('DownloadIntegrityService', '下载完整性服务已启动');
  }

  /// 停止服务
  void stop() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
    _isRunning = false;
    AppLogger.info('DownloadIntegrityService', '下载完整性服务已停止');
  }

  /// 执行全量扫描
  /// 扫描所有标记为已下载的记录，验证文件是否存在
  Future<void> performFullScan() async {
    try {
      AppLogger.info('DownloadIntegrityService', '开始全量扫描下载文件完整性');

      // 获取所有已下载的轨道
      final downloadedTracks = await _trackDao.getDownloadedTracks();
      AppLogger.debug('DownloadIntegrityService',
          '找到 ${downloadedTracks.length} 个已下载轨道');

      final List<String> missingFiles = [];

      for (final track in downloadedTracks) {
        if (track.localPath == null) continue;

        // 验证文件是否存在且有效
        final file = File(track.localPath!);
        final exists = await file.exists();
        final isValid = exists && await file.length() > 0;

        if (!isValid) {
          AppLogger.warn(
              'DownloadIntegrityService', '文件不存在或无效: ${track.localPath}');
          missingFiles.add(track.sourceId);
        }
      }

      // 批量更新状态
      if (missingFiles.isNotEmpty) {
        await _trackDao.batchUpdateDownloadStatus(missingFiles, false);
        AppLogger.info('DownloadIntegrityService',
            '已标记 ${missingFiles.length} 个文件为未下载');
      }

      AppLogger.info('DownloadIntegrityService', '全量扫描完成');
    } catch (e, stack) {
      AppLogger.error('DownloadIntegrityService', '全量扫描失败: $e',
          stackTrace: stack);
    }
  }

  /// 执行增量检查
  /// 仅检查最近可能被修改的文件（优化性能）
  Future<void> performIncrementalCheck() async {
    try {
      AppLogger.debug('DownloadIntegrityService', '开始增量检查');

      // 获取最近24小时内下载的文件
      final recentTracks = await _trackDao.getRecentlyDownloadedTracks(
        since: DateTime.now().subtract(const Duration(hours: 24)),
      );

      final List<String> missingFiles = [];

      for (final track in recentTracks) {
        if (track.localPath == null) continue;

        final file = File(track.localPath!);
        final exists = await file.exists();

        if (!exists) {
          missingFiles.add(track.sourceId);
        }
      }

      if (missingFiles.isNotEmpty) {
        await _trackDao.batchUpdateDownloadStatus(missingFiles, false);
        AppLogger.info('DownloadIntegrityService',
            '增量检查发现 ${missingFiles.length} 个缺失文件');
      }
    } catch (e) {
      AppLogger.error('DownloadIntegrityService', '增量检查失败: $e');
    }
  }

  /// 验证单个文件
  /// 用于播放前验证
  /// 返回文件是否有效，如果无效会自动更新数据库状态
  Future<bool> validateFile(String sourceId) async {
    try {
      final track = await _trackDao.getBySourceId(sourceId);
      if (track == null || track.localPath == null) return false;

      final file = File(track.localPath!);
      final exists = await file.exists();
      final isValid = exists && await file.length() > 0;

      if (!isValid && track.isDownloaded) {
        // 标记为未下载
        await _trackDao.markAsNotDownloaded(sourceId);
        AppLogger.warn('DownloadIntegrityService',
            '播放时发现文件缺失，已更新状态: $sourceId');
      }

      return isValid;
    } catch (e) {
      AppLogger.error(
          'DownloadIntegrityService', '验证文件失败: sourceId=$sourceId, error=$e');
      return false;
    }
  }

  /// 获取本地文件路径（如果文件存在）
  Future<String?> getValidLocalPath(String sourceId) async {
    try {
      final track = await _trackDao.getBySourceId(sourceId);
      if (track?.localPath == null) return null;

      final file = File(track!.localPath!);
      final exists = await file.exists();
      final isValid = exists && await file.length() > 0;

      if (!isValid && track.isDownloaded) {
        await _trackDao.markAsNotDownloaded(sourceId);
        return null;
      }

      return isValid ? track.localPath : null;
    } catch (e) {
      AppLogger.error('DownloadIntegrityService',
          '获取本地路径失败: sourceId=$sourceId, error=$e');
      return null;
    }
  }

  /// 手动触发全量扫描
  Future<void> triggerManualScan() async {
    await performFullScan();
  }

  /// 服务是否正在运行
  bool get isRunning => _isRunning;
}
