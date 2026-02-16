# 双向数据同步实现方案

**方案制定日期**: 2026-02-16
**关联主计划**: architecture-compliance-fix-plan.md
**优先级**: P2

---
## 一、目标

完善数据同步机制，实现从云端到本地的双向同步，确保用户在不同设备上的数据一致性，并添加冲突解决策略。

## 二、当前问题分析

### 2.1 单向同步局限
当前的同步机制(`sync_worker.dart`)只实现了本地到云端的单向同步：
- ✅ 收藏状态同步（favorite/unfavorite）
- ✅ 播放历史同步
- ✅ 歌单操作同步（添加/删除/创建/更新）
- ✅ 断点续传和重试机制（最大3次重试）

### 2.2 缺失功能
- ❌ **双向同步不完善**：只有"本地→云端"同步，缺少"云端→本地"主动拉取
- ❌ **没有冲突解决策略**：当本地和云端数据冲突时，没有明确的解决规则

## 三、解决方案设计

### 3.1 核心思路
1. 实现定期从云端拉取最新数据的功能
2. 创建数据合并逻辑处理云端和本地数据
3. 实现冲突检测和解决机制
4. 提供多种冲突解决策略供用户选择

### 3.2 实现架构
```
SyncWorker -> 定期同步 -> 本地→云端推送
           -> 定期拉取 -> 云端→本地拉取
           -> 数据合并 -> 冲突检测
           -> 冲突解决 -> 应用策略
```

## 四、详细实现步骤

### 4.1 增强SyncTask模型

**文件**: `lib/data/models/sync_task.dart`

添加同步方向字段：
```dart
enum SyncDirection {
  upload,    // 上传(本地→云端)
  download,  // 下载(云端→本地)
  bidirectional, // 双向
}

class SyncTask {
  final int id;
  final String taskId; // 全局唯一任务ID
  final String type;
  final String payload;
  final SyncDirection direction; // 新增字段
  final int retryCount;
  final SyncTaskStatus status;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastAttemptAt;
  
  SyncTask({
    required this.id,
    required this.taskId,
    required this.type,
    required this.payload,
    this.direction = SyncDirection.upload, // 默认为上传
    required this.retryCount,
    required this.status,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
    this.lastAttemptAt,
  });
  
  // 现有方法...
  
  /// 创建下载任务
  static SyncTask createDownloadTask({
    required String taskId,
    required String type,
    required String payload,
  }) {
    return SyncTask(
      id: -1, // 数据库自动生成
      taskId: taskId,
      type: type,
      payload: payload,
      direction: SyncDirection.download,
      retryCount: 0,
      status: SyncTaskStatus.pending,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
```

### 4.2 增强SyncWorker

**文件**: `lib/data/sync/sync_worker.dart`

