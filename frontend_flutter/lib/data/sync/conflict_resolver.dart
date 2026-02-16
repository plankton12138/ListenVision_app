import 'dart:async';

import '../../core/utils/app_logger.dart';
import 'sync_strategy.dart';

/// 冲突解决处理器
///
/// 负责检测和解决本地与云端数据之间的冲突
class ConflictResolver {
  final ConflictResolutionStrategy _defaultStrategy;
  final bool _autoResolve;

  /// 冲突流控制器
  final _conflictController = StreamController<DataConflict>.broadcast();

  /// 冲突解决流控制器
  final _resolutionController = StreamController<ConflictResolution>.broadcast();

  /// 未解决的冲突列表
  final List<DataConflict> _pendingConflicts = [];

  /// 冲突流
  Stream<DataConflict> get conflictStream => _conflictController.stream;

  /// 冲突解决流
  Stream<ConflictResolution> get resolutionStream => _resolutionController.stream;

  /// 未解决的冲突数量
  int get pendingConflictCount => _pendingConflicts.where((c) => !c.isResolved).length;

  /// 是否有未解决的冲突
  bool get hasPendingConflicts => pendingConflictCount > 0;

  ConflictResolver({
    ConflictResolutionStrategy defaultStrategy = ConflictResolutionStrategy.cloudWins,
    bool autoResolve = true,
  })  : _defaultStrategy = defaultStrategy,
        _autoResolve = autoResolve;

  /// 检测并解决数据冲突
  ///
  /// [id] 数据唯一标识
  /// [type] 数据类型（favorite, playlist, playHistory等）
  /// [localData] 本地数据
  /// [cloudData] 云端数据
  /// [localTimestamp] 本地数据时间戳
  /// [cloudTimestamp] 云端数据时间戳
  ///
  /// 返回解决后的数据，如果没有冲突返回 null
  Future<Map<String, dynamic>?> resolveConflict({
    required String id,
    required String type,
    Map<String, dynamic>? localData,
    Map<String, dynamic>? cloudData,
    DateTime? localTimestamp,
    DateTime? cloudTimestamp,
    ConflictResolutionStrategy? strategy,
    String? description,
  }) async {
    AppLogger.info('ConflictResolver', '检测冲突: id=$id, type=$type');

    // 检查是否真正存在冲突
    if (!_hasConflict(localData, cloudData, localTimestamp, cloudTimestamp)) {
      AppLogger.debug('ConflictResolver', '无冲突，跳过: id=$id');
      return null;
    }

    AppLogger.info('ConflictResolver', '检测到冲突: id=$id, type=$type');

    // 创建冲突对象
    final conflict = DataConflict(
      id: id,
      type: type,
      localData: localData,
      cloudData: cloudData,
      localTimestamp: localTimestamp,
      cloudTimestamp: cloudTimestamp,
      description: description ?? '数据冲突: $type',
    );

    // 添加到待解决列表
    _pendingConflicts.add(conflict);

    // 通知监听器
    _conflictController.add(conflict);

    // 尝试自动解决
    if (_autoResolve && strategy != ConflictResolutionStrategy.manualResolve) {
      final effectiveStrategy = strategy ?? _defaultStrategy;
      return await _autoResolveConflict(conflict, effectiveStrategy);
    }

    // 需要手动解决，返回 null
    AppLogger.info('ConflictResolver', '冲突等待手动解决: id=$id');
    return null;
  }

  /// 检查是否存在冲突
  bool _hasConflict(
    Map<String, dynamic>? localData,
    Map<String, dynamic>? cloudData,
    DateTime? localTimestamp,
    DateTime? cloudTimestamp,
  ) {
    // 如果数据完全相同，没有冲突
    if (_dataEquals(localData, cloudData)) {
      return false;
    }

    // 如果本地数据为空，使用云端数据
    if (localData == null) return false;

    // 如果云端数据为空，使用本地数据
    if (cloudData == null) return false;

    // 如果时间戳相同，认为没有冲突（可能数据确实不同，但时间戳是关键）
    if (localTimestamp != null &&
        cloudTimestamp != null &&
        localTimestamp == cloudTimestamp) {
      return false;
    }

    return true;
  }

