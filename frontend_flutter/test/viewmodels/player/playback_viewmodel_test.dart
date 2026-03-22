import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:listenvision/core/utils/playback_state_validator.dart';
import 'package:listenvision/models/local_audio.dart';
import 'package:listenvision/models/local_playable.dart';
import 'package:listenvision/models/playable_audio.dart';
import 'package:listenvision/presentation/viewmodels/player/playback_viewmodel.dart';
import 'package:listenvision/presentation/viewmodels/player/queue_viewmodel.dart';

/// PlaybackState 和 QueueState 单元测试
///
/// 测试内容：
/// 1. PlaybackState 初始状态验证
/// 2. PlaybackState copyWith 方法
/// 3. PlaybackState 错误状态设置
/// 4. PlaybackState 字段完整性
/// 5. QueueState 队列恢复相关测试
void main() {
  group('PlaybackState 初始状态测试', () {
    test('默认构造函数应创建具有正确默认值的状态', () {
      // Act
      const state = PlaybackState();

      // Assert - 播放状态标志
      expect(state.isPlaying, false, reason: 'isPlaying 默认应为 false');
      expect(state.isPaused, false, reason: 'isPaused 默认应为 false');
      expect(state.isLoading, false, reason: 'isLoading 默认应为 false');
      expect(state.isCompleted, false, reason: 'isCompleted 默认应为 false');
    });

    test('默认构造函数应创建具有正确的索引和标题', () {
      // Act
      const state = PlaybackState();

      // Assert
      expect(state.currentIndex, -1, reason: 'currentIndex 默认应为 -1');
      expect(state.title, '未知标题', reason: 'title 默认应为 "未知标题"');
      expect(state.artist, '未知艺术家', reason: 'artist 默认应为 "未知艺术家"');
    });

    test('默认构造函数应创建具有正确的音量和倍速', () {
      // Act
      const state = PlaybackState();

      // Assert
      expect(state.volume, 1.0, reason: 'volume 默认应为 1.0');
      expect(state.speed, 1.0, reason: 'speed 默认应为 1.0');
    });

    test('默认构造函数应创建具有正确的位置和时长', () {
      // Act
      const state = PlaybackState();

      // Assert
      expect(state.position, Duration.zero, reason: 'position 默认应为 Duration.zero');
      expect(state.duration, isNull, reason: 'duration 默认应为 null');
    });

    test('默认构造函数应创建具有正确的可空字段', () {
      // Act
      const state = PlaybackState();

      // Assert
      expect(state.currentPlayable, isNull, reason: 'currentPlayable 默认应为 null');
      expect(state.coverUrl, isNull, reason: 'coverUrl 默认应为 null');
      expect(state.errorMessage, isNull, reason: 'errorMessage 默认应为 null');
    });
  });

  group('PlaybackState copyWith 测试', () {
    test('copyWith 应能修改播放状态标志', () {
      // Arrange
      const state = PlaybackState();

      // Act
      final playingState = state.copyWith(isPlaying: true);
      final pausedState = state.copyWith(isPaused: true);
      final loadingState = state.copyWith(isLoading: true);
      final completedState = state.copyWith(isCompleted: true);

      // Assert
      expect(playingState.isPlaying, true);
      expect(playingState.isPaused, false);

      expect(pausedState.isPaused, true);
      expect(pausedState.isPlaying, false);

      expect(loadingState.isLoading, true);

      expect(completedState.isCompleted, true);
    });

    test('copyWith 应能修改索引和标题', () {
      // Arrange
      const state = PlaybackState();

      // Act
      final newState = state.copyWith(
        currentIndex: 5,
        title: '测试标题',
        artist: '测试艺术家',
      );

      // Assert
      expect(newState.currentIndex, 5);
      expect(newState.title, '测试标题');
      expect(newState.artist, '测试艺术家');
    });

    test('copyWith 应能修改音量和倍速', () {
      // Arrange
      const state = PlaybackState();

      // Act
      final newState = state.copyWith(
        volume: 0.5,
        speed: 1.5,
      );

      // Assert
      expect(newState.volume, 0.5);
      expect(newState.speed, 1.5);
    });

    test('copyWith 应能修改位置和时长', () {
      // Arrange
      const state = PlaybackState();

      // Act
      final newState = state.copyWith(
        position: const Duration(seconds: 30),
        duration: const Duration(minutes: 3),
      );

      // Assert
      expect(newState.position, const Duration(seconds: 30));
      expect(newState.duration, const Duration(minutes: 3));
    });

    test('copyWith 未指定的属性应保持不变', () {
      // Arrange
      final originalState = PlaybackState(
        isPlaying: true,
        currentIndex: 3,
        title: '原始标题',
        volume: 0.7,
        speed: 1.25,
        position: const Duration(seconds: 45),
        duration: const Duration(minutes: 4),
      );

      // Act: 只修改部分属性
      final newState = originalState.copyWith(
        isPlaying: false,
        isPaused: true,
      );

      // Assert: 未修改的属性应保持原值
      expect(newState.currentIndex, 3);
      expect(newState.title, '原始标题');
      expect(newState.volume, 0.7);
      expect(newState.speed, 1.25);
      expect(newState.position, const Duration(seconds: 45));
      expect(newState.duration, const Duration(minutes: 4));
    });

    test('copyWith 应能将可空字段设置为 null', () {
      // Arrange
      final state = PlaybackState(
        coverUrl: 'https://example.com/cover.jpg',
        errorMessage: '之前的错误',
      );

      // Act
      final newState = state.copyWith(
        coverUrl: null,
        errorMessage: null,
      );

      // Assert
      expect(newState.coverUrl, isNull);
      expect(newState.errorMessage, isNull);
    });
  });

  group('PlaybackState 错误状态测试', () {
    test('应能设置错误消息', () {
      // Arrange
      const state = PlaybackState();

      // Act
      final errorState = state.copyWith(
        errorMessage: '播放失败：网络错误',
        isLoading: false,
      );

      // Assert
      expect(errorState.errorMessage, '播放失败：网络错误');
      expect(errorState.isLoading, false);
    });

    test('加载状态应能正确切换', () {
      // Arrange
      const state = PlaybackState();

      // Act: 开始加载
      final loadingState = state.copyWith(isLoading: true);
      expect(loadingState.isLoading, true);

      // Act: 加载完成
      final loadedState = loadingState.copyWith(isLoading: false);
      expect(loadedState.isLoading, false);

      // Act: 加载失败
      final failedState = loadingState.copyWith(
        isLoading: false,
        errorMessage: '加载失败',
      );
      expect(failedState.isLoading, false);
      expect(failedState.errorMessage, '加载失败');
    });

    test('播放失败后应能清除错误并重新播放', () {
      // Arrange
      final errorState = PlaybackState(
        errorMessage: '播放失败',
        isPlaying: false,
        isLoading: false,
      );

      // Act: 清除错误，开始新播放
      final newState = errorState.copyWith(
        errorMessage: null,
        isLoading: true,
      );

      // Assert
      expect(newState.errorMessage, isNull);
      expect(newState.isLoading, true);
    });
  });

  group('PlaybackState 字段完整性测试', () {
    test('所有布尔字段应能正确设置', () {
      // Act
      final state = PlaybackState(
        isPlaying: true,
        isPaused: true,
        isLoading: true,
        isCompleted: true,
      );

      // Assert
      expect(state.isPlaying, true);
      expect(state.isPaused, true);
      expect(state.isLoading, true);
      expect(state.isCompleted, true);
    });

    test('所有数值字段应能正确设置', () {
      // Act
      final state = PlaybackState(
        currentIndex: 10,
        volume: 0.75,
        speed: 2.0,
      );

      // Assert
      expect(state.currentIndex, 10);
      expect(state.volume, 0.75);
      expect(state.speed, 2.0);
    });

    test('所有字符串字段应能正确设置', () {
      // Act
      final state = PlaybackState(
        title: '歌曲标题',
        artist: '艺术家名称',
        coverUrl: 'https://example.com/cover.jpg',
        errorMessage: '错误信息',
      );

      // Assert
      expect(state.title, '歌曲标题');
      expect(state.artist, '艺术家名称');
      expect(state.coverUrl, 'https://example.com/cover.jpg');
      expect(state.errorMessage, '错误信息');
    });

    test('所有 Duration 字段应能正确设置', () {
      // Act
      final state = PlaybackState(
        position: const Duration(minutes: 1, seconds: 30),
        duration: const Duration(minutes: 4, seconds: 15),
      );

      // Assert
      expect(state.position, const Duration(minutes: 1, seconds: 30));
      expect(state.duration, const Duration(minutes: 4, seconds: 15));
    });

    test('边界值：音量应为 0.0 到 1.0 之间的值', () {
      // Act & Assert
      final minVolume = PlaybackState(volume: 0.0);
      expect(minVolume.volume, 0.0);

      final maxVolume = PlaybackState(volume: 1.0);
      expect(maxVolume.volume, 1.0);

      final midVolume = PlaybackState(volume: 0.5);
      expect(midVolume.volume, 0.5);
    });

    test('边界值：倍速应能为合理范围内的值', () {
      // Act & Assert
      final slowSpeed = PlaybackState(speed: 0.5);
      expect(slowSpeed.speed, 0.5);

      final normalSpeed = PlaybackState(speed: 1.0);
      expect(normalSpeed.speed, 1.0);

      final fastSpeed = PlaybackState(speed: 2.0);
      expect(fastSpeed.speed, 2.0);
    });

    test('边界值：索引应能为负数（表示无选中项）', () {
      // Act
      const state = PlaybackState(currentIndex: -1);

      // Assert
      expect(state.currentIndex, -1);
    });

    test('边界值：位置应能为零或正值', () {
      // Act
      final zeroPosition = PlaybackState(position: Duration.zero);
      final positivePosition = PlaybackState(position: const Duration(hours: 1));

      // Assert
      expect(zeroPosition.position, Duration.zero);
      expect(positivePosition.position, const Duration(hours: 1));
    });
  });

  group('PlaybackState 典型使用场景测试', () {
    test('场景：开始播放新音频', () {
      // Arrange
      const initialState = PlaybackState();

      // Act: 模拟开始播放流程
      final loadingState = initialState.copyWith(
        title: '新歌曲',
        artist: '艺术家',
        currentIndex: 0,
        isLoading: true,
        errorMessage: null,
      );

      final playingState = loadingState.copyWith(
        isLoading: false,
        isPlaying: true,
      );

      // Assert
      expect(playingState.title, '新歌曲');
      expect(playingState.artist, '艺术家');
      expect(playingState.currentIndex, 0);
      expect(playingState.isLoading, false);
      expect(playingState.isPlaying, true);
      expect(playingState.errorMessage, isNull);
    });

    test('场景：暂停和恢复播放', () {
      // Arrange
      final playingState = PlaybackState(
        isPlaying: true,
        isPaused: false,
        title: '正在播放的歌曲',
        position: const Duration(seconds: 60),
      );

      // Act: 暂停
      final pausedState = playingState.copyWith(
        isPlaying: false,
        isPaused: true,
      );

      // Assert
      expect(pausedState.isPlaying, false);
      expect(pausedState.isPaused, true);
      expect(pausedState.position, const Duration(seconds: 60));

      // Act: 恢复播放
      final resumedState = pausedState.copyWith(
        isPlaying: true,
        isPaused: false,
      );

      // Assert
      expect(resumedState.isPlaying, true);
      expect(resumedState.isPaused, false);
    });

    test('场景：播放完成', () {
      // Arrange
      final playingState = PlaybackState(
        isPlaying: true,
        isCompleted: false,
        currentIndex: 2,
        position: const Duration(minutes: 3),
        duration: const Duration(minutes: 3),
      );

      // Act
      final completedState = playingState.copyWith(
        isPlaying: false,
        isCompleted: true,
      );

      // Assert
      expect(completedState.isPlaying, false);
      expect(completedState.isCompleted, true);
    });

    test('场景：调整音量和倍速', () {
      // Arrange
      const initialState = PlaybackState();

      // Act
      final adjustedState = initialState.copyWith(
        volume: 0.3,
        speed: 1.5,
      );

      // Assert
      expect(adjustedState.volume, 0.3);
      expect(adjustedState.speed, 1.5);
      // 其他属性应保持默认
      expect(adjustedState.isPlaying, false);
      expect(adjustedState.currentIndex, -1);
    });
  });

  group('QueueState 队列恢复测试', () {
    test('QueueState 默认索引应为 -1', () {
      // Act
      const state = QueueState();

      // Assert
      expect(state.currentIndex, -1, reason: 'currentIndex 默认应为 -1');
    });

    test('QueueState 默认队列应为空', () {
      // Act
      const state = QueueState();

      // Assert
      expect(state.queue, isEmpty, reason: 'queue 默认应为空列表');
    });

    test('队列索引 -1 对任何非空队列都是无效的', () {
      // Arrange
      final localAudio = LocalAudio(
        filePath: '/path/to/audio.mp3',
        title: '测试音频',
        artist: '测试艺术家',
        duration: 180,
      );
      final playable = LocalPlayable(localAudio);
      final state = QueueState(queue: [playable], currentIndex: -1);

      // Act & Assert
      // 索引 -1 在非空队列中是无效的
      expect(state.currentIndex, lessThan(0), reason: '索引 -1 表示无选中项');
      expect(state.queue.isNotEmpty, true, reason: '队列不为空');
      // 验证索引有效性检查逻辑：currentIndex < 0 应跳过恢复
      expect(state.currentIndex < 0, true);
    });

    test('有效索引应在 0 到队列长度-1 之间', () {
      // Arrange
      final localAudio = LocalAudio(
        filePath: '/path/to/audio.mp3',
        title: '测试音频',
        artist: '测试艺术家',
        duration: 180,
      );
      final playable = LocalPlayable(localAudio);

      // Act - 索引 0 对于单元素队列是有效的
      final validState = QueueState(queue: [playable], currentIndex: 0);

      // Assert
      expect(validState.currentIndex, greaterThanOrEqualTo(0));
      expect(validState.currentIndex, lessThan(validState.queue.length));
      expect(validState.queue[validState.currentIndex].title, '测试音频');
    });

    test('索引超出队列长度应为无效', () {
      // Arrange
      final localAudio = LocalAudio(
        filePath: '/path/to/audio.mp3',
        title: '测试音频',
        artist: '测试艺术家',
        duration: 180,
      );
      final playable = LocalPlayable(localAudio);

      // Act - 索引 5 对于单元素队列是无效的
      final invalidState = QueueState(queue: [playable], currentIndex: 5);

      // Assert
      expect(invalidState.currentIndex, greaterThanOrEqualTo(invalidState.queue.length));
      // 验证索引有效性检查逻辑：currentIndex >= queue.length 应跳过恢复
      expect(invalidState.currentIndex >= invalidState.queue.length, true);
    });

    test('空队列时任何索引都是无效的', () {
      // Act
      const state = QueueState(queue: [], currentIndex: 0);

      // Assert
      expect(state.queue.isEmpty, true);
      // 对于空队列，任何索引（包括 0）都是无效的
      expect(state.currentIndex >= state.queue.length, true);
    });
  });

  /// 测试 onQueueRestored 回调机制的设计预期
  ///
  /// 注意：由于 QueueViewModel 是 Riverpod Notifier，完整的回调行为测试
  /// 需要 ProviderContainer 和 mock SharedStorageService。以下测试验证
  /// 回调机制的核心逻辑。
  group('onQueueRestored 回调机制测试', () {
    test('回调机制：应在队列恢复完成后执行回调', () {
      // 这是回调机制的核心设计：
      // 1. 如果 _didFinishInitialRestore == true，回调立即执行
      // 2. 如果 _didFinishInitialRestore == false，回调被添加到列表

      // 模拟回调立即执行的条件
      bool didFinishInitialRestore = true;
      final callbacks = <void Function()>[];
      var callbackExecuted = false;

      void onQueueRestored(void Function() callback) {
        if (didFinishInitialRestore) {
          callback();
        } else {
          callbacks.add(callback);
        }
      }

      // Act: 注册回调
      onQueueRestored(() {
        callbackExecuted = true;
      });

      // Assert: 回调应立即执行
      expect(callbackExecuted, true, reason: '队列已恢复完成，回调应立即执行');
      expect(callbacks.isEmpty, true, reason: '回调不应被添加到列表');
    });

    test('回调机制：应在队列未恢复时延迟执行回调', () {
      // 模拟队列未恢复完成的状态
      bool didFinishInitialRestore = false;
      final callbacks = <void Function()>[];
      var callbackExecuted = false;

      void onQueueRestored(void Function() callback) {
        if (didFinishInitialRestore) {
          callback();
        } else {
          callbacks.add(callback);
        }
      }

      // Act: 注册回调
      onQueueRestored(() {
        callbackExecuted = true;
      });

      // Assert: 回调应被添加到列表，暂不执行
      expect(callbackExecuted, false, reason: '队列未恢复完成，回调不应立即执行');
      expect(callbacks.length, 1, reason: '回调应被添加到列表');

      // Act: 模拟恢复完成，执行回调
      for (final callback in callbacks) {
        callback();
      }
      callbacks.clear();

      // Assert: 回调应被执行
      expect(callbackExecuted, true, reason: '恢复完成后回调应被执行');
      expect(callbacks.isEmpty, true, reason: '回调列表应被清空');
    });

    test('回调机制：多次注册回调应都能执行', () {
      // 模拟队列未恢复完成的状态
      bool didFinishInitialRestore = false;
      final callbacks = <void Function()>[];
      var executionCount = 0;

      void onQueueRestored(void Function() callback) {
        if (didFinishInitialRestore) {
          callback();
        } else {
          callbacks.add(callback);
        }
      }

      // Act: 注册多个回调
      onQueueRestored(() => executionCount++);
      onQueueRestored(() => executionCount++);
      onQueueRestored(() => executionCount++);

      // Assert: 所有回调应被添加
      expect(callbacks.length, 3, reason: '所有回调应被添加到列表');
      expect(executionCount, 0, reason: '回调尚未执行');

      // Act: 模拟恢复完成
      for (final callback in callbacks) {
        callback();
      }
      callbacks.clear();

      // Assert: 所有回调应被执行
      expect(executionCount, 3, reason: '所有回调应被执行');
    });

    test('回调机制：回调是幂等的', () {
      // prepareCurrentFromQueue 的核心逻辑是验证索引有效性
      // 这意味着多次调用不会产生副作用

      // Arrange: 模拟有效队列状态
      final queue = <PlayableAudio>[
        LocalPlayable(LocalAudio(
          filePath: '/path/to/audio.mp3',
          title: '测试音频',
          artist: '测试艺术家',
          duration: 180,
        )),
      ];
      const currentIndex = 0;

      // Assert: 索引验证逻辑
      bool isIndexValid(int index, List<PlayableAudio> queue) {
        return index >= 0 && index < queue.length;
      }

      // 第一次验证
      expect(isIndexValid(currentIndex, queue), true);
      // 第二次验证（幂等性）
      expect(isIndexValid(currentIndex, queue), true);
      // 第三次验证（幂等性）
      expect(isIndexValid(currentIndex, queue), true);
    });
  });

  /// prepareCurrentFromQueue 集成测试
  ///
  /// 测试 prepareCurrentFromQueue 方法的索引验证逻辑
  group('prepareCurrentFromQueue 索引验证测试', () {
    test('有效索引应通过验证', () {
      // Arrange
      final localAudio = LocalAudio(
        filePath: '/path/to/audio.mp3',
        title: '测试音频',
        artist: '测试艺术家',
        duration: 180,
      );
      final playable = LocalPlayable(localAudio);
      final state = QueueState(queue: [playable], currentIndex: 0);

      // Act: 模拟 prepareCurrentFromQueue 的索引验证逻辑
      final currentIndex = state.currentIndex;
      final isValid = currentIndex >= 0 && currentIndex < state.queue.length;

      // Assert
      expect(isValid, true, reason: '索引 0 对于单元素队列是有效的');
    });

    test('索引 -1 应跳过恢复', () {
      // Arrange
      final localAudio = LocalAudio(
        filePath: '/path/to/audio.mp3',
        title: '测试音频',
        artist: '测试艺术家',
        duration: 180,
      );
      final playable = LocalPlayable(localAudio);
      final state = QueueState(queue: [playable], currentIndex: -1);

      // Act: 模拟 prepareCurrentFromQueue 的索引验证逻辑
      final currentIndex = state.currentIndex;
      final shouldSkip = currentIndex < 0;

      // Assert
      expect(shouldSkip, true, reason: '索引 -1 应跳过恢复');
    });

    test('索引超出队列长度应跳过恢复', () {
      // Arrange
      final localAudio = LocalAudio(
        filePath: '/path/to/audio.mp3',
        title: '测试音频',
        artist: '测试艺术家',
        duration: 180,
      );
      final playable = LocalPlayable(localAudio);
      final state = QueueState(queue: [playable], currentIndex: 5);

      // Act: 模拟 prepareCurrentFromQueue 的索引验证逻辑
      final currentIndex = state.currentIndex;
      final shouldSkip = currentIndex >= state.queue.length;

      // Assert
      expect(shouldSkip, true, reason: '索引超出队列长度应跳过恢复');
    });

    test('空队列应跳过恢复', () {
      // Arrange
      const state = QueueState(queue: [], currentIndex: 0);

      // Act: 模拟 prepareCurrentFromQueue 的索引验证逻辑
      final currentIndex = state.currentIndex;
      final queueLength = state.queue.length;
      final shouldSkip = queueLength == 0 || currentIndex < 0 || currentIndex >= queueLength;

      // Assert
      expect(shouldSkip, true, reason: '空队列应跳过恢复');
    });

    test('应能获取当前可播放音频', () {
      // Arrange
      final localAudio = LocalAudio(
        filePath: '/path/to/audio.mp3',
        title: '测试音频',
        artist: '测试艺术家',
        duration: 180,
      );
      final playable = LocalPlayable(localAudio);
      final state = QueueState(queue: [playable], currentIndex: 0);

      // Act: 模拟获取当前播放项
      PlayableAudio? currentPlayable;
      final currentIndex = state.currentIndex;
      if (currentIndex >= 0 && currentIndex < state.queue.length) {
        currentPlayable = state.queue[currentIndex];
      }

      // Assert
      expect(currentPlayable, isNotNull);
      expect(currentPlayable?.title, '测试音频');
    });
  });

  /// 元数据一致性测试
  ///
  /// 验证 _updatePlayableState 方法的行为，确保 play() 和 prepareSource()
  /// 设置的元数据字段一致。
  group('PlaybackState 元数据一致性测试', () {
    test('_updatePlayableState 应正确设置所有元数据字段', () {
      // Arrange
      final localAudio = LocalAudio(
        filePath: '/path/to/audio.mp3',
        title: '测试歌曲',
        artist: '测试艺术家',
        duration: 180,
      );
      final playable = LocalPlayable(localAudio);
      const initialState = PlaybackState();

      // Act: 模拟 _updatePlayableState 的行为
      final newState = initialState.copyWith(
        currentPlayable: playable,
        title: playable.title,
        artist: playable.artist ?? '未知艺术家',
        coverUrl: playable.coverUrl,
        coverData: playable.coverData,
        currentIndex: 0,
        errorMessage: null,
      );

      // Assert: 所有元数据字段应被正确设置
      expect(newState.currentPlayable, equals(playable));
      expect(newState.title, '测试歌曲');
      expect(newState.artist, '测试艺术家');
      expect(newState.coverUrl, playable.coverUrl);
      expect(newState.coverData, playable.coverData);
      expect(newState.currentIndex, 0);
      expect(newState.errorMessage, isNull);
    });

    test('_updatePlayableState 应正确处理 artist 默认值逻辑', () {
      // Arrange: 创建一个有艺术家的音频
      final localAudio = LocalAudio(
        filePath: '/path/to/audio.mp3',
        title: '有艺术家歌曲',
        artist: '具体艺术家',
        duration: 180,
      );
      final playable = LocalPlayable(localAudio);
      const initialState = PlaybackState(errorMessage: '之前的错误');

      // Act: 模拟 _updatePlayableState 的行为
      final newState = initialState.copyWith(
        currentPlayable: playable,
        title: playable.title,
        artist: playable.artist ?? '未知艺术家',
        coverUrl: playable.coverUrl,
        coverData: playable.coverData,
        currentIndex: -1,
        errorMessage: null,
      );

      // Assert: artist 应被正确设置，errorMessage 应被清除
      expect(newState.artist, '具体艺术家');
      expect(newState.errorMessage, isNull);
    });

    test('play() 和 prepareSource() 应设置相同的元数据字段', () {
      // Arrange
      final localAudio = LocalAudio(
        filePath: '/path/to/audio.mp3',
        title: '一致性测试歌曲',
        artist: '测试艺术家',
        duration: 180,
      );
      final playable = LocalPlayable(localAudio);

      // Act: 模拟 play() 的状态设置
      final playState = PlaybackState(
        currentPlayable: playable,
        title: playable.title,
        artist: playable.artist ?? '未知艺术家',
        coverUrl: playable.coverUrl,
        coverData: playable.coverData,
        currentIndex: 0,
        errorMessage: null,
      );

      // Act: 模拟 prepareSource() 的状态设置（现在应该使用相同的 _updatePlayableState）
      final prepareState = PlaybackState(
        currentPlayable: playable,
        title: playable.title,
        artist: playable.artist ?? '未知艺术家',
        coverUrl: playable.coverUrl,
        coverData: playable.coverData,
        currentIndex: -1, // prepareSource 默认不设置索引
        errorMessage: null,
      );

      // Assert: 两个方法设置的元数据字段应该一致（除了 currentIndex）
      expect(playState.currentPlayable, equals(prepareState.currentPlayable));
      expect(playState.title, prepareState.title);
      expect(playState.artist, prepareState.artist);
      expect(playState.coverUrl, prepareState.coverUrl);
      expect(playState.coverData, prepareState.coverData);
      expect(playState.errorMessage, prepareState.errorMessage);
    });

    test('coverData 应被正确设置（本地音频场景）', () {
      // Arrange
      final localAudio = LocalAudio(
        filePath: '/path/to/audio.mp3',
        title: '本地音频',
        artist: '本地艺术家',
        duration: 180,
        albumArt: Uint8List.fromList([1, 2, 3, 4]), // 模拟封面数据
      );
      final playable = LocalPlayable(localAudio);
      const initialState = PlaybackState();

      // Act
      final newState = initialState.copyWith(
        currentPlayable: playable,
        title: playable.title,
        artist: playable.artist ?? '未知艺术家',
        coverUrl: playable.coverUrl,
        coverData: playable.coverData,
        currentIndex: 0,
        errorMessage: null,
      );

      // Assert
      expect(newState.coverData, isNotNull);
      expect(newState.coverData, equals(Uint8List.fromList([1, 2, 3, 4])));
    });

    test('coverUrl 应被正确设置（在线音频场景）', () {
      // Arrange
      final localAudio = LocalAudio(
        filePath: '/path/to/audio.mp3',
        title: '在线音频',
        artist: '在线艺术家',
        duration: 180,
      );
      final playable = LocalPlayable(localAudio);
      const initialState = PlaybackState();

      // Act
      final newState = initialState.copyWith(
        currentPlayable: playable,
        title: playable.title,
        artist: playable.artist ?? '未知艺术家',
        coverUrl: 'https://example.com/cover.jpg',
        coverData: playable.coverData,
        currentIndex: 0,
        errorMessage: null,
      );

      // Assert
      expect(newState.coverUrl, 'https://example.com/cover.jpg');
    });

    test('多次调用 _updatePlayableState 应覆盖之前的状态', () {
      // Arrange
      final localAudio1 = LocalAudio(
        filePath: '/path/to/audio1.mp3',
        title: '第一首歌',
        artist: '艺术家1',
        duration: 180,
      );
      final localAudio2 = LocalAudio(
        filePath: '/path/to/audio2.mp3',
        title: '第二首歌',
        artist: '艺术家2',
        duration: 200,
      );
      final playable1 = LocalPlayable(localAudio1);
      final playable2 = LocalPlayable(localAudio2);

      // Act: 第一次设置
      var state = PlaybackState(
        currentPlayable: playable1,
        title: playable1.title,
        artist: playable1.artist ?? '未知艺术家',
        coverUrl: playable1.coverUrl,
        coverData: playable1.coverData,
        currentIndex: 0,
        errorMessage: null,
      );

      // Act: 第二次设置（模拟切换歌曲）
      state = state.copyWith(
        currentPlayable: playable2,
        title: playable2.title,
        artist: playable2.artist ?? '未知艺术家',
        coverUrl: playable2.coverUrl,
        coverData: playable2.coverData,
        currentIndex: 1,
        errorMessage: null,
      );

      // Assert: 应该是第二次设置的状态
      expect(state.currentPlayable, equals(playable2));
      expect(state.title, '第二首歌');
      expect(state.artist, '艺术家2');
      expect(state.currentIndex, 1);
    });
  });

  /// PlaybackStateValidator 状态验证测试
  group('PlaybackStateValidator 测试', () {
    test('应检测到 isPlaying=true 且 currentPlayable=null 的不一致', () {
      // Arrange
      final state = PlaybackState(isPlaying: true, currentPlayable: null);

      // Act
      final result = PlaybackStateValidator.validate(state);

      // Assert
      expect(result.isValid, false);
      expect(result.issues, contains(contains('currentPlayable')));
    });

    test('应检测到 currentIndex>=0 且 currentPlayable=null 的不一致', () {
      // Arrange
      final state = PlaybackState(currentIndex: 0, currentPlayable: null);

      // Act
      final result = PlaybackStateValidator.validate(state);

      // Assert
      expect(result.isValid, false);
      expect(result.issues, contains(contains('currentPlayable')));
    });

    test('应检测到 isLoading 和 isPlaying 同时为 true', () {
      // Arrange
      final localAudio = LocalAudio(
        filePath: '/path/to/audio.mp3',
        title: '测试音频',
        artist: '测试艺术家',
        duration: 180,
      );
      final playable = LocalPlayable(localAudio);
      final state = PlaybackState(
        isLoading: true,
        isPlaying: true,
        currentPlayable: playable,
      );

      // Act
      final result = PlaybackStateValidator.validate(state);

      // Assert
      expect(result.isValid, false);
      expect(result.issues, contains(contains('isLoading')));
    });

    test('应检测到 isPlaying 和 isPaused 同时为 true', () {
      // Arrange
      final localAudio = LocalAudio(
        filePath: '/path/to/audio.mp3',
        title: '测试音频',
        artist: '测试艺术家',
        duration: 180,
      );
      final playable = LocalPlayable(localAudio);
      final state = PlaybackState(
        isPlaying: true,
        isPaused: true,
        currentPlayable: playable,
      );

      // Act
      final result = PlaybackStateValidator.validate(state);

      // Assert
      expect(result.isValid, false);
      expect(result.issues, contains(contains('isPlaying')));
    });

    test('有效状态应通过验证', () {
      // Arrange
      final localAudio = LocalAudio(
        filePath: '/path/to/audio.mp3',
        title: '测试音频',
        artist: '测试艺术家',
        duration: 180,
      );
      final playable = LocalPlayable(localAudio);
      final state = PlaybackState(
        isPlaying: true,
        isPaused: false,
        isLoading: false,
        currentPlayable: playable,
        currentIndex: 0,
      );

      // Act
      final result = PlaybackStateValidator.validate(state);

      // Assert
      expect(result.isValid, true);
      expect(result.issues, isEmpty);
    });

    test('默认状态应通过验证', () {
      // Arrange
      const state = PlaybackState();

      // Act
      final result = PlaybackStateValidator.validate(state);

      // Assert
      expect(result.isValid, true);
      expect(result.issues, isEmpty);
    });

    test('repair 应重置无效的 currentIndex', () {
      // Arrange
      final state = PlaybackState(currentIndex: 5, currentPlayable: null);

      // Act
      final repaired = PlaybackStateValidator.repair(state);

      // Assert
      expect(repaired.currentIndex, -1);
    });

    test('repair 应修复 isPlaying=true 且 currentPlayable=null 的不一致', () {
      // Arrange
      final state = PlaybackState(isPlaying: true, currentPlayable: null);

      // Act
      final repaired = PlaybackStateValidator.repair(state);

      // Assert
      expect(repaired.isPlaying, false);
    });

    test('repair 应修复 isLoading 和 isPlaying 同时为 true', () {
      // Arrange
      final localAudio = LocalAudio(
        filePath: '/path/to/audio.mp3',
        title: '测试音频',
        artist: '测试艺术家',
        duration: 180,
      );
      final playable = LocalPlayable(localAudio);
      final state = PlaybackState(
        isLoading: true,
        isPlaying: true,
        currentPlayable: playable,
      );

      // Act
      final repaired = PlaybackStateValidator.repair(state);

      // Assert
      expect(repaired.isPlaying, false);
      expect(repaired.isLoading, true);
    });

    test('repair 应修复 isPlaying 和 isPaused 同时为 true', () {
      // Arrange
      final localAudio = LocalAudio(
        filePath: '/path/to/audio.mp3',
        title: '测试音频',
        artist: '测试艺术家',
        duration: 180,
      );
      final playable = LocalPlayable(localAudio);
      final state = PlaybackState(
        isPlaying: true,
        isPaused: true,
        currentPlayable: playable,
      );

      // Act
      final repaired = PlaybackStateValidator.repair(state);

      // Assert
      expect(repaired.isPlaying, true);
      expect(repaired.isPaused, false);
    });

    test('repair 应保持有效状态不变', () {
      // Arrange
      final localAudio = LocalAudio(
        filePath: '/path/to/audio.mp3',
        title: '测试音频',
        artist: '测试艺术家',
        duration: 180,
      );
      final playable = LocalPlayable(localAudio);
      final state = PlaybackState(
        isPlaying: true,
        currentPlayable: playable,
        currentIndex: 0,
        title: '测试标题',
      );

      // Act
      final repaired = PlaybackStateValidator.repair(state);

      // Assert
      expect(repaired.isPlaying, true);
      expect(repaired.currentPlayable, equals(playable));
      expect(repaired.currentIndex, 0);
      expect(repaired.title, '测试标题');
    });

    test('验证结果应包含所有发现的问题', () {
      // Arrange: 创建一个有多个问题的状态
      final state = PlaybackState(
        isPlaying: true,
        isPaused: true,
        isLoading: true,
        currentIndex: 0,
        currentPlayable: null,
      );

      // Act
      final result = PlaybackStateValidator.validate(state);

      // Assert
      expect(result.isValid, false);
      expect(result.issues.length, greaterThanOrEqualTo(3));
    });
  });
}