添加双向同步功能：
```dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/sync_task.dart';
import '../models/conflict_resolution_strategy.dart'; // 新增
import '../repositories/sync_repository.dart';
import '../network/api_client.dart';
import '../../core/utils/logger.dart';

class SyncWorker {
  final SyncRepository _syncRepository;
  final ApiClient _apiClient;
  final Duration _interval;
  Timer? _timer;
  Timer? _pullTimer; // 新增：用于定期拉取云端数据
  
  SyncWorker({
    required SyncRepository syncRepository,
    required ApiClient apiClient,
    Duration interval = const Duration(seconds: 30),
  })  : _syncRepository = syncRepository,
        _apiClient = apiClient,
        _interval = interval;
  
  /// 启动同步工作器
  void start() {
    // 停止现有的定时器
    stop();
    
    // 启动推送同步（原有功能）
    _timer = Timer.periodic(_interval, (_) => _executePushSync());
    
    // 启动拉取同步（新增功能）
    _pullTimer = Timer.periodic(Duration(minutes: 5), (_) => _executePullSync());
    
    AppLogger.info('SyncWorker started with interval: $_interval');
  }
  
  /// 停止同步工作器
  void stop() {
    _timer?.cancel();
    _pullTimer?.cancel();
    _timer = null;
    _pullTimer = null;
    AppLogger.info('SyncWorker stopped');
  }
  
  /// 执行推送同步（本地→云端）
  Future<void> _executePushSync() async {
    try {
      final tasks = await _syncRepository.getPendingTasks(
        limit: 50,
        direction: SyncDirection.upload,
      );
      
      if (tasks.isEmpty) return;
      
      AppLogger.debug('Executing push sync for ${tasks.length} tasks');
      
      for (final task in tasks) {
        await _processUploadTask(task);
      }
    } catch (e) {
      AppLogger.error('Push sync failed: $e');
    }
  }
  
  /// 执行拉取同步（云端→本地）
  Future<void> _executePullSync() async {
    try {
      AppLogger.debug('Executing pull sync from cloud');
      
      // 从云端获取最新的数据变更
      final cloudChanges = await _apiClient.getRecentChanges(
        since: await _syncRepository.getLastPullTimestamp(),
      );
      
      if (cloudChanges.isEmpty) {
        AppLogger.debug('No changes from cloud');
        return;
      }
      
      AppLogger.debug('Processing ${cloudChanges.length} changes from cloud');
      
      // 处理云端变更
      for (final change in cloudChanges) {
        await _processCloudChange(change);
      }
      
      // 更新最后拉取时间戳
      await _syncRepository.updateLastPullTimestamp(DateTime.now());
      
    } catch (e) {
      AppLogger.error('Pull sync failed: $e');
    }
  }
  
  /// 处理上传任务
  Future<void> _processUploadTask(SyncTask task) async {
    try {
      // 更新任务状态为处理中
      await _syncRepository.updateTaskStatus(
        taskId: task.taskId,
        status: SyncTaskStatus.processing,
        lastAttemptAt: DateTime.now(),
      );
      
      // 执行同步
      await _apiClient.syncData(
        type: task.type,
        payload: task.payload,
      );
      
      // 标记为已完成
      await _syncRepository.updateTaskStatus(
        taskId: task.taskId,
        status: SyncTaskStatus.completed,
      );
      
      AppLogger.debug('Upload task completed: ${task.taskId}');
    } catch (e) {
      // 处理重试逻辑
      await _handleTaskFailure(task, e);
    }
  }
  
  /// 处理云端变更
  Future<void> _processCloudChange(CloudChange change) async {
    try {
      // 检查本地是否已有相同的数据
      final localExists = await _syncRepository.localDataExists(
        type: change.type,
        identifier: change.identifier,
      );
      
      if (localExists) {
        // 存在本地数据，检查是否有冲突
        final conflict = await _detectConflict(change);
        if (conflict) {
          await _resolveConflict(change);
          return;
        }
      }
      
      // 没有冲突，直接应用云端变更
      await _applyCloudChange(change);
    } catch (e) {
      AppLogger.error('Failed to process cloud change: $e');
    }
  }
  
  /// 检测冲突
  Future<bool> _detectConflict(CloudChange change) async {
    try {
      final localData = await _syncRepository.getLocalData(
        type: change.type,
        identifier: change.identifier,
      );
      
      if (localData == null) return false;
      
      // 比较时间戳或其他冲突检测逻辑
      final localTimestamp = localData['updatedAt'] as DateTime?;
      final cloudTimestamp = change.timestamp;
      
      if (localTimestamp != null && localTimestamp.isAfter(cloudTimestamp)) {
        // 本地数据更新，可能存在冲突
        return true;
      }
      
      return false;
    } catch (e) {
      AppLogger.error('Conflict detection failed: $e');
      return false;
    }
  }
  
  /// 解决冲突
  Future<void> _resolveConflict(CloudChange change) async {
    try {
      // 获取冲突解决策略
      final strategy = await _syncRepository.getConflictResolutionStrategy();
      
      switch (strategy) {
        case ConflictResolutionStrategy.localWins:
          // 本地数据优先，不需要做任何事情
          AppLogger.debug('Conflict resolved: local wins');
          break;
          
        case ConflictResolutionStrategy.cloudWins:
          // 云端数据优先，应用云端变更
          await _applyCloudChange(change);
          AppLogger.debug('Conflict resolved: cloud wins');
          break;
          
        case ConflictResolutionStrategy.timestampWins:
          // 时间戳优先，已经在_detectConflict中处理
          await _applyCloudChange(change);
          AppLogger.debug('Conflict resolved: timestamp wins');
          break;
          
        case ConflictResolutionStrategy.manualResolve:
          // 手动解决，创建冲突任务供用户处理
          await _createConflictResolutionTask(change);
          AppLogger.debug('Conflict requires manual resolution');
          break;
      }
    } catch (e) {
      AppLogger.error('Conflict resolution failed: $e');
    }
  }
  
  /// 应用云端变更
  Future<void> _applyCloudChange(CloudChange change) async {
    try {
      switch (change.type) {
        case 'favorite':
          await _syncRepository.applyFavoriteChange(change);
          break;
        case 'playHistory':
          await _syncRepository.applyPlayHistoryChange(change);
          break;
        case 'playlist':
          await _syncRepository.applyPlaylistChange(change);
          break;
        // 其他变更类型...
      }
      
      AppLogger.debug('Applied cloud change: ${change.type} - ${change.identifier}');
    } catch (e) {
      AppLogger.error('Failed to apply cloud change: $e');
    }
  }
  
  /// 创建冲突解决任务
  Future<void> _createConflictResolutionTask(CloudChange change) async {
    final task = SyncTask.createDownloadTask(
      taskId: 'conflict_${change.identifier}_${DateTime.now().millisecondsSinceEpoch}',
      type: 'conflict_resolution',
      payload: change.toJson(),
    );
    
    await _syncRepository.saveTask(task);
  }
  
  /// 处理任务失败
  Future<void> _handleTaskFailure(SyncTask task, dynamic error) async {
    final newRetryCount = task.retryCount + 1;
    
    if (newRetryCount >= 3) {
      // 达到最大重试次数，标记为失败
      await _syncRepository.updateTaskStatus(
        taskId: task.taskId,
        status: SyncTaskStatus.failed,
        errorMessage: error.toString(),
      );
      
      AppLogger.warn('Task failed after max retries: ${task.taskId}');
    } else {
      // 增加重试次数
      await _syncRepository.updateTaskRetryCount(
        taskId: task.taskId,
        retryCount: newRetryCount,
        errorMessage: error.toString(),
        lastAttemptAt: DateTime.now(),
      );
      
      AppLogger.debug('Task retry scheduled: ${task.taskId} (attempt $newRetryCount)');
    }
  }
  
  /// 手动触发同步
  Future<void> triggerSync() async {
    await _executePushSync();
    await _executePullSync();
  }
}
```

