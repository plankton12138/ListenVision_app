import '../../../core/utils/app_logger.dart';
import 'media_scanner_platform.dart';

class WebMediaScanner implements MediaScannerPlatform {

  @override
  Future<bool> hasPermission() async => false;

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<ScanResult> scanDeviceAudio({
    int minDurationSeconds = 10,
    bool skipExisting = true,
    ScanCancelToken? cancelToken,
    void Function(int current, int total, String fileName)? onProgress,
  }) async {
    AppLogger.warn('WebMediaScanner', 'Web 平台不支持本地音频扫描');
    return const ScanResult(
      addedCount: 0,
      skippedCount: 0,
      filteredCount: 0,
      addedAudios: [],
    );
  }

  @override
  void dispose() {
    AppLogger.debug('WebMediaScanner', '服务已释放');
  }
}
