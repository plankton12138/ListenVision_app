import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../core/utils/app_logger.dart';
import '../core/constants/api_constants.dart';

/// 下载状态
enum DownloadStatus {
  /// 等待中
  pending,
  /// 下载中
  downloading,
  /// 已暂停
  paused,
  /// 已完成
  completed,
  /// 失败
  failed,
}

/// 下载进度信息
class DownloadProgress {
  /// 进度百分比 (0-100)
  final int percent;

  /// 当前阶段 (fetching/converting/transferring/complete/error)
  final String stage;

  /// 阶段描述信息
  final String message;

  const DownloadProgress({
    required this.percent,
    required this.stage,
    required this.message,
  });

  @override
  String toString() => 'DownloadProgress($percent% - $stage: $message)';

  /// 是否完成
  bool get isComplete => percent >= 100;

  /// 是否失败
  bool get isFailed => stage == 'error';

  /// 是否下载中
  bool get isDownloading => stage == 'fetching' || stage == 'converting' || stage == 'transferring';
}

/// 下载结果
class DownloadResult {
  /// 是否成功
  final bool success;

  /// 保存的文件路径
  final String? filePath;

  /// 错误信息
  final String? error;

  const DownloadResult({
    required this.success,
    this.filePath,
    this.error,
  });

  /// 成功结果
  factory DownloadResult.success(String filePath) {
    return DownloadResult(success: true, filePath: filePath);
  }

  /// 失败结果
  factory DownloadResult.failure(String error) {
    return DownloadResult(success: false, error: error);
  }

  @override
  String toString() => success ? '下载成功: $filePath' : '下载失败: $error';
}

/// 音频下载服务
///
/// 封装 B站音频下载功能，通过后端 API 实现带元数据的音频下载。
///
/// 职责：
/// - 通过后端 SSE 接口下载音频（带实时进度）
/// - 处理文件保存逻辑
/// - 提供进度回调
///
/// 注意：此服务仅负责下载核心功能，不包含任务管理、UI 更新等业务逻辑。
class DownloadService {
  // ==================== 私有字段 ====================

  /// Dio 实例（用于 SSE 下载）
  final Dio _dio;

  /// 后端基础 URL
  final String baseUrl;

  /// 是否已销毁
  bool _disposed = false;

  /// 当前下载取消令牌
  CancellationToken? _currentToken;

  // ==================== 构造函数 ====================

  DownloadService({
    Dio? dio,
    String? baseUrl,
  })  : _dio = dio ?? Dio(),
        baseUrl = baseUrl ?? ApiConstants.fullBaseUrl {
    AppLogger.debug('DownloadService', '服务已创建');
  }

  // ==================== 下载操作 ====================

  /// 下载音频文件（带元数据写入和实时进度）
  ///
  /// 使用 SSE 接收实时进度事件和分块文件传输：
  /// - progress: { percent, stage, message } - 进度更新
  /// - fileStart: { fileName, contentType, totalChunks } - 文件开始
  /// - fileChunk: { chunkIndex, totalChunks, data(base64) } - 文件数据块
  /// - fileEnd: { fileName } - 文件传输完成
  /// - error: { error } - 错误信息
  ///
  /// [bvid] 视频 BVID
  /// [savePath] 保存路径
  /// [format] 输出格式，默认 'mp3'，可选 'm4a'
  /// [onProgress] 进度回调
  ///
  /// 返回 DownloadResult，包含成功/失败状态和文件路径或错误信息
  Future<DownloadResult> downloadAudio({
    required String bvid,
    required String savePath,
    String format = 'mp3',
    void Function(DownloadProgress)? onProgress,
  }) async {
    if (_disposed) {
      return DownloadResult.failure('服务已释放');
    }

    // 创建新的取消令牌
    _currentToken = CancellationToken();
    final token = _currentToken!;

    try {
      AppLogger.info('DownloadService', '开始下载: $bvid -> $savePath');

      // 报告开始状态
      onProgress?.call(const DownloadProgress(
        percent: 0,
        stage: 'pending',
        message: '准备中...',
      ));

      // 构建下载 URL
      final url = '$baseUrl/bilibili/download/$bvid?format=$format';

      // 设置 SSE 请求
      final response = await _dio.get(
        url,
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            'Accept': 'text/event-stream',
          },
        ),
        cancelToken: token.cancelToken,
      );