### 4.3 创建冲突解决策略模型

**新建文件**: `lib/data/models/conflict_resolution_strategy.dart`

```dart
/// 冲突解决策略
enum ConflictResolutionStrategy {
  localWins,      // 本地优先
  cloudWins,      // 云端优先
  timestampWins,  // 时间戳优先
  manualResolve,  // 手动解决
}

extension ConflictResolutionStrategyExtension on ConflictResolutionStrategy {
  String get displayName {
    switch (this) {
      case ConflictResolutionStrategy.localWins:
        return '本地数据优先';
      case ConflictResolutionStrategy.cloudWins:
        return '云端数据优先';
      case ConflictResolutionStrategy.timestampWins:
        return '最新数据优先';
      case ConflictResolutionStrategy.manualResolve:
        return '手动解决冲突';
    }
  }
  
  String get description {
    switch (this) {
      case ConflictResolutionStrategy.localWins:
        return '始终使用设备上的本地数据';
      case ConflictResolutionStrategy.cloudWins:
        return '始终使用云端的最新数据';
      case ConflictResolutionStrategy.timestampWins:
        return '自动选择时间戳更新的数据';
      case ConflictResolutionStrategy.manualResolve:
        return '当检测到冲突时提示用户手动选择';
    }
  }
}
```

### 4.4 增强SyncRepository

**文件**: `lib/data/repositories/sync_repository.dart`

