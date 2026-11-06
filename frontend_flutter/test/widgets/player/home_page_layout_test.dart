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
import 'package:listenvision/presentation/widgets/player_action_bar.dart';

/// 首页布局 widget 测试
///
/// 首页封面使用 BoxFit.contain 自适应显示，不同宽高比的封面会得到不同的
/// 显示高度。这里固定手机视口，分别渲染宽幅（16:9）和近方形封面，
/// 验证播放器内容整体垂直居中，而不是贴顶排列。
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

  final Uint8List _cover;

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
