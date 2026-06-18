import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/bilibili_auth_service.dart';

class CurrentUser {
  final String username;
  final String? email;

  CurrentUser({required this.username, this.email});
}

final _bilibiliAuthProvider = Provider<BilibiliAuthService>((ref) {
  return BilibiliAuthService();
});

/// 纯前端架构：无需登录，全部功能本地可用。
/// B站绑定为可选功能，不影响应用使用。
final isLoggedInProvider = Provider<bool>((ref) => true);

/// 当前用户信息（基于B站绑定状态）
final currentUserProvider = Provider<CurrentUser?>((ref) {
  return CurrentUser(username: '本地用户');
});

final bilibiliAccountProvider = FutureProvider<BilibiliAccount?>((ref) {
  final bilibiliAuth = ref.watch(_bilibiliAuthProvider);
  return bilibiliAuth.getStoredAccount();
});

final bilibiliBoundProvider = FutureProvider<bool>((ref) {
  final bilibiliAuth = ref.watch(_bilibiliAuthProvider);
  return bilibiliAuth.isBound();
});
