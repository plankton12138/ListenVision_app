import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/shared_storage_service.dart';
import '../../../services/bilibili_auth_service.dart';

class CurrentUser {
  final String username;
  final String? email;

  CurrentUser({required this.username, this.email});
}

final _storageProvider = Provider<SharedStorageService>((ref) {
  return SharedStorageService.instance;
});

final _bilibiliAuthProvider = Provider<BilibiliAuthService>((ref) {
  return BilibiliAuthService();
});

final isLoggedInProvider = Provider<bool>((ref) {
  final storage = ref.watch(_storageProvider);
  final token = storage.getString('auth_token');
  return token != null && token.isNotEmpty;
});

final currentUserProvider = Provider<CurrentUser?>((ref) {
  final storage = ref.watch(_storageProvider);
  final token = storage.getString('auth_token');
  if (token == null || token.isEmpty) return null;
  final username = storage.getString('current_username') ?? '用户';
  final email = storage.getString('current_email');
  return CurrentUser(username: username, email: email);
});

final bilibiliAccountProvider = FutureProvider<BilibiliAccount?>((ref) {
  final bilibiliAuth = ref.watch(_bilibiliAuthProvider);
  return bilibiliAuth.getStoredAccount();
});

final bilibiliBoundProvider = FutureProvider<bool>((ref) {
  final bilibiliAuth = ref.watch(_bilibiliAuthProvider);
  return bilibiliAuth.isBound();
});

final authTokenProvider = Provider<String?>((ref) {
  final storage = ref.watch(_storageProvider);
  return storage.getString('auth_token');
});