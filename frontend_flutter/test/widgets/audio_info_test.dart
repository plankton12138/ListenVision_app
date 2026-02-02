import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo/presentation/widgets/audio_info.dart';
import 'package:demo/presentation/providers/audio/audio_provider.dart';
import 'package:demo/presentation/providers/playlist/playlist_provider.dart';
import 'package:demo/presentation/providers/auth/auth_provider.dart';
import 'package:demo/presentation/providers/bilibili/bilibili_provider.dart';
import 'package:demo/domain/entities/audio.dart';
import 'package:demo/domain/entities/local_audio.dart';
import 'package:demo/domain/entities/online_playable.dart';
import 'package:demo/domain/entities/playable_audio.dart';
import 'package:demo/presentation/widgets/cards/favorite_button.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';

/// Fake AudioProvider for testing (不依赖原生插件)
class FakeAudioProvider extends ChangeNotifier implements AudioProvider {
  PlayableAudio? _currentPlayable;
  String _title = "Test Song";
  String _artist = "Test Artist";
  Uint8List? _albumArt;

  @override
  PlayableAudio? get currentPlayable => _currentPlayable;

  @override
  String get title => _title;

  @override
  String get artist => _artist;

  @override
  Uint8List? get albumArt => _albumArt;

  void setTestPlayable(PlayableAudio playable) {
    _currentPlayable = playable;
    _title = playable.title;
    _artist = playable.artist ?? 'Unknown';
    notifyListeners();
  }

  // 实现必需的抽象方法（测试中不需要）
  @override
  Duration get position => Duration.zero;

  @override
  Duration get duration => Duration.zero;

  @override
  bool get isPlaying => false;

  @override
  bool get isPaused => false;

  @override
  bool get isLoading => false;

  @override
  List<LocalAudio> get localPlaylist => [];

  @override
  List<PlayableAudio> get unifiedPlaylist => [];

  @override
  void dispose() {
    _currentPlayable = null;
    super.dispose();
  }

  // 使用 noSuchMethod 处理未实现的方法调用
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AudioInfo 基础渲染测试', () {
    testWidgets('应该能渲染 AudioInfo 组件（使用 FakeAudioProvider）', (tester) async {
      final fakeProvider = FakeAudioProvider();
      final bilibiliProvider = BilibiliProvider();

      // 设置测试数据
      final testAudio = const Audio(
        id: 'BV123456',
        title: 'Test Song',
        artist: 'Test Artist',
        coverUrl: 'https://example.com/cover.jpg',
        duration: 180,
      );
      final playable = OnlinePlayable.fromAudio(testAudio, null);
      fakeProvider.setTestPlayable(playable);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AudioProvider>.value(value: fakeProvider),
            ChangeNotifierProvider<BilibiliProvider>.value(value: bilibiliProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AudioInfo(),
            ),
          ),
        ),
      );

      // 验证组件渲染成功
      expect(find.byType(AudioInfo), findsOneWidget);
      expect(find.text('Test Song'), findsOneWidget);
      expect(find.text('Test Artist'), findsOneWidget);
    });
  });

  // TODO: 添加 FavoriteButton 集成测试（需要在 Phase 2 完成测试环境修复后）
}
