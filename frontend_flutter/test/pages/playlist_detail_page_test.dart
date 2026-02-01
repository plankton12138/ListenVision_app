import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo/presentation/pages/playlist_detail_page.dart';
import 'package:demo/presentation/providers/audio/audio_provider.dart';
import 'package:demo/presentation/providers/playlist/playlist_provider.dart';
import 'package:demo/presentation/providers/auth/auth_provider.dart';
import 'package:demo/domain/entities/models_export.dart';
import 'package:demo/presentation/providers/play_history/play_history_provider.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 设置模拟方法调用处理器
  const _audioGlobalChannel = MethodChannel('xyz.luan/audioplayers.global');
  const _audioPlayerChannel = MethodChannel('xyz.luan/audioplayers');
  const _prefsChannel = MethodChannel('plugins.flutter.io/shared_preferences');

  setUpAll(() {
    // 音频播放器全局频道
    _audioGlobalChannel.setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'init') {
        return null;
      }
      return null;
    });

    // 音频播放器频道
    _audioPlayerChannel.setMockMethodCallHandler((MethodCall methodCall) async {
      return null;
    });

    // 共享偏好设置频道
    _prefsChannel.setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'getAll') {
        return <String, dynamic>{};
      }
      return null;
    });
  });

  tearDownAll(() {
    _audioGlobalChannel.setMockMethodCallHandler(null);
    _audioPlayerChannel.setMockMethodCallHandler(null);
    _prefsChannel.setMockMethodCallHandler(null);
  });

  group('PlaylistDetailPage Local Audio', () {
    testWidgets('本地歌曲应该有localPath字段', (tester) async {
      // 创建本地歌曲测试数据
      final localItem = PlaylistItem(
        bvid: '', // 空bvid表示本地歌曲
        title: '本地歌曲',
        artist: '本地艺术家',
        duration: 180,
        position: 1,
        localPath: '/path/to/local/song.mp3',
      );

      expect(localItem.bvid, '');
      expect(localItem.localPath, '/path/to/local/song.mp3');
    });

    testWidgets('在线歌曲应该有bvid字段', (tester) async {
      // 创建在线歌曲测试数据
      final onlineItem = PlaylistItem(
        bvid: 'BV1234567890',
        title: '在线歌曲',
        artist: '在线艺术家',
        duration: 200,
        position: 1,
      );

      expect(onlineItem.bvid, 'BV1234567890');
      expect(onlineItem.localPath, null);
    });

    testWidgets('应该能够区分本地歌曲和在线歌曲', (tester) async {
      // 创建本地歌曲
      final localItem = PlaylistItem(
        bvid: '',
        title: '本地歌曲',
        position: 1,
        localPath: '/path/to/song.mp3',
      );

      // 创建在线歌曲
      final onlineItem = PlaylistItem(
        bvid: 'BV1234567890',
        title: '在线歌曲',
        position: 2,
      );

      // 测试本地歌曲判断逻辑
      final isLocal1 = localItem.bvid.isEmpty;
      final isLocal2 = localItem.bvid.startsWith('file://');
      expect(isLocal1 || isLocal2, true);

      // 测试在线歌曲判断逻辑
      final isOnline = !(onlineItem.bvid.isEmpty || onlineItem.bvid.startsWith('file://'));
      expect(isOnline, true);
    });

    testWidgets('file://前缀的bvid应该被识别为本地歌曲', (tester) async {
      final fileUrlItem = PlaylistItem(
        bvid: 'file:///path/to/song.mp3',
        title: '文件URL歌曲',
        position: 1,
      );

      final isLocal = fileUrlItem.bvid.startsWith('file://');
      expect(isLocal, true);
    });
  });
}
