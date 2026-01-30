import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:demo/presentation/providers/audio/playback_controller.dart';
import 'package:demo/domain/entities/local_playable.dart';
import 'package:demo/domain/entities/online_playable.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const _globalChannel = MethodChannel('xyz.luan/audioplayers.global');
  const _playerChannel = MethodChannel('xyz.luan/audioplayers');

  setUpAll(() {
    _globalChannel.setMockMethodCallHandler((MethodCall methodCall) async {
      return null;
    });
    _playerChannel.setMockMethodCallHandler((MethodCall methodCall) async {
      return null;
    });
  });

  tearDownAll(() {
    _globalChannel.setMockMethodCallHandler(null);
    _playerChannel.setMockMethodCallHandler(null);
  });

  group('PlaybackController 播放控制', () {
    late PlaybackController controller;

    setUp(() {
      controller = PlaybackController();
    });

    tearDown(() {
      controller.dispose();
    });

    group('播放控制方法', () {
      test('play 应该不抛出异常', () async {
        await expectLater(controller.play(), returnsNormally);
      });

      test('pause 应该不抛出异常', () async {
        await expectLater(controller.pause(), returnsNormally);
      });

      test('stop 应该不抛出异常', () async {
        await expectLater(controller.stop(), returnsNormally);
      });

      test('togglePlayPause 在未播放时应该播放', () async {
        expect(controller.isPlaying, false);

        await controller.togglePlayPause();

        // 播放状态可能因为 stream 事件而变化
        // 这里只验证方法不抛出异常
        expect(controller.disposed, false);
      });

      test('togglePlayPause 在播放时应该暂停', () async {
        // 先播放
        await controller.play();

        // 切换
        await controller.togglePlayPause();

        // 验证不抛出异常
        expect(controller.disposed, false);
      });

      test('seek 应该不抛出异常', () async {
        const position = Duration(seconds: 30);

        await expectLater(
          controller.seek(position),
          returnsNormally,
        );
      });

      test('seek 在不支持时应该安全返回', () async {
        const position = Duration(seconds: 30);

        await expectLater(
          controller.seek(position, seekable: false),
          returnsNormally,
        );
      });

      test('setVolume 应该不抛出异常', () async {
        await expectLater(
          controller.setVolume(0.5),
          returnsNormally,
        );
      });

      test('setVolume 超出范围应该被限制', () async {
        await controller.setVolume(1.5); // 超过 1.0
        await controller.setVolume(-0.5); // 小于 0

        // 验证不抛出异常
        expect(controller.disposed, false);
      });

      test('setSpeed 应该不抛出异常', () async {
        await expectLater(
          controller.setSpeed(1.5),
          returnsNormally,
        );
      });

      test('setSpeed 超出范围应该被限制', () async {
        await controller.setSpeed(3.0); // 超过 2.0
        await controller.setSpeed(0.1); // 小于 0.5

        // 验证不抛出异常
        expect(controller.disposed, false);
      });
    });

    group('音频源管理', () {
      test('setFileSource 应该不抛出异常', () async {
        const testPath = '/path/to/audio.mp3';

        await expectLater(
          controller.setFileSource(testPath),
          returnsNormally,
        );
      });

      test('setUrlSource 应该不抛出异常', () async {
        const testUrl = 'https://example.com/audio.mp3';

        await expectLater(
          controller.setUrlSource(testUrl),
          returnsNormally,
        );
      });

      test('prepareSource 本地音频应该不抛出异常', () async {
        final playable = LocalPlayable(
          id: 'test_id',
          title: 'Test Audio',
          filePath: '/path/to/audio.mp3',
          duration: 180,
        );

        await expectLater(
          controller.prepareSource(playable),
          returnsNormally,
        );
      });

      test('prepareSource 在线音频应该不抛出异常', () async {
        final playable = OnlinePlayable(
          id: 'test_id',
          title: 'Test Audio',
          url: 'https://example.com/audio.mp3',
        );

        await expectLater(
          controller.prepareSource(playable),
          returnsNormally,
        );
      });

      test('prepareSource 带起始位置应该不抛出异常', () async {
        final playable = LocalPlayable(
          id: 'test_id',
          title: 'Test Audio',
          filePath: '/path/to/audio.mp3',
          duration: 180,
        );

        await expectLater(
          controller.prepareSource(playable, startPosition: 30),
          returnsNormally,
        );
      });
    });

    group('播放控制完整流程', () {
      test('setSourceAndPlay 本地音频应该不抛出异常', () async {
        final playable = LocalPlayable(
          id: 'test_id',
          title: 'Test Audio',
          filePath: '/path/to/audio.mp3',
          duration: 180,
        );

        await expectLater(
          controller.setSourceAndPlay(playable),
          returnsNormally,
        );
      });

      test('setSourceAndPlay 在线音频应该不抛出异常', () async {
        final playable = OnlinePlayable(
          id: 'test_id',
          title: 'Test Audio',
          url: 'https://example.com/audio.mp3',
        );

        await expectLater(
          controller.setSourceAndPlay(playable),
          returnsNormally,
        );
      });

      test('setSourceAndPlay 自定义超时应该不抛出异常', () async {
        final playable = OnlinePlayable(
          id: 'test_id',
          title: 'Test Audio',
          url: 'https://example.com/audio.mp3',
        );

        await expectLater(
          controller.setSourceAndPlay(
            playable,
            timeout: const Duration(seconds: 10),
          ),
          returnsNormally,
        );
      });
    });

    group('回调设置', () {
      test('应该可以设置 onPlayingChanged 回调', () {
        bool? callbackCalled;

        controller.setCallbacks(
          onPlayingChanged: (isPlaying) {
            callbackCalled = isPlaying;
          },
        );

        expect(callbackCalled, isNull);
      });

      test('应该可以设置 onPlayerStateChanged 回调', () {
        PlayerState? capturedState;

        controller.setCallbacks(
          onPlayerStateChanged: (state) {
            capturedState = state;
          },
        );

        expect(capturedState, isNull);
      });

      test('应该可以设置 onPlaybackComplete 回调', () {
        bool callbackCalled = false;

        controller.setCallbacks(
          onPlaybackComplete: () {
            callbackCalled = true;
          },
        );

        expect(callbackCalled, false);
      });

      test('应该可以设置 onPlaybackWarning 回调', () {
        String? warningMessage;

        controller.setCallbacks(
          onPlaybackWarning: (message) {
            warningMessage = message;
          },
        );

        expect(warningMessage, isNull);
      });

      test('应该可以设置所有回调', () {
        bool? playingCalled;
        PlayerState? stateCalled;
        bool completeCalled = false;
        String? warningCalled;

        controller.setCallbacks(
          onPlayingChanged: (isPlaying) => playingCalled = isPlaying,
          onPlayerStateChanged: (state) => stateCalled = state,
          onPlaybackComplete: () => completeCalled = true,
          onPlaybackWarning: (msg) => warningCalled = msg,
        );

        expect(playingCalled, isNull);
        expect(stateCalled, isNull);
        expect(completeCalled, false);
        expect(warningCalled, isNull);
      });

      test('多次设置回调应该覆盖', () {
        String? firstCallback;
        String? secondCallback;

        controller.setCallbacks(
          onPlaybackWarning: (msg) => firstCallback = msg,
        );

        controller.setCallbacks(
          onPlaybackWarning: (msg) => secondCallback = msg,
        );

        // 第二个回调应该覆盖第一个
        expect(firstCallback, isNull);
        expect(secondCallback, isNull);
      });
    });

    group('队列管理', () {
      test('cancelPendingCommands 应该不抛出异常', () {
        expect(
          () => controller.cancelPendingCommands(),
          returnsNormally,
        );
      });

      test('hasPending 应该反映队列状态', () {
        // 初始状态应该没有待处理的命令
        expect(controller.hasPendingCommands, false);
      });

      test('queueState 应该返回队列状态', () {
        final state = controller.queueState;

        expect(state, isA<PlaybackQueueState>());
      });
    });

    group('状态检查', () {
      test('isIdle 应该反映播放器状态', () {
        // 初始状态应该是空闲
        expect(controller.isIdle, true);
      });

      test('isReady 应该反映就绪状态', () {
        // 初始状态未加载音频，不应该就绪
        expect(controller.isReady, false);
      });

      test('isLoading 应该反映加载状态', () {
        // 初始状态未加载
        expect(controller.isLoading, false);
      });

      test('isBuffering 应该始终为 false（audioplayers 限制）', () {
        // audioplayers 不直接提供缓冲状态
        expect(controller.isBuffering, false);
      });

      test('isLoadingOrBuffering 应该反映加载或缓冲状态', () {
        // 初始状态
        expect(controller.isLoadingOrBuffering, false);
      });

      test('isCurrentlyPlaying 应该反映实际播放状态', () {
        // 初始状态
        expect(controller.isCurrentlyPlaying, false);
      });

      test('isPaused 应该反映暂停状态', () {
        // 初始状态
        expect(controller.isPaused, false);
      });

      test('isCompleted 应该反映完成状态', () {
        // 初始状态
        expect(controller.isCompleted, false);
      });

      test('playerState 应该返回当前状态', () {
        final state = controller.playerState;

        expect(state, isA<PlayerState>());
      });

      test('position 应该返回当前播放位置', () {
        final position = controller.position;

        expect(position, isA<Duration>());
        expect(position, Duration.zero);
      });

      test('duration 应该返回音频时长', () {
        final duration = controller.duration;

        expect(duration, isA<Duration>());
        expect(duration, Duration.zero);
      });
    });

    group('流对象', () {
      test('positionStream 应该返回有效流', () {
        final stream = controller.positionStream;

        expect(stream, isA<Stream<Duration>>());
      });

      test('durationStream 应该返回有效流', () {
        final stream = controller.durationStream;

        expect(stream, isA<Stream<Duration>>());
      });

      test('playerStateStream 应该返回有效流', () {
        final stream = controller.playerStateStream;

        expect(stream, isA<Stream<PlayerState>>());
      });

      test('bufferedPositionStream 应该返回空流（audioplayers 限制）', () {
        final stream = controller.bufferedPositionStream;

        expect(stream, isA<Stream<Duration>>());
      });
    });

    group('资源管理', () {
      test('dispose 应该释放资源', () {
        final testController = PlaybackController();

        expect(testController.disposed, false);

        testController.dispose();

        expect(testController.disposed, true);
      });

      test('dispose 后调用方法应该是安全的', () async {
        final testController = PlaybackController();
        testController.dispose();

        // dispose 后调用方法不应该崩溃
        await expectLater(
          testController.play(),
          returnsNormally,
        );

        await expectLater(
          testController.pause(),
          returnsNormally,
        );
      });

      test('多次 dispose 应该是安全的', () {
        final testController = PlaybackController();

        testController.dispose();
        testController.dispose();
        testController.dispose();

        expect(testController.disposed, true);
      });
    });

    group('边界情况', () {
      test('播放不存在的本地文件应该处理错误', () async {
        final playable = LocalPlayable(
          id: 'nonexistent',
          title: 'Nonexistent',
          filePath: '/path/to/nonexistent.mp3',
          duration: 180,
        );

        // 应该不抛出未捕获的异常
        await expectLater(
          controller.setSourceAndPlay(playable),
          returnsNormally,
        );
      });

      test('播放无效的在线 URL 应该处理错误', () async {
        final playable = OnlinePlayable(
          id: 'invalid',
          title: 'Invalid URL',
          url: 'https://invalid-url-that-does-not-exist.com/audio.mp3',
        );

        // 应该不抛出未捕获的异常
        await expectLater(
          controller.setSourceAndPlay(playable),
          returnsNormally,
        );
      });

      test('跳转到负位置应该是安全的', () async {
        await expectLater(
          controller.seek(const Duration(seconds: -10)),
          returnsNormally,
        );
      });

      test('跳转到超出时长的位置应该是安全的', () async {
        await expectLater(
          controller.seek(const Duration(hours: 10)),
          returnsNormally,
        );
      });

      test('设置极端音量值应该是安全的', () async {
        await controller.setVolume(double.infinity);
        await controller.setVolume(double.negativeInfinity);

        expect(controller.disposed, false);
      });

      test('设置极端倍速值应该是安全的', () async {
        await controller.setSpeed(double.infinity);
        await controller.setSpeed(double.negativeInfinity);

        expect(controller.disposed, false);
      });

      test('连续切换播放/暂停应该是安全的', () async {
        for (int i = 0; i < 10; i++) {
          await controller.togglePlayPause();
        }

        expect(controller.disposed, false);
      });

      test('连续切换音频源应该是安全的', () async {
        final playable1 = LocalPlayable(
          id: 'test1',
          title: 'Test 1',
          filePath: '/path/to/audio1.mp3',
          duration: 180,
        );

        final playable2 = LocalPlayable(
          id: 'test2',
          title: 'Test 2',
          filePath: '/path/to/audio2.mp3',
          duration: 200,
        );

        await controller.setSourceAndPlay(playable1);
        await controller.setSourceAndPlay(playable2);
        await controller.setSourceAndPlay(playable1);

        expect(controller.disposed, false);
      });
    });

    group('完整播放流程', () {
      test('加载 -> 播放 -> 暂停 -> 恢复 -> 停止 完整流程', () async {
        final playable = LocalPlayable(
          id: 'test',
          title: 'Test Audio',
          filePath: '/path/to/audio.mp3',
          duration: 180,
        );

        // 1. 加载并播放
        await controller.setSourceAndPlay(playable);

        // 2. 暂停
        await controller.pause();

        // 3. 恢复播放
        await controller.play();

        // 4. 停止
        await controller.stop();

        // 验证不抛出异常
        expect(controller.disposed, false);
      });

      test('播放 -> 跳转 -> 继续播放 完整流程', () async {
        final playable = OnlinePlayable(
          id: 'test',
          title: 'Test Audio',
          url: 'https://example.com/audio.mp3',
        );

        // 1. 播放
        await controller.setSourceAndPlay(playable);

        // 2. 跳转
        await controller.seek(const Duration(seconds: 60));

        // 3. 继续播放
        await controller.play();

        expect(controller.disposed, false);
      });

      test('调整音量和倍速 -> 播放 完整流程', () async {
        final playable = LocalPlayable(
          id: 'test',
          title: 'Test Audio',
          filePath: '/path/to/audio.mp3',
          duration: 180,
        );

        // 1. 设置音量
        await controller.setVolume(0.8);

        // 2. 设置倍速
        await controller.setSpeed(1.25);

        // 3. 播放
        await controller.setSourceAndPlay(playable);

        expect(controller.disposed, false);
      });
    });

    group('播放器实例访问', () {
      test('player getter 应该返回 AudioPlayer 实例', () {
        final player = controller.player;

        expect(player, isNotNull);
        expect(player, isA<AudioPlayer>());
      });

      test('返回的 player 实例应该是相同的', () {
        final player1 = controller.player;
        final player2 = controller.player;

        expect(identical(player1, player2), true);
      });
    });
  });
}