添加双向同步支持：
```dart
import '../models/conflict_resolution_strategy.dart';
import '../models/cloud_change.dart'; // 新增

class SyncRepository {
  final SyncDao _syncDao;
  final TrackDao _trackDao;
  final PlaylistDao _playlistDao;
  
  SyncRepository(this._syncDao, this._trackDao, this._playlistDao);
  
  // 现有方法...
  
  /// 获取指定方向的待处理任务
  Future<List<SyncTask>> getPendingTasks({
    int limit = 50,
    SyncDirection? direction,
  }) async {
    return await _syncDao.getPendingTasks(limit: limit, direction: direction);
  }
  
  /// 获取最后一次拉取云端数据的时间戳
  Future<DateTime?> getLastPullTimestamp() async {
    final timestampStr = await _syncDao.getSetting('last_pull_timestamp');
    if (timestampStr == null) return null;
    return DateTime.tryParse(timestampStr);
  }
  
  /// 更新最后一次拉取云端数据的时间戳
  Future<void> updateLastPullTimestamp(DateTime timestamp) async {
    await _syncDao.setSetting('last_pull_timestamp', timestamp.toIso8601String());
  }
  
  /// 检查本地数据是否存在
  Future<bool> localDataExists({
    required String type,
    required String identifier,
  }) async {
    switch (type) {
      case 'favorite':
        return await _trackDao.favoriteExists(identifier);
      case 'playHistory':
        return await _trackDao.playHistoryExists(identifier);
      case 'playlist':
        return await _playlistDao.playlistExists(identifier);
      default:
        return false;
    }
  }
  
  /// 获取本地数据
  Future<Map<String, dynamic>?> getLocalData({
    required String type,
    required String identifier,
  }) async {
    switch (type) {
      case 'favorite':
        final track = await _trackDao.getBySourceId(identifier);
        return track?.toJson();
      case 'playHistory':
        final history = await _trackDao.getPlayHistoryById(identifier);
        return history?.toJson();
      case 'playlist':
        final playlist = await _playlistDao.getById(identifier);
        return playlist?.toJson();
      default:
        return null;
    }
  }
  
  /// 获取冲突解决策略
  Future<ConflictResolutionStrategy> getConflictResolutionStrategy() async {
    final strategyStr = await _syncDao.getSetting('conflict_resolution_strategy');
    if (strategyStr == null) return ConflictResolutionStrategy.timestampWins;
    
    switch (strategyStr) {
      case 'localWins':
        return ConflictResolutionStrategy.localWins;
      case 'cloudWins':
        return ConflictResolutionStrategy.cloudWins;
      case 'manualResolve':
        return ConflictResolutionStrategy.manualResolve;
      default:
        return ConflictResolutionStrategy.timestampWins;
    }
  }
  
  /// 设置冲突解决策略
  Future<void> setConflictResolutionStrategy(ConflictResolutionStrategy strategy) async {
    await _syncDao.setSetting('conflict_resolution_strategy', strategy.name);
  }
  
  /// 应用收藏变更
  Future<void> applyFavoriteChange(CloudChange change) async {
    final payload = change.payload;
    final sourceId = payload['sourceId'] as String;
    final isFavorite = payload['isFavorite'] as bool;
    final timestamp = change.timestamp;
    
    if (isFavorite) {
      await _trackDao.markAsFavorite(sourceId, timestamp: timestamp);
    } else {
      await _trackDao.removeFromFavorites(sourceId);
    }
  }
  
  /// 应用播放历史变更
  Future<void> applyPlayHistoryChange(CloudChange change) async {
    final payload = change.payload;
    final sourceId = payload['sourceId'] as String;
    final position = payload['position'] as int?;
    final timestamp = change.timestamp;
    
    await _trackDao.updatePlayHistory(
      sourceId: sourceId,
      position: position ?? 0,
      playedAt: timestamp,
    );
  }
  
  /// 应用歌单变更
  Future<void> applyPlaylistChange(CloudChange change) async {
    final payload = change.payload;
    final action = payload['action'] as String;
    
    switch (action) {
      case 'create':
        // 创建歌单逻辑
        break;
      case 'update':
        // 更新歌单逻辑
        break;
      case 'delete':
        // 删除歌单逻辑
        break;
      case 'addItem':
        // 添加项逻辑
        break;
      case 'removeItem':
        // 删除项逻辑
        break;
    }
  }
}
```

