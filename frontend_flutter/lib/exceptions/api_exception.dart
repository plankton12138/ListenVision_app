/// API 异常类
///
/// 用于表示 API 请求失败时的异常信息
class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException: $message (状态码: $statusCode)';
}
