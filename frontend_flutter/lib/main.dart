import 'dart:io';

import 'package:demo/providers/audio_provider.dart';
import 'package:demo/providers/auth_provider.dart';
import 'package:demo/providers/theme_provider.dart';
import 'package:demo/routes/router.dart';
import 'package:demo/services/api_service.dart';
import 'package:demo/services/download_manager.dart';
import 'package:demo/services/file_picker.dart';
import 'package:demo/utils/request_permission.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  // check is first launch
  final prefs = await SharedPreferences.getInstance();
  bool isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;

  if (isFirstLaunch) {
    // first launch, request permission
    bool hasPermission = await requestManageStoragePermission();
    if (hasPermission) {
      debugPrint("request permission success");
    } else {
      debugPrint("user denied permission");
      openAppSettings(); // open app settings to grant permission_handler
    }
    await prefs.setBool('isFirstLaunch', false);
  }

  // initialize database factory(desktop only)
  if (kIsWeb) {
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    databaseFactory = databaseFactoryFfi;
  }

  // var databasePath = await getDatabasesPath();
  // debugPrint("database path: $databasePath");

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(create: (_) => AudioProvider()),
        ChangeNotifierProvider(create: (_) => DownloadManager()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        Provider(create: (_) => FilePickerService()),
        Provider(create: (_) => ApiService()),  
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: Provider.of<ThemeController>(context).themeData,
    );
  }
}
