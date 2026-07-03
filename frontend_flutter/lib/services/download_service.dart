import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../core/utils/app_logger.dart';

enum DownloadStatus {
  pending,
  downloading,
  paused,
  completed,
  failed,
}

class DownloadProgress {
  final int percent;
  final String stage;
  final String message;

  const DownloadProgress({
    required this.percent,
    required this.stage,
    required this.message,
  });

  @override
  String toString() => 'DownloadProgress($percent% - $stage: $message)';

  bool get isComplete => percent >= 100;
  bool get isFailed => stage == 'error';
  bool get isDownloading =>
      stage == 'fetching' || stage == 'converting' || stage == 'transferring';
}

class DownloadResult {
  final bool success;
  final String? filePath;
  final String? error;

  const DownloadResult({
    required this.success,
    this.filePath,
    this.error,
  });

  factory DownloadResult.success(String filePath) =>
      DownloadResult(success: true, filePath: filePath);

  factory DownloadResult.failure(String error) =>
      DownloadResult(success: false, error: error);

  @override
  String toString() => success ? '下载成功: $filePath' : '下载失败: $error';
}

class DownloadService {
  final Dio _dio;
  bool _disposed = false;
  CancellationToken? _currentToken;

  DownloadService({Dio? dio}) : _dio = dio ?? Dio();

  Future<DownloadResult> simpleDownload({
    required String url,
    required String savePath,
    void Function(int received, int total)? onProgress,
  }) async {
    if (_disposed) {
      return DownloadResult.failure('服务已释放');
    }

    _currentToken = CancellationToken();
    final token = _currentToken!;

    try {
      await _dio.download(
        url,
        savePath,
        cancelToken: token.cancelToken,
        onReceiveProgress: onProgress,
      );

      return DownloadResult.success(savePath);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        return DownloadResult.failure('下载已取消');
      }
      return DownloadResult.failure(e.message ?? '下载失败');
    } catch (e) {
      return DownloadResult.failure(e.toString());
    } finally {
      _currentToken = null;
    }
  }

  void cancelCurrent() {
    _currentToken?.cancel();
    AppLogger.info('DownloadService', '取消当前下载');
  }

  static String generateFileName(String title, {String format = 'm4a'}) {
    final sanitized =
        title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
    final ext = format.startsWith('.') ? format : '.$format';
    return '$sanitized$ext';
  }

  static String buildSavePath(String directory, String fileName) {
    return path.join(directory, fileName);
  }

  @mustCallSuper
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    cancelCurrent();
    _dio.close();
    AppLogger.debug('DownloadService', '服务已释放');
  }
}

class CancellationToken {
  bool _isCancelled = false;
  final CancelToken _cancelToken = CancelToken();

  CancelToken get cancelToken => _cancelToken;
  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
    _cancelToken.cancel();
  }
}
