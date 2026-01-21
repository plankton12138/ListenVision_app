import 'dart:convert';

import 'package:demo/core/network/dio_provider.dart';
import 'package:demo/models/user_model.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 用户认证状态管理
///
/// 负责管理用户的登录状态、用户信息持久化
class AuthProvider with ChangeNotifier {
  User? _user;
  static const _authKey = 'user_data';
  static const _tokenKey = 'auth_token';  // 单独存储 token，方便 DioProvider 恢复

  User? get user => _user;
  bool get isLoggedIn => _user != null;

  AuthProvider() {
    _loadUser();
  }

  /// 从本地存储加载用户信息
  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_authKey);

    if (userData != null) {
      _user = User.fromJson(jsonDecode(userData));

      // 恢复 token 到 DioProvider
      if (_user?.token != null) {
        DioProvider.instance.updateToken(_user!.token);
        debugPrint('【AuthProvider】Token restored to DioProvider');
      }

      notifyListeners();
    }
  }

  /// 设置当前用户并持久化到本地
  Future<void> setUser(User user) async {
    _user = user;
    final prefs = await SharedPreferences.getInstance();

    // 保存完整用户信息
    await prefs.setString(_authKey, jsonEncode({
      'id': user.id,
      'username': user.username,
      'email': user.email,
      'token': user.token,
    }));

    // 单独保存 token，方便应用启动时快速恢复
    if (user.token != null) {
      await prefs.setString(_tokenKey, user.token!);
      // 同步更新 DioProvider 的 Authorization header
      DioProvider.instance.updateToken(user.token!);
      debugPrint('【AuthProvider】Token saved and updated to DioProvider');
    }

    notifyListeners();
  }

  /// 用户登出，清除本地存储的用户信息
  Future<void> logout() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authKey);
    await prefs.remove(_tokenKey);  // 同时清除 token

    // 清除 DioProvider 的 token
    DioProvider.instance.updateToken(null);
    debugPrint('【AuthProvider】Logged out, token cleared');

    notifyListeners();
  }
}
