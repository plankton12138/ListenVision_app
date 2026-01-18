import 'package:demo/theme/dark_mode.dart';
import 'package:demo/theme/light_mode.dart';
import 'package:flutter/material.dart';

/// 主题控制器
///
/// 负责管理应用的主题切换（浅色/深色模式）
class ThemeController extends ChangeNotifier {
  // 初始化为浅色模式
  ThemeData _themeData = lightMode;

  // 获取当前主题
  ThemeData get themeData => _themeData;

  // 是否为深色模式
  bool get isDarkMode => _themeData == darkMode;

  // 设置主题
  set themeData(ThemeData themeData) {
    _themeData = themeData;
    // 通知UI更新
    notifyListeners();
  }

  // 切换主题
  void toggleTheme() {
    if (_themeData == lightMode) {
      themeData = darkMode;
    } else {
      themeData = lightMode;
    }
  }
}
