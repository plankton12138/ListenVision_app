import 'dart:io';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import '../core/utils/app_logger.dart';

enum AudioOutputFormat {
  m4a('m4a'),
  mp3('mp3'),
  aac('aac');

  final String extension;
  const AudioOutputFormat(this.extension);
}

class FfmpegService {
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

    final arguments = _buildArguments(inputPath, outputPath, outputFormat);
    AppLogger.info('FfmpegService', '开始转换: $inputPath → $outputPath');

    final session = await FFmpegKit.executeWithArguments(arguments);
    final returnCode = await session.getReturnCode();

    if (!ReturnCode.isSuccess(returnCode)) {
      throw FfmpegException('音频格式转换失败，返回码: $returnCode');
    }

    AppLogger.info('FfmpegService', '转换完成: $outputPath');
    return outputPath;
  }

  Future<void> cancel() async {
    await FFmpegKit.cancel();
  }

  Future<bool> isAvailable() async {
    try {
      final version = await FFmpegKit.listSessions();
      return true;
    } catch (_) {
      return false;
    }
  }

  String _buildOutputPath(String inputPath, AudioOutputFormat format) {
    final dir = Directory(inputPath).parent.path;
    final baseName = inputPath.split(Platform.pathSeparator).last;
    final nameWithoutExt =
        baseName.contains('.') ? baseName.substring(0, baseName.lastIndexOf('.')) : baseName;
    return '$dir${Platform.pathSeparator}$nameWithoutExt.${format.extension}';
  }

  List<String> _buildArguments(
    String inputPath,
    String outputPath,
    AudioOutputFormat format,
  ) {
    final args = <String>['-i', inputPath, '-y'];

    switch (format) {
      case AudioOutputFormat.mp3:
        args.addAll(['-c:a', 'libmp3lame', '-b:a', '192k']);
        break;
      case AudioOutputFormat.aac:
        args.addAll(['-c:a', 'aac', '-b:a', '192k']);
        break;
      case AudioOutputFormat.m4a:
        args.addAll(['-c:a', 'copy']);
        break;
    }

    args.add(outputPath);
    return args;
  }
}

class FfmpegException implements Exception {
  final String message;
  FfmpegException(this.message);

  @override
  String toString() => 'FfmpegException: $message';
}
