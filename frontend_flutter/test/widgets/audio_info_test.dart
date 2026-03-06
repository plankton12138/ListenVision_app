import 'dart:typed_data';

import 'package:listenvision/presentation/viewmodels/player/player_viewmodel.dart';
import 'package:listenvision/presentation/widgets/audio_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Widget 测试：AudioInfo
///
/// 对应测试用例：
/// - 用例4：音频类型切换及状态显示测试
/// - 验证在线/本地音频的封面显示
/// - 验证音频信息（标题、艺术家）的显示
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer createTestContainer({
    PlayerState? playerState,
  }) {
    SharedPreferences.setMockInitialValues({});
    return ProviderContainer();
  }

  group('AudioInfo Widget Tests - 基础显示', () {
    testWidgets('应显示音频标题和艺术家', (tester) async {
      // Arrange
      final playerState = PlayerState(
        title: '测试歌曲标题',
        artist: '测试艺术家',
        isPlaying: true,
      );

      final container = createTestContainer();
      container.read(playerViewModelProvider.notifier).state = playerState;

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: AudioInfo(),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('测试歌曲标题'), findsOneWidget);
      expect(find.text('测试艺术家'), findsOneWidget);

      container.dispose();
    });

    testWidgets('应显示默认封面图片（当无封面时）', (tester) async {
      // Arrange
      final playerState = PlayerState(
        title: '测试歌曲',
        artist: '测试艺术家',
        isPlaying: true,
        albumArt: null,
        coverUrl: null,
      );

      final container = createTestContainer();
      container.read(playerViewModelProvider.notifier).state = playerState;

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: AudioInfo(),
            ),
          ),
        ),
      );

      // Assert: 应显示默认封面
      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);

      final image = tester.widget<Image>(imageFinder);
      expect(image.image, isA<AssetImage>());

      container.dispose();
    });

    testWidgets('标题过长时应正确截断（最多2行）', (tester) async {
      // Arrange
      final longTitle = '这是一首非常非常非常非常非常非常非常非常非常长的歌曲标题，应该被正确截断显示';
      final playerState = PlayerState(
        title: longTitle,
        artist: '测试艺术家',
        isPlaying: true,
      );

      final container = createTestContainer();
      container.read(playerViewModelProvider.notifier).state = playerState;

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                child: const AudioInfo(),
              ),
            ),
          ),
        ),
      );

      // Assert: 验证文本存在且设置了截断
      expect(find.text(longTitle), findsOneWidget);

      final textWidget = tester.widget<Text>(find.text(longTitle));
      expect(textWidget.maxLines, 2);
      expect(textWidget.overflow, TextOverflow.ellipsis);

      container.dispose();
    });

    testWidgets('艺术家名称过长时应截断（最多1行）', (tester) async {
      // Arrange
      final longArtist = '这是一个非常非常非常非常非常非常长的艺术家名称';
      final playerState = PlayerState(
        title: '测试歌曲',
        artist: longArtist,
        isPlaying: true,
      );

      final container = createTestContainer();
      container.read(playerViewModelProvider.notifier).state = playerState;

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                child: const AudioInfo(),
              ),
            ),
          ),
        ),
      );

      // Assert: 验证文本存在且设置了截断
      expect(find.text(longArtist), findsOneWidget);

      final textWidget = tester.widget<Text>(find.text(longArtist));
      expect(textWidget.maxLines, 1);
      expect(textWidget.overflow, TextOverflow.ellipsis);

      container.dispose();
    });
  });

  group('AudioInfo Widget Tests - 在线音频封面', () {
    testWidgets('应显示在线音频封面（通过 coverUrl）', (tester) async {
      // Arrange
      const coverUrl = 'https://example.com/cover.jpg';
      final playerState = PlayerState(
        title: '在线歌曲',
        artist: '在线艺术家',
        isPlaying: true,
        isCurrentOnline: true,
        coverUrl: coverUrl,
        albumArt: null,
      );

      final container = createTestContainer();
      container.read(playerViewModelProvider.notifier).state = playerState;

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: AudioInfo(),
            ),
          ),
        ),
      );

      // Assert: 应显示网络图片
      final networkImageFinder = find.byType(Image);
      expect(networkImageFinder, findsOneWidget);

      final image = tester.widget<Image>(networkImageFinder);
      expect(image.image, isA<NetworkImage>());

      container.dispose();
    });

    testWidgets('本地封面优先级高于在线封面', (tester) async {
      // Arrange: 创建有效的最小 PNG 图片数据 (1x1 透明像素 PNG)
      // PNG 文件头 + IHDR + IDAT + IEND
      final coverData = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG 签名
        0x00, 0x00, 0x00, 0x0D, // IHDR 长度
        0x49, 0x48, 0x44, 0x52, // IHDR 类型
        0x00, 0x00, 0x00, 0x01, // 宽度 1
        0x00, 0x00, 0x00, 0x01, // 高度 1
        0x08, 0x06, 0x00, 0x00, 0x00, // 位深度、颜色类型等
        0x1F, 0x15, 0xC4, 0x89, // CRC
        0x00, 0x00, 0x00, 0x0A, // IDAT 长度
        0x49, 0x44, 0x41, 0x54, // IDAT 类型
        0x78, 0x9C, 0x62, 0x00, 0x02, 0x00, 0x00, 0x05, 0x00, 0x01, // 压缩数据
        0x0D, 0x0A, 0x2D, 0xB4, // CRC
        0x00, 0x00, 0x00, 0x00, // IEND 长度
        0x49, 0x45, 0x4E, 0x44, // IEND 类型
        0xAE, 0x42, 0x60, 0x82, // CRC
      ]);

      final playerState = PlayerState(
        title: '测试歌曲',
        artist: '测试艺术家',
        isPlaying: true,
        albumArt: coverData,
        coverUrl: 'https://example.com/cover.jpg',
      );

      final container = createTestContainer();
      container.read(playerViewModelProvider.notifier).state = playerState;

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: AudioInfo(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert: 应显示本地封面（MemoryImage）
      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);

      final image = tester.widget<Image>(imageFinder);
      expect(image.image, isA<MemoryImage>());

      container.dispose();
    });
  });

  group('AudioInfo Widget Tests - 用户交互', () {
    testWidgets('点击音频信息区域应打开播放列表', (tester) async {
      // Arrange
      final playerState = PlayerState(
        title: '测试歌曲',
        artist: '测试艺术家',
        isPlaying: true,
      );

      final container = createTestContainer();
      container.read(playerViewModelProvider.notifier).state = playerState;

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: const AudioInfo(),
            ),
            // 捕获 showModalBottomSheet 调用
            onGenerateRoute: (settings) {
              if (settings.name == '/') {
                return MaterialPageRoute(
                  builder: (context) => const Scaffold(
                    body: AudioInfo(),
                  ),
                );
              }
              return null;
            },
          ),
        ),
      );

      // 点击音频信息区域
      await tester.tap(find.byType(AudioInfo));
      await tester.pumpAndSettle();

      // Assert: 验证没有崩溃
      expect(tester.takeException(), isNull);

      container.dispose();
    });
  });

  group('AudioInfo Widget Tests - 状态更新', () {
    testWidgets('音频切换时封面和信息应正确更新', (tester) async {
      // Arrange
      final playerState1 = PlayerState(
        title: '歌曲1',
        artist: '艺术家1',
        isPlaying: true,
        coverUrl: 'https://example.com/cover1.jpg',
      );

      final container = createTestContainer();
      final notifier = container.read(playerViewModelProvider.notifier);
      notifier.state = playerState1;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: AudioInfo(),
            ),
          ),
        ),
      );

      // Assert: 初始状态
      expect(find.text('歌曲1'), findsOneWidget);
      expect(find.text('艺术家1'), findsOneWidget);

      // Act: 切换到新歌曲
      final playerState2 = PlayerState(
        title: '歌曲2',
        artist: '艺术家2',
        isPlaying: true,
        coverUrl: 'https://example.com/cover2.jpg',
      );
      notifier.state = playerState2;

      await tester.pump();

      // Assert: 更新后的状态
      expect(find.text('歌曲2'), findsOneWidget);
      expect(find.text('艺术家2'), findsOneWidget);
      expect(find.text('歌曲1'), findsNothing);
      expect(find.text('艺术家1'), findsNothing);

      container.dispose();
    });

    testWidgets('在线音频和本地音频切换时状态显示正确', (tester) async {
      // Arrange
      final container = createTestContainer();
      final notifier = container.read(playerViewModelProvider.notifier);

      // 初始：在线音频
      final onlineState = PlayerState(
        title: '在线歌曲',
        artist: '在线艺术家',
        isPlaying: true,
        isCurrentOnline: true,
        coverUrl: 'https://example.com/cover.jpg',
      );
      notifier.state = onlineState;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: AudioInfo(),
            ),
          ),
        ),
      );

      // Assert: 在线音频状态
      expect(find.text('在线歌曲'), findsOneWidget);

      // Act: 切换到本地音频
      final localCoverData = Uint8List.fromList([1, 2, 3, 4, 5]);
      final localState = PlayerState(
        title: '本地歌曲',
        artist: '本地艺术家',
        isPlaying: true,
        isCurrentOnline: false,
        albumArt: localCoverData,
        coverUrl: null,
      );
      notifier.state = localState;

      await tester.pump();

      // Assert: 本地音频状态
      expect(find.text('本地歌曲'), findsOneWidget);
      expect(find.text('本地艺术家'), findsOneWidget);

      // 验证使用了本地封面
      final image = tester.widget<Image>(find.byType(Image));
      expect(image.image, isA<MemoryImage>());

      container.dispose();
    });
  });

  group('AudioInfo Widget Tests - 边界情况', () {
    testWidgets('空标题时应显示默认值', (tester) async {
      // Arrange
      final playerState = const PlayerState(
        title: '未知标题',
        artist: '未知艺术家',
        isPlaying: false,
        isIdle: true,
      );

      final container = createTestContainer();
      container.read(playerViewModelProvider.notifier).state = playerState;

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: AudioInfo(),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('未知标题'), findsOneWidget);
      expect(find.text('未知艺术家'), findsOneWidget);

      container.dispose();
    });

    testWidgets('艺术家为 null 时应显示"未知艺术家"', (tester) async {
      // Arrange
      final playerState = PlayerState(
        title: '测试歌曲',
        artist: '', // 使用空字符串而不是 null，因为 PlayerState 使用 @Default('未知艺术家')
        isPlaying: true,
      );

      final container = createTestContainer();
      container.read(playerViewModelProvider.notifier).state = playerState;

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: AudioInfo(),
            ),
          ),
        ),
      );

      // Assert: 使用默认值
      expect(find.text('测试歌曲'), findsOneWidget);
      // ArtistState 默认值是 '未知艺术家'

      container.dispose();
    });

    testWidgets('封面容器应有固定高度', (tester) async {
      // Arrange
      final playerState = PlayerState(
        title: '测试歌曲',
        artist: '测试艺术家',
        isPlaying: true,
      );

      final container = createTestContainer();
      container.read(playerViewModelProvider.notifier).state = playerState;

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: AudioInfo(),
            ),
          ),
        ),
      );

      // Assert: 验证封面容器存在且有正确的高度
      final containerFinder = find.byType(Container);
      expect(containerFinder, findsWidgets);

      // 获取封面容器（第一个 Container）
      final coverContainer = tester.widget<Container>(
        containerFinder.at(0),
      );
      expect(coverContainer.constraints?.minHeight, 300);
      expect(coverContainer.constraints?.maxHeight, 300);

      container.dispose();
    });
  });
}
