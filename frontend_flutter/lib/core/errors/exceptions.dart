/// 异常类定义
///
/// Clean Architecture 中的 Exceptions 层：
/// - 由 Data 层抛出
/// - 在 Repository 层被捕获并转换为 Failures
/// - 使用 freezed 生成不可变类（P2 阶段集成）

// ==================== 兼容旧代码 ====================

/// API 异常类（已废弃）
///
/// 从 exceptions/api_exception.dart 迁移
/// @Deprecated('请使用 ServerException 或 NetworkException')
class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException: $message (状态码: $statusCode)';
}

// ==================== 新异常体系 ====================

/// 基础异常类
///
/// 所有自定义异常的基类
abstract class AppException implements Exception {
  const AppException(this.message, [this.code]);

  final String message;
  final String? code;

  @override
  String toString() => 'AppException: $message${code != null ? ' (code: $code)' : ''}';
}

// ==================== 网络相关异常 ====================

/// 任务被取消异常
class TaskCanceledException extends AppException {
  const TaskCanceledException([String message = '任务已取消']) : super(message, 'TASK_CANCELED');
}

/// 网络请求异常
///
/// 请求失败、超时、无网络连接等情况
class NetworkException extends AppException {
  const NetworkException(super.message, [super.code]);

  factory NetworkException.requestFailed() {
    return const NetworkException('网络请求失败', 'NETWORK_REQUEST_FAILED');
  }

  factory NetworkException.timeout() {
    return const NetworkException('请求超时', 'NETWORK_TIMEOUT');
  }

  factory NetworkException.noConnection() {
    return const NetworkException('无网络连接', 'NO_CONNECTION');
  }

  factory NetworkException.invalidResponse() {
    return const NetworkException('无效的响应', 'INVALID_RESPONSE');
  }
}

// ==================== 服务器相关异常 ====================

/// 服务器异常
///
/// 服务器返回错误状态码
class ServerException extends AppException {
  const ServerException(super.message, [super.code, this.statusCode]);

  final int? statusCode;

  factory ServerException.internalError() {
    return const ServerException('服务器内部错误', 'SERVER_INTERNAL_ERROR', 500);
  }

  factory ServerException.notFound() {
    return const ServerException('资源不存在', 'NOT_FOUND', 404);
  }

  factory ServerException.unauthorized() {
    return const ServerException('未授权', 'UNAUTHORIZED', 401);
  }

  factory ServerException.forbidden() {
    return const ServerException('无权限访问', 'FORBIDDEN', 403);
  }

  factory ServerException.fromStatusCode(int statusCode) {
    return ServerException(
      '服务器错误: $statusCode',
      'SERVER_ERROR',
      statusCode,
    );
  }
}

// ==================== 认证相关异常 ====================

/// 认证异常
///
/// 登录失败、token 无效等
class AuthException extends AppException {
  const AuthException(super.message, [super.code]);

  factory AuthException.invalidCredentials() {
    return const AuthException('用户名或密码错误', 'INVALID_CREDENTIALS');
  }

  factory AuthException.tokenExpired() {
    return const AuthException('登录已过期，请重新登录', 'TOKEN_EXPIRED');
  }

  factory AuthException.tokenInvalid() {
    return const AuthException('无效的登录凭证', 'TOKEN_INVALID');
  }

  factory AuthException.notLoggedIn() {
    return const AuthException('请先登录', 'NOT_LOGGED_IN');
  }

  factory AuthException.loginFailed() {
    return const AuthException('登录失败', 'LOGIN_FAILED');
  }
}

// ==================== 数据相关异常 ====================

/// 数据异常
///
/// 数据解析错误、缓存错误等
class DataException extends AppException {
  const DataException(super.message, [super.code]);

  factory DataException.parseError() {
    return const DataException('数据解析失败', 'PARSE_ERROR');
  }

  factory DataException.cacheError() {
    return const DataException('缓存操作失败', 'CACHE_ERROR');
  }

  factory DataException.notFound() {
    return const DataException('数据不存在', 'DATA_NOT_FOUND');
  }

  factory DataException.invalidData() {
    return const DataException('无效的数据', 'INVALID_DATA');
  }
}

// ==================== 本地存储异常 ====================

/// 本地存储异常
///
/// 数据库操作、文件读写等错误
class StorageException extends AppException {
  const StorageException(super.message, [super.code]);

  factory StorageException.databaseError() {
    return const StorageException('数据库操作失败', 'DATABASE_ERROR');
  }

  factory StorageException.fileError() {
    return const StorageException('文件操作失败', 'FILE_ERROR');
  }

  factory StorageException.permissionDenied() {
    return const StorageException('没有存储权限', 'PERMISSION_DENIED');
  }

  factory StorageException.noSpace() {
    return const StorageException('存储空间不足', 'NO_SPACE');
  }
}

// ==================== 业务逻辑异常 ====================

