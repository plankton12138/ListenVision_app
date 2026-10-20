import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import '../core/errors/exceptions.dart';
import '../core/network/dio_client.dart';
import '../core/utils/app_logger.dart';
import 'bilibili_api_service.dart';
import 'bilibili_headers.dart';
import 'ffmpeg_service.dart';
import 'metadata_writer.dart';
import 'resumable_download_service.dart';

class DownloadResult {
  final bool success;
  final String? filePath;
  final String? error;
  final String? warning;
  final int? fileSize;
  final String format;
  DownloadResult({
    required this.success,
    this.filePath,
    this.error,
    this.warning,
    this.fileSize,
    this.format = 'm4a',
  });
}

typedef DownloadMetadataWriter =
    Future<bool> Function(String path, AudioMetadata metadata);

class BilibiliDownloader {
  final BilibiliApiService _api;
  final Dio _dio;
  final bool _ownsDio;
  final FfmpegService _ffmpeg;
  final DownloadMetadataWriter _writeMetadata;
  BilibiliDownloader(
    this._api, {
    Dio? dio,
    FfmpegService? ffmpeg,
    DownloadMetadataWriter? writeMetadata,
  }) : _dio = dio ?? DioClient.create(download: true),
       _ownsDio = dio == null,
       _ffmpeg = ffmpeg ?? FfmpegService(),
       _writeMetadata =
           writeMetadata ??
           ((path, metadata) async => (await MetadataWriter.writeMetadata(
             filePath: path,
             metadata: metadata,
           )).success);

  Future<DownloadResult> download({
    required String bvid,
    int? cid,
    required String saveDir,
    required String fileName,
    String? albumTitle,
    AudioOutputFormat? format,
    String? tempPath,
    CancelToken? cancelToken,
    bool downloadCover = true,
    void Function(int percent, String stage)? onProgress,
  }) async {
    final token = cancelToken ?? CancelToken();
    void progress(int percent, String stage) {
      if (token.isCancelled) throw const TaskCanceledException();
      onProgress?.call(percent, stage);
    }

    final safeName = _sanitize(fileName);
    final source = File(
      tempPath ?? p.join(saveDir, '.$safeName.$bvid.${cid ?? 0}.part.m4a'),
    );
    final cover = File('${source.path}.jpg');
    final transfer = ResumableDownloadService(dio: _dio);
    String? converted;
    try {
      progress(5, 'fetching_info');
      final info = await _api.getVideoInfo(bvid, cancelToken: token);
      progress(10, 'fetching_audio');
      final streams = await _api.getAudioStreams(
        bvid,
        cid: cid,
        cancelToken: token,
      );
      if (streams.streams.isEmpty) throw StateError('无法获取音频流');
      final sorted = [...streams.streams]
        ..sort((a, b) => b.qualityId.compareTo(a.qualityId));
      progress(15, 'downloading_audio');
      await transfer.downloadFile(
        url: sorted.first.url,
        savePath: source.path,
        headers: bilibiliHeaders,
        cancelToken: token,
        onProgress: (received, total) => progress(
          total > 0 ? (15 + 50 * received / total).round().clamp(15, 65) : 15,
          'downloading_audio',
        ),
      );
      // 元数据会改变字节布局，后续重试不得将该文件当作原始 Range 片段。
      final sidecar = File('${source.path}.json');
      if (await sidecar.exists()) await sidecar.delete();
      progress(70, 'downloading_cover');
      final coverUrl = info['pic'] ?? info['cover'];
      File? downloadedCover;
      if (downloadCover && coverUrl is String && coverUrl.isNotEmpty) {
        try {
          final response = await _dio.get<List<int>>(
            normalizeBilibiliUrl(coverUrl),
            options: Options(
              responseType: ResponseType.bytes,
              headers: bilibiliHeaders,
            ),
            cancelToken: token,
          );
          await cover.writeAsBytes(response.data!, flush: true);
          downloadedCover = cover;
        } catch (error) {
          if (token.isCancelled) throw const TaskCanceledException();
          AppLogger.warn('BilibiliDownloader', '封面下载失败: $error');
        }
      }
      progress(80, 'writing_metadata');
      final owner = info['owner'];
      await _writeMetadata(
        source.path,
        AudioMetadata(
          title: albumTitle != null
              ? fileName
              : info['title'] as String? ?? fileName,
          artist: owner is Map ? owner['name'] as String? ?? '未知艺术家' : '未知艺术家',
          album: albumTitle,
          coverFile: downloadedCover,
        ),
      );
      var resultFormat = AudioOutputFormat.m4a;
      String? warning;
      if (format != null && format != AudioOutputFormat.m4a) {
        progress(85, 'converting');
        try {
          converted = await _ffmpeg.convert(
            inputPath: source.path,
            outputFormat: format,
            cancelToken: token,
          );
          resultFormat = format;
        } catch (error) {
          if (token.isCancelled || error is TaskCanceledException) rethrow;
          warning = '格式转换失败，已保存 M4A';
          AppLogger.warn('BilibiliDownloader', '$warning: $error');
        }
      }
      progress(95, 'processing_file');
      final candidate = File(converted ?? source.path);
      final extension = resultFormat.extension;
      final stem = '$safeName [$bvid${cid == null ? '' : '-$cid'}]';
      var target = p.join(saveDir, '$stem.$extension');
      var index = 1;
      while (await File(target).exists()) {
        target = p.join(saveDir, '$stem (${index++}).$extension');
      }
      if (token.isCancelled) throw const TaskCanceledException();
      final output = await candidate.rename(target);
      if (token.isCancelled) {
        // 发布过程中取消：移回任务私有临时路径，保留可恢复的源文件。
        await output.rename(candidate.path);
        throw const TaskCanceledException();
      }
      // 完成事件由 Repository 在提交数据库后发出。
      return DownloadResult(
        success: true,
        filePath: output.path,
        fileSize: await output.length(),
        format: extension,
        warning: warning,
      );
    } catch (error) {
      if (token.isCancelled || error is TaskCanceledException) {
        throw const TaskCanceledException();
      }
      return DownloadResult(success: false, error: error.toString());
    } finally {
      if (await cover.exists()) await cover.delete();
      if (converted != null && await File(converted).exists()) {
        await File(converted).delete();
      }
    }
  }

  String _sanitize(String text) {
    var value = text.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_').trim();
    value = value.replaceAll(RegExp(r'[. ]+$'), '');
    if (value.isEmpty) value = 'audio';
    if (RegExp(
      r'^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])$',
      caseSensitive: false,
    ).hasMatch(value)) {
      value = '_$value';
    }
    return value.length > 140 ? value.substring(0, 140) : value;
  }

  void dispose() {
    if (_ownsDio) _dio.close(force: true);
  }
}
