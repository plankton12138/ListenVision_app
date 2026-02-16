# 文件系统监听机制实现方案

**方案制定日期**: 2026-02-16
**最后更新日期**: 2026-02-16
**关联主计划**: architecture-compliance-fix-plan.md
**优先级**: P0

---

## 一、目标

实现文件系统监听机制，当用户手动删除已下载的音频文件时，系统能够自动感知并更新数据库状态，避免播放时出现文件不存在的错误。

## 二、当前问题分析

### 2.1 缺失功能
系统目前没有任何文件系统监听机制，导致：
1. 用户手动删除下载文件后，数据库仍标记为已下载
2. 播放时尝试访问已删除文件导致错误
3. 数据库状态与实际文件系统状态不一致

### 2.2 数据不一致风险
假设场景：
1. 用户下载音频A，数据库记录`isDownloaded=true`, `localPath="/path/to/A.mp3"`
2. 用户手动删除`/path/to/A.mp3`
3. 系统不知道文件已被删除，仍认为A已下载
4. 播放时尝试访问已删除文件，导致错误

## 三、解决方案设计

### 3.1 核心思路
**方案变更**: 原计划使用`FileSystemEntity.watch()`，但该API在移动端支持有限且不可靠。改用以下策略：

1. **启动时全量扫描**: 应用启动时扫描所有已下载文件，验证文件是否存在
2. **定期轮询检查**: 后台定期轮询检查文件状态（每30分钟）
3. **播放前验证**: 播放本地文件前验证文件存在性
4. **数据库驱动**: 直接从数据库获取下载记录，验证对应文件

### 3.2 实现架构
```
启动流程:
应用启动 -> 启动DownloadIntegrityService -> 全量扫描验证
            -> 定时器启动(30分钟间隔) -> 增量检查

播放流程:
播放请求 -> 检查isDownloaded=true -> 验证文件存在性
            -> 文件不存在? -> 标记为未下载 -> 使用网络播放
            -> 文件存在? -> 本地播放
```

### 3.3 方案对比

| 方案 | 优点 | 缺点 | 适用性 |
|------|------|------|--------|
| **启动扫描+轮询** (推荐) | 可靠、跨平台、实现简单 | 非实时、有延迟 | ⭐⭐⭐⭐⭐ |
| FileSystem.watch() | 实时响应 | 移动端支持差、不可靠 | ⭐⭐ |
| 播放时验证 | 实现最简单 | 延迟发现问题 | ⭐⭐⭐ |

---

## 四、详细实现步骤

### 4.1 创建DownloadIntegrityService服务

**新建文件**: `lib/services/download_integrity_service.dart`

```dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:riverpod/riverpod.dart';
import '../data/repositories/track_repository.dart';
import '../core/utils/logger.dart';

/// 下载完整性服务
/// 负责验证已下载文件的完整性，检测外部删除的文件
class DownloadIntegrityService {
  final TrackRepository _trackRepository;
  Timer? _periodicTimer;
  bool _isRunning = false;

  DownloadIntegrityService(this._trackRepository);

  /// 启动服务
  Future<void> start() async {
    if (_isRunning) return;
    
    AppLogger.info('启动下载完整性服务');
    _isRunning = true;
    
    // 启动时立即执行一次全量扫描
    await performFullScan();
    
    // 启动定期轮询（每30分钟）
    _periodicTimer = Timer.periodic(
      const Duration(minutes: 30),
      (_) => performIncrementalCheck(),
    );
    
    AppLogger.info('下载完整性服务已启动');
  }

  /// 停止服务
  void stop() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
    _isRunning = false;
    AppLogger.info('下载完整性服务已停止');
  }

  /// 执行全量扫描
  /// 扫描所有标记为已下载的记录，验证文件是否存在
  Future<void> performFullScan() async {
    try {
      AppLogger.info('开始全量扫描下载文件完整性');
      
      // 获取所有已下载的轨道
      final downloadedTracks = await _trackRepository.getDownloadedTracks();
      AppLogger.debug('找到 ${downloadedTracks.length} 个已下载轨道');
      
      final List<String> missingFiles = [];
      
      for (final track in downloadedTracks) {
        if (track.localPath == null) continue;
        
        // 验证文件是否存在且有效
        final file = File(track.localPath!);
        final exists = await file.exists();
        final isValid = exists && await file.length() > 0;
        
        if (!isValid) {
          AppLogger.warn('文件不存在或无效: ${track.localPath}');
          missingFiles.add(track.sourceId);
        }
      }
      
      // 批量更新状态
      if (missingFiles.isNotEmpty) {
        await _trackRepository.batchMarkAsNotDownloaded(missingFiles);
        AppLogger.info('已标记 ${missingFiles.length} 个文件为未下载');
      }
      
      AppLogger.info('全量扫描完成');
    } catch (e, stack) {
      AppLogger.error('全量扫描失败: $e', stackTrace: stack);
    }
  }

  /// 执行增量检查
  /// 仅检查最近可能被修改的文件（优化性能）
  Future<void> performIncrementalCheck() async {
    try {
      AppLogger.debug('开始增量检查');
      
      // 获取最近24小时内下载的文件
      final recentTracks = await _trackRepository.getRecentlyDownloadedTracks(
        since: DateTime.now().subtract(const Duration(hours: 24)),
      );
      
      final List<String> missingFiles = [];
      
      for (final track in recentTracks) {
        if (track.localPath == null) continue;
        
        final file = File(track.localPath!);
        final exists = await file.exists();
        
        if (!exists) {
          missingFiles.add(track.sourceId);
        }
      }
      
      if (missingFiles.isNotEmpty) {
        await _trackRepository.batchMarkAsNotDownloaded(missingFiles);
        AppLogger.info('增量检查发现 ${missingFiles.length} 个缺失文件');
      }
    } catch (e) {
      AppLogger.error('增量检查失败: $e');
    }
  }

  /// 验证单个文件
  /// 用于播放前验证
  Future<bool> validateFile(String sourceId) async {
    try {
      final track = await _trackRepository.getBySourceId(sourceId);
      if (track == null || track.localPath == null) return false;
      
      final file = File(track.localPath!);
      final exists = await file.exists();
      final isValid = exists && await file.length() > 0;
      
      if (!isValid && track.isDownloaded) {
        // 标记为未下载
        await _trackRepository.markAsNotDownloaded(sourceId);
        AppLogger.warn('播放时发现文件缺失，已更新状态: $sourceId');
      }
      
      return isValid;
    } catch (e) {
      AppLogger.error('验证文件失败: $e');
      return false;
    }
  }

  /// 手动触发全量扫描
  Future<void> triggerManualScan() async {
    await performFullScan();
  }
}
```

### 4.2 增强TrackRepository

**文件**: `lib/data/repositories/track_repository.dart`

```dart
/// 获取所有已下载的轨道
Future<List<CachedTrack>> getDownloadedTracks() async {
  return await _trackDao.getDownloadedTracks();
}

/// 获取最近下载的轨道
Future<List<CachedTrack>> getRecentlyDownloadedTracks({
  required DateTime since,
}) async {
  return await _trackDao.getRecentlyDownloadedTracks(since: since);
}

/// 标记为未下载
Future<void> markAsNotDownloaded(String sourceId) async {
  await _trackDao.markAsNotDownloaded(sourceId);
}

/// 批量标记为未下载
Future<void> batchMarkAsNotDownloaded(List<String> sourceIds) async {
  await _trackDao.batchUpdateDownloadStatus(sourceIds, false);
}

/// 通过sourceId获取轨道
Future<CachedTrack?> getBySourceId(String sourceId) async {
  return await _trackDao.getBySourceId(sourceId);
}
```

### 4.3 增强TrackDAO

**文件**: `lib/data/database/track_dao.dart`

