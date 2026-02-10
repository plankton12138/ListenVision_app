import 'dart:typed_data';

import 'package:on_audio_query/on_audio_query.dart' as audio_query;
import 'package:on_audio_query/on_audio_query.dart'
    show OnAudioQuery, SongModel, ArtworkType, SongSortType, OrderType, UriType;

import '../core/utils/app_logger.dart';
import '../data/repositories/local_music_repository.dart';
import '../models/local_audio.dart';

class ScanResult {
  final int addedCount;
  final int skippedCount;
  final int filteredCount;
  final List<LocalAudio> addedAudios;

  const ScanResult({
    required this.addedCount,
    required this.skippedCount,
    required this.filteredCount,
    required this.addedAudios,
  });

  bool get isEmpty => addedCount == 0 && skippedCount == 0 && filteredCount == 0;

  String get summary {
    final parts = <String>[];
    if (addedCount > 0) parts.add('新增 $addedCount 首');
    if (skippedCount > 0) parts.add('跳过 $skippedCount 首');
    if (filteredCount > 0) parts.add('过滤 $filteredCount 首');
    return parts.isEmpty ? '无变化' : parts.join('，');
  }
}

class MediaScannerService {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final LocalMusicRepository _repository;

  bool _initialized = false;

  MediaScannerService({LocalMusicRepository? repository})
      : _repository = repository ?? LocalMusicRepository();

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    final logConfig = audio_query.LogConfig(logType: audio_query.LogType.WARN);
    await _audioQuery.setLogConfig(logConfig);
    _initialized = true;
    AppLogger.debug('MediaScannerService', '服务已初始化');
  }

  Future<bool> hasPermission() async {
    await _ensureInitialized();
    try {
      final status = await _audioQuery.permissionsStatus();
      return status;
    } catch (e) {
      AppLogger.error('MediaScannerService', '检查权限失败: $e');
      return false;
    }
  }

  Future<bool> requestPermission() async {
    await _ensureInitialized();
    try {
      final granted = await _audioQuery.checkAndRequest(retryRequest: false);
      AppLogger.info('MediaScannerService', '权限请求结果: $granted');
      return granted;
    } catch (e) {
      AppLogger.error('MediaScannerService', '请求权限失败: $e');
      return false;
    }
  }

  Future<ScanResult> scanDeviceAudio({
    int minDurationSeconds = 10,
    bool skipExisting = true,
    void Function(int current, int total, String fileName)? onProgress,
  }) async {
    await _ensureInitialized();

    AppLogger.info('MediaScannerService', '开始扫描设备音频，最小时长: ${minDurationSeconds}s');

    final hasAccess = await hasPermission();
    if (!hasAccess) {
      final granted = await requestPermission();
      if (!granted) {
        AppLogger.warn('MediaScannerService', '无权限访问媒体库');
        return const ScanResult(
          addedCount: 0,
          skippedCount: 0,
          filteredCount: 0,
          addedAudios: [],
        );
      }
    }

    List<SongModel> songs;
    try {
      songs = await _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
      );
      AppLogger.info('MediaScannerService', '查询到 ${songs.length} 首音频');
    } catch (e) {
      AppLogger.error('MediaScannerService', '查询音频失败: $e');
      return const ScanResult(
        addedCount: 0,
        skippedCount: 0,
        filteredCount: 0,
        addedAudios: [],
      );
    }

    final addedAudios = <LocalAudio>[];
    int skippedCount = 0;
    int filteredCount = 0;

    for (int i = 0; i < songs.length; i++) {
      final song = songs[i];

      onProgress?.call(i + 1, songs.length, song.title);

      final durationMs = song.duration ?? 0;
      final durationSec = durationMs ~/ 1000;
      if (durationSec < minDurationSeconds) {
        filteredCount++;
        continue;
      }

      final filePath = song.data;
      if (filePath.isEmpty) {
        filteredCount++;
        continue;
      }

      if (skipExisting) {
        final exists = await _repository.isFileImported(filePath);
        if (exists) {
          skippedCount++;
          continue;
        }
      }

      Uint8List? artwork;
      try {
        artwork = await _audioQuery.queryArtwork(
          song.id,
          ArtworkType.AUDIO,
          size: 200,
          quality: 80,
        );
      } catch (e) {
        AppLogger.debug('MediaScannerService', '获取封面失败: ${song.title} - $e');
      }

      final localAudio = _mapToLocalAudio(song, artwork);

      try {
        await _repository.addLocalMusic(localAudio);
        addedAudios.add(localAudio);
        AppLogger.debug('MediaScannerService', '添加: ${localAudio.title}');
      } catch (e) {
        AppLogger.warn('MediaScannerService', '添加失败: ${localAudio.title} - $e');
        skippedCount++;
      }
    }

    final result = ScanResult(
      addedCount: addedAudios.length,
      skippedCount: skippedCount,
      filteredCount: filteredCount,
      addedAudios: addedAudios,
    );

    AppLogger.info(
      'MediaScannerService',
      '扫描完成: 新增 ${result.addedCount}, 跳过 ${result.skippedCount}, 过滤 ${result.filteredCount}',
    );

    return result;
  }

  LocalAudio _mapToLocalAudio(SongModel song, Uint8List? artwork) {
    String title = song.title;
    if (title.isEmpty) {
      title = _extractFileName(song.data);
    }

    String artist = song.artist ?? '';
    if (artist.isEmpty || artist == '<unknown>') {
      artist = '未知艺术家';
    }

    final durationSec = (song.duration ?? 0) ~/ 1000;

    return LocalAudio(
      id: null,
      filePath: song.data,
      title: title,
      artist: artist,
      duration: durationSec,
      albumArt: artwork,
      url: null,
      isFavorite: false,
    );
  }

  String _extractFileName(String filePath) {
    if (filePath.isEmpty) return '未知标题';
    final fileName = filePath.split(RegExp(r'[\\/]')).last;
    final lastDotIndex = fileName.lastIndexOf('.');
    if (lastDotIndex > 0) {
      return fileName.substring(0, lastDotIndex);
    }
    return fileName;
  }

  void dispose() {
    AppLogger.debug('MediaScannerService', '服务已释放');
  }
}
