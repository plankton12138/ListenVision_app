import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo/presentation/providers/audio/audio_provider.dart';
import 'package:demo/domain/entities/audio.dart';

void main() {
  // 初始化 Flutter 测试绑定
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock audio players 的方法调用
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

  group('AudioProvider.addToPlaylistOnline', () {
    late AudioProvider audioProvider;

    setUp(() async {
      audioProvider = AudioProvider();
      // 等待异步初始化完成
      await Future.delayed(const Duration(milliseconds: 100));
    });

    tearDown(() {
      audioProvider.dispose();
    });

    test('应该将在线音频添加到统一播放列表', () async {
      // Arrange
      final audio = Audio(
        id: 'BV1xx411c7mD',
        title: '测试歌曲',
      );

      // Act
      await audioProvider.addToPlaylistOnline(audio);

      // Assert
      expect(audioProvider.unifiedPlaylist.length, greaterThanOrEqualTo(1));
      // 检查添加的音频在播放列表中
      final hasAudio = audioProvider.unifiedPlaylist.any(
        (item) => item.id.contains('BV1xx411c7mD'),
      );
      expect(hasAudio, true);
    });

    test('应该添加多首歌曲到播放列表', () async {
      // Arrange
      final audios = List.generate(
        3,
        (i) => Audio(id: 'BV$i', title: '歌曲$i'),
      );

      // 获取初始播放列表长度
      final initialLength = audioProvider.unifiedPlaylist.length;

      // Act
      for (final audio in audios) {
        await audioProvider.addToPlaylistOnline(audio);
      }

      // Assert
      expect(audioProvider.unifiedPlaylist.length, greaterThanOrEqualTo(initialLength + 3));
    });
  });
}
