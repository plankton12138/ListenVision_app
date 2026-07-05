import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import '../core/utils/app_logger.dart';
import '../presentation/widgets/common/snackbar_helper.dart';
import 'bilibili_api_service.dart';
import 'ffmpeg_service.dart';
import 'metadata_writer.dart';

class DownloadResult {
  final bool success;
  final String? filePath;
  final String? error;
  final int? fileSize;
  final String format;

  DownloadResult({
    required this.success,
    this.filePath,
    this.error,
    this.fileSize,
    this.format = 'm4a',
  });
}

class BilibiliDownloader {
  final BilibiliApiService _api;
  final Dio _dio;

  BilibiliDownloader(this._api) : _dio = Dio();

  Future<DownloadResult> download({
    required String bvid,
    int? cid,
    required String saveDir,
    required String fileName,
    AudioOutputFormat? format,
    void Function(int percent, String stage)? onProgress,
  }) async {
    // 临时文件目录
    final tempDir = Directory.systemTemp;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final tempM4s = '${tempDir.path}/$timestamp$bvid.m4s';
    final tempCover = '${tempDir.path}/$timestamp$bvid.jpg';

    try {
      AppLogger.info('BilibiliDownloader', '开始下载: $bvid');

      onProgress?.call(5, 'fetching_info');
      final videoInfo = await _api.getVideoInfo(bvid);

      final title = videoInfo['title'] as String? ?? '未知标题';
      final owner = videoInfo['owner'] as Map<String, dynamic>?;
      final artist = owner?['name'] as String? ?? '未知艺术家';
      final coverUrl = videoInfo['cover'] as String?;

      AppLogger.info('BilibiliDownloader', '获取视频信息: $title - $artist');

      onProgress?.call(10, 'fetching_audio');
      final audioStream = await _api.getAudioStreams(bvid, cid: cid);

      if (audioStream.streams.isEmpty) {
        throw Exception('无法获取音频流 URL');
      }

      final streams = audioStream.streams
        ..sort((a, b) => b.qualityId.compareTo(a.qualityId));

      final audioUrl = streams.first.url;
      if (audioUrl.isEmpty) {
        throw Exception('无法获取音频流 URL');
      }
      AppLogger.info('BilibiliDownloader', '获取音频流 URL: ${audioUrl.substring(0, audioUrl.length > 50 ? 50 : audioUrl.length)}...');

      // 步骤3: 下载 m4s 音频文件（50% 进度）
      onProgress?.call(15, 'downloading_audio');
      await _downloadFile(
        audioUrl,
        tempM4s,
        onProgress: (received, total) {
          final percent = 15 + ((received / total) * 50).toInt();
          onProgress?.call(percent.clamp(15, 65), 'downloading_audio');
        },
      );

      final m4sFile = File(tempM4s);
      final m4sSize = await m4sFile.length();
      AppLogger.info('BilibiliDownloader', '音频下载完成: $m4sSize bytes');

      // 步骤4: 重命名 m4s → m4a（零转换！）
      onProgress?.call(65, 'processing_file');
      final safeFileName = _sanitizeFileName(fileName);
      final m4aPath = p.join(saveDir, '$safeFileName.m4a');

      // 确保目标目录存在
      await Directory(saveDir).create(recursive: true);

      // 移动文件（重命名）
      await m4sFile.rename(m4aPath);
      AppLogger.info('BilibiliDownloader', '文件已重命名: $m4aPath');

      // 步骤5: 下载封面（10% 进度）
      onProgress?.call(70, 'downloading_cover');
      File? coverFile;
      if (coverUrl != null) {
        try {
          await _downloadFile(coverUrl, tempCover);
          coverFile = File(tempCover);
          AppLogger.info('BilibiliDownloader', '封面下载完成');
        } catch (e) {
          AppLogger.warn('BilibiliDownloader', '封面下载失败: $e');
        }
      }

      // 步骤6: 写入元数据（20% 进度）
      onProgress?.call(80, 'writing_metadata');
      final metadataResult = await MetadataWriter.writeMetadata(
        filePath: m4aPath,
        metadata: AudioMetadata(
          title: title,
          artist: artist,
          album: 'https://www.bilibili.com/video/$bvid',
          coverFile: coverFile,
        ),
      );

      if (!metadataResult.success) {
        AppLogger.warn('BilibiliDownloader', '元数据写入失败: ${metadataResult.error}');
      }

      String audioPath = m4aPath;
      String resultFormat = 'm4a';

      if (format != null && format != AudioOutputFormat.m4a) {
        onProgress?.call(85, 'converting');
        final ffmpeg = FfmpegService();
        try {
          final convertedPath = await ffmpeg.convert(
            inputPath: m4aPath,
            outputFormat: format,
          );
          await File(m4aPath).delete();
          audioPath = convertedPath;
          resultFormat = format.extension;
        } catch (e) {
          AppLogger.warn('BilibiliDownloader', '格式转换失败，保留 m4a: $e');
          final msg = e is ProcessException
              ? 'FFmpeg 未安装或不在 PATH 中，已保留 M4A 格式'
              : '格式转换失败，已保留 M4A 格式';
          SnackbarHelper.showToast(msg);
        }
      }

      onProgress?.call(100, 'completed');

      final finalFile = File(audioPath);
      final finalSize = await finalFile.length();

      AppLogger.info('BilibiliDownloader', '下载完成: $audioPath ($finalSize bytes)');

      return DownloadResult(
        success: true,
        filePath: audioPath,
        fileSize: finalSize,
        format: resultFormat,
      );
    } catch (e) {
      AppLogger.error('BilibiliDownloader', '下载失败: $e');

      return DownloadResult(
        success: false,
        error: e.toString(),
      );
    } finally {
      // 清理临时文件
      await _deleteIfExists(tempM4s);
      await _deleteIfExists(tempCover);
    }
  }

  /// 下载文件（带进度节流，避免主线程消息溢出）
  Future<void> _downloadFile(
    String url,
    String savePath, {
    void Function(int received, int total)? onProgress,
  }) async {
    // 进度节流：只当进度变化超过 1% 或每 500ms 才更新
    int? _lastNotifiedPercent;
    DateTime? _lastNotifiedTime;

    await _dio.download(
      url,
      savePath,
      options: Options(
        headers: {
          'Referer': 'https://www.bilibili.com/',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ),
      onReceiveProgress: (received, total) {
        if (total <= 0 || onProgress == null) return;

        final percent = (received / total * 100).toInt();
        final now = DateTime.now();

        // 节流条件：
        // 1. 进度变化超过 1%，或
        // 2. 距离上次通知超过 500ms
        final shouldNotify = _lastNotifiedPercent == null ||
            (percent - _lastNotifiedPercent!).abs() >= 1 ||
            _lastNotifiedTime == null ||
            now.difference(_lastNotifiedTime!).inMilliseconds >= 500;

        if (shouldNotify) {
          _lastNotifiedPercent = percent;
          _lastNotifiedTime = now;
          onProgress(received, total);
        }
      },
    );
  }

  /// 删除文件（忽略错误）
  Future<void> _deleteIfExists(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  /// 清理文件名（移除非法字符）
  String _sanitizeFileName(String name) {
    // 移除或替换不允许的字符
    final invalidChars = RegExp(r'[<>:"/\\|?*]');
    return name.replaceAll(invalidChars, '_').trim();
  }
}
