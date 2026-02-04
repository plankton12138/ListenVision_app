import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_logger.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/api/backend_api_client.dart' show LoginRequest, RegisterRequest;
import '../../../models/user.dart';

part 'auth_viewmodel.freezed.dart';
part 'auth_viewmodel.g.dart';

/// 认证状态
@freezed
class AuthState with _$AuthState {
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
class AuthViewModel extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthViewModel(this._repository) : super(const AuthState.initial()) {
    _initialize();
  }

  /// 初始化：检查登录状态
  Future<void> _initialize() async {
    try {
      AppLogger.info('AuthViewModel', '初始化，检查登录状态');
      final user = await _repository.checkLoginStatus();

      if (user != null && !user.isGuest) {
        final token = await _repository.getToken();
        state = AuthState.authenticated(user: user, token: token);
        AppLogger.info('AuthViewModel', '用户已登录: ${user.username}');
      } else {
        state = const AuthState.unauthenticated();
        AppLogger.debug('AuthViewModel', '用户未登录');
      }
    } catch (e) {
      AppLogger.error('AuthViewModel', '初始化失败: $e');
      state = const AuthState.unauthenticated();
    }
  }

  /// 用户登录
  Future<bool> login({required String email, required String password}) async {
    try {
      state = const AuthState.loading();
      AppLogger.info('AuthViewModel', '开始登录: $email');

      final user = await _repository.login(
        LoginRequest(email: email, password: password),
      );

      AppLogger.logUserAction(
        'Auth',
        '登录成功',
        parameters: {'userId': user.id, 'username': user.username},
        userId: user.id,
      );

      state = AuthState.authenticated(user: user, token: user.token);
      return true;
    } catch (e) {
      AppLogger.error('AuthViewModel', '登录失败: $e');
      state = AuthState.error(message: e.toString());
      return false;
    }
  }

  /// 用户注册
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    String? captchaCode,
  }) async {
    try {
      state = const AuthState.loading();
      AppLogger.info('AuthViewModel', '开始注册: $email');

      final user = await _repository.register(
        RegisterRequest(
          username: username,
          email: email,
          password: password,
          captchaCode: captchaCode,
        ),
      );

      AppLogger.logUserAction(
        'Auth',
        '注册成功',
        parameters: {'userId': user.id, 'username': user.username},
        userId: user.id,
      );

      state = AuthState.authenticated(user: user, token: user.token);
      return true;
    } catch (e) {
      AppLogger.error('AuthViewModel', '注册失败: $e');
      state = AuthState.error(message: e.toString());
      return false;
    }
  }

  /// 发送验证码
  Future<bool> sendVerificationCode(String email) async {
    try {
      AppLogger.info('AuthViewModel', '发送验证码: $email');
      await _repository.sendVerificationCode(email);
      return true;
    } catch (e) {
      AppLogger.error('AuthViewModel', '发送验证码失败: $e');
      state = AuthState.error(message: e.toString());
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
      await _repository.resetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
      );
      return true;
    } catch (e) {
      AppLogger.error('AuthViewModel', '重置密码失败: $e');
      state = AuthState.error(message: e.toString());
      return false;
    }
  }

  /// 用户登出
  Future<void> logout() async {
    try {
      final userId = whenOrNull(authenticated: (user, token) => user.id);
      AppLogger.logUserAction(
        'Auth',
        '用户登出',
        parameters: {'userId': userId},
        userId: userId,
      );

      await _repository.logout();
      state = const AuthState.unauthenticated();

      AppLogger.info('AuthViewModel', '登出完成');
    } catch (e) {
      AppLogger.error('AuthViewModel', '登出失败: $e');
      // 即使失败也切换到未登录状态
      state = const AuthState.unauthenticated();
    }
  }

  /// 获取当前状态（公开 getter）
  AuthState get authState => state;

  /// 获取当前用户
  User? get currentUser {
    return whenOrNull(authenticated: (user, token) => user);
  }

  /// 获取当前 token
  String? get currentToken {
    return state.maybeWhen(
      authenticated: (user, token) => token ?? user.token,
      orElse: () => null,
    );
  }

  /// 是否已登录
  bool get isLoggedIn {
    return state.maybeWhen(
      authenticated: (_, __) => true,
      orElse: () => false,
    );
  }

  /// 清除错误状态
  void clearError() {
    state.maybeWhen(
      error: (_) => state = const AuthState.unauthenticated(),
      orElse: () {},
    );
  }

  /// 模式匹配辅助方法
  T? whenOrNull<T>({
    T Function(User user, String? token)? authenticated,
  }) {
    return state.maybeWhen(
      authenticated: authenticated,
      orElse: () => null,
    );
  }
}

/// Provider 定义
@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  return AuthRepository();
}

@riverpod
AuthViewModel authViewModel(AuthViewModelRef ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthViewModel(repository);
}

/// 当前用户 Provider
@riverpod
User? currentUser(CurrentUserRef ref) {
  return ref.watch(authViewModelProvider).currentUser;
}

/// 当前 token Provider（用于 Dio）
@riverpod
String? authToken(AuthTokenRef ref) {
  return ref.watch(authViewModelProvider).currentToken;
}

/// 是否已登录 Provider
@riverpod
bool isLoggedIn(IsLoggedInRef ref) {
  return ref.watch(authViewModelProvider).isLoggedIn;
}
