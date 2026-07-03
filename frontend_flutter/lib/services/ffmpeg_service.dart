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
  /// 将 M4A 音频转换为指定格式
  ///
  /// [inputPath] 源 M4A 文件路径
  /// [outputFormat] 目标格式（m4a 直接返回原路径，零转换）
  ///
  /// 返回转换后的文件路径，转换失败时抛出 [FfmpegException]。
  Future<String> convert({
    required String inputPath,
    required AudioOutputFormat outputFormat,
  }) async {
    // 同格式无需转换
    if (outputFormat == AudioOutputFormat.m4a) {
      return inputPath;
    }

    final outputPath = _buildOutputPath(inputPath, outputFormat);

    if (await File(outputPath).exists()) {
      AppLogger.info('FfmpegService', '输出文件已存在，跳过转换: $outputPath');
      return outputPath;
    }

    final args = <String>[
      '-i', inputPath,
      '-codec:a',
      outputFormat == AudioOutputFormat.mp3 ? 'libmp3lame' : 'aac',
      if (outputFormat == AudioOutputFormat.mp3) ...['-q:a', '2'],
      if (outputFormat == AudioOutputFormat.aac) ...['-b:a', '256k'],
      '-y',
      outputPath,
    ];

    AppLogger.info('FfmpegService', '开始转换: $inputPath → $outputPath');
    final result = await Process.run('ffmpeg', args);

    if (result.exitCode == 0) {
      AppLogger.info('FfmpegService', '转换完成: $outputPath');
      return outputPath;
    } else {
      final error = 'FFmpeg 转换失败: ${result.stderr}';
      AppLogger.error('FfmpegService', error);
      throw FfmpegException(error);
    }
  }

  /// 取消当前转换任务（Process.run 不支持取消，保留接口兼容性）
  Future<void> cancel() async {}

  /// 检查系统 FFmpeg 是否可用
  Future<bool> isAvailable() async {
    try {
      final result = await Process.run('ffmpeg', ['-version']);
      return result.exitCode == 0;
    } catch (e) {
      AppLogger.warn('FfmpegService', 'FFmpeg 不可用: $e');
      return false;
    }
  }

  String _buildOutputPath(String inputPath, AudioOutputFormat format) {
    final dir = Directory(inputPath).parent.path;
    final baseName = inputPath.split(Platform.pathSeparator).last;
    final nameWithoutExt = baseName.contains('.')
        ? baseName.substring(0, baseName.lastIndexOf('.'))
        : baseName;
    return '$dir${Platform.pathSeparator}$nameWithoutExt.${format.extension}';
  }
}

class FfmpegException implements Exception {
  final String message;
  FfmpegException(this.message);

  @override
  String toString() => 'FfmpegException: $message';
}
