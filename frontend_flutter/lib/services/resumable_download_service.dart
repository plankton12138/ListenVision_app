import 'dart:io';

import 'package:dio/dio.dart';

import '../core/utils/app_logger.dart';

/// 断点续传下载结果
class ResumableDownloadResult {
  /// 是否成功
  final bool success;

  /// 保存的文件路径
  final String? filePath;

  /// 错误信息
  final String? error;

  /// 错误类型
  final ResumableDownloadErrorType? errorType;

  /// 文件 ETag
  final String? etag;

  /// Last-Modified 头
  final String? lastModified;

  /// 文件总大小
  final int? fileSize;

  const ResumableDownloadResult({
    required this.success,
    this.filePath,
    this.error,
    this.errorType,
    this.etag,
    this.lastModified,
    this.fileSize,
  });

  /// 成功结果
  factory ResumableDownloadResult.success({
    required String filePath,
    String? etag,
    String? lastModified,
    int? fileSize,
  }) {
    return ResumableDownloadResult(
      success: true,
      filePath: filePath,
      etag: etag,
      lastModified: lastModified,
      fileSize: fileSize,
    );
  }

  /// 失败结果
  factory ResumableDownloadResult.failure(String error) {
    return ResumableDownloadResult(success: false, error: error);
  }

  /// 失败结果（带类型）
  factory ResumableDownloadResult.failureWithType(
    String error,
    ResumableDownloadErrorType errorType,
  ) {
    return ResumableDownloadResult(
      success: false,
      error: error,
      errorType: errorType,
    );
  }

  @override
  String toString() => success ? '下载成功: $filePath' : '下载失败: $error';
}

/// 断点续传错误类型
enum ResumableDownloadErrorType {
  etagMismatch,
  notResumable,
  cancelled,
  network,
  unknown,
}

/// 断点续传下载服务
///
/// 支持通过 HTTP Range 请求实现断点续传。
/// 适用于支持 Range 请求的 HTTP 下载接口。
class ResumableDownloadService {
  final Dio _dio;
  final String baseUrl;

  bool _disposed = false;
  CancellationToken? _currentToken;

  ResumableDownloadService({
    Dio? dio,
    String? baseUrl,
  })  : _dio = dio ?? Dio(),
        baseUrl = baseUrl ?? const String.fromEnvironment('API_BASE_URL');

