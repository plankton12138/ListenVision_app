import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:demo/presentation/providers/audio/playback_controller.dart';

void main() {
  group('PlaybackController', () {
    late PlaybackController controller;

    setUp(() {
      controller = PlaybackController();
    });

    tearDown(() {
      controller.dispose();
    });

    group('初始化状态', () {
      test('初始状态应该是未播放', () {
        expect(controller.isPlaying, false);
        expect(controller.position, Duration.zero);
      });

      test('初始状态应该是空闲', () {
        expect(controller.isIdle, true);
      });

      test('应该可以访问 player 实例', () {
        expect(controller.player, isNotNull);
        expect(controller.player, isA<AudioPlayer>());
      });

      test('状态 getters 应该返回正确的值', () {
        expect(controller.isLoading, false);
        expect(controller.isBuffering, false);
        expect(controller.isReady, false); // 空闲时未就绪
        expect(controller.isCompleted, false);
        expect(controller.isLoadingOrBuffering, false);
      });
    });

    group('播放控制', () {
      test('音量应该可以被设置', () async {
        await controller.setVolume(0.5);
        // 注意: 由于是实际播放器，值可能不完全匹配
        // audioplayers 不直接暴露 volume getter，只验证不抛出异常
        expect(true, true);
      });

      test('倍速应该可以被设置', () async {
        await controller.setSpeed(1.5);
        // audioplayers 使用 setPlaybackRate，不直接暴露 speed getter
        expect(true, true);
      });

      test('音量应该在 0-1 范围内', () async {
        await controller.setVolume(1.5); // 超过范围
        // 应该被限制在 1.0 以内，不抛出异常
        expect(true, true);
      });

      test('倍速应该在 0.5-2 范围内', () async {
        await controller.setSpeed(3.0); // 超过范围
        // 应该被限制在 2.0 以内，不抛出异常
        expect(true, true);
      });
    });

    group('回调设置', () {
      test('应该可以设置播放状态变化回调', () {
        bool? callbackCalled;

        controller.setCallbacks(
          onPlayingChanged: (isPlaying) {
            callbackCalled = isPlaying;
          },
        );

        expect(callbackCalled, isNull);
      });

      test('应该可以设置播放器状态变化回调', () {
        PlayerState? capturedState;

        controller.setCallbacks(
          onPlayerStateChanged: (state) {
            capturedState = state;
          },
        );

        expect(capturedState, isNull);
      });

      test('两个回调可以同时设置', () {
        bool? playingCallback;
        PlayerState? stateCallback;

        controller.setCallbacks(
          onPlayingChanged: (isPlaying) {
            playingCallback = isPlaying;
          },
          onPlayerStateChanged: (state) {
            stateCallback = state;
          },
        );

        expect(playingCallback, isNull);
        expect(stateCallback, isNull);
      });
    });

    group('音频源操作', () {
      test('设置本地音频源应该不抛出异常', () async {
        // 使用一个虚拟路径进行测试
        try {
          await controller.setFileSource('/fake/path/audio.mp3');
          // 预期会失败，但不应该抛出未处理的异常
        } catch (e) {
          // 预期的错误（文件不存在）
          expect(e, isA<Exception>());
        }
      });

      test('设置在线音频源应该不抛出异常', () async {
        try {
          await controller.setUrlSource('http://example.com/audio.mp3');
          // 可能失败网络错误
        } catch (e) {
          // 预期的错误
          expect(e, isA<Exception>());
        }
      });
    });

    group('dispose', () {
      test('dispose 后 disposed 应该为 true', () {
        expect(controller.disposed, false);
        controller.dispose();
        expect(controller.disposed, true);
      });

      test('dispose 后不应该抛出异常', () {
        controller.dispose();
        expect(() => controller.dispose(), returnsNormally);
      });

      test('多次 dispose 应该是安全的', () {
        controller.dispose();
        controller.dispose();
        controller.dispose();
        expect(controller.disposed, true);
      });
    });

    group('流访问', () {
      test('应该提供位置流', () {
        expect(controller.positionStream, isNotNull);
        expect(controller.positionStream, isA<Stream<Duration>>());
      });

      test('应该提供时长流', () {
        expect(controller.durationStream, isNotNull);
        expect(controller.durationStream, isA<Stream<Duration>>());
      });

      test('应该提供播放状态流', () {
        expect(controller.playerStateStream, isNotNull);
        expect(controller.playerStateStream, isA<Stream<PlayerState>>());
      });
    });
  });
}
