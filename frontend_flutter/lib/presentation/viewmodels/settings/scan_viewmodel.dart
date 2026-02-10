import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/app_logger.dart';
import '../../../services/media_scanner_service.dart';

part 'scan_viewmodel.freezed.dart';
part 'scan_viewmodel.g.dart';

@freezed
class ScanState with _$ScanState {
  const factory ScanState.idle() = _Idle;
  const factory ScanState.requestingPermission() = _RequestingPermission;
  const factory ScanState.scanning({
    required int current,
    required int total,
    required String currentFile,
  }) = _Scanning;
  const factory ScanState.completed({required ScanResult result}) = _Completed;
  const factory ScanState.error({required String message}) = _Error;
}

@riverpod
class ScanViewModel extends _$ScanViewModel {
  MediaScannerService? _scannerService;

  @override
  ScanState build() {
    _scannerService = MediaScannerService();
    ref.onDispose(() {
      _scannerService?.dispose();
    });
    return const ScanState.idle();
  }

  Future<void> startScan({int minDurationSeconds = 10}) async {
    if (_scannerService == null) {
      state = const ScanState.error(message: '扫描服务未初始化');
      return;
    }

    AppLogger.info('ScanViewModel', '开始扫描，最小时长: ${minDurationSeconds}s');

    final hasPermission = await _scannerService!.hasPermission();
    if (!hasPermission) {
      state = const ScanState.requestingPermission();
      final granted = await _scannerService!.requestPermission();
      if (!granted) {
        state = const ScanState.error(message: '需要存储权限才能扫描本地音乐');
        return;
      }
    }

    state = const ScanState.scanning(current: 0, total: 0, currentFile: '');

    try {
      final result = await _scannerService!.scanDeviceAudio(
        minDurationSeconds: minDurationSeconds,
        skipExisting: true,
        onProgress: (current, total, fileName) {
          state = ScanState.scanning(
            current: current,
            total: total,
            currentFile: fileName,
          );
        },
      );

      state = ScanState.completed(result: result);
      AppLogger.info('ScanViewModel', '扫描完成: ${result.summary}');
    } catch (e) {
      AppLogger.error('ScanViewModel', '扫描失败: $e');
      state = ScanState.error(message: '扫描失败: $e');
    }
  }

  void reset() {
    state = const ScanState.idle();
  }
}
