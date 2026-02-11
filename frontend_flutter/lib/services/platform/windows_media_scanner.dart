import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:path/path.dart' as p;

import '../../../core/utils/app_logger.dart';
import '../../../core/utils/audio_metadata_helper.dart';
import '../../../data/repositories/local_music_repository.dart';
import '../../../models/local_audio.dart';
import 'media_scanner_platform.dart';

const _supportedExtensions = ['.mp3', '.flac', '.m4a', '.mp4', '.wav', '.ogg', '.wma'];

class WindowsMediaScanner implements MediaScannerPlatform {
  final LocalMusicRepository _repository;
  final AudioMetadataHelper _metadataHelper = AudioMetadataHelper();

  WindowsMediaScanner(this._repository);

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<ScanResult> scanDeviceAudio({
    int minDurationSeconds = 10,
    bool skipExisting = true,
    ScanCancelToken? cancelToken,
    void Function(int current, int total, String fileName)? onProgress,
    List<String>? scanDirs,
  }) async {
    AppLogger.info('WindowsMediaScanner', '开始扫描本地音频');

    final directories = scanDirs ?? await _getDefaultScanDirectories();
    if (directories.isEmpty) {
      AppLogger.warn('WindowsMediaScanner', '未找到可扫描的目录');
      return const ScanResult(
        addedCount: 0,
        skippedCount: 0,
        filteredCount: 0,
        addedAudios: [],
      );
    }

    final audioFiles = await _collectAudioFiles(directories, cancelToken);
    if (audioFiles.isEmpty) {
      AppLogger.info('WindowsMediaScanner', '未找到音频文件');
      return const ScanResult(
        addedCount: 0,
        skippedCount: 0,
        filteredCount: 0,
        addedAudios: [],
      );
    }

    AppLogger.info('WindowsMediaScanner', '找到 ${audioFiles.length} 个音频文件');

    final addedAudios = <LocalAudio>[];
    int skippedCount = 0;

    for (int i = 0; i < audioFiles.length; i++) {
      if (cancelToken?.isCancelled ?? false) {
        AppLogger.info('WindowsMediaScanner', '扫描已取消');
        break;
      }

      final filePath = audioFiles[i];
      final fileName = p.basename(filePath);
      onProgress?.call(i + 1, audioFiles.length, fileName);

      if (skipExisting) {
        final exists = await _repository.isFileImported(filePath);
        if (exists) {
          skippedCount++;
          continue;
        }
      }

      try {
        final localAudio = await _processAudioFile(filePath);
        await _repository.addLocalMusic(localAudio);
        addedAudios.add(localAudio);
        AppLogger.debug('WindowsMediaScanner', '添加: ${localAudio.title}');
      } catch (e) {
        AppLogger.warn('WindowsMediaScanner', '处理文件失败: $filePath - $e');
        skippedCount++;
      }
    }

    final result = ScanResult(
      addedCount: addedAudios.length,
      skippedCount: skippedCount,
      filteredCount: 0,
      addedAudios: addedAudios,
    );

    AppLogger.info(
      'WindowsMediaScanner',
      '扫描完成: 新增 ${result.addedCount}, 跳过 ${result.skippedCount}',
    );

    return result;
  }

  Future<List<String>> _getDefaultScanDirectories() async {
    final directories = <String>[];

    final userProfile = Platform.environment['USERPROFILE'];
    if (userProfile != null) {
      final downloadsDir = p.join(userProfile, 'Downloads', 'ListenVision');
      final musicDir = p.join(userProfile, 'Music');

      if (await Directory(downloadsDir).exists()) {
        directories.add(downloadsDir);
      }
      if (await Directory(musicDir).exists()) {
        directories.add(musicDir);
      }
    }

    final dMusic = p.join('D:', 'Music');
    if (await Directory(dMusic).exists()) {
      directories.add(dMusic);
    }

    return directories;
  }

  Future<List<String>> _collectAudioFiles(
    List<String> directories,
    ScanCancelToken? cancelToken,
  ) async {
    final audioFiles = <String>[];

    for (final dirPath in directories) {
      if (cancelToken?.isCancelled ?? false) break;

      final dir = Directory(dirPath);
      if (!await dir.exists()) continue;

      try {
        await for (final entity in dir.list(recursive: true, followLinks: false)) {
          if (cancelToken?.isCancelled ?? false) break;
          if (entity is! File) continue;

          final extension = p.extension(entity.path).toLowerCase();
          if (_supportedExtensions.contains(extension)) {
            audioFiles.add(entity.path);
          }
        }
      } catch (e) {
        AppLogger.warn('WindowsMediaScanner', '扫描目录失败: $dirPath - $e');
      }
    }

    return audioFiles;
  }

  Future<LocalAudio> _processAudioFile(String filePath) async {
    String title = '';
    String artist = '未知艺术家';
    Uint8List? albumArt;
    int durationSec = 0;

    // 1. 尝试从 audio_metadata_reader 读取元数据
    try {
      final result = _metadataHelper.readMetadata(filePath: filePath, fetchCover: true);
      title = result.title;
      artist = result.artist.isNotEmpty ? result.artist : '未知艺术家';
      albumArt = result.cover;
      durationSec = result.duration ?? 0;
      AppLogger.debug('WindowsMediaScanner', '元数据读取: $filePath, durationSec: $durationSec');
    } catch (e) {
      AppLogger.warn('WindowsMediaScanner', '读取元数据失败: $filePath - $e');
    }

    // 2. 后备方案：如果时长为 0，使用 audioplayers 获取
    if (durationSec == 0) {
      try {
        final player = AudioPlayer();
        await player.setSource(DeviceFileSource(filePath));
        final duration = await player.getDuration();
        await player.dispose();
        if (duration != null && duration.inSeconds > 0) {
          durationSec = duration.inSeconds;
          AppLogger.debug('WindowsMediaScanner', '从 audioplayers 获取时长: ${durationSec}s');
        }
      } catch (e) {
        AppLogger.warn('WindowsMediaScanner', 'audioplayers 获取时长失败: $filePath - $e');
      }
    }

    // 3. 补充标题（如果元数据未读取到）
    if (title.isEmpty) {
      title = _extractFileName(filePath);
    }

    return LocalAudio(
      id: null,
      filePath: filePath,
      title: title,
      artist: artist,
      duration: durationSec,
      albumArt: albumArt,
      url: null,
      isFavorite: false,
    );
  }

  String _extractFileName(String filePath) {
    if (filePath.isEmpty) return '未知标题';
    final fileName = p.basenameWithoutExtension(filePath);
    return fileName.isEmpty ? '未知标题' : fileName;
  }

  @override
  void dispose() {
    AppLogger.debug('WindowsMediaScanner', '服务已释放');
  }
}
