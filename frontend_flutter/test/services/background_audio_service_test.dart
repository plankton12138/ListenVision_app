import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listenvision/services/background_audio_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('listenvision/background-audio-test');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('恢复播放前以 loading 状态启动服务，保留元数据', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return call.method == 'prepare' ? true : null;
    });
    final service = BackgroundAudioService(channel: channel, enabled: true);
    await service.update({'title': '曲目', 'playing': false, 'loading': false});
    expect(await service.prepare(), isTrue);
    expect(calls.last.method, 'prepare');
    expect(calls.last.arguments['loading'], isTrue);
    expect(calls.last.arguments['hasContent'], isTrue);
    expect(calls.last.arguments['title'], '曲目');
    service.dispose();
  });

  test('无法启动系统服务时返回失败，不误报已取得音频焦点', () async {
    messenger.setMockMethodCallHandler(channel, (_) async {
      throw PlatformException(code: 'BACKGROUND_START_FAILED');
    });
    final service = BackgroundAudioService(channel: channel, enabled: true);
    expect(await service.prepare(), isFalse);
    service.dispose();
  });

  test('非 Android 平台播放不依赖原生通道', () async {
    final service = BackgroundAudioService(channel: channel, enabled: false);
    expect(await service.prepare(), isTrue);
    await service.update({'playing': true});
    await service.stop();
    service.dispose();
  });
}
