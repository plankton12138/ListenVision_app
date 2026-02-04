import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/storage_constants.dart';
import '../utils/app_logger.dart';

/// 安全存储服务
///
/// 封装 flutter_secure_storage，用于存储敏感数据
class SecureStorageService {
  /// 单例实例
  static SecureStorageService? _instance;

  /// FlutterSecureStorage 实例
  late final FlutterSecureStorage _storage;

  /// 私有构造函数
  SecureStorageService._internal({
    FlutterSecureStorage? storage,
  }) : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
            );

  /// 获取单例
  static SecureStorageService get instance {
    _instance ??= SecureStorageService._internal();
    return _instance!;
  }

  /// 初始化（可传入自定义配置）
  static Future<SecureStorageService> init({
    FlutterSecureStorage? storage,
  }) async {
    final instance = SecureStorageService._internal(storage: storage);
    AppLogger.info('SecureStorageService', '初始化完成');
    return instance;
  }

  // ==================== 基础方法 ====================

  /// 写入字符串
  Future<bool> setString(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      AppLogger.debug('SecureStorageService', '写入字符串: $key');
      return true;
    } catch (e) {
      AppLogger.error('SecureStorageService', '写入字符串失败: $key, $e');
      return false;
    }
  }

  /// 读取字符串
  Future<String?> getString(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      AppLogger.error('SecureStorageService', '读取字符串失败: $key, $e');
      return null;
    }
  }

  /// 写入 JSON
  Future<bool> setJson(String key, Map<String, dynamic> value) async {
    try {
      return await setString(key, jsonEncode(value));
    } catch (e) {
      AppLogger.error('SecureStorageService', '写入 JSON 失败: $key, $e');
      return false;
    }
  }

  /// 读取 JSON
  Future<Map<String, dynamic>?> getJson(String key) async {
    try {
      final str = await getString(key);
      if (str == null) return null;
      return jsonDecode(str) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('SecureStorageService', '读取 JSON 失败: $key, $e');
      return null;
    }
  }

  /// 删除键
  Future<bool> remove(String key) async {
    try {
      await _storage.delete(key: key);
      AppLogger.debug('SecureStorageService', '删除键: $key');
      return true;
    } catch (e) {
      AppLogger.error('SecureStorageService', '删除键失败: $key, $e');
      return false;
    }
  }

  /// 检查键是否存在
  Future<bool> containsKey(String key) async {
    try {
      return await _storage.containsKey(key: key);
    } catch (e) {
      AppLogger.error('SecureStorageService', '检查键失败: $key, $e');
      return false;
    }
  }

  /// 清空所有数据
  Future<bool> clear() async {
    try {
      await _storage.deleteAll();
      AppLogger.info('SecureStorageService', '清空所有数据');
      return true;
    } catch (e) {
      AppLogger.error('SecureStorageService', '清空数据失败: $e');
      return false;
    }
  }

  /// 读取所有键值对
  Future<Map<String, String>> readAll() async {
    try {
      return await _storage.readAll();
    } catch (e) {
      AppLogger.error('SecureStorageService', '读取所有数据失败: $e');
      return {};
    }
  }

  // ==================== B站相关快捷方法 ====================

  /// 保存 B站 Cookie
  Future<bool> setBilibiliCookie(String cookie) =>
      setString(StorageKeys.bilibiliCookie, cookie);

  /// 获取 B站 Cookie
  Future<String?> getBilibiliCookie() => getString(StorageKeys.bilibiliCookie);

  /// 删除 B站 Cookie
  Future<bool> clearBilibiliCookie() => remove(StorageKeys.bilibiliCookie);

  /// 保存 B站账号信息
  Future<bool> setBilibiliAccount(Map<String, dynamic> account) =>
      setJson(StorageKeys.bilibiliAccount, account);

  /// 获取 B站账号信息
  Future<Map<String, dynamic>?> getBilibiliAccount() =>
      getJson(StorageKeys.bilibiliAccount);

  /// 删除 B站账号信息
  Future<bool> clearBilibiliAccount() => remove(StorageKeys.bilibiliAccount);

  /// 保存 B站绑定状态
  Future<bool> setBilibiliBound(bool bound) =>
      setString(StorageKeys.bilibiliBound, bound.toString());

  /// 获取 B站绑定状态
  Future<bool> isBilibiliBound() async {
    final value = await getString(StorageKeys.bilibiliBound);
    return value == 'true';
  }
}
