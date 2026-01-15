
import 'package:demo/theme/dark_mode.dart';
import 'package:demo/theme/light_mode.dart';
import 'package:flutter/material.dart';

class ThemeController extends ChangeNotifier{
  // init light mode
  ThemeData _themeData = lightMode;

  // get theme
  ThemeData get themeData => _themeData;

  // is dark mode
  bool get isDarkMode => _themeData == darkMode;

  // set theme
  set themeData(ThemeData themeData){
    _themeData = themeData;
    // update ui
    notifyListeners();
  }

  //toggle theme
  void toggleTheme(){
    if (_themeData == lightMode){
      themeData = darkMode;
    }else{
      themeData = lightMode;
    }
  }
}