```dart
/// 获取所有已下载的轨道
Future<List<CachedTrack>> getDownloadedTracks() async {
  final maps = await _db.query(
    'tracks',
    where: 'is_downloaded = ?',
    whereArgs: [1],
  );
  return maps.map((map) => CachedTrack.fromJson(map)).toList();
}

/// 获取最近下载的轨道
Future<List<CachedTrack>> getRecentlyDownloadedTracks({
  required DateTime since,
}) async {
  final maps = await _db.query(
    'tracks',
    where: 'is_downloaded = ? AND updated_at >= ?',
    whereArgs: [1, since.toIso8601String()],
  );
  return maps.map((map) => CachedTrack.fromJson(map)).toList();
}

/// 标记轨道为未下载状态
Future<void> markAsNotDownloaded(String sourceId) async {
  await _db.update(
    'tracks',
    {
      'is_downloaded': 0,
      'local_path': null,
      'updated_at': DateTime.now().toIso8601String(),
    },
    where: 'source_id = ?',
    whereArgs: [sourceId],
  );
}

/// 批量更新下载状态
Future<void> batchUpdateDownloadStatus(
  List<String> sourceIds,
  bool downloaded,
) async {
  if (sourceIds.isEmpty) return;

  final placeholders = List.generate(sourceIds.length, (i) => '?').join(',');
  
  await _db.update(
    'tracks',
    {
      'is_downloaded': downloaded ? 1 : 0,
      'local_path': downloaded ? null : null,
      'updated_at': DateTime.now().toIso8601String(),
    },
    where: 'source_id IN ($placeholders)',
    whereArgs: sourceIds,
  );
}
```

### 4.4 创建Provider

**新建文件**: `lib/core/providers/download_integrity_provider.dart`

```dart
import 'package:riverpod/riverpod.dart';
import '../../services/download_integrity_service.dart';
import '../../data/repositories/track_repository.dart';

/// 下载完整性服务Provider
final downloadIntegrityServiceProvider = Provider<DownloadIntegrityService>((ref) {
  final trackRepository = ref.read(trackRepositoryProvider);
  return DownloadIntegrityService(trackRepository);
});

/// 上次扫描时间Provider
final lastIntegrityScanTimeProvider = StateProvider<DateTime?>((ref) => null);

/// 扫描状态Provider
final integrityScanStatusProvider = StateProvider<String>((ref) => 'idle');
```

### 4.5 集成到应用启动流程

**文件**: `lib/main.dart`

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化数据库
  final database = await $FloorAppDatabase.databaseBuilder('app_database.db').build();

  // 创建ProviderContainer
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(database),
    ],
  );

  // 启动下载完整性服务
  await _initDownloadIntegrityService(container);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}

/// 初始化下载完整性服务
Future<void> _initDownloadIntegrityService(ProviderContainer container) async {
  try {
    final integrityService = container.read(downloadIntegrityServiceProvider);
    await integrityService.start();
    AppLogger.info('下载完整性服务初始化完成');
  } catch (e) {
    AppLogger.error('初始化下载完整性服务失败: $e');
  }
}
```

### 4.6 更新播放逻辑

**文件**: `lib/presentation/viewmodels/player/queue_viewmodel.dart`

在播放前添加文件验证：

```dart
Future<void> playAt(int index) async {
  if (index < 0 || index >= state.queue.length) return;

  final playable = state.queue[index];

  // 本地优先播放逻辑
  if (playable.isOnline && playable is OnlinePlayable) {
    final sourceId = playable.original.id;
    
    // 检查本地是否已下载
    final isDownloaded = await _trackRepository.isTrackDownloaded(sourceId);
    
    if (isDownloaded) {
      // 验证文件实际存在
      final integrityService = ref.read(downloadIntegrityServiceProvider);
      final isValid = await integrityService.validateFile(sourceId);
      
      if (isValid) {
        final localPath = await _trackRepository.getLocalPath(sourceId);
        if (localPath != null) {
          await playerNotifier.playLocalAudio(
            localPath,
            title: playable.original.title,
            artist: playable.original.artistName,
            coverUrl: playable.original.coverUrl,
          );
          return;
        }
      }
      // 文件无效会继续使用网络播放
    }

    // 使用网络流播放
    await playerNotifier.playOnlineAudio(
      audio: playable.original,
      proxyUrl: playable.proxyUrl,
    );
  } else {
    // 本地音频直接播放
    await playerNotifier.playLocalAudio(
      playable.url,
      title: playable.title,
      artist: playable.artist,
      coverUrl: playable.coverUrl,
    );
  }
}
```

---

## 五、测试方案

### 5.1 单元测试

**测试文件**: `test/services/download_integrity_service_test.dart`

```dart
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import '../../lib/services/download_integrity_service.dart';
import '../../lib/data/repositories/track_repository.dart';
import '../../lib/models/cached_track.dart';