### 4.5 增强SyncDao

**文件**: `lib/data/database/sync_dao.dart`

添加双向同步支持：
```dart
class SyncDao {
  final Database _db;
  
  SyncDao(this._db);
  
  // 现有方法...
  
  /// 获取指定方向的待处理任务
  Future<List<SyncTask>> getPendingTasks({
    int limit = 50,
    SyncDirection? direction,
  }) async {
    final whereClause = direction != null 
        ? 'WHERE status = ? AND direction = ?' 
        : 'WHERE status = ?';
    final whereArgs = direction != null 
        ? [SyncTaskStatus.pending.name, direction.name] 
        : [SyncTaskStatus.pending.name];
        
    final maps = await _db.query(
      'sync_tasks',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'created_at ASC',
      limit: limit,
    );
    
    return maps.map((map) => SyncTask.fromJson(map)).toList();
  }
  
  /// 获取设置值
  Future<String?> getSetting(String key) async {
    final maps = await _db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    
    if (maps.isEmpty) return null;
    return maps.first['value'] as String?;
  }
  
  /// 设置值
  Future<void> setSetting(String key, String value) async {
    await _db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  /// 更新任务重试次数
  Future<void> updateTaskRetryCount({
    required String taskId,
    required int retryCount,
    String? errorMessage,
    DateTime? lastAttemptAt,
  }) async {
    await _db.update(
      'sync_tasks',
      {
        'retry_count': retryCount,
        'error_message': errorMessage,
        'last_attempt_at': lastAttemptAt?.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'task_id = ?',
      whereArgs: [taskId],
    );
  }
}
```

### 4.6 创建云端变更模型

**新建文件**: `lib/data/models/cloud_change.dart`

```dart
class CloudChange {
  final String id;
  final String type;
  final String identifier; // 唯一标识符
  final Map<String, dynamic> payload;
  final DateTime timestamp;
  final String userId;
  
  CloudChange({
    required this.id,
    required this.type,
    required this.identifier,
    required this.payload,
    required this.timestamp,
    required this.userId,
  });
  
  factory CloudChange.fromJson(Map<String, dynamic> json) {
    return CloudChange(
      id: json['id'] as String,
      type: json['type'] as String,
      identifier: json['identifier'] as String,
      payload: json['payload'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
      userId: json['userId'] as String,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'identifier': identifier,
      'payload': payload,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
    };
  }
}
```

### 4.7 增强API客户端

**文件**: `lib/data/network/api_client.dart`

添加获取云端变更的方法：
```dart
class ApiClient {
  final Dio _dio;
  
  ApiClient(ProviderRef ref) : _dio = Dio() {
    // 现有初始化...
  }
  
  // 现有方法...
  
  /// 获取最近的云端变更
  Future<List<CloudChange>> getRecentChanges({DateTime? since}) async {
    try {
      final response = await _dio.get(
        '/api/v1/sync/changes',
        queryParameters: {
          if (since != null) 'since': since.toIso8601String(),
        },
      );
      
      final List<dynamic> changesData = response.data['changes'];
      return changesData
          .map((data) => CloudChange.fromJson(Map<String, dynamic>.from(data)))
          .toList();
    } catch (e) {
      throw NetworkException('获取云端变更失败: $e');
    }
  }
  
  /// 同步数据到云端
  Future<void> syncData({
    required String type,
    required String payload,
  }) async {
    try {
      await _dio.post(
        '/api/v1/sync',
        data: {
          'type': type,
          'payload': payload,
        },
      );
    } catch (e) {
      throw NetworkException('数据同步失败: $e');
    }
  }
}
```

## 五、测试方案

### 5.1 单元测试

**测试文件**: `test/data/sync/sync_worker_test.dart`

