/// ListenVision 应用 Widget 测试
///
/// P1: 替换 Flutter 默认模板测试为真实业务测试
library;

import 'package:demo/presentation/providers/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ThemeController', () {
    late ThemeController controller;

    setUp(() {
      controller = ThemeController();
    });

    tearDown(() {
      controller.dispose();
    });

    group('基本初始化', () {
      test('应该成功创建 ThemeController', () {
        expect(controller, isNotNull);
        expect(controller.themeData, isNotNull);
      });

      test('默认应该是浅色主题', () {
        expect(controller.isDarkMode, false);
        expect(controller.themeData.brightness, Brightness.light);
      });

      test('浅色主题应该使用 Material 3', () {
        expect(controller.themeData.useMaterial3, true);
      });
    });

    group('主题切换', () {
      test('应该能够切换到深色模式', () {
        controller.toggleTheme();

        expect(controller.isDarkMode, true);
        expect(controller.themeData.brightness, Brightness.dark);
      });

      test('应该能够切换回浅色模式', () {
        controller.toggleTheme();
        controller.toggleTheme();

        expect(controller.isDarkMode, false);
        expect(controller.themeData.brightness, Brightness.light);
      });

      test('深色主题应该使用 Material 3', () {
        controller.toggleTheme();
        final theme = controller.themeData;

        expect(theme.useMaterial3, true);
        expect(theme.brightness, Brightness.dark);
      });
    });

    group('监听器通知', () {
      test('切换主题应该通知监听器', () async {
        var notified = false;

        controller.addListener(() {
          notified = true;
        });

        controller.toggleTheme();
        expect(notified, true);
      });

      test('移除监听器后不应该再收到通知', () async {
        var notified = false;

        final VoidCallback listener = () {
          notified = true;
        };

        controller.addListener(listener);
        controller.removeListener(listener);
        controller.toggleTheme();

        expect(notified, false);
      });
    });

    group('主题配置', () {
      test('浅色主题应该有正确的颜色配置', () {
        final colorScheme = controller.themeData.colorScheme;

        expect(colorScheme.brightness, Brightness.light);
        expect(colorScheme.primary, isNotNull);
      });

      test('深色主题应该有正确的颜色配置', () {
        controller.toggleTheme();
        final colorScheme = controller.themeData.colorScheme;

        expect(colorScheme.brightness, Brightness.dark);
        expect(colorScheme.primary, isNotNull);
      });
    });
  });
}
