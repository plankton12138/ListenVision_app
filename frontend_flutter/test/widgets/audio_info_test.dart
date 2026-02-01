import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo/presentation/widgets/audio_info.dart';
import 'package:demo/presentation/providers/audio/audio_metadata_provider.dart';
import 'package:demo/presentation/providers/playlist/playlist_provider.dart';
import 'package:demo/presentation/providers/auth/auth_provider.dart';
import 'package:demo/presentation/providers/bilibili/bilibili_provider.dart';
import 'package:demo/domain/entities/audio.dart';
import 'package:demo/domain/entities/online_playable.dart';
import 'package:demo/presentation/widgets/cards/favorite_button.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AudioInfo with Favorite', () {
    late Audio testAudio;
    late AudioMetadataProvider metadataProvider;

    setUp(() {
      testAudio = const Audio(
        id: 'BV123456',
        title: 'Test Song',
        artist: 'Test Artist',
        coverUrl: 'https://example.com/cover.jpg',
        duration: 180,
      );

      metadataProvider = AudioMetadataProvider();
      final playable = OnlinePlayable.fromAudio(testAudio, null);
      metadataProvider.updateMetadata(
        title: testAudio.title,
        artist: testAudio.artist ?? 'Unknown',
        albumArt: null,
        playable: playable,
      );
    });

    testWidgets('显示收藏按钮', (tester) async {
      final playlistProvider = PlaylistProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: metadataProvider),
            ChangeNotifierProvider.value(value: playlistProvider),
            ChangeNotifierProvider<AuthProvider>(
              create: (_) => AuthProvider(),
            ),
            ChangeNotifierProvider<BilibiliProvider>(
              create: (_) => BilibiliProvider(),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AudioInfo(),
            ),
          ),
        ),
      );

      expect(find.byType(FavoriteButton), findsOneWidget);
    });

    testWidgets('收藏按钮显示正确状态', (tester) async {
      final playlistProvider = PlaylistProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: metadataProvider),
            ChangeNotifierProvider.value(value: playlistProvider),
            ChangeNotifierProvider<AuthProvider>(
              create: (_) => AuthProvider(),
            ),
            ChangeNotifierProvider<BilibiliProvider>(
              create: (_) => BilibiliProvider(),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AudioInfo(),
            ),
          ),
        ),
      );

      // 未收藏状态应显示空心图标
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });
  });
}
