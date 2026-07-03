import '../../services/bilibili_auth_service.dart';

/// 认证仓库
///
/// 负责B站绑定状态相关的数据操作
class AuthRepository {
  final BilibiliAuthService _bilibiliAuth;

  AuthRepository({BilibiliAuthService? bilibiliAuth})
      : _bilibiliAuth = bilibiliAuth ?? BilibiliAuthService();

  // ==================== B站绑定状态 ====================

  /// 检查B站是否已绑定
  Future<bool> isBilibiliBound() => _bilibiliAuth.isBound();

  /// 获取B站账号信息
  Future<BilibiliAccount?> getBilibiliAccount() =>
      _bilibiliAuth.getStoredAccount();

  /// 解绑B站账号
  Future<void> unbindBilibili() => _bilibiliAuth.unbind();
}