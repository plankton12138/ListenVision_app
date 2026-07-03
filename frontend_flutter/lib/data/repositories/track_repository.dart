import 'dart:async';
import 'dart:io';

import '../../core/utils/app_logger.dart';
import '../../models/audio.dart';
import '../../models/cached_track.dart';
import '../../models/local_audio.dart';
import '../../services/bilibili_api_service.dart';
import '../database/app_database.dart';
import '../database/download_task_dao.dart';
import '../database/track_dao.dart';

/// 音轨仓库 - 单一数据源
///
/// 实现"本地优先，网络回源"的核心原则：
/// 1. 所有读取操作优先查询本地数据库
/// 2. 本地没有数据时，从网络获取并缓存到本地
class TrackRepository {
  final TrackDao _trackDao;
  final DownloadTaskDao _downloadTaskDao;
  final BilibiliApiService _bilibiliApi;

  // 用于通知下载进度的事件流
  final _downloadProgressController =
      StreamController<DownloadProgressEvent>.broadcast();

  TrackRepository({
    TrackDao? trackDao,
    DownloadTaskDao? downloadTaskDao,
    BilibiliApiService? bilibiliApi,
  })  : _trackDao = trackDao ?? TrackDao(AppDatabase.instance),
        _downloadTaskDao = downloadTaskDao ??
            DownloadTaskDao(AppDatabase.instance),
        _bilibiliApi = bilibiliApi ?? BilibiliApiService();

  /// 下载进度事件流
  Stream<DownloadProgressEvent> get downloadProgressStream =>
      _downloadProgressController.stream;

  // ==================== 核心查询方法 ====================

  /// 根据 BVID 获取 Track（优先本地，网络回源）
  ///
  /// 这是核心方法，体现了"本地优先"原则：
  /// 1. 先查本地数据库
  /// 2. 本地没有，从网络获取
  /// 3. 网络获取后缓存到本地
  Future<CachedTrack> getTrackByBvid(String bvid) async {
    // 1. 先查本地
    final local = await _trackDao.getBySourceId(bvid);
    if (local != null) {
      AppLogger.info('TrackRepository', '从本地获取 Track: $bvid');
      return local;
    }

    // 2. 本地没有，从网络获取
    AppLogger.info('TrackRepository', '从网络获取 Track: $bvid');
    final videoInfo = await _bilibiliApi.getVideoInfo(bvid);
    final audio = Audio.fromDto(videoInfo);

    // 3. 存入本地并返回
    return await _trackDao.saveFromAudio(audio);
  }

  /// 根据 source_id 获取 Track
  Future<CachedTrack?> getTrackBySourceId(String sourceId) async {
    return await _trackDao.getBySourceId(sourceId);
  }

  /// 批量获取 Tracks
  Future<List<CachedTrack>> getTracksByBvids(List<String> bvids) async {
    final tracks = <CachedTrack>[];
    for (final bvid in bvids) {
      try {
        final track = await getTrackByBvid(bvid);
        tracks.add(track);
      } catch (e) {
        AppLogger.error('TrackRepository', '获取 Track 失败: $bvid - $e');
      }
    }
    return tracks;
  }

  // ==================== 搜索 ====================

  /// 搜索（优先本地缓存，补充网络结果）
  ///
  /// [keyword] 搜索关键词
  /// [forceRemote] 是否强制从网络获取（默认 false）
  Future<List<CachedTrack>> search(String keyword,
      {bool forceRemote = false}) async {
    // 如果强制网络，跳过本地
    if (!forceRemote) {
      // 先返回本地历史记录
      final localResults = await _trackDao.search(keyword);
      if (localResults.isNotEmpty) {
        AppLogger.info('TrackRepository', '从本地搜索到 ${localResults.length} 条结果');
        return localResults;
      }
    }

    // 本地没有，搜索网络
    AppLogger.info('TrackRepository', '从网络搜索: $keyword');
    final results = await _bilibiliApi.search(keyword: keyword);

    // 转换为 Audio 并缓存到本地
    final tracks = <CachedTrack>[];
    for (final audio in results) {
      try {
        final track = await _trackDao.saveFromAudio(audio);
        tracks.add(track);
      } catch (e) {
        AppLogger.error('TrackRepository', '转换搜索结果失败: $e');
      }
    }

    return tracks;
  }

