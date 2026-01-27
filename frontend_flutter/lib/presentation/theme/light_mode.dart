import 'package:flutter/material.dart';

/// 浅色主题配置
///
/// 定义应用在浅色模式下的颜色方案和样式
ThemeData lightMode = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  
  // 分割线主题
  dividerTheme: const DividerThemeData(
    color: Colors.black12,
    space: 1,
    thickness: 0.5,
  ),

  // 颜色方案 - 使用更现代、对比度更好的配色
  colorScheme: const ColorScheme.light(
    // 主色调：使用更鲜明的蓝色，替代原来的灰色 #979797
    primary: Color.fromARGB(255, 99, 178, 242), 
    onPrimary: Colors.white,
    
    // 次要色调：用于强调
    secondary: Color.fromARGB(255, 160, 227, 134),
    onSecondary: Colors.black,

    // 背景色：保持清爽的灰白色，替代原来的 #D8D6D6 (太深了)
    surface: Color(0xFFF5F5F5),
    onSurface: Colors.black87,
    
    // 表面变体：用于卡片背景等
    surfaceContainerHighest: Colors.white,

    // 错误色
    error: Color(0xFFB00020),
    
    // 逆转色
    inversePrimary: Colors.white,
  ),

  // 卡片主题 - 统一卡片风格
  cardTheme: CardThemeData(
    elevation: 2,
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    color: Colors.white,
    surfaceTintColor: Colors.white, // 避免 M3 的染色效果
  ),

  // 列表项主题
  listTileTheme: const ListTileThemeData(
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    minLeadingWidth: 40,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
  ),

  // 文本主题 - 统一字体层级
  textTheme: const TextTheme(
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.15,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.15,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      letterSpacing: 0.25,
      color: Colors.black87,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      letterSpacing: 0.4,
      color: Colors.black54,
    ),
    labelSmall: TextStyle(
      fontSize: 10,
      letterSpacing: 0.5,
      color: Colors.black45,
    ),
  ),

  // AppBar 主题
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black87, // 图标和文字颜色
    elevation: 0,
    centerTitle: true,
    scrolledUnderElevation: 2,
  ),
  
  // 图标主题
  iconTheme: const IconThemeData(
    color: Colors.black54,
    size: 24,
  ),
);
