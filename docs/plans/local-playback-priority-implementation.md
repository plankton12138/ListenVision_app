# 本地优先播放策略实现方案

**方案制定日期**: 2026-02-16
**关联主计划**: architecture-compliance-fix-plan.md
**优先级**: P0
**状态**: ✅ 已完成
**完成报告**: [Phase 1 完成报告](../reports/phase1-completion-report.md)

---
## 一、目标

实现播放时优先使用本地文件的策略，即使音频标记为在线资源，如果本地已下载则优先使用本地文件播放。

## 二、当前问题分析

### 2.1 播放逻辑缺陷
当前播放逻辑(`controls_panel.dart:80-99`)仅根据`isOnline`布尔值决定播放方式：
```dart
void _playPlayable(BuildContext context, WidgetRef ref, PlayableAudio playable) {
  if (playable.isOnline) {
    // 在线音频 - 直接播放网络流
    playerViewModel.playOnlineAudio(
      audio: playable.original,
      proxyUrl: playable.proxyUrl,
    );
  } else {
    // 本地音频 - 使用本地文件
    playerViewModel.playLocalAudio(playable.url, ...);
  }
}
```

### 2.2 数据模型未充分利用
`CachedTrack`模型包含有用字段但未被播放逻辑使用：
- `isDownloaded`: 标记是否已下载
- `localPath`: 本地文件路径

## 三、解决方案设计

### 3.1 核心思路
在播放前增加本地文件检查步骤：
1. 对于标记为在线的音频，首先检查是否已在本地下载
2. 如果已下载且文件存在，则使用本地路径播放
3. 只有在本地文件不可用时才使用网络流

### 3.2 实现架构
```
播放请求 -> 检查本地文件 -> 本地可用? -> 本地播放
                    |                  -> 网络播放
                    -> 未下载
```

## 四、详细实现步骤

### 4.1 增强TrackRepository

**文件**: `lib/data/repositories/track_repository.dart`

新增方法：
```dart
/// 检查指定sourceId的轨道是否已下载
Future<bool> isTrackDownloaded(String sourceId) async {
  final track = await _trackDao.getBySourceId(sourceId);
  return track?.isDownloaded ?? false;
}

/// 获取本地文件路径
Future<String?> getLocalPath(String sourceId) async {
  final track = await _trackDao.getBySourceId(sourceId);
  return track?.localPath;
}

/// 验证本地文件是否存在且有效
Future<bool> validateLocalFile(String sourceId) async {
  final localPath = await getLocalPath(sourceId);
  if (localPath == null) return false;
  
  final file = File(localPath);
  return await file.exists() && await file.length() > 0;
}
```

### 4.2 修改QueueViewModel播放逻辑

**文件**: `lib/presentation/viewmodels/player/queue_viewmodel.dart`

