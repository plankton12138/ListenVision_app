import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

import '../data/repositories/local_music_repository.dart';
import 'platform/android_media_scanner.dart';
import 'platform/media_scanner_platform.dart';
import 'platform/web_media_scanner.dart';
import 'platform/windows_media_scanner.dart';

export 'platform/media_scanner_platform.dart' show ScanResult, ScanCancelToken;

class MediaScannerService {
  late final MediaScannerPlatform _scanner;
  final LocalMusicRepository _repository;

  MediaScannerService({LocalMusicRepository? repository})
      : _repository = repository ?? LocalMusicRepository() {
    _scanner = _createScanner();
  }

  MediaScannerPlatform _createScanner() {
    if (kIsWeb) {
      return WebMediaScanner();
    } else if (Platform.isAndroid) {
      return AndroidMediaScanner(_repository);
    } else if (Platform.isWindows) {
      return WindowsMediaScanner(_repository);
    } else {
      return WebMediaScanner();
    }
  }

  Future<bool> hasPermission() => _scanner.hasPermission();

  Future<bool> requestPermission() => _scanner.requestPermission();

  Future<ScanResult> scanDeviceAudio({
    int minDurationSeconds = 10,
    bool skipExisting = true,
    ScanCancelToken? cancelToken,
    void Function(int current, int total, String fileName)? onProgress,
  }) =>
      _scanner.scanDeviceAudio(
        minDurationSeconds: minDurationSeconds,
        skipExisting: skipExisting,
        cancelToken: cancelToken,
        onProgress: onProgress,
      );

  void dispose() => _scanner.dispose();
}