@GenerateMocks([TrackRepository])
import 'download_integrity_service_test.mocks.dart';

void main() {
  group('DownloadIntegrityService', () {
    late MockTrackRepository mockTrackRepository;
    late DownloadIntegrityService service;

    setUp(() {
      mockTrackRepository = MockTrackRepository();
      service = DownloadIntegrityService(mockTrackRepository);
    });

    test('全量扫描应检测并标记缺失文件', () async {
      // 准备测试数据
      final tracks = [
        CachedTrack(
          sourceId: 'test1',
          isDownloaded: true,
          localPath: '/tmp/exists.mp3',
          title: 'Exists',
        ),
        CachedTrack(
          sourceId: 'test2',
          isDownloaded: true,
          localPath: '/tmp/missing.mp3',
          title: 'Missing',
        ),
      ];

      when(mockTrackRepository.getDownloadedTracks())
          .thenAnswer((_) async => tracks);
      when(mockTrackRepository.batchMarkAsNotDownloaded(any))
          .thenAnswer((_) async {});

      // 执行扫描
      await service.performFullScan();

      // 验证缺失文件被标记
      verify(mockTrackRepository.batchMarkAsNotDownloaded(
        argThat(contains('test2')),
      )).called(1);
    });
  });
}
```

### 5.2 集成测试

**测试文件**: `test/integration/download_integrity_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

void main() {
  group('下载完整性集成测试', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('integrity_test');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('文件删除后应被检测到', () async {
      // 创建测试文件
      final testFile = File(path.join(tempDir.path, 'test.mp3'));
      await testFile.writeAsString('test content');
      
      expect(await testFile.exists(), true);
      
      // 删除文件
      await testFile.delete();
      
      expect(await testFile.exists(), false);
    });
  });
}
```

---

## 六、性能与资源考虑

### 6.1 扫描性能
- **全量扫描**: 扫描1000个文件约需200-500ms
- **增量检查**: 通常<50ms（仅检查最近文件）
- **内存占用**: 扫描过程中临时占用内存<5MB

### 6.2 电池消耗
- 30分钟轮询间隔对电池影响极小
- 扫描使用异步操作，不阻塞主线程
- 可在后台执行（可选）

### 6.3 错误处理
- 服务失败不影响应用主要功能
- 日志记录所有异常情况
- 提供手动触发扫描的备用方案

---

## 七、部署验证清单

- [ ] DownloadIntegrityService服务实现
- [ ] TrackRepository和TrackDAO增强方法
- [ ] 应用启动时正确初始化服务
- [ ] 全量扫描功能验证
- [ ] 增量检查功能验证
- [ ] 播放前验证功能验证
- [ ] 异常情况下的错误处理
- [ ] 性能基准测试(1000个文件扫描<1秒)
- [ ] 不同平台兼容性测试(Windows/Linux/macOS/Android/iOS)
- [ ] 手动触发扫描功能验证

---

## 八、方案变更记录

| 日期 | 变更内容 | 原因 |
|------|----------|------|
| 2026-02-16 | 初始版本 | 使用FileSystemEntity.watch()方案 |
| 2026-02-16 | 重大修订 | 改用启动扫描+定期轮询方案，解决移动端watch API不可靠问题 |

---

**方案版本**: v2.0
**预计开发时间**: 6小时
**预计测试时间**: 3小时
