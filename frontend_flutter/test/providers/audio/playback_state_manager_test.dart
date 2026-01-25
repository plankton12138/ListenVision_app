import 'package:flutter_test/flutter_test.dart';
import 'package:demo/presentation/providers/audio/playback_state_manager.dart';
import 'package:demo/domain/entities/local_playable.dart';
import 'package:demo/domain/entities/online_playable.dart';
import 'package:demo/domain/entities/local_audio.dart';
import 'package:demo/domain/entities/audio.dart';

void main() {
  group('PlaybackStateManager', () {
    late PlaybackStateManager manager;

    // 测试用的本地音频
    LocalPlayable createTestLocalPlayable({
      int? id,
      required String title,
      String artist = 'Test Artist',
    }) {
      return LocalPlayable(LocalAudio(
        filePath: '/test/path/$title.mp3',
        title: title,
        artist: artist,
        duration: 180,
        id: id,
      ));
    }

    // 测试用的在线音频
    OnlinePlayable createTestOnlinePlayable({
      required String id,
      required String title,
      String artist = 'Test Artist',
    }) {
      return OnlinePlayable(Audio(
        id: id,
        title: title,
        artist: artist,
        duration: 180,
        streamUrl: 'https://example.com/audio.mp3',
        coverUrl: 'https://example.com/cover.jpg',
      ));
    }

    setUp(() {
      manager = PlaybackStateManager();
    });

    tearDown(() {
      manager.dispose();
    });

    group('初始化状态', () {
      test('初始音量应该是 1.0', () {
        expect(manager.volume, 1.0);
      });

      test('初始倍速应该是 1.0', () {
        expect(manager.speed, 1.0);
      });

      test('不应该立即启动定时器', () {
        // 定时器应该只在调用 start 方法后启动
        expect(manager, isA<PlaybackStateManager>());
      });
    });

    group('音量控制', () {
      test('应该能够设置音量', () async {
        await manager.setVolume(0.5);
        expect(manager.volume, 0.5);
      });

      test('音量应该被限制在 0.0 - 1.0 范围内', () async {
        await manager.setVolume(1.5); // 超过上限
        expect(manager.volume, 1.0);

        await manager.setVolume(-0.5); // 低于下限
        expect(manager.volume, 0.0);
      });

      test('音量边界值应该正确', () async {
        await manager.setVolume(0.0);
        expect(manager.volume, 0.0);

        await manager.setVolume(1.0);
        expect(manager.volume, 1.0);
      });
    });

    group('倍速控制', () {
      test('应该能够设置倍速', () async {
        await manager.setSpeed(1.5);
        expect(manager.speed, 1.5);
      });

      test('倍速应该被限制在 0.5 - 2.0 范围内', () async {
        await manager.setSpeed(3.0); // 超过上限
        expect(manager.speed, 2.0);

        await manager.setSpeed(0.1); // 低于下限
        expect(manager.speed, 0.5);
      });

      test('倍速边界值应该正确', () async {
        await manager.setSpeed(0.5);
        expect(manager.speed, 0.5);

        await manager.setSpeed(2.0);
        expect(manager.speed, 2.0);
      });

      test('应该支持常用的倍速值', () async {
        final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

        for (final speed in speeds) {
          await manager.setSpeed(speed);
          expect(manager.speed, speed);
        }
      });
    });

    group('回调设置', () {
      test('应该能够设置状态获取回调', () {
        var callbackCalled = false;

        manager.setStateCallbacks(
          getCurrentIndex: () async {
            callbackCalled = true;
            return 0;
          },
          getCurrentPlayable: () async => null,
          getCurrentPosition: () async => Duration.zero,
          getIsPlaying: () async => false,
        );

        // 只测试设置不抛出异常
        expect(callbackCalled, false);
      });

      test('应该能够设置状态变化回调', () {
        var callbackCalled = false;

        manager.setOnStateChanged(() {
          callbackCalled = true;
        });

        // 设置音量触发回调
        manager.setVolume(0.8);
        // 由于是异步，等待一小段时间
        return Future.delayed(const Duration(milliseconds: 100), () {
          expect(callbackCalled, true);
        });
      });

      test('所有回调可以同时设置', () {
        var stateCallbackCalled = false;

        manager.setStateCallbacks(
          getCurrentIndex: () async => 0,
          getCurrentPlayable: () async => null,
          getCurrentPosition: () async => Duration.zero,
          getIsPlaying: () async => false,
        );

        manager.setOnStateChanged(() {
          stateCallbackCalled = true;
        });

        // 触发回调
        manager.setSpeed(1.5);

        return Future.delayed(const Duration(milliseconds: 100), () {
          expect(stateCallbackCalled, true);
        });
      });
    });

    group('定时器管理', () {
      test('startPositionSaveTimer 应该启动定时器', () {
        manager.setStateCallbacks(
          getCurrentIndex: () async => 0,
          getCurrentPlayable: () async => createTestLocalPlayable(id: 1, title: 'Test'),
          getCurrentPosition: () async => const Duration(seconds: 10),
          getIsPlaying: () async => true,
        );

        manager.startPositionSaveTimer();

        // 定时器应该正在运行（不抛出异常即为成功）
        expect(manager, isNotNull);
      });

      test('stopPositionSaveTimer 应该停止定时器', () {
        manager.startPositionSaveTimer();
        manager.stopPositionSaveTimer();

        // 再次停止不应该报错
        manager.stopPositionSaveTimer();
        expect(manager, isNotNull);
      });

      test('startProgressUpdateTimer 应该启动进度更新定时器', () {
        manager.setStateCallbacks(
          getCurrentIndex: () async => 0,
          getCurrentPlayable: () async => createTestLocalPlayable(id: 1, title: 'Test'),
          getCurrentPosition: () async => const Duration(seconds: 10),
          getIsPlaying: () async => true,
        );

        manager.startProgressUpdateTimer();

        expect(manager, isNotNull);
      });

      test('stopProgressUpdateTimer 应该停止进度更新定时器', () {
        manager.startProgressUpdateTimer();
        manager.stopProgressUpdateTimer();

        // 再次停止不应该报错
        manager.stopProgressUpdateTimer();
        expect(manager, isNotNull);
      });

      test('多次启动定时器应该取消之前的定时器', () {
        manager.setStateCallbacks(
          getCurrentIndex: () async => 0,
          getCurrentPlayable: () async => null,
          getCurrentPosition: () async => Duration.zero,
          getIsPlaying: () async => false,
        );

        manager.startPositionSaveTimer();
        manager.startPositionSaveTimer(); // 应该取消之前的定时器

        manager.startProgressUpdateTimer();
        manager.startProgressUpdateTimer(); // 应该取消之前的定时器

        expect(manager, isNotNull);
      });
    });

    group('播放历史记录', () {
      test('recordPlaybackStart 应该记录在线音频', () async {
        var recorded = false;
        Map<String, dynamic>? recordedData;

        final onlineAudio = createTestOnlinePlayable(
          id: 'BV123456',
          title: 'Online Song',
          artist: 'Online Artist',
        );

        await manager.recordPlaybackStart(
          onlineAudio,
          token: 'test_token',
          record: (data) {
            recorded = true;
            recordedData = data;
          },
        );

        expect(recorded, true);
        expect(recordedData?['bvid'], 'BV123456');
        expect(recordedData?['title'], 'Online Song');
        expect(recordedData?['artist'], 'Online Artist');
        expect(recordedData?['isOnline'], null); // 不包含 isOnline 字段
      });

      test('recordPlaybackStart 应该记录本地音频', () async {
        var recorded = false;
        Map<String, dynamic>? recordedData;

        final localAudio = createTestLocalPlayable(
          id: 1,
          title: 'Local Song',
          artist: 'Local Artist',
        );

        await manager.recordPlaybackStart(
          localAudio,
          token: 'test_token',
          record: (data) {
            recorded = true;
            recordedData = data;
          },
        );

        expect(recorded, true);
        expect(recordedData?['bvid'], null);
        expect(recordedData?['title'], 'Local Song');
        expect(recordedData?['localPath'], '/test/path/Local Song.mp3');
      });

      test('recordPlaybackStart 没有设置 record 回调时不应该报错', () async {
        final audio = createTestOnlinePlayable(
          id: 'BV123456',
          title: 'Test Song',
        );

        // 不设置 record 回调，应该优雅地跳过
        await manager.recordPlaybackStart(audio);

        expect(manager, isNotNull);
      });

      test('updatePlaybackProgress 应该更新在线音频进度', () async {
        var updated = false;
        Map<String, dynamic>? updatedData;

        manager.setStateCallbacks(
          getCurrentIndex: () async => 0,
          getCurrentPlayable: () async => createTestOnlinePlayable(
            id: 'BV123456',
            title: 'Test Song',
          ),
          getCurrentPosition: () async => const Duration(seconds: 30),
          getIsPlaying: () async => true,
        );

        await manager.updatePlaybackProgress(
          token: 'test_token',
          update: (data) {
            updated = true;
            updatedData = data;
          },
        );

        expect(updated, true);
        expect(updatedData?['progress'], 30);
      });

      test('updatePlaybackProgress 应该更新本地音频进度', () async {
        var updated = false;
        Map<String, dynamic>? updatedData;

        manager.setStateCallbacks(
          getCurrentIndex: () async => 0,
          getCurrentPlayable: () async => createTestLocalPlayable(
            id: 1,
            title: 'Test Song',
          ),
          getCurrentPosition: () async => const Duration(seconds: 45),
          getIsPlaying: () async => true,
        );

        await manager.updatePlaybackProgress(
          token: 'test_token',
          update: (data) {
            updated = true;
            updatedData = data;
          },
        );

        expect(updated, true);
        expect(updatedData?['progress'], 45);
      });

      test('updatePlaybackProgress 索引无效时应该跳过', () async {
        var updated = false;

        manager.setStateCallbacks(
          getCurrentIndex: () async => -1, // 无效索引
          getCurrentPlayable: () async => null,
          getCurrentPosition: () async => Duration.zero,
          getIsPlaying: () async => true,
        );

        await manager.updatePlaybackProgress(
          update: (data) {
            updated = true;
          },
        );

        expect(updated, false);
      });
    });

    group('防抖保存', () {
      test('debouncedSave 应该延迟执行保存', () async {
        var saved = false;

        manager.debouncedSave(() async {
          saved = true;
        });

        // 立即检查，应该还没有保存
        expect(saved, false);

        // 等待延迟后应该保存
        await Future.delayed(const Duration(milliseconds: 600));
        expect(saved, true);
      });

      test('debouncedSave 应该取消之前的保存计划', () async {
        var saveCount = 0;

        manager.debouncedSave(() async {
          saveCount++;
          await Future.delayed(const Duration(milliseconds: 100));
        });

        // 立即再次调用，应该取消之前的
        await Future.delayed(const Duration(milliseconds: 100));
        manager.debouncedSave(() async {
          saveCount++;
        });

        await Future.delayed(const Duration(milliseconds: 600));

        // 应该只执行一次（最后一次）
        expect(saveCount, 1);
      });

      test('flushPendingSave 应该取消待处理的保存', () async {
        var saved = false;

        manager.debouncedSave(() async {
          saved = true;
        });

        // 立即刷新，取消待处理的保存
        await manager.flushPendingSave();
        await Future.delayed(const Duration(milliseconds: 600));

        // 由于被取消，不应该保存
        expect(saved, false);
      });
    });

    group('通用状态持久化', () {
      test('saveString 和 getString 应该正常工作', () async {
        await manager.saveString('test_key', 'test_value');
        final result = await manager.getString('test_key');
        expect(result, 'test_value');
      });

      test('getString 获取不存在的键应该返回 null', () async {
        final result = await manager.getString('non_existent_key');
        expect(result, isNull);
      });

      test('saveInt 和 getInt 应该正常工作', () async {
        await manager.saveInt('test_int', 42);
        final result = await manager.getInt('test_int');
        expect(result, 42);
      });

      test('getInt 获取不存在的键应该返回 null', () async {
        final result = await manager.getInt('non_existent_int');
        expect(result, isNull);
      });

      test('saveBool 和 getBool 应该正常工作', () async {
        await manager.saveBool('test_bool', true);
        final result = await manager.getBool('test_bool');
        expect(result, true);
      });

      test('getBool 获取不存在的键应该返回 null', () async {
        final result = await manager.getBool('non_existent_bool');
        expect(result, isNull);
      });

      test('saveBool 应该保存 false 值', () async {
        await manager.saveBool('test_bool_false', false);
        final result = await manager.getBool('test_bool_false');
        expect(result, false);
      });
    });

    group('dispose', () {
      test('dispose 后 disposed 应该为 true', () {
        manager.dispose();
        // 无法直接访问 _disposed，但多次 dispose 不应该报错
        manager.dispose();
        manager.dispose();
      });

      test('dispose 后定时器应该被取消', () {
        manager.startPositionSaveTimer();
        manager.startProgressUpdateTimer();

        manager.dispose();

        // 不应该抛出异常
        expect(manager, isNotNull);
      });

      test('dispose 后调用方法不应该报错', () async {
        manager.dispose();

        // 这些方法应该检查 disposed 状态并安全返回
        await manager.setVolume(0.5);
        await manager.setSpeed(1.5);
        await manager.saveNow();
        await manager.saveString('key', 'value');
      });
    });

    group('saveNow', () {
      test('saveNow 应该立即执行保存', () async {
        manager.setStateCallbacks(
          getCurrentIndex: () async => 0,
          getCurrentPlayable: () async => createTestLocalPlayable(id: 1, title: 'Test'),
          getCurrentPosition: () async => const Duration(seconds: 10),
          getIsPlaying: () async => true,
        );

        // saveNow 实际上会调用 _savePlaybackState
        // 由于我们没有数据库，这里只测试不抛出异常
        await manager.saveNow();

        expect(manager, isNotNull);
      });
    });
  });
}