  /// 自动解决冲突
  Future<Map<String, dynamic>?> _autoResolveConflict(
    DataConflict conflict,
    ConflictResolutionStrategy strategy,
  ) async {
    AppLogger.info('ConflictResolver', '自动解决冲突: id=${conflict.id}, strategy=$strategy');

    Map<String, dynamic>? resolvedData;
    String winner;

    switch (strategy) {
      case ConflictResolutionStrategy.localWins:
        resolvedData = conflict.localData;
        winner = 'local';
        AppLogger.debug('ConflictResolver', '使用本地数据: id=${conflict.id}');

      case ConflictResolutionStrategy.cloudWins:
        resolvedData = conflict.cloudData;
        winner = 'cloud';
        AppLogger.debug('ConflictResolver', '使用云端数据: id=${conflict.id}');

      case ConflictResolutionStrategy.timestampWins:
        if (conflict.isLocalNewer) {
          resolvedData = conflict.localData;
          winner = 'local';
          AppLogger.debug('ConflictResolver', '时间戳优先-使用本地数据: id=${conflict.id}');
        } else {
          resolvedData = conflict.cloudData;
          winner = 'cloud';
          AppLogger.debug('ConflictResolver', '时间戳优先-使用云端数据: id=${conflict.id}');
        }

      case ConflictResolutionStrategy.manualResolve:
        // 不应该到达这里，但为了安全起见
        AppLogger.warn('ConflictResolver', '手动解决策略不应触发自动解决: id=${conflict.id}');
        return null;
    }

    // 创建解决方案
    final resolution = ConflictResolution(
      strategy: strategy,
      winner: winner,
      autoResolved: true,
    );

    // 标记冲突已解决
    conflict.markResolved(resolution);
    _resolutionController.add(resolution);

    AppLogger.info(
      'ConflictResolver',
      '冲突已自动解决: id=${conflict.id}, winner=$winner',
    );

    return resolvedData;
  }

  /// 手动解决冲突
  ///
  /// 用于 UI 层让用户选择解决方式
  Future<Map<String, dynamic>?> resolveManually({
    required String conflictId,
    required String choice, // 'local' 或 'cloud'
    Map<String, dynamic>? mergedData,
  }) async {
    AppLogger.info('ConflictResolver', '手动解决冲突: id=$conflictId, choice=$choice');

    // 查找冲突
    final conflict = _pendingConflicts.firstWhere(
      (c) => c.id == conflictId && !c.isResolved,
      orElse: () => throw ArgumentError('Conflict not found: $conflictId'),
    );

    Map<String, dynamic>? resolvedData;
    ConflictResolutionStrategy strategy;

    switch (choice) {
      case 'local':
        resolvedData = conflict.localData;
        strategy = ConflictResolutionStrategy.localWins;

      case 'cloud':
        resolvedData = conflict.cloudData;
        strategy = ConflictResolutionStrategy.cloudWins;

      case 'merge':
        if (mergedData == null) {
          throw ArgumentError('Merged data required for merge strategy');
        }
        resolvedData = mergedData;
        strategy = ConflictResolutionStrategy.manualResolve;

      default:
        throw ArgumentError('Invalid choice: $choice');
    }

    // 创建解决方案
    final resolution = ConflictResolution(
      strategy: strategy,
      winner: choice,
      autoResolved: false,
      userChoice: mergedData,
    );

    // 标记冲突已解决
    conflict.markResolved(resolution);
    _resolutionController.add(resolution);

    AppLogger.info(
      'ConflictResolver',
      '冲突已手动解决: id=$conflictId, choice=$choice',
    );

    return resolvedData;
  }

