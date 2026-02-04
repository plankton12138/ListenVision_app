import '../../core/constants/storage_constants.dart';
import '../../core/storage/shared_storage_service.dart';
import '../../core/utils/app_logger.dart';
import '../../models/user.dart';
import '../api/backend_api_client.dart';

/// 认证仓库
///
/// 负责用户认证相关的数据操作
class AuthRepository {
  final BackendApiClient _apiClient;
  final SharedStorageService _storage;

  AuthRepository({
    BackendApiClient? apiClient,
    SharedStorageService? storage,
  })  : _apiClient = apiClient ?? BackendApiClient(),
        _storage = storage ?? SharedStorageService.instance;

  // ==================== 认证操作 ====================

  /// 用户登录
  Future<User> login(LoginRequest request) async {
    try {
      AppLogger.info('AuthRepository', '开始登录: ${request.email}');
      final data = await _apiClient.login(request);

      final user = User.fromDto({
        ...data['user'],
        'token': data['token'],
      });

      // 保存 token 和用户信息
      await _storage.setToken(data['token'] as String);
      await _storage.setUserId(user.id);
      await _storage.setJson(StorageKeys.userInfo, user.toDto());

      AppLogger.info('AuthRepository', '登录成功: ${user.username}');
      return user;
    } catch (e) {
      AppLogger.error('AuthRepository', '登录失败: $e');
      rethrow;
    }
  }

  /// 用户注册
  Future<User> register(RegisterRequest request) async {
    try {
      AppLogger.info('AuthRepository', '开始注册: ${request.email}');
      final data = await _apiClient.register(request);

      final user = User.fromDto({
        ...data['user'],
        'token': data['token'],
      });

      // 保存 token 和用户信息
      await _storage.setToken(data['token'] as String);
      await _storage.setUserId(user.id);
      await _storage.setJson(StorageKeys.userInfo, user.toDto());

      AppLogger.info('AuthRepository', '注册成功: ${user.username}');
      return user;
    } catch (e) {
      AppLogger.error('AuthRepository', '注册失败: $e');
      rethrow;
    }
  }

  /// 获取当前用户信息
  Future<User?> getCurrentUser() async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        return User.guest;
      }

      final data = await _apiClient.getCurrentUser();
      return User.fromDto(data);
    } catch (e) {
      AppLogger.error('AuthRepository', '获取用户信息失败: $e');
      // 失败时返回缓存的用户信息
      return _getCachedUser();
    }
  }

  /// 发送验证码
  Future<bool> sendVerificationCode(String email) async {
    try {
      await _apiClient.sendVerificationCode(email);
      AppLogger.info('AuthRepository', '验证码发送成功: $email');
      return true;
    } catch (e) {
      AppLogger.error('AuthRepository', '发送验证码失败: $e');
      rethrow;
    }
  }

  /// 重置密码
  Future<bool> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      await _apiClient.resetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
      );
      AppLogger.info('AuthRepository', '密码重置成功: $email');
      return true;
    } catch (e) {
      AppLogger.error('AuthRepository', '重置密码失败: $e');
      rethrow;
    }
  }

  /// 退出登录
  Future<void> logout() async {
    try {
      AppLogger.info('AuthRepository', '开始登出');
      await _storage.clearToken();
      await _storage.remove(StorageKeys.keyUserId);
      await _storage.remove(StorageKeys.userInfo);
      AppLogger.info('AuthRepository', '登出成功');
    } catch (e) {
      AppLogger.error('AuthRepository', '登出失败: $e');
      rethrow;
    }
  }

  /// 检查登录状态
  Future<User?> checkLoginStatus() async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        return User.guest;
      }

      // 尝试从缓存获取用户信息
      final cachedUser = _getCachedUser();
      if (cachedUser != null && !cachedUser.isGuest) {
        return cachedUser;
      }

      // 缓存无效时从服务器获取
      return await getCurrentUser();
    } catch (e) {
      AppLogger.error('AuthRepository', '检查登录状态失败: $e');
      return User.guest;
    }
  }

  // ==================== Token 管理 ====================

  /// 保存 token
  Future<void> saveToken(String token) async {
    await _storage.setToken(token);
    AppLogger.debug('AuthRepository', 'Token 已保存');
  }

  /// 获取 token
  Future<String?> getToken() async => _getToken();

  /// 获取当前 token (内部方法)
  Future<String?> _getToken() async {
    return _storage.getToken();
  }

  /// 清除 token
  Future<void> clearToken() async {
    await _storage.clearToken();
    AppLogger.debug('AuthRepository', 'Token 已清除');
  }

  // ==================== 私有方法 ====================

  /// 获取缓存的用户信息
  User? _getCachedUser() {
    try {
      final json = _storage.getJson(StorageKeys.userInfo);
      if (json == null) return null;
      return User.fromDto(json);
    } catch (e) {
      AppLogger.error('AuthRepository', '获取缓存用户失败: $e');
      return null;
    }
  }

  /// 判断是否有有效的 token
  Future<bool> hasValidToken() async {
    final token = await _getToken();
    return token != null && token.isNotEmpty;
  }
}
