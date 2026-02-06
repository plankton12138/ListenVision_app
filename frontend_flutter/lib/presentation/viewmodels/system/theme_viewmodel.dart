import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/app_logger.dart';
import '../../../core/storage/shared_storage_service.dart';

part 'theme_viewmodel.g.dart';

/// 主题模式枚举
enum AppThemeMode {
  light,
  dark,
  system,
}

/// 主题 ViewModel
///
/// 负责应用的主题切换（浅色/深色/跟随系统）
@Riverpod(keepAlive: true)
class ThemeViewModel extends _$ThemeViewModel {
  static const _themeKey = 'app_theme_mode';
  late final SharedStorageService _storage;

  @override
  AppThemeMode build() {
    _storage = ref.watch(themeStorageServiceProvider);
    _loadThemePreference();
    return AppThemeMode.light;
  }

  /// 切换主题（light <-> dark）
  void toggleTheme() {
    state = state == AppThemeMode.light ? AppThemeMode.dark : AppThemeMode.light;
    _saveThemePreference();
    AppLogger.info('ThemeViewModel', '主题切换为: ${state.name}');
  }

  /// 设置为浅色模式
  void setLightMode() {
    state = AppThemeMode.light;
    _saveThemePreference();
  }

  /// 设置为深色模式
  void setDarkMode() {
    state = AppThemeMode.dark;
    _saveThemePreference();
  }

  /// 设置为跟随系统
  void setSystemMode() {
    state = AppThemeMode.system;
    _saveThemePreference();
  }

  /// 从本地存储加载主题偏好
  Future<void> _loadThemePreference() async {
    try {
      final savedMode = await _storage.getString(_themeKey);
      if (savedMode != null) {
        state = AppThemeMode.values.byName(savedMode);
        AppLogger.info('ThemeViewModel', '主题加载: $savedMode');
      }
    } catch (e) {
      AppLogger.error('ThemeViewModel', '加载主题失败: $e');
    }
  }

  /// 保存主题偏好到本地存储
  Future<void> _saveThemePreference() async {
    try {
      await _storage.setString(_themeKey, state.name);
      AppLogger.debug('ThemeViewModel', '主题保存: ${state.name}');
    } catch (e) {
      AppLogger.error('ThemeViewModel', '保存主题失败: $e');
    }
  }
}

/// Provider 定义
@riverpod
SharedStorageService themeStorageService(Ref ref) {
  return SharedStorageService.instance;
}

/// 将 AppThemeMode 转换为 Flutter 的 ThemeMode
extension AppThemeModeExtension on AppThemeMode {
  ThemeMode get flutterThemeMode {
    switch (this) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}
