import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_logger.dart';
import '../../services/download_integrity_service.dart';
import '../database/app_database.dart';
import '../database/track_dao.dart';

part 'download_integrity_provider.g.dart';

/// 下载完整性服务 Provider
///
/// 提供下载完整性服务的单例访问
/// 负责验证已下载文件的完整性，检测外部删除的文件
@riverpod
DownloadIntegrityService downloadIntegrityService(Ref ref) {
  final trackDao = TrackDao(AppDatabase.instance);
  final service = DownloadIntegrityService(trackDao);

  // 启动服务
  service.start();

  AppLogger.info('DownloadIntegrityProvider', 'DownloadIntegrityService 已启动');

  // 在 ref dispose 时停止
  ref.onDispose(() {
    service.stop();
    AppLogger.info('DownloadIntegrityProvider', 'DownloadIntegrityService 已释放');
  });

  return service;
}

/// 服务运行状态 Provider
@riverpod
bool downloadIntegrityRunning(Ref ref) {
  final service = ref.watch(downloadIntegrityServiceProvider);
  return service.isRunning;
}

/// 上次扫描时间 Provider
@riverpod
DateTime? lastIntegrityScanTime(Ref ref) {
  return null;
}

/// 扫描状态 Provider
@riverpod
String integrityScanStatus(Ref ref) {
  return 'idle';
}
