import 'package:flutter_test/flutter_test.dart';
import 'package:listenvision/models/local_audio.dart';
import 'package:listenvision/models/local_playable.dart';
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
}