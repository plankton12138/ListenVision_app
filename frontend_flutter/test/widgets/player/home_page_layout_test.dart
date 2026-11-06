import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:listenvision/core/models/network_status.dart';
import 'package:listenvision/core/network/network_status_provider.dart';
import 'package:listenvision/models/audio.dart';
import 'package:listenvision/models/online_playable.dart';
import 'package:listenvision/presentation/theme/light_mode.dart';
import 'package:listenvision/presentation/viewmodels/library/favorite_tracks_notifier.dart';
import 'package:listenvision/presentation/viewmodels/player/playback_viewmodel.dart';
import 'package:listenvision/presentation/viewmodels/player/queue_viewmodel.dart';
import 'package:listenvision/presentation/views/player/home_page.dart';
import 'package:listenvision/presentation/widgets/audio_info.dart';
import 'package:listenvision/presentation/widgets/controls_panel.dart';
import 'package:listenvision/presentation/widgets/player_action_bar.dart';

/// 首页布局 widget 测试
///
/// 首页封面使用固定高度的展示区域，图片按原始宽高比 contain 居中显示。
/// 这里固定手机视口，分别渲染宽幅（16:9）和近方形封面，验证内容整体
/// 垂直居中，且标题/控制区位置不随封面比例变化。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const viewSize = Size(390, 844);

  ProviderContainer createContainer(Uint8List cover) {
    return ProviderContainer(
      overrides: [
        playbackViewModelProvider.overrideWith(
          () => _FakePlaybackViewModel(cover),
        ),
        queueViewModelProvider.overrideWith(_FakeQueueViewModel.new),
        favoriteTracksProvider.overrideWith(_FakeFavoriteTracksNotifier.new),
        networkStatusProvider.overrideWith(_FakeNetworkStatusNotifier.new),
      ],
    );
  }

  Future<void> pumpHomePage(
    WidgetTester tester,
    ProviderContainer container,
    Uint8List cover,
  ) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomePage()),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: lightMode,
          routerConfig: router,
        ),
      ),
    );

    // Image.memory 的解码是真实异步操作，需要在 runAsync 中等待完成，
    // 否则断言会在封面尚未解码、尺寸为 0 的中间状态下执行。
    await tester.runAsync(() async {
      await precacheImage(
        MemoryImage(cover),
        tester.element(find.byType(AudioInfo)),
      );
    });
    await tester.pumpAndSettle();
  }

  for (final sample in <({String name, String asset})>[
    (name: '宽幅封面', asset: 'assets/images/1.png'),
    (name: '近方形封面', asset: 'assets/images/default_album_art.png'),
  ]) {
    testWidgets('${sample.name}下首页内容保持垂直居中', (tester) async {
      tester.view.physicalSize = viewSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // 资源在测试体内加载；setUpAll 的 late 变量在测试注册阶段不可用。
      final cover = (await rootBundle.load(sample.asset)).buffer.asUint8List();
      final container = createContainer(cover);
      addTearDown(container.dispose);

      await pumpHomePage(tester, container, cover);

      // 确认封面已解码并按宽高比占据布局高度，避免在图片尚未加载时误判。
      expect(
        tester.getSize(find.byType(Image)).height,
        greaterThan(150.0),
        reason: '封面图片未完成解码，布局断言不可信',
      );

      final body = tester.getRect(find.byKey(const ValueKey('home-content')));
      final audioInfo = tester.getRect(find.byType(AudioInfo));
      final actionBar = tester.getRect(find.byType(PlayerActionBar));

      final topGap = audioInfo.top - body.top;
      final bottomGap = body.bottom - actionBar.bottom;

      expect(
        topGap,
        greaterThan(16.0),
        reason: '内容不应贴顶，封面比例为 $sample.name 时顶部留白过小',
      );
      expect(
        (topGap - bottomGap).abs(),
        lessThan(2.0),
        reason: '上下留白应基本一致，实际 top=$topGap bottom=$bottomGap',
      );
    });
  }

  testWidgets('不同封面比例下标题与控制区布局位置保持不变', (tester) async {
    tester.view.physicalSize = viewSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final wideCover = (await rootBundle.load(
      'assets/images/1.png',
    )).buffer.asUint8List();
    final squareCover = (await rootBundle.load(
      'assets/images/default_album_art.png',
    )).buffer.asUint8List();

    final container = createContainer(wideCover);
    addTearDown(container.dispose);
    await pumpHomePage(tester, container, wideCover);

    final wideAudio = tester.getRect(find.byType(AudioInfo));
    final wideControls = tester.getRect(find.byType(ControlsPanel));
    final wideActionBar = tester.getRect(find.byType(PlayerActionBar));

    // 在同一个页面内切换封面，避免重建路由/页面引入额外状态。
    final playback =
        container.read(playbackViewModelProvider.notifier)
            as _FakePlaybackViewModel;
    playback.cover = squareCover;
    await tester.runAsync(() async {
      await precacheImage(
        MemoryImage(squareCover),
        tester.element(find.byType(AudioInfo)),
      );
    });
    await tester.pumpAndSettle();

    final squareAudio = tester.getRect(find.byType(AudioInfo));
    final squareControls = tester.getRect(find.byType(ControlsPanel));
    final squareActionBar = tester.getRect(find.byType(PlayerActionBar));

    expect(
      squareAudio.top,
      closeTo(wideAudio.top, 1.0),
      reason: '封面比例变化不应改变音频信息位置',
    );
    expect(
      squareAudio.height,
      closeTo(wideAudio.height, 1.0),
      reason: '封面展示区域高度应固定',
    );
    expect(
      squareControls.top,
      closeTo(wideControls.top, 1.0),
      reason: '封面比例变化不应改变控制区位置',
    );
    expect(
      squareActionBar.top,
      closeTo(wideActionBar.top, 1.0),
      reason: '封面比例变化不应改变底部操作栏位置',
    );
  });
}

PlaybackState _buildPlaybackState(Uint8List cover) {
  return PlaybackState(
    currentPlayable: OnlinePlayable.fromAudio(
      const Audio(id: 'BV1TEST', title: '测试歌曲', artist: '测试艺术家', duration: 215),
      null,
    ),
    title: '测试歌曲',
    artist: '测试艺术家',
    coverData: cover,
    duration: const Duration(seconds: 215),
  );
}

class _FakePlaybackViewModel extends PlaybackViewModel {
  _FakePlaybackViewModel(this._cover);

  Uint8List _cover;

  set cover(Uint8List value) {
    _cover = value;
    state = _buildPlaybackState(value);
  }

  @override
  PlaybackState build() => _buildPlaybackState(_cover);
}

class _FakeQueueViewModel extends QueueViewModel {
  @override
  QueueState build() => const QueueState();
}

class _FakeFavoriteTracksNotifier extends FavoriteTracksNotifier {
  @override
  Future<Set<String>> build() async => <String>{};
}

class _FakeNetworkStatusNotifier extends NetworkStatusNotifier {
  @override
  Future<NetworkStatus> build() async =>
      NetworkStatus.connected(NetworkConnectionType.wifi);
}
