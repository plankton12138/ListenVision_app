import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import '../core/errors/exceptions.dart';
import '../core/utils/app_logger.dart';

enum AudioOutputFormat {
  m4a('m4a'),
  mp3('mp3'),
  aac('aac');

  final String extension;
  const AudioOutputFormat(this.extension);
}

typedef AudioProcessStarter =
    Future<Process> Function(String command, List<String> args);

class FfmpegService {
  FfmpegService({
    AudioProcessStarter? startProcess,
    this.timeout = const Duration(minutes: 20),
    bool? supportsConversion,
  }) : _startProcess =
           startProcess ?? ((command, args) => Process.start(command, args)),
       supportsConversion =
           supportsConversion ??
           (!kIsWeb &&
               (Platform.isWindows || Platform.isLinux || Platform.isMacOS));
  final AudioProcessStarter _startProcess;
  final Duration timeout;
  final bool supportsConversion;
  Process? _process;
  bool _busy = false;
  bool _cancelled = false;

  Future<String> convert({
    required String inputPath,
    required AudioOutputFormat outputFormat,
    CancelToken? cancelToken,
  }) async {
    if (outputFormat == AudioOutputFormat.m4a) return inputPath;
    if (!supportsConversion) throw FfmpegException('此平台暂不支持格式转换');
    if (_busy) throw StateError('转换任务正在运行');
    _busy = true;
    _cancelled = false;
    var finished = false;
    final requested = p.setExtension(inputPath, '.${outputFormat.extension}');
    var outputPath = requested;
    var suffix = 1;
    File? temp;
    Timer? timer;
    var timedOut = false;
    try {
      while (await File(outputPath).exists()) {
        outputPath =
            '${p.withoutExtension(requested)} (${suffix++}).${outputFormat.extension}';
      }
      temp = File(
        p.join(
          p.dirname(outputPath),
          '.${p.basenameWithoutExtension(outputPath)}.${DateTime.now().microsecondsSinceEpoch}.part.${outputFormat.extension}',
        ),
      );
      if (cancelToken?.isCancelled ?? false) {
        throw const TaskCanceledException();
      }
      unawaited(
        cancelToken?.whenCancel.then((_) async {
          if (!finished) await cancel();
        }),
      );
      _process = await _startProcess('ffmpeg', [
        '-nostdin',
        '-i',
        inputPath,
        '-codec:a',
        outputFormat == AudioOutputFormat.mp3 ? 'libmp3lame' : 'aac',
        if (outputFormat == AudioOutputFormat.mp3) ...[
          '-q:a',
          '2',
        ] else ...[
          '-b:a',
          '256k',
        ],
        '-y',
        temp.path,
      ]);
      if (_cancelled || (cancelToken?.isCancelled ?? false)) _process!.kill();
      timer = Timer(timeout, () {
        timedOut = true;
        _process?.kill();
      });
      // 始终消费两个管道，避免大输出阻塞子进程。
      final stdoutDone = _process!.stdout.drain<void>();
      final errorText = StringBuffer();
      final stderrDone = _process!.stderr.transform(utf8.decoder).forEach((
        text,
      ) {
        if (errorText.length < 8192) errorText.write(text);
      });
      final exitCode = await _process!.exitCode;
      await Future.wait([stdoutDone, stderrDone]);
      if (_cancelled || (cancelToken?.isCancelled ?? false)) {
        throw const TaskCanceledException();
      }
      if (timedOut) throw FfmpegException('格式转换超时');
      if (exitCode != 0 || !await temp.exists() || await temp.length() == 0) {
        throw FfmpegException('格式转换失败: $errorText');
      }
      await temp.rename(outputPath);
      AppLogger.info('FfmpegService', '转换完成: $outputPath');
      return outputPath;
    } finally {
      finished = true;
      timer?.cancel();
      _process = null;
      _busy = false;
      if (temp != null && await temp.exists()) await temp.delete();
    }
  }

  Future<void> cancel() async {
    _cancelled = true;
    _process?.kill();
  }

  Future<bool> isAvailable() async {
    if (!supportsConversion) return false;
    try {
      final result = await Process.run('ffmpeg', [
        '-version',
      ]).timeout(const Duration(seconds: 5));
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }
}

class FfmpegException implements Exception {
  final String message;
  FfmpegException(this.message);
  @override
  String toString() => message;
}
