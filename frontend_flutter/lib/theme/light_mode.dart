import 'package:flutter/material.dart';

/// 浅色主题配置
///
/// 定义应用在浅色模式下的颜色方案和样式
ThemeData lightMode = ThemeData(
  dividerTheme: const DividerThemeData(
    color: Colors.transparent,
    space: 0,
  ),
  colorScheme: ColorScheme.light(
    surface: const Color.fromARGB(255, 216, 214, 214),
    primary: const Color.fromARGB(255, 151, 151, 151),
    secondary: const Color.fromARGB(255, 121, 119, 119),
    inversePrimary: const Color.fromARGB(255, 82, 80, 80),
  ),
);