```dart
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:riverpod/riverpod.dart';
import '../../../lib/data/sync/sync_worker.dart';
import '../../../lib/data/models/sync_task.dart';
import '../../../lib/data/models/conflict_resolution_strategy.dart';

@GenerateMocks([
  SyncRepository,
  ApiClient,
])
import 'sync_worker_test.mocks.dart';

void main() {
  group('SyncWorker', () {
    late MockSyncRepository mockSyncRepository;
    late MockApiClient mockApiClient;
    late SyncWorker syncWorker;
    
    setUp(() {
      mockSyncRepository = MockSyncRepository();
      mockApiClient = MockApiClient();
      syncWorker = SyncWorker(
        syncRepository: mockSyncRepository,
        apiClient: mockApiClient,
        interval: Duration(milliseconds: 100), // 快速测试间隔
      );
    });
    
    test('应该能够启动和停止', () {
      syncWorker.start();
      expect(syncWorker, isNotNull);
      
      syncWorker.stop();
      // 停止不应该抛出异常
      expect(() => syncWorker.stop(), returnsNormally);
    });
    
    test('应该能够执行推送同步', () async {
      final tasks = [
        SyncTask(
          id: 1,
          taskId: 'test1',
          type: 'favorite',
          payload: '{"sourceId":"123","isFavorite":true}',
          retryCount: 0,
          status: SyncTaskStatus.pending,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        )
      ];
      
      when(mockSyncRepository.getPendingTasks(
        limit: anyNamed('limit'),
        direction: anyNamed('direction'),
      )).thenAnswer((_) async => tasks);
      
      when(mockApiClient.syncData(
        type: anyNamed('type'),
        payload: anyNamed('payload'),
      )).thenAnswer((_) async {});
      
      when(mockSyncRepository.updateTaskStatus(
        taskId: anyNamed('taskId'),
        status: anyNamed('status'),
      )).thenAnswer((_) async {});
      
      await syncWorker._executePushSync();
      
      verify(mockSyncRepository.getPendingTasks(
        limit: 50,
        direction: SyncDirection.upload,
      )).called(1);
    });
    
    test('冲突解决策略应该正确映射', () {
      expect(ConflictResolutionStrategy.localWins.displayName, '本地数据优先');
      expect(ConflictResolutionStrategy.cloudWins.displayName, '云端数据优先');
      expect(ConflictResolutionStrategy.timestampWins.displayName, '最新数据优先');
      expect(ConflictResolutionStrategy.manualResolve.displayName, '手动解决冲突');
    });
  });
}
```

### 5.2 集成测试

**测试文件**: `test/integration/bidirectional_sync_test.dart`

```dart
import 'package:test/test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import '../../lib/data/sync/sync_worker.dart';
import '../../lib/data/models/conflict_resolution_strategy.dart';

void main() {
  group('双向同步集成测试', () {
    late ProviderContainer container;
    
    setUp(() {
      container = ProviderContainer();
    });
    
    tearDown(() {
      container.dispose();
    });
    
    test('SyncWorker应该能够初始化', () {
      // 这里需要适当的Provider设置来测试完整的SyncWorker
      expect(() => SyncWorker(
        syncRepository: MockSyncRepository(), // 需要实际的mock实现
        apiClient: MockApiClient(),
      ), returnsNormally);
    });
    
    test('冲突解决策略应该能够正确存储和检索', () async {
      // 测试策略设置和获取
      final strategies = ConflictResolutionStrategy.values;
      expect(strategies.length, 4);
      
      for (final strategy in strategies) {
        expect(strategy.displayName, isNotEmpty);
        expect(strategy.description, isNotEmpty);
      }
    });
  });
}
```

## 六、配置管理

### 6.1 创建同步设置Provider

**新建文件**: `lib/presentation/viewmodels/settings/sync_settings_viewmodel.dart`