  /// 下载音频文件（支持断点续传）
  ///
  /// [bvid] 视频 BVID
  /// [savePath] 保存路径
  /// [downloadedBytes] 已下载字节数（用于断点续传）
  /// [onProgress] 进度回调 (当前字节数, 总字节数, 进度百分比)
  ///
  /// 返回 ResumableDownloadResult，包含 ETag 和 Last-Modified 用于续传验证
  Future<ResumableDownloadResult> downloadAudio({
    required String bvid,
    required String savePath,
    int downloadedBytes = 0,
    String? etag,
    String? lastModified,
    void Function(int current, int total, int percent)? onProgress,
  }) async {
    if (_disposed) {
      return ResumableDownloadResult.failureWithType(
        '服务已释放',
        ResumableDownloadErrorType.unknown,
      );
    }

    _currentToken = CancellationToken();
    final token = _currentToken!;

    try {
      final resumeInfo = downloadedBytes > 0 ? '(断点续传: $downloadedBytes bytes)' : '';
      AppLogger.info(
        'ResumableDownloadService',
        '开始下载: $bvid -> $savePath $resumeInfo',
      );

      // 构建下载 URL（使用支持 Range 的接口）
      final url = '$baseUrl/bilibili/download-range/$bvid';

      // 检查是否有临时文件
      File? tempFile;
      int currentBytes = downloadedBytes;

      if (downloadedBytes > 0) {
        // 断点续传模式
        tempFile = File('$savePath.tmp');

        if (await tempFile.exists()) {
          currentBytes = await tempFile.length();
          AppLogger.info(
            'ResumableDownloadService',
            '找到临时文件，从 $currentBytes 字节继续',
          );
        } else {
          currentBytes = 0;
        }
      }

      // 设置请求头
      final headers = <String, dynamic>{};

      if (currentBytes > 0) {
        // 添加 Range 请求头
        headers['Range'] = 'bytes=$currentBytes-';
        AppLogger.debug('ResumableDownloadService', 'Range: bytes=$currentBytes-');
      }

      // 如果有 ETag，添加 If-Range 或 If-Match
      if (currentBytes > 0 && etag != null) {
        headers['If-Match'] = etag;
        AppLogger.debug('ResumableDownloadService', 'If-Match: $etag');
      }

      // 发起请求
      final response = await _dio.get(
        url,
        options: Options(
          responseType: ResponseType.stream,
          headers: headers,
        ),
        cancelToken: token.cancelToken,
      );

      if (_disposed || token.isCancelled) {
        return ResumableDownloadResult.failureWithType(
          '下载已取消',
          ResumableDownloadErrorType.cancelled,
        );
      }

      // 获取响应信息
      final statusCode = response.statusCode ?? 200;
      final contentRange = response.headers['Content-Range']?.first;
      final responseEtag = response.headers['Etag']?.first;
      final responseLastModified = response.headers['Last-Modified']?.first;

      // 解析 Content-Range 获取文件总大小
      // 格式: bytes 0-1048575/1048576 或 bytes 512000-1048575/1048576
      int? totalBytes;
      if (contentRange != null) {
        final parts = contentRange.split('/');
        if (parts.length == 2) {
          totalBytes = int.tryParse(parts[1]);
        }
      }

      // 从 Content-Length 获取剩余字节数
      final contentLength = response.headers['Content-Length']?.first;
      final remainingBytes = contentLength != null ? int.tryParse(contentLength) : null;

      if (totalBytes == null && remainingBytes != null) {
        totalBytes = currentBytes + remainingBytes;
      }

      AppLogger.info(
        'ResumableDownloadService',
        '响应状态: $statusCode, 范围: $contentRange, 总大小: $totalBytes',
      );

      // 根据响应状态决定处理方式
      if (statusCode == 206 || (statusCode == 200 && currentBytes == 0)) {
        // 206 Partial Content 或 200 OK (首次下载)
        return await _downloadStream(
          response.data.stream,
          savePath,
          currentBytes,
          totalBytes,
          token,
          onProgress,
          responseEtag,
          responseLastModified,
        );
      } else if (statusCode == 412) {
        // Precondition Failed - 文件已更改，需要重新下载
        AppLogger.warn('ResumableDownloadService', '文件已更改 (ETag 不匹配)，重新下载');
        return ResumableDownloadResult.failureWithType(
          'ETag 不匹配，需重新下载',
          ResumableDownloadErrorType.etagMismatch,
        );
      } else {
        return ResumableDownloadResult.failureWithType(
          '服务器返回状态码: $statusCode',
          ResumableDownloadErrorType.notResumable,
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        AppLogger.info('ResumableDownloadService', '下载已取消');
        return ResumableDownloadResult.failureWithType(
          '下载已取消',
          ResumableDownloadErrorType.cancelled,
        );
      }
      final error = e.message ?? '网络请求失败';
      AppLogger.error('ResumableDownloadService', '下载失败: $error');
      return ResumableDownloadResult.failureWithType(
        error,
        ResumableDownloadErrorType.network,
      );
    } catch (e) {
      AppLogger.error('ResumableDownloadService', '下载失败: $e');
      return ResumableDownloadResult.failureWithType(
        e.toString(),
        ResumableDownloadErrorType.unknown,
      );
    } finally {
      _currentToken = null;
    }
  }

  /// 处理下载流
  Future<ResumableDownloadResult> _downloadStream(
    Stream<List<int>> stream,
    String savePath,
    int currentBytes,
    int? totalBytes,
    CancellationToken token,
    void Function(int current, int total, int percent)? onProgress,
    String? etag,
    String? lastModified,
  ) async {
    // 创建临时文件
    final tempFile = File('$savePath.tmp');
    final file = await tempFile.open(mode: FileMode.append);

    try {
      int lastProgressReport = 0;

      await for (final data in stream) {
        if (_disposed || token.isCancelled) {
          await file.close();
          return ResumableDownloadResult.failureWithType(
            '下载已取消',
            ResumableDownloadErrorType.cancelled,
          );
        }

        // 写入数据
        await file.writeFrom(data);
        currentBytes += data.length;

        // 报告进度
        if (totalBytes != null && totalBytes > 0) {
          final percent = ((currentBytes / totalBytes) * 100).floor();
          if (percent > lastProgressReport || percent % 5 == 0) {
            lastProgressReport = percent;
            onProgress?.call(currentBytes, totalBytes, percent);
          }
        }
      }

      await file.close();

      // 下载完成，重命名临时文件
      if (await tempFile.exists()) {
        // 删除旧文件（如果存在）
        final targetFile = File(savePath);
        if (await targetFile.exists()) {
          await targetFile.delete();
        }

        // 重命名临时文件
        await tempFile.rename(savePath);
      }

      AppLogger.info(
        'ResumableDownloadService',
        '下载完成: $savePath ($currentBytes bytes)',
      );

      // 最终进度报告
      onProgress?.call(currentBytes, totalBytes ?? currentBytes, 100);

      return ResumableDownloadResult.success(
        filePath: savePath,
        etag: etag,
        lastModified: lastModified,
        fileSize: currentBytes,
      );
    } catch (e) {
      await file.close();
      AppLogger.error('ResumableDownloadService', '下载流处理失败: $e');
      // 保留临时文件以便续传
      return ResumableDownloadResult.failureWithType(
        e.toString(),
        ResumableDownloadErrorType.unknown,
      );
    }
  }

  /// 验证服务器是否支持断点续传
  ///
  /// 返回支持的信息，包含是否支持、文件大小、ETag 等
  Future<Map<String, dynamic>> checkResumableSupport(String bvid) async {
    try {
      final url = '$baseUrl/bilibili/download-range/$bvid';

      final response = await _dio.head(
        url,
        options: Options(
          headers: {'Range': 'bytes=0-0'}, // 请求 1 字节测试
        ),
      );

      final acceptRanges = response.headers['Accept-Ranges']?.first;
      final contentLength = response.headers['Content-Length']?.first;
      final etag = response.headers['Etag']?.first;
      final lastModified = response.headers['Last-Modified']?.first;

      final supportsRange = acceptRanges == 'bytes' || response.statusCode == 206;

      return {
        'supportsRange': supportsRange,
        'contentLength': contentLength != null ? int.tryParse(contentLength) : null,
        'etag': etag,
        'lastModified': lastModified,
        'statusCode': response.statusCode,
      };
    } catch (e) {
      AppLogger.error('ResumableDownloadService', '检查断点续传支持失败: $e');
      return {
        'supportsRange': false,
        'error': e.toString(),
      };
    }
  }

  /// 取消当前下载
  void cancelCurrent() {
    _currentToken?.cancel();
    AppLogger.info('ResumableDownloadService', '取消当前下载');
  }

  /// 释放资源
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    cancelCurrent();
    _dio.close();

    AppLogger.debug('ResumableDownloadService', '服务已释放');
  }
}

/// 下载取消令牌
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
