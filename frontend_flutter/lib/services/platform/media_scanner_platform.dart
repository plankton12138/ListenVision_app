import '../../models/local_audio.dart';

class ScanResult {
  final int addedCount;
  final int skippedCount;
  final int filteredCount;
  final List<LocalAudio> addedAudios;

  const ScanResult({
    required this.addedCount,
    required this.skippedCount,
    required this.filteredCount,
    required this.addedAudios,
  });

  bool get isEmpty => addedCount == 0 && skippedCount == 0 && filteredCount == 0;

  String get summary {
    final parts = <String>[];
    if (addedCount > 0) parts.add('新增 $addedCount 首');
    if (skippedCount > 0) parts.add('跳过 $skippedCount 首');
    if (filteredCount > 0) parts.add('过滤 $filteredCount 首');
    return parts.isEmpty ? '无变化' : parts.join('，');
  }
}

class ScanCancelToken {
  bool _isCancelled = false;
  bool get isCancelled => _isCancelled;
  void cancel() => _isCancelled = true;
}

abstract class MediaScannerPlatform {
  Future<bool> hasPermission();
  Future<bool> requestPermission();
  Future<ScanResult> scanDeviceAudio({
    int minDurationSeconds,
    bool skipExisting,
    ScanCancelToken? cancelToken,
    void Function(int current, int total, String fileName)? onProgress,
  });
  void dispose();
}
