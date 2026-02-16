/// 冲突解决策略枚举
///
/// 定义数据冲突时的解决方式
enum ConflictResolutionStrategy {
  /// 本地数据优先 - 本地版本覆盖云端版本
  localWins('local_wins'),

  /// 云端数据优先 - 云端版本覆盖本地版本
  cloudWins('cloud_wins'),

  /// 最新时间戳优先 - 时间戳较新的版本获胜
  timestampWins('timestamp_wins'),

  /// 手动解决 - 提示用户手动选择
  manualResolve('manual_resolve');

  final String value;
  const ConflictResolutionStrategy(this.value);

  static ConflictResolutionStrategy fromString(String value) {
    return ConflictResolutionStrategy.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ConflictResolutionStrategy.cloudWins,
    );
  }
}

/// 同步方向模式枚举
///
/// 定义同步数据的流向
enum SyncDirection {
  /// 单向同步 - 仅上传本地更改到云端
  /// 当前默认模式，用于向后兼容
  uploadOnly('upload_only'),

  /// 双向同步 - 本地和云端数据互相同步
  bidirectional('bidirectional'),

  /// 仅下载 - 仅从云端拉取数据到本地
  downloadOnly('download_only'),

  /// 仅上传 - 仅上传本地更改到云端
  uploadOnlyExplicit('upload_only_explicit');

  final String value;
  const SyncDirection(this.value);

  static SyncDirection fromString(String value) {
    return SyncDirection.values.firstWhere(
      (type) => type.value == value,
      orElse: () => SyncDirection.bidirectional,
    );
  }
}

/// 同步配置
///
/// 定义双向同步的行为和策略
class SyncConfiguration {
  /// 同步方向模式
  final SyncDirection direction;

  /// 冲突解决策略
  final ConflictResolutionStrategy conflictStrategy;

  /// 同步间隔（分钟）
  final int syncIntervalMinutes;

  /// 是否自动解决冲突
  final bool autoResolveConflicts;

  /// 是否在 WiFi 下才同步
  final bool syncOnWifiOnly;

  /// 是否同步收藏数据
  final bool syncFavorites;

  /// 是否同步播放历史
  final bool syncPlayHistory;

  /// 是否同步歌单数据
  final bool syncPlaylists;

  /// 同步歌单项数据
  final bool syncPlaylistItems;

  /// 最后同步时间戳
  final DateTime? lastSyncTimestamp;

  /// 同步版本号（用于数据迁移）
  final int syncVersion;

  const SyncConfiguration({
    this.direction = SyncDirection.uploadOnly,
    this.conflictStrategy = ConflictResolutionStrategy.cloudWins,
    this.syncIntervalMinutes = 30,
    this.autoResolveConflicts = true,
    this.syncOnWifiOnly = false,
    this.syncFavorites = true,
    this.syncPlayHistory = true,
    this.syncPlaylists = true,
    this.syncPlaylistItems = true,
    this.lastSyncTimestamp,
    this.syncVersion = 1,
  });

  /// 创建副本
  SyncConfiguration copyWith({
    SyncDirection? direction,
    ConflictResolutionStrategy? conflictStrategy,
    int? syncIntervalMinutes,
    bool? autoResolveConflicts,
    bool? syncOnWifiOnly,
    bool? syncFavorites,
    bool? syncPlayHistory,
    bool? syncPlaylists,
    bool? syncPlaylistItems,
    DateTime? lastSyncTimestamp,
    int? syncVersion,
  }) {
    return SyncConfiguration(
      direction: direction ?? this.direction,
      conflictStrategy: conflictStrategy ?? this.conflictStrategy,
      syncIntervalMinutes: syncIntervalMinutes ?? this.syncIntervalMinutes,
      autoResolveConflicts: autoResolveConflicts ?? this.autoResolveConflicts,
      syncOnWifiOnly: syncOnWifiOnly ?? this.syncOnWifiOnly,
      syncFavorites: syncFavorites ?? this.syncFavorites,
      syncPlayHistory: syncPlayHistory ?? this.syncPlayHistory,
      syncPlaylists: syncPlaylists ?? this.syncPlaylists,
      syncPlaylistItems: syncPlaylistItems ?? this.syncPlaylistItems,
      lastSyncTimestamp: lastSyncTimestamp ?? this.lastSyncTimestamp,
      syncVersion: syncVersion ?? this.syncVersion,
    );
  }