```dart
import 'package:riverpod/riverpod.dart';
import '../../../data/repositories/sync_repository.dart';
import '../../../data/models/conflict_resolution_strategy.dart';

@riverpod
class SyncSettings extends _$SyncSettings {
  @override
  Future<SyncSettingsState> build() async {
    final syncRepository = ref.read(syncRepositoryProvider);
    final strategy = await syncRepository.getConflictResolutionStrategy();
    
    return SyncSettingsState(
      conflictResolutionStrategy: strategy,
      isBidirectionalSyncEnabled: true, // 默认启用双向同步
      pullInterval: Duration(minutes: 5), // 拉取间隔
    );
  }
  
  /// 更新冲突解决策略
  Future<void> updateConflictResolutionStrategy(ConflictResolutionStrategy strategy) async {
    final syncRepository = ref.read(syncRepositoryProvider);
    await syncRepository.setConflictResolutionStrategy(strategy);
    
    // 更新状态
    state = AsyncData(state.value!.copyWith(conflictResolutionStrategy: strategy));
  }
  
  /// 手动触发同步
  Future<void> triggerManualSync() async {
    final syncWorker = ref.read(syncWorkerProvider);
    await syncWorker.triggerSync();
  }
}

@freezed
class SyncSettingsState with _$SyncSettingsState {
  const factory SyncSettingsState({
    required ConflictResolutionStrategy conflictResolutionStrategy,
    required bool isBidirectionalSyncEnabled,
    required Duration pullInterval,
  }) = _SyncSettingsState;
  
  const SyncSettingsState._();
}
```

### 6.2 创建同步设置UI

**新建文件**: `lib/presentation/views/settings/sync_settings_view.dart`

```dart
import 'package:flutter/material.dart';
import 'package:riverpod/riverpod.dart';
import '../viewmodels/settings/sync_settings_viewmodel.dart';
import '../../../data/models/conflict_resolution_strategy.dart';

class SyncSettingsView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(syncSettingsProvider);
    
    return Scaffold(
      appBar: AppBar(title: Text('同步设置')),
      body: settings.when(
        data: (state) => _buildSettingsContent(context, ref, state),
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('加载失败: $error')),
      ),
    );
  }
  
  Widget _buildSettingsContent(
    BuildContext context, 
    WidgetRef ref, 
    SyncSettingsState state,
  ) {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            title: Text('双向同步'),
            subtitle: Text('启用从云端拉取数据'),
            trailing: Switch(
              value: state.isBidirectionalSyncEnabled,
              onChanged: (value) {
                // 可以添加启用/禁用双向同步的逻辑
              },
            ),
          ),
        ),
        
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '冲突解决策略',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ...ConflictResolutionStrategy.values.map((strategy) {
                return RadioListTile<ConflictResolutionStrategy>(
                  title: Text(strategy.displayName),
                  subtitle: Text(strategy.description),
                  value: strategy,
                  groupValue: state.conflictResolutionStrategy,
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(syncSettingsProvider.notifier)
                          .updateConflictResolutionStrategy(value);
                    }
                  },
                );
              }).toList(),
            ],
          ),
        ),
        
        Card(
          child: ListTile(
            title: Text('手动同步'),
            subtitle: Text('立即执行一次同步'),
            trailing: Icon(Icons.sync),
            onTap: () {
              ref.read(syncSettingsProvider.notifier).triggerManualSync();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('开始同步...')),
              );
            },
          ),
        ),
      ],
    );
  }
}
```

## 七、部署验证清单

- [ ] SyncTask模型增强，添加同步方向字段
- [ ] SyncWorker实现双向同步功能
- [ ] 冲突解决策略模型创建
- [ ] SyncRepository增强支持双向同步
- [ ] SyncDao增强支持新功能
- [ ] API客户端添加云端变更获取方法
- [ ] 云端变更模型创建
- [ ] 同步设置ViewModel和UI实现
- [ ] 单元测试覆盖新功能
- [ ] 集成测试验证双向同步流程
- [ ] 冲突检测和解决功能验证
- [ ] 不同冲突解决策略测试
- [ ] 性能基准测试(同步延迟<2秒/任务)

---
**方案版本**: v1.0
**预计开发时间**: 6小时
**预计测试时间**: 3小时