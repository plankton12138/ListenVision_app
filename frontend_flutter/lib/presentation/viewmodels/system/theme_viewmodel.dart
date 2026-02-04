import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_logger.dart';
import '../../../core/storage/shared_storage_service.dart';
import '../../../presentation/theme/light_mode.dart';
import '../../../presentation/theme/dark_mode.dart';

part 'theme_viewmodel.g.dart';

/// 主题模式枚举
enum AppThemeMode {
  light,
  dark,
  system,
}

/// 主题 ViewModel
///
/// 负责应用的主题切换（浅色/深色模式）
class ThemeViewModel extends StateNotifier<ThemeData> {
  final SharedStorageService _storage;

  static const _themeKey = 'is_dark_mode';

  ThemeViewModel(this._storage) : super(lightMode) {
    _loadThemePreference();
  }

  /// 获取当前主题
  ThemeData get themeData => state;

  /// 是否为深色模式
  bool get isDarkMode => state == darkMode;

  /// 从本地存储加载主题偏好
  Future<void> _loadThemePreference() async {
    try {
      final isDark = await _storage.getBool(_themeKey);
      if (isDark == true) {
        state = darkMode;
      } else {
        state = lightMode;
      }
      AppLogger.info('ThemeViewModel', '主题加载: ${isDark == true ? "dark" : "light"}');
    } catch (e) {
      AppLogger.error('ThemeViewModel', '加载主题失败: $e');
      state = lightMode;
    }
  }

  /// 设置主题
  void setThemeData(ThemeData themeData) {
    state = themeData;
    _saveThemePreference();
  }

  /// 切换主题
  void toggleTheme() {
    if (state == lightMode) {
      state = darkMode;
    } else {
      state = lightMode;
    }
    _saveThemePreference();
  }

  /// 设置深色模式
  void setDarkMode() {
    state = darkMode;
    _saveThemePreference();
  }

  /// 设置浅色模式
  void setLightMode() {
    state = lightMode;
    _saveThemePreference();
  }

  /// 保存主题偏好到本地存储
  Future<void> _saveThemePreference() async {
    try {
      await _storage.setBool(_themeKey, isDarkMode);
      AppLogger.debug('ThemeViewModel', '主题保存: ${isDarkMode ? "dark" : "light"}');
    } catch (e) {
      AppLogger.error('ThemeViewModel', '保存主题失败: $e');
    }
  }
}

/// Provider 定义
@riverpod
SharedStorageService themeStorageService(ThemeStorageServiceRef ref) {
  return SharedStorageService.instance;
}

@riverpod
ThemeViewModel themeViewModel(ThemeViewModelRef ref) {
  final storage = ref.watch(themeStorageServiceProvider);
  return ThemeViewModel(storage);
}
