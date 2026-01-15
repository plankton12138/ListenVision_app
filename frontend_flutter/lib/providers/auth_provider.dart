
import 'dart:convert';

import 'package:demo/models/user_model.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  static const _authKey = 'user_data';

  User? get user => _user;
  bool get isLoggedIn => _user != null;

  AuthProvider() {
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_authKey);
    
    if (userData != null) {
      _user = User.fromJson(jsonDecode(userData));
      notifyListeners();
    }
  }

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

  Future<void> logout() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authKey);
    notifyListeners();
  }
}