import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/app_logger.dart';
import 'sync_strategy.dart';

/// 同步配置存储键
const _syncConfigKey = 'sync_configuration';

/// 同步配置 Notifier
///
/// 管理用户的同步配置设置
class SyncCfgNotifier extends Notifier<SyncConfiguration> {
  @override
  SyncConfiguration build() {
    _init();
    return const SyncConfiguration();
  }

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString(_syncConfigKey);

      if (configJson == null) {
        AppLogger.info('SyncConfiguration', '使用默认配置');
        return;
      }

      final configMap = jsonDecode(configJson) as Map<String, dynamic>;
      final config = SyncCfgExt.fromMap(configMap);

      AppLogger.info('SyncConfiguration', '加载配置成功: $config');
      state = config;
    } catch (e) {
      AppLogger.error('SyncConfiguration', '加载配置失败: $e');
    }
  }

  /// 保存配置
  Future<void> _saveConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = jsonEncode(state.toMap());
      await prefs.setString(_syncConfigKey, configJson);
      AppLogger.info('SyncConfiguration', '配置已保存');
    } catch (e) {
      AppLogger.error('SyncConfiguration', '保存配置失败: $e');
      rethrow;
    }
  }

  /// 更新配置
  Future<void> updateConfig(SyncConfiguration config) async {
    AppLogger.info('SyncConfiguration', '更新配置: $config');
    state = config;
    await _saveConfiguration();
  }

  /// 更新同步方向
  Future<void> updateDirection(SyncDirection direction) async {
    await updateConfig(state.copyWith(direction: direction));
  }

  /// 更新冲突解决策略
  Future<void> updateConflictStrategy(ConflictResolutionStrategy strategy) async {
    await updateConfig(state.copyWith(conflictStrategy: strategy));
  }

  /// 更新同步间隔
  Future<void> updateSyncInterval(int minutes) async {
    await updateConfig(state.copyWith(syncIntervalMinutes: minutes));
  }

  /// 切换自动解决冲突
  Future<void> toggleAutoResolve(bool enabled) async {
    await updateConfig(state.copyWith(autoResolveConflicts: enabled));
  }

  /// 切换仅 WiFi 同步
  Future<void> toggleSyncOnWifiOnly(bool enabled) async {
    await updateConfig(state.copyWith(syncOnWifiOnly: enabled));
  }

  /// 切换数据类型同步
  Future<void> toggleDataType(String type, bool enabled) async {
    SyncConfiguration newConfig;
    switch (type) {
      case 'favorites':
        newConfig = state.copyWith(syncFavorites: enabled);
      case 'playHistory':
        newConfig = state.copyWith(syncPlayHistory: enabled);
      case 'playlists':
        newConfig = state.copyWith(syncPlaylists: enabled);
      case 'playlistItems':
        newConfig = state.copyWith(syncPlaylistItems: enabled);
      default:
        return;
    }
    await updateConfig(newConfig);
  }

  /// 更新最后同步时间
  Future<void> updateLastSyncTime(DateTime timestamp) async {
    await updateConfig(state.copyWith(lastSyncTimestamp: timestamp));
  }

  /// 重置配置
  Future<void> reset() async {
    AppLogger.info('SyncConfiguration', '重置配置');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_syncConfigKey);
      state = const SyncConfiguration();
    } catch (e) {
      AppLogger.error('SyncConfiguration', '重置配置失败: $e');
    }
  }
}

/// 同步配置 Provider
final syncConfigurationProvider = NotifierProvider<SyncCfgNotifier, SyncConfiguration>(
  () => SyncCfgNotifier(),
);

/// 同步方向 Provider
final syncDirectionProvider = Provider<SyncDirection>((ref) {
  final config = ref.watch(syncConfigurationProvider);
  return config.direction;
});

/// 冲突解决策略 Provider
final conflictStrategyProvider = Provider<ConflictResolutionStrategy>((ref) {
  final config = ref.watch(syncConfigurationProvider);
  return config.conflictStrategy;
});

/// 是否应该拉取云端数据
final shouldPullFromCloudProvider = Provider<bool>((ref) {
  final direction = ref.watch(syncDirectionProvider);
  return direction == SyncDirection.bidirectional ||
      direction == SyncDirection.downloadOnly;
});

/// 是否应该上传本地数据
final shouldUploadToCloudProvider = Provider<bool>((ref) {
  final direction = ref.watch(syncDirectionProvider);
  return direction == SyncDirection.bidirectional ||
      direction == SyncDirection.uploadOnly ||
      direction == SyncDirection.uploadOnlyExplicit;
});

/// 最后同步时间 Provider
final lastSyncTimeProvider = Provider<DateTime?>((ref) {
  final config = ref.watch(syncConfigurationProvider);
  return config.lastSyncTimestamp;
});

/// 同步配置扩展方法
extension SyncCfgExt on SyncConfiguration {
  static SyncConfiguration fromMap(Map<String, dynamic> map) {
    return SyncConfiguration(
      direction: SyncDirection.fromString(map['direction'] as String? ?? 'upload_only'),
      conflictStrategy: ConflictResolutionStrategy.fromString(
        map['conflictStrategy'] as String? ?? 'cloud_wins',
      ),
      syncIntervalMinutes: map['syncIntervalMinutes'] as int? ?? 30,
      autoResolveConflicts: map['autoResolveConflicts'] as bool? ?? true,
      syncOnWifiOnly: map['syncOnWifiOnly'] as bool? ?? false,
      syncFavorites: map['syncFavorites'] as bool? ?? true,
      syncPlayHistory: map['syncPlayHistory'] as bool? ?? true,
      syncPlaylists: map['syncPlaylists'] as bool? ?? true,
      syncPlaylistItems: map['syncPlaylistItems'] as bool? ?? true,
      lastSyncTimestamp: map['lastSyncTimestamp'] != null
          ? DateTime.parse(map['lastSyncTimestamp'] as String)
          : null,
      syncVersion: map['syncVersion'] as int? ?? 1,
    );
  }
}
