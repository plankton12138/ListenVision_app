import 'package:demo/presentation/theme/dark_mode.dart';
import 'package:demo/presentation/theme/light_mode.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// 主题控制器
///
/// 负责管理应用的主题切换（浅色/深色模式）
class ThemeController extends ChangeNotifier {
  static const String _themeKey = 'is_dark_mode';

  // 初始化为浅色模式
  ThemeData _themeData = lightMode;

  // 获取当前主题
  ThemeData get themeData => _themeData;

  // 是否为深色模式
  bool get isDarkMode => _themeData == darkMode;

  ThemeController() {
    _loadThemePreference();
  }

  /// 从本地存储加载主题偏好
  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool(_themeKey) ?? false;
      _themeData = isDark ? darkMode : lightMode;
      debugPrint('【ThemeController】Theme loaded: ${isDark ? "dark" : "light"}');
      notifyListeners();
    } catch (e) {
      debugPrint('【ThemeController】Failed to load theme: $e');
    }
  }

  /// 设置主题并持久化
  set themeData(ThemeData themeData) {
    _themeData = themeData;
    _saveThemePreference();
    // 通知UI更新
    notifyListeners();
  }

  /// 保存主题偏好到本地存储
  Future<void> _saveThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, isDarkMode);
      debugPrint('【ThemeController】Theme saved: ${isDarkMode ? "dark" : "light"}');
    } catch (e) {
      debugPrint('【ThemeController】Failed to save theme: $e');
    }
  }

  /// 切换主题
  void toggleTheme() {
    if (_themeData == lightMode) {
      themeData = darkMode;
    } else {
      themeData = lightMode;
    }
  }
}
