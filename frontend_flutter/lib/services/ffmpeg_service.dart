import 'dart:io';

import 'package:ffmpeg_kit_flutter_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/return_code.dart';

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

    String command;
    switch (outputFormat) {
      case AudioOutputFormat.mp3:
        command = '-i "$inputPath" -codec:a libmp3lame -q:a 2 "$outputPath"';
        break;
      case AudioOutputFormat.aac:
        command = '-i "$inputPath" -codec:a aac -b:a 256k "$outputPath"';
        break;
      case AudioOutputFormat.m4a:
        return inputPath;
    }

    AppLogger.info('FfmpegService', '开始转换: $inputPath → $outputPath');

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      AppLogger.info('FfmpegService', '转换完成: $outputPath');
      return outputPath;
    } else {
      final output = await session.getOutput();
      final error = 'FFmpeg 转换失败: $output';
      AppLogger.error('FfmpegService', error);
      throw FfmpegException(error);
    }
  }

  /// 取消当前转换任务
  Future<void> cancel() async {
    await FFmpegKit.cancel();
  }

  /// 检查 FFmpeg 是否可用
  Future<bool> isAvailable() async {
    try {
      final session = await FFmpegKit.execute('-version');
      final returnCode = await session.getReturnCode();
      return ReturnCode.isSuccess(returnCode);
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