/// 业务逻辑异常
///
/// 歌单不存在、已在收藏中等业务规则违反
class BusinessException extends AppException {
  const BusinessException(super.message, [super.code]);

  factory BusinessException.playlistNotFound() {
    return const BusinessException('歌单不存在', 'PLAYLIST_NOT_FOUND');
  }

  factory BusinessException.playlistAlreadyExists() {
    return const BusinessException('歌单已存在', 'PLAYLIST_ALREADY_EXISTS');
  }

  factory BusinessException.audioAlreadyFavorited() {
    return const BusinessException('已添加到我喜欢', 'ALREADY_FAVORITED');
  }

  factory BusinessException.audioNotInPlaylist() {
    return const BusinessException('音频不在歌单中', 'AUDIO_NOT_IN_PLAYLIST');
  }

  factory BusinessException.invalidOperation() {
    return const BusinessException('无效的操作', 'INVALID_OPERATION');
  }
}

// ==================== 验证异常 ====================

/// 参数验证异常
///
/// 输入参数验证失败、格式错误等
class ValidationException extends AppException {
  const ValidationException(super.message, [super.code]);

  factory ValidationException.invalidInput() {
    return const ValidationException('输入无效', 'INVALID_INPUT');
  }

  factory ValidationException.invalidEmail() {
    return const ValidationException('邮箱格式不正确', 'INVALID_EMAIL');
  }

  factory ValidationException.invalidPassword() {
    return const ValidationException('密码不符合要求', 'INVALID_PASSWORD');
  }

  factory ValidationException.fieldRequired(String fieldName) {
    return ValidationException('$fieldName 不能为空', 'FIELD_REQUIRED');
  }

  factory ValidationException.fieldTooLong(String fieldName, int maxLength) {
    return ValidationException(
      '$fieldName 长度不能超过 $maxLength 个字符',
      'FIELD_TOO_LONG',
    );
  }

  factory ValidationException.invalidFormat(String fieldName) {
    return ValidationException(
      '$fieldName 格式不正确',
      'INVALID_FORMAT',
    );
  }
}

// ==================== B站相关异常 ====================

/// B站 API 异常
///
/// B站接口调用失败、Cookie 失效等
class BilibiliException extends AppException {
  const BilibiliException(super.message, [super.code]);

  factory BilibiliException.qrCodeExpired() {
    return const BilibiliException('二维码已过期', 'QR_EXPIRED');
  }

  factory BilibiliException.qrCodePending() {
    return const BilibiliException('二维码待扫描', 'QR_PENDING');
  }

  factory BilibiliException.videoNotFound() {
    return const BilibiliException('视频不存在', 'VIDEO_NOT_FOUND');
  }

  factory BilibiliException.audioNotFound() {
    return const BilibiliException('音频不存在', 'AUDIO_NOT_FOUND');
  }

  factory BilibiliException.cookieInvalid() {
    return const BilibiliException('B站Cookie已失效，请重新绑定', 'COOKIE_INVALID');
  }

  factory BilibiliException.apiRateLimit() {
    return const BilibiliException('请求过于频繁，请稍后再试', 'RATE_LIMIT');
  }

  factory BilibiliException.apiError([String? detail]) {
    return BilibiliException(
      detail ?? 'B站API调用失败',
      'BILIBILI_API_ERROR',
    );
  }
}

// ==================== API 响应异常 ====================

/// API 响应异常
///
/// 从后端返回的错误响应创建的异常
class ApiServerException extends ServerException {
  const ApiServerException(super.message, [super.code, super.statusCode]);

  /// 从 API 响应创建异常
  /// [response] 后端返回的 error 字段
  /// [statusCode] HTTP 状态码
  factory ApiServerException.fromResponse({
    required String error,
    required int statusCode,
    String? code,
  }) {
    return ApiServerException(
      error,
      code ?? 'API_ERROR',
      statusCode,
    );
  }

  /// 从后端错误码映射到异常
  factory ApiServerException.fromErrorCode(String errorCode) {
    switch (errorCode) {
      case 'INVALID_TOKEN':
      case 'TOKEN_EXPIRED':
        return const ApiServerException('登录已过期', 'TOKEN_EXPIRED', 401);
      case 'NOT_LOGGED_IN':
        return const ApiServerException('请先登录', 'NOT_LOGGED_IN', 401);
      case 'FORBIDDEN':
        return const ApiServerException('无权限访问', 'FORBIDDEN', 403);
      case 'NOT_FOUND':
        return const ApiServerException('资源不存在', 'NOT_FOUND', 404);
      case 'VALIDATION_ERROR':
        return const ApiServerException('参数验证失败', 'VALIDATION_ERROR', 400);
      case 'RATE_LIMITED':
        return const ApiServerException('请求过于频繁', 'RATE_LIMITED', 429);
      default:
        return const ApiServerException('服务器错误', 'SERVER_ERROR', 500);
    }
  }
}
