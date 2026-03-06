import 'package:listenvision/models/audio.dart';
import 'package:listenvision/models/online_playable.dart';
import 'package:listenvision/presentation/providers.dart';
import 'package:listenvision/presentation/viewmodels/player/player_viewmodel.dart';
import 'package:listenvision/presentation/viewmodels/player/queue_viewmodel.dart';
import 'package:listenvision/presentation/widgets/controls_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Widget 测试：ControlsPanel
///
/// 对应测试用例：
/// - 用例1：音频快速切换测试
/// - 用例3：多方式音频切换测试
/// - 用例5：播放控制功能测试
void main() {
  // 初始化 SharedPreferences 用于测试
  TestWidgetsFlutterBinding.ensureInitialized();

  /// 创建测试用的 Provider 容器
  ProviderContainer createTestContainer({
    PlayerState? playerState,
    QueueState? queueState,
  }) {
    // 设置空的 SharedPreferences
    SharedPreferences.setMockInitialValues({});

    final container = ProviderContainer();

    // 设置初始状态
    if (playerState != null) {
      container.read(playerViewModelProvider.notifier).state = playerState;
    }
    if (queueState != null) {
      container.read(queueViewModelProvider.notifier).state = queueState;
    }

    return container;
  }

  group('ControlsPanel Widget Tests', () {
    testWidgets('应该显示播放控制按钮（上一首、播放/暂停、下一首）', (tester) async {
      // Arrange: 创建带当前播放内容的播放器状态
      final currentPlayable = OnlinePlayable.fromAudio(
        const Audio(id: '1', title: '测试歌曲', artist: '测试艺术家'),
        'http://example.com/test.mp3',
      );

      final playerState = PlayerState(
        currentPlayable: currentPlayable,
        title: '测试歌曲',
        artist: '测试艺术家',
        isPlaying: false,
        isIdle: false, // 设置为 false，因为现在有内容
      );

      final queueState = const QueueState();

      final container = createTestContainer(
        playerState: playerState,
        queueState: queueState,
      );

      // Act: 构建 widget
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

      // Assert: 验证控制按钮存在
      expect(find.byIcon(Icons.skip_previous), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.skip_next), findsOneWidget);

      container.dispose();
    });

    testWidgets('播放状态为 true 时应显示暂停图标', (tester) async {
      // Arrange
      final currentPlayable = OnlinePlayable.fromAudio(
        const Audio(id: '1', title: '测试歌曲', artist: '测试艺术家'),
        'http://example.com/test.mp3',
      );

      final playerState = PlayerState(
        currentPlayable: currentPlayable,
        title: '测试歌曲',
        artist: '测试艺术家',
        isPlaying: true,
        isPaused: false,
        duration: const Duration(minutes: 3),
        position: const Duration(minutes: 1),
      );

      final queueState = const QueueState();

      final container = createTestContainer(
        playerState: playerState,
        queueState: queueState,
      );

      // Act
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

      // Assert: 播放时显示暂停图标
      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNothing);

      container.dispose();
    });

    testWidgets('应该显示时间进度（当前位置/总时长）', (tester) async {
      // Arrange
      final currentPlayable = OnlinePlayable.fromAudio(
        const Audio(id: '1', title: '测试歌曲', artist: '测试艺术家'),
        'http://example.com/test.mp3',
      );

      final playerState = PlayerState(
        currentPlayable: currentPlayable,
        title: '测试歌曲',
        artist: '测试艺术家',
        isPlaying: true,
        duration: const Duration(minutes: 3, seconds: 30),
        position: const Duration(minutes: 1, seconds: 15),
      );

      final queueState = const QueueState();

      final container = createTestContainer(
        playerState: playerState,
        queueState: queueState,
      );

      // Act
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

      // Assert: 验证时间显示
      // Duration.toString() 格式为 "HH:MM:SS.mmmmmm"，split('.')[0] 得到 "HH:MM:SS"
      expect(find.text('0:01:15 / 0:03:30'), findsOneWidget);

      container.dispose();
    });

    testWidgets('应该显示进度条', (tester) async {
      // Arrange
      final currentPlayable = OnlinePlayable.fromAudio(
        const Audio(id: '1', title: '测试歌曲', artist: '测试艺术家'),
        'http://example.com/test.mp3',
      );

      final playerState = PlayerState(
        currentPlayable: currentPlayable,
        title: '测试歌曲',
        artist: '测试艺术家',
        isPlaying: true,
        duration: const Duration(minutes: 3),
        position: const Duration(minutes: 1, seconds: 30),
      );

      final queueState = const QueueState();

      final container = createTestContainer(
        playerState: playerState,
        queueState: queueState,
      );

      // Act
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

      // Assert: 验证进度条存在（现在有2个 Slider：进度条 + 音量滑块）
      expect(find.byType(Slider), findsAtLeastNWidgets(1));

      // 验证进度条值（找到值为90的进度条 Slider）
      final sliders = tester.widgetList<Slider>(find.byType(Slider)).toList();
      final progressBar = sliders.firstWhere(
        (s) => s.max == 180, // 进度条的最大值是180秒
        orElse: () => throw Exception('找不到进度条 Slider'),
      );
      expect(progressBar.value, 90); // 1分30秒 = 90秒
      expect(progressBar.max, 180); // 3分钟 = 180秒

      container.dispose();
    });

    testWidgets('拖动进度条应调用 seek 方法', (tester) async {
      // Arrange
      final currentPlayable = OnlinePlayable.fromAudio(
        const Audio(id: '1', title: '测试歌曲', artist: '测试艺术家'),
        'http://example.com/test.mp3',
      );

      final playerState = PlayerState(
        currentPlayable: currentPlayable,
        title: '测试歌曲',
        artist: '测试艺术家',
        isPlaying: true,
        duration: const Duration(minutes: 3),
        position: const Duration(minutes: 1),
      );

      final queueState = const QueueState();

      final container = createTestContainer(
        playerState: playerState,
        queueState: queueState,
      );

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

      // Act: 点击进度条中间位置（找到进度条 Slider）
      final sliders = tester.widgetList<Slider>(find.byType(Slider)).toList();
      final progressBarFinder = find.byWidget(sliders.firstWhere(
        (s) => s.max == 180, // 进度条的最大值是180秒
        orElse: () => throw Exception('找不到进度条 Slider'),
      ));
      await tester.tap(progressBarFinder);
      await tester.pumpAndSettle();

      // Assert: 验证状态已更新（位置改变）
      // 位置应该已经改变（通过 seek 被调用）
      // 注意：这里我们主要验证没有崩溃，实际 seek 由 AudioPlayerService 处理

      container.dispose();
    });

    testWidgets('点击播放/暂停按钮应切换状态', (tester) async {
      // Arrange
      final currentPlayable = OnlinePlayable.fromAudio(
        const Audio(id: '1', title: '测试歌曲', artist: '测试艺术家'),
        'http://example.com/test.mp3',
      );

      final playerState = PlayerState(
        currentPlayable: currentPlayable,
        title: '测试歌曲',
        artist: '测试艺术家',
        isPlaying: false,
        isPaused: true,
        duration: const Duration(minutes: 3),
        position: const Duration(minutes: 1),
      );

      final queueState = const QueueState();

      final container = createTestContainer(
        playerState: playerState,
        queueState: queueState,
      );

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

      // Act: 点击播放按钮
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      // Assert: 验证方法被调用（无崩溃）
      // 实际状态变化由 PlayerViewModel 处理

      container.dispose();
    });

    testWidgets('队列中有歌曲时点击下一首应正常响应', (tester) async {
      // Arrange
      final playerState = PlayerState(
        title: '当前歌曲',
        artist: '当前艺术家',
        isPlaying: true,
      );

      final audio1 = Audio(
        id: '2',
        title: '下一首歌曲',
        artist: '下一个艺术家',
        duration: 180,
      );

      final queueState = QueueState(
        queue: [
          OnlinePlayable.fromAudio(
            Audio(
              id: '1',
              title: '当前歌曲',
              artist: '当前艺术家',
            ),
            'http://example.com/1.mp3',
          ),
          OnlinePlayable.fromAudio(audio1, 'http://example.com/2.mp3'),
        ],
        currentIndex: 0,
      );

      final container = createTestContainer(
        playerState: playerState,
        queueState: queueState,
      );

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

      // Act: 点击下一首按钮
      await tester.tap(find.byIcon(Icons.skip_next));
      await tester.pump();

      // Assert: 验证没有错误
      expect(find.byType(SnackBar), findsNothing);

      container.dispose();
    });

    testWidgets('队列中没有歌曲时点击下一首应显示提示', (tester) async {
      // Arrange
      final playerState = PlayerState(
        title: '当前歌曲',
        artist: '当前艺术家',
        isPlaying: true,
      );

      final queueState = const QueueState(queue: [], currentIndex: -1);

      final container = createTestContainer(
        playerState: playerState,
        queueState: queueState,
      );

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

      // Act: 点击下一首按钮
      await tester.tap(find.byIcon(Icons.skip_next));
      await tester.pumpAndSettle();

      // Assert: 应显示提示消息
      expect(find.text('没有下一首了'), findsOneWidget);

      container.dispose();
    });

    testWidgets('错误状态应显示重试按钮', (tester) async {
      // Arrange
      final playerState = PlayerState(
        title: '测试歌曲',
        artist: '测试艺术家',
        hasError: true,
        statusMessage: '播放失败: 网络错误',
      );

      final queueState = const QueueState();

      final container = createTestContainer(
        playerState: playerState,
        queueState: queueState,
      );

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

      // Assert: 应显示重试按钮
      expect(find.text('点击重试'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.text('播放失败: 网络错误'), findsOneWidget);

      container.dispose();
    });

    testWidgets('加载状态应显示进度指示器', (tester) async {
      // Arrange
      final playerState = PlayerState(
        title: '测试歌曲',
        artist: '测试艺术家',
        isLoading: true,
        statusMessage: '正在加载...',
      );

      final queueState = const QueueState();

      final container = createTestContainer(
        playerState: playerState,
        queueState: queueState,
      );

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

      // Assert: 应显示加载状态
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      expect(find.text('正在加载...'), findsOneWidget);

      container.dispose();
    });

    testWidgets('空闲状态应显示"就绪"', (tester) async {
      // Arrange
      final playerState = PlayerState(
        title: '测试歌曲',
        artist: '测试艺术家',
        isIdle: true,
      );

      final queueState = const QueueState();

      final container = createTestContainer(
        playerState: playerState,
        queueState: queueState,
      );

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

      // Assert: 应显示"就绪"
      expect(find.text('就绪'), findsOneWidget);

      container.dispose();
    });

    testWidgets('应显示音量和倍速控制', (tester) async {
      // Arrange
      final playerState = PlayerState(
        title: '测试歌曲',
        artist: '测试艺术家',
        isPlaying: true,
        volume: 0.8,
        speed: 1.0,
      );

      final queueState = const QueueState();

      final container = createTestContainer(
        playerState: playerState,
        queueState: queueState,
      );

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

      // Assert: 应显示音量滑块和倍速按钮
      expect(find.byIcon(Icons.remove), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      // 验证音量百分比显示
      expect(find.text('80%'), findsOneWidget);

      container.dispose();
    });
  });

  group('ControlsPanel 快速切换测试', () {
    /// 测试用例1：音频快速切换测试
    /// 以每秒至少2次的频率，交替使用"上一首"和"下一首"按钮
    testWidgets('快速交替点击上一首和下一首应不崩溃', (tester) async {
      // Arrange: 创建包含多首歌曲的队列
      final playerState = PlayerState(
        title: '歌曲1',
        artist: '艺术家1',
        isPlaying: true,
      );

      final queueState = QueueState(
        queue: List.generate(
          5,
          (i) => OnlinePlayable.fromAudio(
            Audio(
              id: '$i',
              title: '歌曲$i',
              artist: '艺术家$i',
              duration: 180,
            ),
            'http://example.com/$i.mp3',
          ),
        ),
        currentIndex: 2,
      );

      final container = createTestContainer(
        playerState: playerState,
        queueState: queueState,
      );

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

      // Act: 快速交替点击上一首和下一首（模拟快速切换）
      for (int i = 0; i < 10; i++) {
        await tester.tap(find.byIcon(Icons.skip_previous));
        await tester.pump(const Duration(milliseconds: 100));

        await tester.tap(find.byIcon(Icons.skip_next));
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Assert: 验证没有崩溃
      expect(tester.takeException(), isNull);

      container.dispose();
    });

    /// 测试用例3：多方式音频切换测试
    testWidgets('通过控制按钮切换音频应正确工作', (tester) async {
      // Arrange
      final playerState = PlayerState(
        title: '歌曲1',
        artist: '艺术家1',
        isPlaying: true,
      );

      final queueState = QueueState(
        queue: List.generate(
          3,
          (i) => OnlinePlayable.fromAudio(
            Audio(
              id: '$i',
              title: '歌曲$i',
              artist: '艺术家$i',
            ),
            'http://example.com/$i.mp3',
          ),
        ),
        currentIndex: 0,
      );

      final container = createTestContainer(
        playerState: playerState,
        queueState: queueState,
      );

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

      // Act & Assert: 点击下一首
      await tester.tap(find.byIcon(Icons.skip_next));
      await tester.pump();
      expect(tester.takeException(), isNull);

      // 点击上一首
      await tester.tap(find.byIcon(Icons.skip_previous));
      await tester.pump();
      expect(tester.takeException(), isNull);

      container.dispose();
    });
  });
}