      if (_disposed || token.isCancelled) {
        return DownloadResult.failure('下载已取消');
      }

      // 解析 SSE 流
      await _processSSEStream(
        response.data.stream,
        savePath,
        onProgress,
        token,
      );

      // 验证文件是否创建成功
      final file = File(savePath);
      if (await file.exists()) {
        final fileSize = await file.length();
        AppLogger.info('DownloadService', '下载成功: $savePath ($fileSize bytes)');
        return DownloadResult.success(savePath);
      } else {
        return DownloadResult.failure('文件未创建');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        AppLogger.info('DownloadService', '下载已取消');
        return DownloadResult.failure('下载已取消');
      }
      final error = e.message ?? '网络请求失败';
      AppLogger.error('DownloadService', '下载失败: $error');
      return DownloadResult.failure(error);
    } catch (e) {
      AppLogger.error('DownloadService', '下载失败: $e');
      return DownloadResult.failure(e.toString());
    } finally {
      _currentToken = null;
    }
  }

  /// 处理 SSE 流
  Future<void> _processSSEStream(
    Stream<List<int>> stream,
    String savePath,
    void Function(DownloadProgress)? onProgress,
    CancellationToken token,
  ) async {
    String? currentEvent;
    String? currentData;
    final buffer = StringBuffer();

    // 文件接收状态
    int? totalChunks;
    int receivedChunks = 0;
    final List<Uint8List> fileChunks = [];
    int lastProgressReport = 0;

    await for (final data in stream) {
      if (_disposed || token.isCancelled) {
        throw Exception('下载已取消');
      }

      buffer.write(String.fromCharCodes(data));
      final content = buffer.toString();
      final lines = content.split('\n');

      // 处理完整的行
      int processed = 0;
      for (int i = 0; i < lines.length - 1; i++) {
        final line = lines[i];

        // 解析 SSE 事件类型行 (event: xxx)
        if (line.startsWith('event: ')) {
          currentEvent = line.substring(7).trim();
        }
        // 解析 SSE 数据行 (data: xxx)
        else if (line.startsWith('data: ')) {
          currentData = line.substring(6);

          if (currentData.isNotEmpty) {
            await _processSSEEvent(
              currentEvent,
              currentData,
              savePath,
              onProgress,
              token,
              // 文件状态
              (
                getTotalChunks: () => totalChunks,
                setTotalChunks: (v) => totalChunks = v,
                clearChunks: () => fileChunks.clear(),
                addChunk: (chunk) => fileChunks.add(chunk),
                incrementReceivedChunks: () => receivedChunks++,
                getReceivedChunks: () => receivedChunks,
                getLastProgressReport: () => lastProgressReport,
                setLastProgressReport: (v) => lastProgressReport = v,
                getFileChunks: () => fileChunks,
              ),
            );
          }
        }
        // 空行表示事件结束
        else if (line.isEmpty) {
          currentEvent = null;
          currentData = null;
        }

        processed += line.length + 1;
      }

      // 清理已处理的内容
      if (processed > 0) {
        buffer.clear();
        if (lines.length > 1 && lines.last.isNotEmpty) {
          buffer.write(lines.last);
        }
      }
    }
  }

  /// 处理单个 SSE 事件
  Future<void> _processSSEEvent(
    String? eventType,
    String? data,
    String savePath,
    void Function(DownloadProgress)? onProgress,
    CancellationToken token,
    ({
      int? Function() getTotalChunks,
      void Function(int?) setTotalChunks,
      void Function() clearChunks,
      void Function(Uint8List) addChunk,
      void Function() incrementReceivedChunks,
      int Function() getReceivedChunks,
      int Function() getLastProgressReport,
      void Function(int) setLastProgressReport,
      List<Uint8List> Function() getFileChunks,
    }) fileState,
  ) async {
    try {
      final json = jsonDecode(data!) as Map<String, dynamic>;
      final type = eventType ?? json['type'] as String?;

      if (type == 'progress' || json.containsKey('percent')) {
        // 进度更新
        final percent = json['percent'] as int? ?? 0;
        final stage = json['stage'] as String? ?? '';
        final message = json['message'] as String? ?? '';
        onProgress?.call(DownloadProgress(
          percent: percent,
          stage: stage,
          message: message,
        ));
        AppLogger.debug('下载进度', '$percent% - $stage - $message');
      } else if (type == 'fileStart') {
        fileState.setTotalChunks(json['totalChunks'] as int?);
        fileState.clearChunks();
        AppLogger.info('文件传输', '开始接收: ${json['fileName']}, 分块数: ${json['totalChunks']}');
      } else if (type == 'fileChunk') {
        // 文件数据块
        if (json['receiving'] as bool? ?? true) {
          final chunkData = json['data'] as String? ?? '';
          final chunkBytes = base64Decode(chunkData);
          fileState.addChunk(chunkBytes);
          fileState.incrementReceivedChunks();

          // 报告文件传输进度 (95% -> 99%)
          final total = fileState.getTotalChunks();
          final received = fileState.getReceivedChunks();
          if (total != null && total > 0) {
            final fileProgress = 95 + (received * 4 ~/ total);
            if (fileProgress > fileState.getLastProgressReport()) {
              fileState.setLastProgressReport(fileProgress);
              onProgress?.call(DownloadProgress(
                percent: fileProgress,
                stage: 'transferring',
                message: '接收文件中... $received/$total',
              ));
            }
            AppLogger.debug('文件传输', '进度: $received/$total');
          }
        }
      } else if (type == 'fileEnd') {
        // 文件传输完成
        AppLogger.info('文件传输', '传输完成，合并 ${fileState.getFileChunks().length} 个块');

        // 合并所有块
        final chunks = fileState.getFileChunks();
        final totalSize = chunks.fold<int>(0, (sum, chunk) => sum + chunk.length);
        final fileBytes = Uint8List(totalSize);
        int offset = 0;
        for (final chunk in chunks) {
          fileBytes.setRange(offset, offset + chunk.length, chunk);
          offset += chunk.length;
        }

        // 写入文件
        final file = File(savePath);
        await file.writeAsBytes(fileBytes);

        AppLogger.info('音频下载', '保存成功: $savePath ($totalSize bytes)');
        onProgress?.call(const DownloadProgress(
          percent: 100,
          stage: 'complete',
          message: '下载完成',
        ));
      } else if (type == 'error') {
        final error = json['error'] as String? ?? '未知错误';
        AppLogger.error('音频下载', '错误: $error');
        throw Exception(error);
      }
    } catch (e) {
      AppLogger.error('音频下载', '解析事件失败: $e, data: $data');
    }
  }

  /// 获取下载 URL（不带进度回调的简单下载）
  ///
  /// [bvid] 视频 BVID
  /// [format] 输出格式，默认 'mp3'
  String getDownloadUrl(String bvid, {String format = 'mp3'}) {
    return '$baseUrl/bilibili/download/$bvid?format=$format';
  }

  /// 简单下载（不使用 SSE，直接保存文件）
  ///
  /// [bvid] 视频 BVID
  /// [savePath] 保存路径
  /// [format] 输出格式，默认 'mp3'
  /// [onProgress] 进度回调 (接收到的字节数, 总字节数)
  Future<DownloadResult> simpleDownload({
    required String bvid,
    required String savePath,
    String format = 'mp3',
    void Function(int received, int total)? onProgress,
  }) async {
    if (_disposed) {
      return DownloadResult.failure('服务已释放');
    }

    _currentToken = CancellationToken();
    final token = _currentToken!;

    try {
      final url = getDownloadUrl(bvid, format: format);

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

  /// 取消当前下载
  void cancelCurrent() {
    _currentToken?.cancel();
    AppLogger.info('DownloadService', '取消当前下载');
  }

  /// 生成默认文件名
  ///
  /// [title] 音频标题
  /// [format] 文件格式
  static String generateFileName(String title, {String format = 'mp3'}) {
    // 清理非法字符
    final sanitized = title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
    final ext = format.startsWith('.') ? format : '.$format';
    return '$sanitized$ext';
  }

  /// 构建完整保存路径
  ///
  /// [directory] 保存目录
  /// [fileName] 文件名
  static String buildSavePath(String directory, String fileName) {
    return path.join(directory, fileName);
  }

  // ==================== 资源释放 ====================

  /// 释放资源
  ///
  /// 调用后对象不可再使用。会取消当前进行中的下载。
  @mustCallSuper
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    // 取消当前下载
    cancelCurrent();

    // 关闭 Dio
    _dio.close();

    AppLogger.debug('DownloadService', '服务已释放');
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