  // ==================== 下载 ====================

  /// 下载音频（核心流程）
  ///
  /// 1. 获取或创建 Track
  /// 2. 检查是否已下载
  /// 3. 创建下载任务
  /// 4. 实际下载由 DownloadRepository 处理
  Future<String> downloadAudio(String bvid) async {
    // 1. 获取或创建 Track
    final track = await getTrackByBvid(bvid);

    // 2. 检查是否已下载
    if (track.isDownloaded && track.localPath != null) {
      final file = File(track.localPath!);
      if (await file.exists()) {
        AppLogger.info('TrackRepository', '音频已下载: ${track.localPath}');
        return track.localPath!;
      }
    }

    // 3. 检查是否已有下载任务
    final existingTask = await _downloadTaskDao.getByBvid(bvid);
    if (existingTask != null && existingTask.isActive) {
      AppLogger.info('TrackRepository', '下载任务已存在: $bvid');
      return existingTask.savePath;
    }

    // 4. 创建下载任务
    final savePath = await _getSavePath(track);
    await _downloadTaskDao.create(
      url: '',
      savePath: savePath,
      trackId: track.id,
      bvid: bvid,
      title: track.title,
      artist: track.artist,
      coverUrl: track.coverUrl,
    );

    return savePath;
  }

  /// 根据任务 ID 执行下载（已废弃，请使用 DownloadRepository.startDownload）
  Future<void> downloadByTaskId(int taskId) async {
    throw UnimplementedError(
      '请使用 DownloadRepository.startDownload($taskId) 来启动下载。'
      'TrackRepository.downloadByTaskId 已废弃。',
    );
  }

  /// 获取下载保存路径
  Future<String> _getSavePath(CachedTrack track) async {
    final sanitizedTitle = track.title
        .replaceAll(RegExp(r'[<>:"/\|?*]'), '_')
        .trim()
        .substring(0, track.title.length > 50 ? 50 : track.title.length);
    return '${track.bvid}_$sanitizedTitle.mp3';
  }

  // ==================== 收藏 ====================

  /// 切换收藏状态（本地优先）
  Future<void> toggleFavorite(
    int trackId,
    bool isFavorite, {
    String? title,
    String? artist,
    int? duration,
    String? coverUrl,
  }) async {
    await _trackDao.toggleFavorite(trackId, isFavorite);
    AppLogger.debug('TrackRepository', '收藏状态已更新: trackId=$trackId, isFavorite=$isFavorite');
  }

  /// 获取收藏列表
  Future<List<CachedTrack>> getFavoriteTracks() async {
    return await _trackDao.getFavoriteTracks();
  }

  // ==================== 本地音乐导入 ====================

  /// 导入本地音频文件
  Future<CachedTrack> importLocalAudio(LocalAudio localAudio) async {
    return await _trackDao.saveFromLocalAudio(localAudio);
  }

  /// 批量导入本地音频
  Future<List<CachedTrack>> importLocalAudios(List<LocalAudio> audios) async {
    final tracks = <CachedTrack>[];
    for (final audio in audios) {
      try {
        final track = await importLocalAudio(audio);
        tracks.add(track);
      } catch (e) {
        AppLogger.error('TrackRepository', '导入本地音频失败: ${audio.filePath} - $e');
      }
    }
    return tracks;
  }

  // ==================== 播放历史 ====================

  /// 记录播放历史（本地优先）
  Future<void> recordPlayHistory(int trackId) async {
    await _trackDao.incrementPlayCount(trackId);
    AppLogger.debug('TrackRepository', '播放历史已记录: trackId=$trackId');
  }

  /// 获取最近播放
  Future<List<CachedTrack>> getRecentlyPlayed({int limit = 20}) async {
    final db = await AppDatabase.instance.database;
    final history = await db.query(
      'play_history',
      orderBy: 'played_at DESC',
      limit: limit,
    );

    final tracks = <CachedTrack>[];
    for (final item in history) {
      final trackId = item['track_id'] as int?;
      if (trackId != null) {
        final track = await _trackDao.getById(trackId);
        if (track != null) {
          tracks.add(track);
        }
      }
    }

    return tracks;
  }

