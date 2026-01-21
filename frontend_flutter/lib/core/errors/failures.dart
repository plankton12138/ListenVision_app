/// 失败类定义
///
/// Clean Architecture 中的 Failures 层：
/// - 由 Repository 层抛出
/// - 由 UseCase 层捕获并处理或向上传递
/// - 使用 sealed 类确保类型安全

/// 基础失败类
///
/// 所有 Failure 的基类
sealed class Failure {
  final String? message;
  final String? code;
  final Object? exception;

  const Failure({
    this.message,
    this.code,
    this.exception,
  });

  @override
  String toString() {
    final msg = message ?? 'An error occurred';
    return 'Failure: $msg${code != null ? ' (code: $code)' : ''}';
  }
}

// ==================== 网络相关失败 ====================

/// 网络失败
final class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message,
    super.code,
    super.exception,
  });

  /// 请求失败
  const NetworkFailure.requestFailed({super.message, super.exception})
      : super(code: 'REQUEST_FAILED');

  /// 请求超时
  const NetworkFailure.timeout({super.message, super.exception})
      : super(code: 'TIMEOUT');

  /// 无网络连接
  const NetworkFailure.noConnection({super.message, super.exception})
      : super(code: 'NO_CONNECTION');

  /// 响应无效
  const NetworkFailure.invalidResponse({super.message, super.exception})
      : super(code: 'INVALID_RESPONSE');
}

// ==================== 服务器相关失败 ====================

/// 服务器失败
final class ServerFailure extends Failure {
  const ServerFailure({
    super.message,
    super.code,
    super.exception,
  });

  /// 服务器内部错误
  const ServerFailure.internalError({super.message, super.exception})
      : super(code: 'INTERNAL_ERROR');

  /// 资源未找到
  const ServerFailure.notFound({super.message, super.exception})
      : super(code: 'NOT_FOUND');

  /// 未授权
  const ServerFailure.unauthorized({super.message, super.exception})
      : super(code: 'UNAUTHORIZED');

  /// 禁止访问
  const ServerFailure.forbidden({super.message, super.exception})
      : super(code: 'FORBIDDEN');
}

// ==================== 认证相关失败 ====================

/// 认证失败
final class AuthFailure extends Failure {
  const AuthFailure({
    super.message,
    super.code,
    super.exception,
  });

  /// 凭证无效
  const AuthFailure.invalidCredentials({super.message, super.exception})
      : super(code: 'INVALID_CREDENTIALS');

  /// Token 过期
  const AuthFailure.tokenExpired({super.message, super.exception})
      : super(code: 'TOKEN_EXPIRED');

  /// Token 无效
  const AuthFailure.tokenInvalid({super.message, super.exception})
      : super(code: 'TOKEN_INVALID');

  /// 未登录
  const AuthFailure.notLoggedIn({super.message, super.exception})
      : super(code: 'NOT_LOGGED_IN');

  /// 登录失败
  const AuthFailure.loginFailed({super.message, super.exception})
      : super(code: 'LOGIN_FAILED');
}

// ==================== 数据相关失败 ====================

/// 数据失败
final class DataFailure extends Failure {
  const DataFailure({
    super.message,
    super.code,
    super.exception,
  });

  /// 解析错误
  const DataFailure.parseError({super.message, super.exception})
      : super(code: 'PARSE_ERROR');

  /// 缓存错误
  const DataFailure.cacheError({super.message, super.exception})
      : super(code: 'CACHE_ERROR');

  /// 数据未找到
  const DataFailure.notFound({super.message, super.exception})
      : super(code: 'DATA_NOT_FOUND');

  /// 数据无效
  const DataFailure.invalidData({super.message, super.exception})
      : super(code: 'INVALID_DATA');
}

// ==================== 本地存储失败 ====================

/// 存储失败
final class StorageFailure extends Failure {
  const StorageFailure({
    super.message,
    super.code,
    super.exception,
  });

  /// 数据库错误
  const StorageFailure.databaseError({super.message, super.exception})
      : super(code: 'DATABASE_ERROR');

  /// 文件错误
  const StorageFailure.fileError({super.message, super.exception})
      : super(code: 'FILE_ERROR');

  /// 权限被拒绝
  const StorageFailure.permissionDenied({super.message, super.exception})
      : super(code: 'PERMISSION_DENIED');

  /// 空间不足
  const StorageFailure.noSpace({super.message, super.exception})
      : super(code: 'NO_SPACE');
}

// ==================== 业务逻辑失败 ====================

/// 业务失败
final class BusinessFailure extends Failure {
  const BusinessFailure({
    super.message,
    super.code,
    super.exception,
  });

  /// 歌单未找到
  const BusinessFailure.playlistNotFound({super.message, super.exception})
      : super(code: 'PLAYLIST_NOT_FOUND');

  /// 歌单已存在
  const BusinessFailure.playlistAlreadyExists({super.message, super.exception})
      : super(code: 'PLAYLIST_ALREADY_EXISTS');

  /// 已收藏
  const BusinessFailure.alreadyFavorited({super.message, super.exception})
      : super(code: 'ALREADY_FAVORITED');

  /// 音频不在歌单中
  const BusinessFailure.audioNotInPlaylist({super.message, super.exception})
      : super(code: 'AUDIO_NOT_IN_PLAYLIST');

  /// 无效操作
  const BusinessFailure.invalidOperation({super.message, super.exception})
      : super(code: 'INVALID_OPERATION');
}

// ==================== B站相关失败 ====================

/// B站 API 失败
final class BilibiliFailure extends Failure {
  const BilibiliFailure({
    super.message,
    super.code,
    super.exception,
  });

  /// QR 码过期
  const BilibiliFailure.qrCodeExpired({super.message, super.exception})
      : super(code: 'QR_CODE_EXPIRED');

  /// QR 码待扫描
  const BilibiliFailure.qrCodePending({super.message, super.exception})
      : super(code: 'QR_CODE_PENDING');

  /// 视频未找到
  const BilibiliFailure.videoNotFound({super.message, super.exception})
      : super(code: 'VIDEO_NOT_FOUND');

  /// 音频未找到
  const BilibiliFailure.audioNotFound({super.message, super.exception})
      : super(code: 'AUDIO_NOT_FOUND');

  /// Cookie 无效
  const BilibiliFailure.cookieInvalid({super.message, super.exception})
      : super(code: 'COOKIE_INVALID');

  /// 请求限流
  const BilibiliFailure.rateLimit({super.message, super.exception})
      : super(code: 'RATE_LIMIT');

  /// API 错误
  const BilibiliFailure.apiError({super.message, super.exception})
      : super(code: 'API_ERROR');
}
