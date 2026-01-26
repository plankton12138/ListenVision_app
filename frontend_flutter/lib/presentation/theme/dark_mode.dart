import 'package:flutter/material.dart';

/// 深色主题配置
///
/// 定义应用在深色模式下的颜色方案和样式
ThemeData darkMode = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,

  // 分割线主题
  dividerTheme: const DividerThemeData(
    color: Colors.white12,
    space: 1,
    thickness: 0.5,
  ),

  // 颜色方案
  colorScheme: const ColorScheme.dark(
    // 主色调：深色模式下稍微减淡一点，避免刺眼
    primary: Color(0xFF64B5F6), // Blue 300
    onPrimary: Colors.black,

    // 次要色调
    secondary: Color(0xFF03DAC6),
    onSecondary: Colors.black,

    // 背景色：深灰色
    surface: Color(0xFF121212),
    onSurface: Colors.white70,
    
    // 表面变体
    surfaceContainerHighest: Color(0xFF2C2C2C),

    // 错误色
    error: Color(0xFFCF6679),
    
    // 逆转色
    inversePrimary: Colors.black87,
  ),

  // 卡片主题
  cardTheme: CardThemeData(
    elevation: 2,
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    color: const Color(0xFF1E1E1E),
    surfaceTintColor: const Color(0xFF1E1E1E),
  ),

  // 列表项主题
  listTileTheme: const ListTileThemeData(
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    minLeadingWidth: 40,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
  ),

  // 文本主题
  textTheme: const TextTheme(
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.15,
      color: Colors.white,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.15,
      color: Colors.white,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      letterSpacing: 0.25,
      color: Colors.white70,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      letterSpacing: 0.4,
      color: Colors.white54,
    ),
    labelSmall: TextStyle(
      fontSize: 10,
      letterSpacing: 0.5,
      color: Colors.white38,
    ),
  ),

  // AppBar 主题
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF121212),
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
    scrolledUnderElevation: 2,
  ),
  
  // 图标主题
  iconTheme: const IconThemeData(
    color: Colors.white70,
    size: 24,
  ),
);