  /// 批量解决冲突
  ///
  /// [conflictIds] 冲突 ID 列表
  /// [choice] 选择（local/cloud）
  Future<List<String>> resolveBatch({
    required List<String> conflictIds,
    required String choice,
  }) async {
    AppLogger.info('ConflictResolver', '批量解决冲突: count=${conflictIds.length}, choice=$choice');

    final resolvedIds = <String>[];

    for (final id in conflictIds) {
      try {
        await resolveManually(conflictId: id, choice: choice);
        resolvedIds.add(id);
      } catch (e) {
        AppLogger.error('ConflictResolver', '解决冲突失败: id=$id, error=$e');
      }
    }

    AppLogger.info('ConflictResolver', '批量解决完成: ${resolvedIds.length}/${conflictIds.length}');
    return resolvedIds;
  }

  /// 获取所有待解决的冲突
  List<DataConflict> getPendingConflicts() {
    return _pendingConflicts.where((c) => !c.isResolved).toList();
  }

  /// 获取特定类型的待解决冲突
  List<DataConflict> getPendingConflictsByType(String type) {
    return _pendingConflicts
        .where((c) => !c.isResolved && c.type == type)
        .toList();
  }

  /// 清空已解决的冲突
  void clearResolvedConflicts() {
    final beforeCount = _pendingConflicts.length;
    _pendingConflicts.removeWhere((c) => c.isResolved);
    final clearedCount = beforeCount - _pendingConflicts.length;
    AppLogger.info('ConflictResolver', '清空已解决冲突: $clearedCount');
  }

  /// 比较两个数据对象是否相等
  bool _dataEquals(Map<String, dynamic>? a, Map<String, dynamic>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;

    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      if (a[key] != b[key]) return false;
    }

    return true;
  }

  /// 释放资源
  void dispose() {
    AppLogger.info('ConflictResolver', '释放资源');
    _conflictController.close();
    _resolutionController.close();
    _pendingConflicts.clear();
  }
}

/// 同步数据合并器
///
/// 用于合并本地和云端数据
class DataMerger {
  /// 合并歌单数据
  ///
  /// 策略：保留所有歌单，对于同名歌单使用时间戳优先
  static List<Map<String, dynamic>> mergePlaylists(
    List<Map<String, dynamic>> localPlaylists,
    List<Map<String, dynamic>> cloudPlaylists, {
    ConflictResolutionStrategy strategy = ConflictResolutionStrategy.timestampWins,
  }) {
    AppLogger.debug('DataMerger', '合并歌单数据: local=${localPlaylists.length}, cloud=${cloudPlaylists.length}');

    final merged = <String, Map<String, dynamic>>{};
    final conflicts = <String, List<Map<String, dynamic>>>{};

    // 添加本地歌单
    for (final playlist in localPlaylists) {
      final id = playlist['id'] as String?;
      if (id == null) continue;

      if (merged.containsKey(id)) {
        conflicts[id] = [merged[id]!, playlist];
      } else {
        merged[id] = playlist;
      }
    }

    // 添加云端歌单
    for (final playlist in cloudPlaylists) {
      final id = playlist['id'] as String?;
      if (id == null) continue;

      if (merged.containsKey(id)) {
        conflicts.putIfAbsent(id, () => [merged[id]!]).add(playlist);
      } else {
        merged[id] = playlist;
      }
    }

    // 处理冲突
    for (final entry in conflicts.entries) {
      final id = entry.key;
      final items = entry.value;

      if (items.length < 2) continue;

      final local = items.firstWhere(
        (p) => p['source'] == 'local' || p['_source'] == 'local',
        orElse: () => items[0],
      );
      final cloud = items.firstWhere(
        (p) => p['source'] == 'cloud' || p['_source'] == 'cloud',
        orElse: () => items[1],
      );

      final localTime = _parseTimestamp(local['updated_at']);
      final cloudTime = _parseTimestamp(cloud['updated_at']);

      switch (strategy) {
        case ConflictResolutionStrategy.localWins:
          merged[id] = local;
          AppLogger.debug('DataMerger', '歌单冲突-local优先: id=$id');

        case ConflictResolutionStrategy.cloudWins:
          merged[id] = cloud;
          AppLogger.debug('DataMerger', '歌单冲突-cloud优先: id=$id');

        case ConflictResolutionStrategy.timestampWins:
          merged[id] = (localTime?.isAfter(cloudTime ?? DateTime(0)) ?? false)
              ? local
              : cloud;
          AppLogger.debug('DataMerger', '歌单冲突-时间戳优先: id=$id');

        case ConflictResolutionStrategy.manualResolve:
          // 保留两个，等待手动解决
          merged[id] = local; // 临时使用本地
          AppLogger.debug('DataMerger', '歌单冲突-等待手动解决: id=$id');
      }
    }

    AppLogger.info('DataMerger', '歌单合并完成: ${merged.length}');
    return merged.values.toList();
  }

