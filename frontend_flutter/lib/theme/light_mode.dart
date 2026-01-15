import 'package:flutter/material.dart';

ThemeData lightMode = ThemeData(
  dividerTheme: DividerThemeData(
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