  // ==================== 已下载 ====================

/// 获取已下载列表
Future<List<CachedTrack>> getDownloadedTracks() async {
  return await _trackDao.getDownloadedTracks();
}

/// 获取最近下载的轨道
Future<List<CachedTrack>> getRecentlyDownloadedTracks({
  required DateTime since,
}) async {
  return await _trackDao.getRecentlyDownloadedTracks(since: since);
}

/// 检查是否已下载
Future<bool> isDownloaded(String bvid) async {
  return await _trackDao.isDownloaded(bvid);
}

/// 根据 sourceId 获取本地文件路径（如果文件有效）
Future<String?> getLocalPath(String sourceId) async {
  final track = await _trackDao.getBySourceId(sourceId);
  if (track == null || track.localPath == null) return null;

  final file = File(track.localPath!);
  final exists = await file.exists();
  final isValid = exists && await file.length() > 0;

  if (!isValid && track.isDownloaded) {
    await _trackDao.markAsNotDownloaded(sourceId);
    return null;
  }

  return isValid ? track.localPath : null;
}

/// 验证本地文件是否有效
Future<bool> validateLocalFile(String sourceId) async {
  final track = await _trackDao.getBySourceId(sourceId);
  if (track?.localPath == null) return false;

  final file = File(track!.localPath!);
  final exists = await file.exists();
  final isValid = exists && await file.length() > 0;

  if (!isValid && track.isDownloaded) {
    await _trackDao.markAsNotDownloaded(sourceId);
  }

  return isValid;
}

/// 标记为未下载
Future<void> markAsNotDownloaded(String sourceId) async {
  await _trackDao.markAsNotDownloaded(sourceId);
}

/// 批量标记为未下载
Future<void> batchMarkAsNotDownloaded(List<String> sourceIds) async {
  await _trackDao.batchUpdateDownloadStatus(sourceIds, false);
}

// ==================== 资源释放 ====================

  /// 释放资源
  void dispose() {
    _downloadProgressController.close();
  }
}

/// 下载进度事件
///
/// 包含下载过程中的实时状态信息，用于 UI 显示进度、速度和状态
class DownloadProgressEvent {
  final int taskId;
  final int? trackId;
  final String bvid;
  final int progress;
  final String stage;
  final String message;
  final int? downloadedBytes;
  final int? totalBytes;
  final double? speed;
  final String? speedDisplay;
  final String? timeRemaining;

  DownloadProgressEvent({
    required this.taskId,
    this.trackId,
    required this.bvid,
    required this.progress,
    required this.stage,
    required this.message,
    this.downloadedBytes,
    this.totalBytes,
    this.speed,
    this.speedDisplay,
    this.timeRemaining,
  });

  /// 下载状态文本
  String get statusText {
    if (progress >= 100) return '下载完成';
    if (stage == 'error' || stage == 'failed') return '下载失败';
    if (stage == 'paused') return '已暂停';
    return message;
  }

  /// 是否为下载中状态
  bool get isDownloading =>
      stage == 'downloading' ||
      stage == 'converting' ||
      stage == 'fetching_audio' ||
      stage == 'transferring';

  /// 是否为已完成状态
  bool get isCompleted => stage == 'completed' || progress >= 100;

  /// 是否为失败状态
  bool get isFailed => stage == 'error' || stage == 'failed';

  /// 是否为暂停状态
  bool get isPaused => stage == 'paused';

  @override
  String toString() {
    return 'DownloadProgressEvent(taskId: $taskId, bvid: $bvid, progress: $progress%, stage: $stage)';
  }

  /// 复制并修改部分字段
  DownloadProgressEvent copyWith({
    int? taskId,
    int? trackId,
    String? bvid,
    int? progress,
    String? stage,
    String? message,
    int? downloadedBytes,
    int? totalBytes,
    double? speed,
    String? speedDisplay,
    String? timeRemaining,
  }) {
    return DownloadProgressEvent(
      taskId: taskId ?? this.taskId,
      trackId: trackId ?? this.trackId,
      bvid: bvid ?? this.bvid,
      progress: progress ?? this.progress,
      stage: stage ?? this.stage,
      message: message ?? this.message,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      speed: speed ?? this.speed,
      speedDisplay: speedDisplay ?? this.speedDisplay,
      timeRemaining: timeRemaining ?? this.timeRemaining,
    );
  }
}