  /// 转换为 Map（用于存储）
  Map<String, dynamic> toMap() {
    return {
      'direction': direction.value,
      'conflictStrategy': conflictStrategy.value,
      'syncIntervalMinutes': syncIntervalMinutes,
      'autoResolveConflicts': autoResolveConflicts,
      'syncOnWifiOnly': syncOnWifiOnly,
      'syncFavorites': syncFavorites,
      'syncPlayHistory': syncPlayHistory,
      'syncPlaylists': syncPlaylists,
      'syncPlaylistItems': syncPlaylistItems,
      'lastSyncTimestamp': lastSyncTimestamp?.toIso8601String(),
      'syncVersion': syncVersion,
    };
  }

  /// 从 Map 创建
  factory SyncConfiguration.fromMap(Map<String, dynamic> map) {
    return SyncConfiguration(
      direction: SyncDirection.fromString(map['direction'] as String? ?? 'bidirectional'),
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

  @override
  String toString() {
    return 'SyncConfiguration(direction: $direction, conflictStrategy: $conflictStrategy, '
        'interval: ${syncIntervalMinutes}min, autoResolve: $autoResolveConflicts)';
  }
}

/// 数据冲突信息
///
/// 表示本地和云端数据之间的冲突
class DataConflict {
  /// 冲突的唯一标识
  final String id;

  /// 冲突类型（例如：favorite, playlist, playHistory）
  final String type;

  /// 本地数据
  final Map<String, dynamic>? localData;

  /// 云端数据
  final Map<String, dynamic>? cloudData;

  /// 本地数据时间戳
  final DateTime? localTimestamp;

  /// 云端数据时间戳
  final DateTime? cloudTimestamp;

  /// 冲突描述
  final String description;

  /// 冲突发生时间
  final DateTime conflictTime;

  /// 是否已解决
  bool isResolved;

  /// 解决方案（如果已解决）
  ConflictResolution? resolution;

  DataConflict({
    required this.id,
    required this.type,
    this.localData,
    this.cloudData,
    this.localTimestamp,
    this.cloudTimestamp,
    required this.description,
    this.isResolved = false,
    this.resolution,
  }) : conflictTime = DateTime.now();

  /// 判断本地数据是否较新
  bool get isLocalNewer {
    if (localTimestamp == null || cloudTimestamp == null) return false;
    return localTimestamp!.isAfter(cloudTimestamp!);
  }

  /// 判断云端数据是否较新
  bool get isCloudNewer {
    if (localTimestamp == null || cloudTimestamp == null) return false;
    return cloudTimestamp!.isAfter(localTimestamp!);
  }

  /// 获取时间戳较新的数据
  Map<String, dynamic>? get newerData => isLocalNewer ? localData : cloudData;

  /// 获取较旧的数据
  Map<String, dynamic>? get olderData => isLocalNewer ? cloudData : localData;

  /// 标记为已解决
  void markResolved(ConflictResolution resolution) {
    isResolved = true;
    this.resolution = resolution;
  }

  @override
  String toString() {
    return 'DataConflict(id: $id, type: $type, localNewer: $isLocalNewer, resolved: $isResolved)';
  }
}

/// 冲突解决方案
///
/// 记录冲突是如何被解决的
class ConflictResolution {
  /// 使用的策略
  final ConflictResolutionStrategy strategy;

  /// 获胜的数据（local 或 cloud）
  final String winner;

  /// 解决时间
  final DateTime resolvedAt;

  /// 是否自动解决
  final bool autoResolved;

  /// 用户选择的数据（如果是手动解决）
  final Map<String, dynamic>? userChoice;

  ConflictResolution({
    required this.strategy,
    required this.winner,
    this.autoResolved = true,
    this.userChoice,
  }) : resolvedAt = DateTime.now();

  @override
  String toString() {
    return 'ConflictResolution(strategy: $strategy, winner: $winner, auto: $autoResolved)';
  }
}
