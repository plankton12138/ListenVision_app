import 'dart:io';
import '../core/utils/app_logger.dart';

enum AudioOutputFormat {
  m4a('m4a'),
  mp3('mp3'),
  aac('aac');

  final String extension;
  const AudioOutputFormat(this.extension);
}

class FfmpegService {
  /// FFmpeg 转换不可用（ffmpeg_kit_flutter 已移除）。
  /// 当前 PDF 能直接从 .m4s 重命名为 .m4a（同容器格式零转换）。
  /// 如需 mp3/aac 输出，考虑替代的转换方案。
  Future<String> convert({
    required String inputPath,
    required AudioOutputFormat outputFormat,
  }) async {
    final outputPath = _buildOutputPath(inputPath, outputFormat);
    if (await File(outputPath).exists()) {
      AppLogger.info('FfmpegService', '输出文件已存在，跳过转换: $outputPath');
      return outputPath;
    }

    if (inputPath.endsWith('.m4a') && outputFormat == AudioOutputFormat.m4a) {
      return inputPath;
    }

    throw FfmpegException('FFmpeg 不可用，无法转换格式。请使用默认 m4a 格式。');
  }

  Future<void> cancel() async {}

  Future<bool> isAvailable() async => false;

  String _buildOutputPath(String inputPath, AudioOutputFormat format) {
    final dir = Directory(inputPath).parent.path;
    final baseName = inputPath.split(Platform.pathSeparator).last;
    final nameWithoutExt =
        baseName.contains('.') ? baseName.substring(0, baseName.lastIndexOf('.')) : baseName;
    return '$dir${Platform.pathSeparator}$nameWithoutExt.${format.extension}';
  }
}

class FfmpegException implements Exception {
  final String message;
  FfmpegException(this.message);

  @override
  String toString() => 'FfmpegException: $message';
}
