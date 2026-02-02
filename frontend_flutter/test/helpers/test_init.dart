/// 测试初始化辅助工具
///
/// 提供统一的测试环境初始化方法，确保所有测试正确 mock 原生插件

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 测试初始化辅助类
class TestHelpers {
  /// 初始化 SharedPreferences mock
  ///
  /// 在每个测试用例开始前调用，确保 SharedPreferences 正确 mock
  static Future<void> initSharedPreferences() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await SharedPreferences.getInstance();
  }

  /// 初始化带预设值的 SharedPreferences mock
  ///
  /// [values] 预设的键值对
  static Future<void> initSharedPreferencesWithValues(
    Map<String, dynamic> values,
  ) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(values);
    await SharedPreferences.getInstance();
  }
}

/// 测试组初始化 SharedPreferences
///
/// 使用示例：
/// ```dart
/// group('MyTests', () {
///   setUpAll(() async => await setupTestSharedPreferences());
///   ...
/// });
/// ```
Future<void> setupTestSharedPreferences() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  await SharedPreferences.getInstance();
}
