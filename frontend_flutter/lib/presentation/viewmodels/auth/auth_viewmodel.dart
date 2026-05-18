import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/shared_storage_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';

enum AuthStatus { initial, loading, authenticated, error }

class AuthState {
  final AuthStatus status;
  final String? error;
  final String? token;

  const AuthState({this.status = AuthStatus.initial, this.error, this.token});

  AuthState copyWith({AuthStatus? status, String? error, String? token}) {
    return AuthState(
      status: status ?? this.status,
      error: error,
      token: token ?? this.token,
    );
  }
}

class AuthViewModel extends Notifier<AuthState> {
  @override
  AuthState build() {
    return const AuthState();
  }

  String? get currentToken => state.token ?? SharedStorageService.instance.getString('auth_token');

  Future<bool> login({required String email, required String password}) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      final apiClient = ApiClient();
      final response = await apiClient.post(Endpoints.login, data: {
        'email': email,
        'password': password,
      });

      final token = response['token'] as String?;
      if (token != null) {
        final storage = SharedStorageService.instance;
        await storage.setString('auth_token', token);
        final username = response['username'] as String? ?? email;
        await storage.setString('current_username', username);
        if (response['email'] != null) {
          await storage.setString('current_email', response['email'] as String);
        }
        state = AuthState(status: AuthStatus.authenticated, token: token);
        AppLogger.info('AuthViewModel', '登录成功: $email');
        return true;
      }
      state = const AuthState(status: AuthStatus.error, error: '登录失败');
      return false;
    } catch (e) {
      AppLogger.error('AuthViewModel', '登录失败: $e');
      state = AuthState(status: AuthStatus.error, error: e.toString());
      return false;
    }
  }

  Future<bool> sendVerificationCode(String email) async {
    try {
      final apiClient = ApiClient();
      await apiClient.post(Endpoints.sendVerificationCode, data: {'email': email});
      AppLogger.info('AuthViewModel', '验证码已发送: $email');
      return true;
    } catch (e) {
      AppLogger.error('AuthViewModel', '发送验证码失败: $e');
      return false;
    }
  }

  Future<bool> verifyEmail({
    required String email,
    required String code,
    required String password,
    required String username,
  }) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      final apiClient = ApiClient();
      final response = await apiClient.post(Endpoints.register, data: {
        'email': email,
        'code': code,
        'password': password,
        'username': username,
      });

      final token = response['token'] as String?;
      if (token != null) {
        final storage = SharedStorageService.instance;
        await storage.setString('auth_token', token);
        await storage.setString('current_username', username);
        await storage.setString('current_email', email);
        state = AuthState(status: AuthStatus.authenticated, token: token);
        AppLogger.info('AuthViewModel', '注册成功: $email');
        return true;
      }
      state = const AuthState(status: AuthStatus.error, error: '注册失败');
      return false;
    } catch (e) {
      AppLogger.error('AuthViewModel', '注册失败: $e');
      state = AuthState(status: AuthStatus.error, error: e.toString());
      return false;
    }
  }

  Future<bool> resetPassword({required String email, required String code, required String newPassword}) async {
    try {
      final apiClient = ApiClient();
      await apiClient.post(Endpoints.resetPassword, data: {
        'email': email,
        'code': code,
        'new_password': newPassword,
      });
      AppLogger.info('AuthViewModel', '密码重置成功: $email');
      return true;
    } catch (e) {
      AppLogger.error('AuthViewModel', '密码重置失败: $e');
      return false;
    }
  }

  Future<void> logout() async {
    final storage = SharedStorageService.instance;
    await storage.remove('auth_token');
    await storage.remove('current_username');
    await storage.remove('current_email');
    state = const AuthState();
    AppLogger.info('AuthViewModel', '已退出登录');
  }

  Future<bool> deleteAccount() async {
    try {
      final token = currentToken;
      if (token == null) return false;
      final apiClient = ApiClient();
      await apiClient.delete(Endpoints.deleteAccount);
      await logout();
      AppLogger.info('AuthViewModel', '账号已注销');
      return true;
    } catch (e) {
      AppLogger.error('AuthViewModel', '注销账号失败: $e');
      return false;
    }
  }
}

final authViewModelProvider = NotifierProvider<AuthViewModel, AuthState>(AuthViewModel.new);