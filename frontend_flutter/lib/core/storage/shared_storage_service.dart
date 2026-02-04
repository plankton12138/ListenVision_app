import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../constants/storage_constants.dart';
import '../utils/app_logger.dart';

/// 共享存储服务
///
/// 封装 SharedPreferences，提供类型安全的读写方法
class SharedStorageService {
  /// 单例实例
  static SharedStorageService? _instance;

  /// SharedPreferences 实例
  SharedPreferences? _prefs;

  /// 私有构造函数
  SharedStorageService._internal();

  /// 获取单例
  static SharedStorageService get instance {
    _instance ??= SharedStorageService._internal();
    return _instance!;
  }

  /// 初始化（必须在 main() 中调用）
  static Future<SharedStorageService> init() async {
    final instance = SharedStorageService.instance;
    instance._prefs = await SharedPreferences.getInstance();
    AppLogger.info('SharedStorageService', '初始化完成');
    return instance;
  }

  /// 获取 SharedPreferences 实例
  SharedPreferences get prefs {
    if (_prefs == null) {
      throw StateError('SharedStorageService 未初始化，请先调用 init()');
    }
    return _prefs!;
  }

  // ==================== 基础方法 ====================

  /// 写入字符串
  Future<bool> setString(String key, String value) async {
    try {
      final result = await prefs.setString(key, value);
      AppLogger.debug('SharedStorageService', '写入字符串: $key');
      return result;
    } catch (e) {
      AppLogger.error('SharedStorageService', '写入字符串失败: $key, $e');
      return false;
    }
  }

  /// 读取字符串
  String? getString(String key) {
    try {
      return prefs.getString(key);
    } catch (e) {
      AppLogger.error('SharedStorageService', '读取字符串失败: $key, $e');
      return null;
    }
  }

  /// 写入整数
  Future<bool> setInt(String key, int value) async {
    try {
      final result = await prefs.setInt(key, value);
      AppLogger.debug('SharedStorageService', '写入整数: $key = $value');
      return result;
    } catch (e) {
      AppLogger.error('SharedStorageService', '写入整数失败: $key, $e');
      return false;
    }
  }

  /// 读取整数
  int? getInt(String key) {
    try {
      return prefs.getInt(key);
    } catch (e) {
      AppLogger.error('SharedStorageService', '读取整数失败: $key, $e');
      return null;
    }
  }

  /// 写入布尔值
  Future<bool> setBool(String key, bool value) async {
    try {
      final result = await prefs.setBool(key, value);
      AppLogger.debug('SharedStorageService', '写入布尔: $key = $value');
      return result;
    } catch (e) {
      AppLogger.error('SharedStorageService', '写入布尔失败: $key, $e');
      return false;
    }
  }

  /// 读取布尔值
  bool? getBool(String key) {
    try {
      return prefs.getBool(key);
    } catch (e) {
      AppLogger.error('SharedStorageService', '读取布尔失败: $key, $e');
      return null;
    }
  }

  /// 写入双精度浮点数
  Future<bool> setDouble(String key, double value) async {
    try {
      final result = await prefs.setDouble(key, value);
      AppLogger.debug('SharedStorageService', '写入双精度: $key = $value');
      return result;
    } catch (e) {
      AppLogger.error('SharedStorageService', '写入双精度失败: $key, $e');
      return false;
    }
  }

  /// 读取双精度浮点数
  double? getDouble(String key) {
    try {
      return prefs.getDouble(key);
    } catch (e) {
      AppLogger.error('SharedStorageService', '读取双精度失败: $key, $e');
      return null;
    }
  }

  /// 写入 JSON 字符串
  Future<bool> setJson(String key, Map<String, dynamic> value) async {
    try {
      return await setString(key, jsonEncode(value));
    } catch (e) {
      AppLogger.error('SharedStorageService', '写入 JSON 失败: $key, $e');
      return false;
    }
  }

  /// 读取 JSON 字符串
  Map<String, dynamic>? getJson(String key) {
    try {
      final str = getString(key);
      if (str == null) return null;
      return jsonDecode(str) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('SharedStorageService', '读取 JSON 失败: $key, $e');
      return null;
    }
  }

  /// 写入 JSON 列表
  Future<bool> setJsonList(String key, List<dynamic> value) async {
    try {
      return await setString(key, jsonEncode(value));
    } catch (e) {
      AppLogger.error('SharedStorageService', '写入 JSON 列表失败: $key, $e');
      return false;
    }
  }

  /// 读取 JSON 列表
  List<dynamic>? getJsonList(String key) {
    try {
      final str = getString(key);
      if (str == null) return null;
      return jsonDecode(str) as List<dynamic>;
    } catch (e) {
      AppLogger.error('SharedStorageService', '读取 JSON 列表失败: $key, $e');
      return null;
    }
  }

  /// 删除键
  Future<bool> remove(String key) async {
    try {
      final result = await prefs.remove(key);
      AppLogger.debug('SharedStorageService', '删除键: $key');
      return result;
    } catch (e) {
      AppLogger.error('SharedStorageService', '删除键失败: $key, $e');
      return false;
    }
  }

  /// 检查键是否存在
  bool containsKey(String key) {
    return prefs.containsKey(key);
  }

  /// 清空所有数据
  Future<bool> clear() async {
    try {
      final result = await prefs.clear();
      AppLogger.info('SharedStorageService', '清空所有数据');
      return result;
    } catch (e) {
      AppLogger.error('SharedStorageService', '清空数据失败: $e');
      return false;
    }
  }

  // ==================== 认证相关快捷方法 ====================

  /// 保存 token
  Future<bool> setToken(String token) => setString(StorageKeys.keyToken, token);

  /// 获取 token
  String? getToken() => getString(StorageKeys.keyToken);

  /// 删除 token
  Future<bool> clearToken() => remove(StorageKeys.keyToken);

  /// 保存用户 ID
  Future<bool> setUserId(String id) => setString(StorageKeys.keyUserId, id);

  /// 获取用户 ID
  String? getUserId() => getString(StorageKeys.keyUserId);

  // ==================== 主题相关快捷方法 ====================

  /// 保存主题模式
  Future<bool> setThemeMode(String mode) => setString(StorageKeys.themeMode, mode);

  /// 获取主题模式
  String? getThemeMode() => getString(StorageKeys.themeMode);

  // ==================== 播放相关快捷方法 ====================

  /// 保存播放位置
  Future<bool> setPlaybackPosition(int position) => setInt(StorageKeys.playbackPosition, position);

  /// 获取播放位置
  int? getPlaybackPosition() => getInt(StorageKeys.playbackPosition);

  /// 保存播放音量
  Future<bool> setPlaybackVolume(double volume) => setDouble(StorageKeys.playbackVolume, volume);

  /// 获取播放音量
  double? getPlaybackVolume() => getDouble(StorageKeys.playbackVolume);

  /// 保存播放倍速
  Future<bool> setPlaybackSpeed(double speed) => setDouble(StorageKeys.playbackSpeed, speed);

  /// 获取播放倍速
  double? getPlaybackSpeed() => getDouble(StorageKeys.playbackSpeed);
}
