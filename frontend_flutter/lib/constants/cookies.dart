import 'package:demo/config/local_config.dart';
import 'package:flutter/foundation.dart';

// Cookie 管理类 - 负责 Bilibili Cookie 的轮换和获取
//
// 工作原理：
// 1. 从 LocalConfig 读取配置的 Cookies
// 2. 每进行 10 次搜索，自动轮换到下一个 Cookie
// 3. 循环使用所有配置的 Cookies，避免单个 Cookie 被限流
class AppCookies {
  static int _searchCount = 0;
  static const int maxSearchCount = 10000;

  /// 获取当前应该使用的 Cookie
  ///
  /// 返回逻辑：
  /// - 如果未配置 Cookie，返回空字符串
  /// - 如果已配置，根据搜索次数轮换使用不同的 Cookie
  static String getCurrentCookie() {
    // 获取本地配置的 Cookies
    final cookies = LocalConfig.bilibiliCookies;

    // 如果未配置任何 Cookie，返回空并打印警告
    if (cookies.isEmpty) {
      debugPrint('⚠️ 警告: 未配置任何 Bilibili Cookie，请在 local_config.dart 中配置');
      return '';
    }

    // 过滤出非空的 Cookie
    final validCookies = cookies.where((c) => c.isNotEmpty).toList();

    if (validCookies.isEmpty) {
      debugPrint('⚠️ 警告: 所有 Cookie 都为空，请在 local_config.dart 中填入真实的 Cookie');
      return '';
    }

    // 根据搜索次数轮换 Cookie
    // 例如: 0-9 次用 Cookie[0], 10-19 次用 Cookie[1], ...
    final index = (_searchCount ~/ 10) % validCookies.length;
    return validCookies[index];
  }

  /// 增加搜索计数，用于触发 Cookie 轮换
  static void incrementSearchCount() {
    _searchCount = (_searchCount + 1) % maxSearchCount;
  }
}