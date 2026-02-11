import 'dart:typed_data';

import 'package:on_audio_query/on_audio_query.dart' as audio_query;

import '../../../core/utils/app_logger.dart';
import '../../../data/repositories/local_music_repository.dart';
import '../../../models/local_audio.dart';
import 'media_scanner_platform.dart';

class AndroidMediaScanner implements MediaScannerPlatform {
  final audio_query.OnAudioQuery _audioQuery = audio_query.OnAudioQuery();
  final LocalMusicRepository _repository;
  bool _initialized = false;

  AndroidMediaScanner(this._repository);

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    final logConfig = audio_query.LogConfig(logType: audio_query.LogType.WARN);
    await _audioQuery.setLogConfig(logConfig);
    _initialized = true;
    AppLogger.debug('AndroidMediaScanner', '服务已初始化');
  }

  @override
  Future<bool> hasPermission() async {
    await _ensureInitialized();
    try {
      return await _audioQuery.permissionsStatus();
    } catch (e) {
      AppLogger.error('AndroidMediaScanner', '检查权限失败: $e');
      return false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    await _ensureInitialized();
    try {
      final granted = await _audioQuery.checkAndRequest(retryRequest: false);
      AppLogger.info('AndroidMediaScanner', '权限请求结果: $granted');
      return granted;
    } catch (e) {
      AppLogger.error('AndroidMediaScanner', '请求权限失败: $e');
      return false;
    }
  }

  @override
  Future<ScanResult> scanDeviceAudio({
    int minDurationSeconds = 10,
    bool skipExisting = true,
    ScanCancelToken? cancelToken,
    void Function(int current, int total, String fileName)? onProgress,
  }) async {
    await _ensureInitialized();

    AppLogger.info('AndroidMediaScanner', '开始扫描设备音频，最小时长: ${minDurationSeconds}s');

    final hasAccess = await hasPermission();
    if (!hasAccess) {
      final granted = await requestPermission();
      if (!granted) {
        AppLogger.warn('AndroidMediaScanner', '无权限访问媒体库');
        return const ScanResult(
          addedCount: 0,
          skippedCount: 0,
          filteredCount: 0,
          addedAudios: [],
        );
      }
    }

    List<audio_query.SongModel> songs;
    try {
      songs = await _audioQuery.querySongs(
        sortType: audio_query.SongSortType.TITLE,
        orderType: audio_query.OrderType.ASC_OR_SMALLER,
        uriType: audio_query.UriType.EXTERNAL,
      );
      AppLogger.info('AndroidMediaScanner', '查询到 ${songs.length} 首音频');
    } catch (e) {
      AppLogger.error('AndroidMediaScanner', '查询音频失败: $e');
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
      if (cancelToken?.isCancelled ?? false) {
        AppLogger.info('AndroidMediaScanner', '扫描已取消');
        break;
      }

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
          audio_query.ArtworkType.AUDIO,
          size: 200,
          quality: 80,
        );
      } catch (e) {
        AppLogger.debug('AndroidMediaScanner', '获取封面失败: ${song.title} - $e');
      }

      final localAudio = _mapToLocalAudio(song, artwork);

      try {
        await _repository.addLocalMusic(localAudio);
        addedAudios.add(localAudio);
        AppLogger.debug('AndroidMediaScanner', '添加: ${localAudio.title}');
      } catch (e) {
        AppLogger.warn('AndroidMediaScanner', '添加失败: ${localAudio.title} - $e');
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
      'AndroidMediaScanner',
      '扫描完成: 新增 ${result.addedCount}, 跳过 ${result.skippedCount}, 过滤 ${result.filteredCount}',
    );

    return result;
  }

  LocalAudio _mapToLocalAudio(audio_query.SongModel song, Uint8List? artwork) {
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

  @override
  void dispose() {
    AppLogger.debug('AndroidMediaScanner', '服务已释放');
  }
}
