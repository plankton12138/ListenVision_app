import 'package:flutter/material.dart';

ThemeData darkMode = ThemeData(
  dividerTheme: DividerThemeData(
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