修改`playAt`方法：
```dart
Future<void> playAt(int index) async {
  if (index < 0 || index >= state.queue.length) return;
  
  final playable = state.queue[index];
  
  // 本地优先播放逻辑
  if (playable.isOnline && playable is OnlinePlayable) {
    final sourceId = playable.original.id;
    
    // 检查本地是否已下载且文件有效
    final isDownloaded = await _trackRepository.isTrackDownloaded(sourceId);
    if (isDownloaded) {
      final isValidLocalFile = await _trackRepository.validateLocalFile(sourceId);
      if (isValidLocalFile) {
        final localPath = await _trackRepository.getLocalPath(sourceId);
        if (localPath != null) {
          // 使用本地文件播放
          await playerNotifier.playLocalAudio(
            localPath,
            title: playable.original.title,
            artist: playable.original.artistName,
            coverUrl: playable.original.coverUrl,
          );
          return;
        }
      } else {
        // 本地文件无效，标记为未下载
        await _trackRepository.markAsNotDownloaded(sourceId);
      }
    }
    
    // 本地不存在或无效，使用网络流播放
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

### 4.3 更新ControlsPanel播放逻辑

**文件**: `lib/presentation/widgets/controls_panel.dart`

修改`_playPlayable`方法：
```dart
void _playPlayable(BuildContext context, WidgetRef ref, PlayableAudio playable) {
  final playerViewModel = ref.read(queueViewModelProvider.notifier);
  
  // 对于在线音频，让QueueViewModel处理本地优先逻辑
  if (playable.isOnline) {
    // 获取当前播放队列索引
    final queueState = ref.read(queueViewModelProvider);
    final currentIndex = queueState.queue.indexWhere((item) => item.id == playable.id);
    
    if (currentIndex != -1) {
      playerViewModel.playAt(currentIndex);
    } else {
      // 如果不在当前队列中，添加到队列并播放
      playerViewModel.addAndPlay(playable);
    }
  } else {
    // 本地音频直接播放
    playerViewModel.playLocalAudio(
      playable.url,
      title: playable.title,
      artist: playable.artist,
      coverUrl: playable.coverUrl,
    );
  }
}
```

## 五、测试方案

### 5.1 单元测试

**测试文件**: `test/data/repositories/track_repository_test.dart`

增加测试用例：
```dart
group('本地文件检查', () {
  test('已下载且文件存在的轨道应返回true', () async {
    // 准备测试数据
    final track = CachedTrack(
      sourceId: 'test123',
      isDownloaded: true,
      localPath: '/tmp/test.mp3',
      title: 'Test Track',
    );
    
    // 模拟文件存在
    when(() => mockFile.exists()).thenAnswer((_) async => true);
    when(() => mockFile.length()).thenAnswer((_) async => 1024);
    
    final result = await repository.validateLocalFile('test123');
    expect(result, true);
  });
  
  test('未下载的轨道应返回false', () async {
    final result = await repository.isTrackDownloaded('nonexistent');
    expect(result, false);
  });
});
```

### 5.2 集成测试

**测试文件**: `test/viewmodels/player/queue_viewmodel_test.dart`

增加测试用例：
```dart
group('本地优先播放', () {
  test('已下载的在线音频应优先使用本地文件播放', () async {
    // 设置已下载的轨道
    when(() => mockTrackRepository.isTrackDownloaded(any())).thenAnswer((_) async => true);
    when(() => mockTrackRepository.validateLocalFile(any())).thenAnswer((_) async => true);
    when(() => mockTrackRepository.getLocalPath(any())).thenAnswer((_) async => '/tmp/audio.mp3');
    
    // 执行播放
    await viewModel.playAt(0);
    
    // 验证调用了本地播放
    verify(() => mockPlayerNotifier.playLocalAudio(any(), title: any(named: 'title'))).called(1);
  });
  
  test('未下载的在线音频应使用网络流播放', () async {
    // 设置未下载的轨道
    when(() => mockTrackRepository.isTrackDownloaded(any())).thenAnswer((_) async => false);
    
    // 执行播放
    await viewModel.playAt(0);
    
    // 验证调用了网络播放
    verify(() => mockPlayerNotifier.playOnlineAudio(audio: any(named: 'audio'))).called(1);
  });
});
```

## 六、兼容性考虑

### 6.1 向后兼容
- 现有播放队列逻辑不受影响
- 本地音频播放逻辑保持不变
- 未下载的在线音频行为与之前一致

### 6.2 性能影响
- 文件存在性检查增加约1-2ms延迟
- 通过异步处理避免阻塞UI线程
- 缓存机制可进一步优化性能

## 七、部署验证清单

- [ ] TrackRepository新增方法实现并通过单元测试
- [ ] QueueViewModel播放逻辑修改并通过集成测试
- [ ] ControlsPanel调用逻辑调整
- [ ] 本地文件存在时优先播放功能验证
- [ ] 本地文件不存在时正常回退到网络播放验证
- [ ] 本地文件损坏时正确标记为未下载验证
- [ ] 性能基准测试(播放延迟<5ms)

---
**方案版本**: v1.0
**预计开发时间**: 4小时
**预计测试时间**: 2小时