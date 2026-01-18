import 'dart:convert';

import 'package:demo/models/user_model.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 用户认证状态管理
///
/// 负责管理用户的登录状态、用户信息持久化
class AuthProvider with ChangeNotifier {
  User? _user;
  static const _authKey = 'user_data';

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
      notifyListeners();
    }
  }

  /// 设置当前用户并持久化到本地
  Future<void> setUser(User user) async {
    _user = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authKey, jsonEncode({
      'id': user.id,
      'username': user.username,
      'email': user.email,
      'token': user.token,
    }));
    notifyListeners();
  }

  /// 用户登出，清除本地存储的用户信息
  Future<void> logout() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authKey);
    notifyListeners();
  }
}
