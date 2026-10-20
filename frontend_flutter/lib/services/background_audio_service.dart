import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/app_logger.dart';

final backgroundAudioServiceProvider = Provider<BackgroundAudioService>((ref) {
  final service = BackgroundAudioService();
  ref.onDispose(service.dispose);
  return service;
});

/// 系统媒体控制桥接。Windows 等平台无需创建原生服务。
class BackgroundAudioService {
  BackgroundAudioService({MethodChannel? channel, bool? enabled})
    : _channel =
          channel ?? const MethodChannel('listenvision/background_audio'),
      _enabled = enabled ?? (!kIsWeb && Platform.isAndroid) {
    if (_enabled) {
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'command' && !_commands.isClosed) {
          _commands.add(Map<String, dynamic>.from(call.arguments as Map));
        }
      });
    }
  }
  final MethodChannel _channel;
  final bool _enabled;
  final _commands = StreamController<Map<String, dynamic>>.broadcast();
  Map<String, dynamic> _snapshot = {};
  Stream<Map<String, dynamic>> get commands => _commands.stream;

  Future<bool> prepare() async {
    if (!_enabled) return true;
    try {
      return await _channel.invokeMethod<bool>('prepare', {
            ..._snapshot,
            'loading': true,
            'hasContent': true,
          }) ??
          false;
    } on PlatformException catch (error) {
      AppLogger.error('BackgroundAudio', '启动系统播放服务失败: $error');
      return false;
    }
  }

  Future<void> update(Map<String, dynamic> state) async {
    _snapshot = state;
    await _invoke('update', state);
  }

  Future<void> stop() => _invoke('stop');
  Future<void> abandonFocus() => _invoke('abandonFocus');
  Future<void> _invoke(String method, [Object? arguments]) async {
    if (!_enabled) return;
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } on PlatformException catch (error) {
      AppLogger.warn('BackgroundAudio', '$method: $error');
    }
  }

  void dispose() {
    if (_enabled) _channel.setMethodCallHandler(null);
    _commands.close();
  }
}
