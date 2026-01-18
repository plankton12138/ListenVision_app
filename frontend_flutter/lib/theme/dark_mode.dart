import 'package:flutter/material.dart';

/// 深色主题配置
///
/// 定义应用在深色模式下的颜色方案和样式
ThemeData darkMode = ThemeData(
  dividerTheme: const DividerThemeData(
    color: Colors.transparent,
    space: 0,
  ),
  colorScheme: ColorScheme.dark(
    surface: const Color.fromARGB(255, 85, 82, 82),
    primary: const Color.fromARGB(255, 59, 52, 52),
    secondary: Colors.grey.shade900,
    inversePrimary: Colors.grey.shade300,
  ),
);