  /// 合并歌单项数据
  ///
  /// 策略：合并两个列表，去重（基于 bvid）
  static List<Map<String, dynamic>> mergePlaylistItems(
    List<Map<String, dynamic>> localItems,
    List<Map<String, dynamic>> cloudItems,
  ) {
    AppLogger.debug('DataMerger', '合并歌单项: local=${localItems.length}, cloud=${cloudItems.length}');

    final merged = <String, Map<String, dynamic>>{};

    // 添加本地项
    for (final item in localItems) {
      final bvid = item['bvid'] as String?;
      if (bvid != null) {
        merged[bvid] = item;
      }
    }

    // 添加云端项（会覆盖同 bvid 的本地项）
    for (final item in cloudItems) {
      final bvid = item['bvid'] as String?;
      if (bvid != null) {
        merged[bvid] = item;
      }
    }

    AppLogger.info('DataMerger', '歌单项合并完成: ${merged.length}');
    return merged.values.toList();
  }

  /// 合并收藏数据
  ///
  /// 策略：取并集
  static List<Map<String, dynamic>> mergeFavorites(
    List<Map<String, dynamic>> localFavorites,
    List<Map<String, dynamic>> cloudFavorites,
  ) {
    AppLogger.debug('DataMerger', '合并收藏: local=${localFavorites.length}, cloud=${cloudFavorites.length}');

    final merged = <String, Map<String, dynamic>>{};

    // 添加本地收藏
    for (final item in localFavorites) {
      final bvid = item['bvid'] as String?;
      if (bvid != null) {
        merged[bvid] = item;
      }
    }

    // 添加云端收藏
    for (final item in cloudFavorites) {
      final bvid = item['bvid'] as String?;
      if (bvid != null) {
        merged[bvid] = item;
      }
    }

    AppLogger.info('DataMerger', '收藏合并完成: ${merged.length}');
    return merged.values.toList();
  }

  /// 合并播放历史
  ///
  /// 策略：按播放时间排序，去重（基于 bvid）
  static List<Map<String, dynamic>> mergePlayHistory(
    List<Map<String, dynamic>> localHistory,
    List<Map<String, dynamic>> cloudHistory,
  ) {
    AppLogger.debug('DataMerger', '合并播放历史: local=${localHistory.length}, cloud=${cloudHistory.length}');

    final merged = <String, Map<String, dynamic>>{};

    // 合并所有历史
    final allHistory = [...localHistory, ...cloudHistory];

    for (final item in allHistory) {
      final bvid = item['bvid'] as String?;
      final playedAt = _parseTimestamp(item['played_at']);

      if (bvid == null) continue;

      // 如果已存在，保留较新的记录
      if (merged.containsKey(bvid)) {
        final existingTime = _parseTimestamp(merged[bvid]!['played_at']);
        if (playedAt != null && (existingTime == null || playedAt.isAfter(existingTime))) {
          merged[bvid] = item;
        }
      } else {
        merged[bvid] = item;
      }
    }

    // 按播放时间排序
    final result = merged.values.toList()
      ..sort((a, b) {
        final timeA = _parseTimestamp(a['played_at']);
        final timeB = _parseTimestamp(b['played_at']);
        if (timeA == null || timeB == null) return 0;
        return timeB.compareTo(timeA); // 降序
      });

    AppLogger.info('DataMerger', '播放历史合并完成: ${result.length}');
    return result;
  }

  /// 解析时间戳
  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
