import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/state/state_utils.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/api/backend_api_client.dart' show LoginRequest, RegisterRequest;
import '../../../data/sync/sync_worker_provider.dart';
import '../../../models/user.dart';
import 'platform_auth_viewmodel.dart';

part 'auth_viewmodel.freezed.dart';
part 'auth_viewmodel.g.dart';

/// 认证状态
@freezed
abstract class AuthState with _$AuthState {
  /// 初始状态
  const factory AuthState.initial() = AuthStateInitial;

  /// 加载中
  const factory AuthState.loading() = AuthStateLoading;

  /// 已认证
  const factory AuthState.authenticated({
    required User user,
    String? token,
  }) = AuthStateAuthenticated;

  /// 未认证
  const factory AuthState.unauthenticated() = AuthStateUnauthenticated;

  /// 错误
  const factory AuthState.error({
    required String message,
  }) = AuthStateError;
}

/// 主账号认证 ViewModel
///
/// 负责主账号（Email/Password）的登录、注册、登出
@Riverpod(keepAlive: true)
class AuthViewModel extends _$AuthViewModel {
  AuthRepository? _repository;

  @override
  Future<AuthState> build() async {
    _repository = ref.watch(authRepositoryProvider);

    try {
      AppLogger.info('AuthViewModel', '初始化，检查登录状态');
      final user = await _repository!.checkLoginStatus();

      if (user != null && !user.isGuest) {
        final token = await _repository!.getToken();
        AppLogger.info('AuthViewModel', '用户已登录: ${user.username}');

        // 启动同步工作器（通过读取 Provider 触发初始化）
        ref.read(syncWorkerProvider);

        return AuthState.authenticated(user: user, token: token);
      }
      AppLogger.debug('AuthViewModel', '用户未登录');
      return const AuthState.unauthenticated();
    } catch (e) {
      AppLogger.error('AuthViewModel', '初始化失败: $e');
      return const AuthState.unauthenticated();
    }
  }

