import '../errors/exceptions.dart';
import 'app_logger.dart';

/// 下载错误类型
enum DownloadErrorType {
  network,      // 网络错误
  timeout,      // 超时
  conversion,   // 转换错误
  checksum,     // 校验失败
  storage,      // 存储空间不足
  server,       // 服务器错误
  unknown,      // 未知错误
}

/// 下载错误信息
class DownloadError {
  final DownloadErrorType type;
  final String message;
  final String? suggestion;
  final String? technicalDetails;

  const DownloadError({
    required this.type,
    required this.message,
    this.suggestion,
    this.technicalDetails,
  });

  factory DownloadError.fromException(Object exception) {
    if (exception is ApiException) {
      final message = exception.message.toLowerCase();

      // 网络相关错误
      if (message.contains('network') || message.contains('connection')) {
        return DownloadError(
          type: DownloadErrorType.network,
          message: '网络连接失败',
          suggestion: '📶 请检查网络连接后重试',
          technicalDetails: exception.message,
        );
      }

      // 超时错误
      if (message.contains('timeout') || message.contains('超时')) {
        return DownloadError(
          type: DownloadErrorType.timeout,
          message: '下载超时',
          suggestion: '⏱️ 服务器响应时间过长，请稍后重试',
          technicalDetails: exception.message,
        );
      }

      // 转换错误
      if (message.contains('转换') || message.contains('convert')) {
        return DownloadError(
          type: DownloadErrorType.conversion,
          message: '音频转换失败',
          suggestion: '🔄 可能是源视频问题，请尝试其他视频',
          technicalDetails: exception.message,
        );
      }

      // 校验错误
      if (message.contains('校验') || message.contains('checksum')) {
        return DownloadError(
          type: DownloadErrorType.checksum,
          message: '文件校验失败',
          suggestion: '🔄 文件可能损坏，正在自动重新下载...',
          technicalDetails: exception.message,
        );
      }

      // 服务器错误
      if (exception.statusCode >= 500) {
        return DownloadError(
          type: DownloadErrorType.server,
          message: '服务器错误 (${exception.statusCode})',
          suggestion: '🖥️ 服务器暂时不可用，请稍后重试',
          technicalDetails: exception.message,
        );
      }

      // 默认 API 错误
      return DownloadError(
        type: DownloadErrorType.server,
        message: exception.message,
        suggestion: '🔄 请稍后重试',
        technicalDetails: 'Status: ${exception.statusCode}',
      );
    }

    // 通用错误
    return DownloadError(
      type: DownloadErrorType.unknown,
      message: exception.toString(),
      suggestion: '🔄 请重试或联系支持',
      technicalDetails: exception.runtimeType.toString(),
    );
  }

  /// 获取用户友好的完整错误消息
  String get userMessage {
    final buffer = StringBuffer();
    buffer.write('❌ ');
    buffer.write(message);
    if (suggestion != null) {
      buffer.write('\n\n');
      buffer.write(suggestion);
    }
    return buffer.toString();
  }

  /// 获取简短错误消息（用于 Toast）
  String get shortMessage => message;

  @override
  String toString() => userMessage;
}

/// 下载状态提示
class DownloadStatusMessage {
  static String forProgress(int percent, String stage, String message) {
    // 根据阶段返回不同的提示
    switch (stage) {
      case 'fetching_info':
        return '📋 正在获取视频信息...';
      case 'downloading_audio':
        return '⬇️ 正在下载音频... $percent%';
      case 'downloading_cover':
        return '🖼️ 正在下载封面...';
      case 'converting':
        return '🔄 正在转换格式... $percent%';
      case 'transferring':
        return '📦 正在接收文件... $percent%';
      case 'verifying':
        return '✅ 正在验证文件...';
      case 'complete':
        return '✅ 下载完成！';
      default:
        return message.isNotEmpty ? message : '下载中... $percent%';
    }
  }

  static String forError(DownloadError error) {
    return error.userMessage;
  }

  /// 获取可操作的提示
  static String getSuggestion(DownloadErrorType type) {
    switch (type) {
      case DownloadErrorType.network:
        return '检查网络连接';
      case DownloadErrorType.timeout:
        return '稍后重试';
      case DownloadErrorType.conversion:
        return '尝试其他视频';
      case DownloadErrorType.checksum:
        return '重新下载';
      case DownloadErrorType.storage:
        return '清理存储空间';
      case DownloadErrorType.server:
        return '稍后重试';
      case DownloadErrorType.unknown:
        return '联系支持';
    }
  }

  /// 判断错误是否可重试
  static bool isRetryable(DownloadErrorType type) {
    return switch (type) {
      DownloadErrorType.network || DownloadErrorType.timeout || DownloadErrorType.server => true,
      DownloadErrorType.checksum => true, // 校验失败也可以重试
      DownloadErrorType.conversion => false, // 转换失败通常重试无用
      DownloadErrorType.storage => false, // 存储不足需要用户处理
      DownloadErrorType.unknown => true,
    };
  }
}

/// 下载阶段描述
class DownloadStageDescription {
  static const descriptions = {
    'pending': '准备中',
    'fetching_info': '获取信息',
    'downloading_audio': '下载音频',
    'downloading_cover': '下载封面',
    'converting': '转换格式',
    'transferring': '传输文件',
    'verifying': '验证文件',
    'complete': '完成',
  };

  static String getDescription(String stage) {
    return descriptions[stage] ?? stage;
  }

  /// 获取阶段图标
  static String getIcon(String stage) {
    switch (stage) {
      case 'pending':
        return '⏳';
      case 'fetching_info':
        return '📋';
      case 'downloading_audio':
        return '⬇️';
      case 'downloading_cover':
        return '🖼️';
      case 'converting':
        return '🔄';
      case 'transferring':
        return '📦';
      case 'verifying':
        return '✅';
      case 'complete':
        return '✨';
      default:
        return '📥';
    }
  }
}

/// 下载进度信息
class DownloadProgress {
  final int percent;
  final String stage;
  final String message;
  final String? requestId;

  const DownloadProgress({
    required this.percent,
    required this.stage,
    required this.message,
    this.requestId,
  });

  /// 获取格式化的进度显示
  String get formatted {
    final icon = DownloadStageDescription.getIcon(stage);
    final description = DownloadStageDescription.getDescription(stage);
    return '$icon $description $percent%';
  }

  /// 获取简短显示
  String get short {
    return '$percent%';
  }

  @override
  String toString() => formatted;
}

/// 日志辅助
class DownloadLogger {
  static void logStart(String bvid, String format) {
    AppLogger.info('Download', '开始下载: bvid=$bvid, format=$format');
  }

  static void logProgress(DownloadProgress progress) {
    if (progress.percent % 20 == 0 || progress.percent == 100) {
      AppLogger.debug('Download', '${progress.stage}: ${progress.percent}%');
    }
  }

  static void logSuccess(String bvid, String savePath) {
    AppLogger.info('Download', '下载成功: bvid=$bvid, path=$savePath');
  }

  static void logError(String bvid, DownloadError error) {
    AppLogger.error(
      'Download',
      '下载失败: bvid=$bvid, error=${error.message}',
      error: Exception(error.technicalDetails),
    );
  }
}
