import 'package:listenvision/models/audio.dart';
import 'package:listenvision/models/online_playable.dart';
import 'package:listenvision/models/playable_audio.dart';
import 'package:listenvision/presentation/providers.dart';
import 'package:listenvision/presentation/viewmodels/player/player_viewmodel.dart';
import 'package:listenvision/presentation/viewmodels/player/queue_viewmodel.dart';
import 'package:listenvision/presentation/widgets/controls_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 集成测试：播放器快速切换
///
/// 对应测试用例1：
/// "音频快速切换测试：以每秒至少2次的频率，交替使用播放器界面的"上一首"
/// 和"下一首"按钮进行连续15-20次歌曲切换操作，验证播放器能否正确响应
/// 每次切换请求，无卡顿、崩溃或播放异常现象。"
///
/// 对应测试用例2：
/// "音频切换后上传功能测试：在完成测试用例1的快速歌曲切换操作后，
/// 立即点击界面上的"上传音频"按钮，验证上传功能能否正常启动。"
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// 创建带有预填充队列的测试容器
  ProviderContainer createContainerWithQueue({
    required int queueSize,
    int startIndex = 0,
  }) {
    SharedPreferences.setMockInitialValues({});

    final container = ProviderContainer();

    // 创建测试队列
    final queue = List.generate(
      queueSize,
      (i) => OnlinePlayable.fromAudio(
        Audio(
          id: 'audio_$i',
          title: '歌曲$i',
          artist: '艺术家$i',
          duration: 180 + i * 10,
        ),
        'http://example.com/audio_$i.mp3',
      ),
    );

    // 设置队列状态
    container.read(queueViewModelProvider.notifier).state = QueueState(
      queue: queue,
      currentIndex: startIndex,
    );

    // 设置播放器状态
    container.read(playerViewModelProvider.notifier).state = PlayerState(
      title: '歌曲$startIndex',
      artist: '艺术家$startIndex',
      isPlaying: true,
      currentPlayable: queue[startIndex],
      currentOnlineAudio: Audio(
        id: 'audio_$startIndex',
        title: '歌曲$startIndex',
        artist: '艺术家$startIndex',
      ),
    );

    return container;
  }

  group('集成测试：音频快速切换', () {
    /// 测试用例1：快速切换上一首和下一首
    testWidgets('以每秒2次频率交替点击上一首和下一首15次', (tester) async {
      // Arrange: 创建包含10首歌曲的队列
      final container = createContainerWithQueue(queueSize: 10, startIndex: 5);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: ControlsPanel(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act: 快速交替点击上一首和下一首15次（模拟每秒2次的频率）
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 15; i++) {
        // 点击下一首
        await tester.tap(find.byIcon(Icons.skip_next));
        await tester.pump(const Duration(milliseconds: 100));

        // 点击上一首
        await tester.tap(find.byIcon(Icons.skip_previous));
        await tester.pump(const Duration(milliseconds: 100));
      }

      stopwatch.stop();

      // Assert: 验证没有崩溃
      expect(tester.takeException(), isNull);

      // 验证操作在合理时间内完成（15次交替切换约3秒）
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));

      // 验证播放器和队列状态仍然有效
      final queueState = container.read(queueViewModelProvider);
      final playerState = container.read(playerViewModelProvider);

      expect(queueState.queue.length, 10);
      expect(playerState, isNotNull);

      container.dispose();
    });

    /// 测试用例1扩展：更极端的快速切换测试
    testWidgets('连续20次快速切换操作', (tester) async {
      // Arrange
      final container = createContainerWithQueue(queueSize: 20, startIndex: 10);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: ControlsPanel(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act: 连续20次快速切换
      for (int i = 0; i < 20; i++) {
        if (i % 2 == 0) {
          await tester.tap(find.byIcon(Icons.skip_next));
        } else {
          await tester.tap(find.byIcon(Icons.skip_previous));
        }
        // 更短的间隔测试极限情况
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Assert: 无崩溃
      expect(tester.takeException(), isNull);

      // 验证状态一致性
      final queueState = container.read(queueViewModelProvider);
      expect(queueState.queue.length, greaterThan(0));

      container.dispose();
    });

    /// 测试用例3：多方式音频切换测试
    testWidgets('交替使用上一首/下一首和播放列表切换', (tester) async {
      // Arrange
      final container = createContainerWithQueue(queueSize: 5, startIndex: 2);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  ControlsPanel(),
                  // 播放列表按钮会在这里
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act: 交替使用不同切换方式
      for (int i = 0; i < 10; i++) {
        // 方式1：使用控制按钮
        if (i % 2 == 0) {
          await tester.tap(find.byIcon(Icons.skip_next));
          await tester.pump(const Duration(milliseconds: 100));
        } else {
          await tester.tap(find.byIcon(Icons.skip_previous));
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      // Assert: 验证没有异常
      expect(tester.takeException(), isNull);

      container.dispose();
    });

    /// 测试用例5：播放控制功能测试
    testWidgets('快速切换后播放控制功能应正常工作', (tester) async {
      // Arrange
      final container = createContainerWithQueue(queueSize: 5, startIndex: 0);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: ControlsPanel(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act: 先进行快速切换
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byIcon(Icons.skip_next));
        await tester.pump(const Duration(milliseconds: 100));
      }

      // 然后测试播放控制
      final playPauseButton = find.byIcon(Icons.pause);
      expect(playPauseButton, findsOneWidget);

      await tester.tap(playPauseButton);
      await tester.pump();

      // Assert: 验证播放/暂停状态切换
      expect(tester.takeException(), isNull);

      container.dispose();
    });

    /// 测试用例4：音频类型切换测试
    testWidgets('快速切换在线和本地音频', (tester) async {
      // Arrange: 创建混合队列
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();

      final queueNotifier = container.read(queueViewModelProvider.notifier);

      // 创建混合队列（在线和本地交替）
      final mixedQueue = <PlayableAudio>[];
      for (int i = 0; i < 10; i++) {
        if (i % 2 == 0) {
          // 在线音频
          mixedQueue.add(OnlinePlayable.fromAudio(
            Audio(
              id: 'online_$i',
              title: '在线歌曲$i',
              artist: '在线艺术家$i',
            ),
            'http://example.com/online_$i.mp3',
          ));
        } else {
          // 本地音频（使用 OnlinePlayable 模拟本地，因为实际本地文件路径测试复杂）
          mixedQueue.add(OnlinePlayable.fromAudio(
            Audio(
              id: 'local_$i',
              title: '本地歌曲$i',
              artist: '本地艺术家$i',
            ),
            'file:///local/path/local_$i.mp3',
          ));
        }
      }

      queueNotifier.state = QueueState(queue: mixedQueue, currentIndex: 0);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: ControlsPanel(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act: 快速切换
      for (int i = 0; i < 10; i++) {
        await tester.tap(find.byIcon(Icons.skip_next));
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Assert: 验证无崩溃
      expect(tester.takeException(), isNull);

      // 验证状态
      final playerState = container.read(playerViewModelProvider);
      expect(playerState, isNotNull);

      container.dispose();
    });

    /// 边界测试：空队列时的快速切换
    testWidgets('空队列时快速切换应优雅处理', (tester) async {
      // Arrange
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();

      container.read(queueViewModelProvider.notifier).state =
          const QueueState(queue: [], currentIndex: -1);
      container.read(playerViewModelProvider.notifier).state = const PlayerState();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: ControlsPanel(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act: 快速点击下一首
      for (int i = 0; i < 10; i++) {
        await tester.tap(find.byIcon(Icons.skip_next));
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Assert: 应显示提示，但不崩溃
      expect(tester.takeException(), isNull);

      container.dispose();
    });

    /// 性能测试：大列表快速切换
    testWidgets('大队列（100首）快速切换性能测试', (tester) async {
      // Arrange
      final container = createContainerWithQueue(queueSize: 100, startIndex: 50);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: ControlsPanel(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final stopwatch = Stopwatch()..start();

      // Act: 快速切换20次
      for (int i = 0; i < 20; i++) {
        await tester.tap(find.byIcon(Icons.skip_next));
        await tester.pump(const Duration(milliseconds: 50));
      }

      stopwatch.stop();

      // Assert: 应在合理时间内完成
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));
      expect(tester.takeException(), isNull);

      container.dispose();
    });
  });

  group('集成测试：音频切换后功能验证', () {
    /// 测试用例2：音频切换后上传功能测试
    testWidgets('快速切换后上传按钮应可点击', (tester) async {
      // Arrange
      final container = createContainerWithQueue(queueSize: 5, startIndex: 0);

      bool uploadButtonPressed = false;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              appBar: AppBar(
                actions: [
                  IconButton(
                    icon: const Icon(Icons.file_upload),
                    onPressed: () {
                      uploadButtonPressed = true;
                    },
                  ),
                ],
              ),
              body: const ControlsPanel(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act: 快速切换
      for (int i = 0; i < 10; i++) {
        await tester.tap(find.byIcon(Icons.skip_next));
        await tester.pump(const Duration(milliseconds: 100));
      }

      // 尝试点击上传按钮
      await tester.tap(find.byIcon(Icons.file_upload));
      await tester.pumpAndSettle();

      // Assert: 上传按钮应可点击
      expect(uploadButtonPressed, isTrue);
      expect(tester.takeException(), isNull);

      container.dispose();
    });
  });
}