  /// 用户登录
  Future<bool> login({required String email, required String password}) async {
    state = const AsyncLoading();
    try {
      AppLogger.info('AuthViewModel', '开始登录: $email');

      final user = await _repository!.login(
        LoginRequest(email: email, password: password),
      );

      AppLogger.logUserAction(
        'Auth',
        '登录成功',
        parameters: {'userId': user.id, 'username': user.username},
        userId: user.id,
      );

      if (!ref.mounted) return false;
      state = AsyncData(AuthState.authenticated(user: user, token: user.token));

      // 启动同步工作器（通过读取 Provider 触发初始化）
      ref.read(syncWorkerProvider);

      return true;
    } catch (e) {
      AppLogger.error('AuthViewModel', '登录失败: $e');
      if (!ref.mounted) return false;
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  /// 用户注册 - 发送验证码
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    String? captchaCode,
  }) async {
    state = const AsyncLoading();
    try {
      AppLogger.info('AuthViewModel', '开始注册: $email');

      await _repository!.register(
        RegisterRequest(
          username: username,
          email: email,
          password: password,
          captchaCode: captchaCode,
        ),
      );

      AppLogger.info('AuthViewModel', '验证码已发送: $email');
      
      if (!ref.mounted) return false;
      state = const AsyncData(AuthState.unauthenticated());
      return true;
    } catch (e) {
      AppLogger.error('AuthViewModel', '注册失败: $e');
      if (!ref.mounted) return false;
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  /// 验证邮箱并完成注册
  Future<bool> verifyEmail({
    required String email,
    required String code,
  }) async {
    state = const AsyncLoading();
    try {
      AppLogger.info('AuthViewModel', '验证邮箱: $email');

      final user = await _repository!.verifyEmail(email: email, code: code);

      AppLogger.logUserAction(
        'Auth',
        '注册成功',
        parameters: {'userId': user.id, 'username': user.username},
        userId: user.id,
      );

      if (!ref.mounted) return false;
      state = AsyncData(AuthState.authenticated(user: user, token: user.token));

      // 启动同步工作器
      ref.read(syncWorkerProvider);

      return true;
    } catch (e) {
      AppLogger.error('AuthViewModel', '邮箱验证失败: $e');
      if (!ref.mounted) return false;
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  /// 发送验证码
  Future<bool> sendVerificationCode(String email) async {
    try {
      AppLogger.info('AuthViewModel', '发送验证码: $email');
      await _repository!.sendVerificationCode(email);
      return true;
    } catch (e) {
      AppLogger.error('AuthViewModel', '发送验证码失败: $e');
      if (!ref.mounted) return false;
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  /// 重置密码
  Future<bool> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      AppLogger.info('AuthViewModel', '重置密码: $email');
      await _repository!.resetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
      );
      return true;
    } catch (e) {
      AppLogger.error('AuthViewModel', '重置密码失败: $e');
      if (!ref.mounted) return false;
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  /// 用户登出
  Future<void> logout() async {
    try {
      final userId = state.valueOrNull?.whenOrNull(authenticated: (user, token) => user.id);
      AppLogger.logUserAction(
        'Auth',
        '用户登出',
        parameters: {'userId': userId},
        userId: userId,
      );

      await _repository!.logout();
      
      // 重置平台认证状态
      ref.read(platformAuthViewModelProvider.notifier).reset();
      
      if (!ref.mounted) return;
      state = const AsyncData(AuthState.unauthenticated());

      AppLogger.info('AuthViewModel', '登出完成');
    } catch (e) {
      AppLogger.error('AuthViewModel', '登出失败: $e');
      // 即使失败也切换到未登录状态
      if (!ref.mounted) return;
      state = const AsyncData(AuthState.unauthenticated());
    }
  }

  /// 注销账号
  Future<bool> deleteAccount() async {
    state = const AsyncLoading();
    try {
      final userId = state.valueOrNull?.whenOrNull(authenticated: (user, token) => user.id);
      AppLogger.logUserAction(
        'Auth',
        '注销账号',
        parameters: {'userId': userId},
        userId: userId,
      );

      await _repository!.deleteAccount();
      
      // 重置平台认证状态
      ref.read(platformAuthViewModelProvider.notifier).reset();
      
      if (!ref.mounted) return false;
      state = const AsyncData(AuthState.unauthenticated());

      AppLogger.info('AuthViewModel', '账号已注销');
      return true;
    } catch (e) {
      AppLogger.error('AuthViewModel', '注销账号失败: $e');
      if (!ref.mounted) return false;
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  /// 清除错误状态
  void clearError() {
    final current = state.valueOrNull;
    if (current is AuthStateError) {
      state = const AsyncData(AuthState.unauthenticated());
    }
  }

  /// 获取当前用户
  User? get currentUser {
    return state.valueOrNull?.whenOrNull(authenticated: (user, token) => user);
  }

  /// 获取当前 token
  String? get currentToken {
    return state.valueOrNull?.maybeWhen(
      authenticated: (user, token) => token ?? user.token,
      orElse: () => null,
    );
  }

  /// 是否已登录
  bool get isLoggedIn {
    return state.valueOrNull?.maybeWhen(
      authenticated: (_, __) => true,
      orElse: () => false,
    ) ?? false;
  }
}

/// Provider 定义
@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepository();
}

/// 当前用户 Provider
@riverpod
User? currentUser(Ref ref) {
  return ref.watch(authViewModelProvider).valueOrNull?.whenOrNull(
    authenticated: (user, token) => user,
  );
}

/// 当前 token Provider（用于 Dio）
@riverpod
String? authToken(Ref ref) {
  return ref.watch(authViewModelProvider).valueOrNull?.maybeWhen(
    authenticated: (user, token) => token ?? user.token,
    orElse: () => null,
  );
}

/// 是否已登录 Provider
@riverpod
bool isLoggedIn(Ref ref) {
  return ref.watch(authViewModelProvider).valueOrNull?.maybeWhen(
    authenticated: (_, __) => true,
    orElse: () => false,
  ) ?? false;
}
