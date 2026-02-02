import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:demo/presentation/providers/audio/audio_provider.dart';
import 'package:demo/presentation/widgets/controls_panel.dart';

class FakeAudioProvider extends ChangeNotifier implements AudioProvider {
  bool _hasPlaybackError = false;
  String _playerStatusMessage = '';

  int clearCalls = 0;
  int toggleCalls = 0;
  double _volume = 1.0;
  double _speed = 1.0;

  @override
  bool get hasPlaybackError => _hasPlaybackError;

  @override
  String get playerStatusMessage => _playerStatusMessage;

  @override
  Duration get duration => Duration.zero;

  @override
  Duration get position => Duration.zero;

  @override
  bool get isLoading => false;

  @override
  bool get isBuffering => false;

  @override
  bool get isCompleted => false;

  @override
  bool get isIdle => false;

  @override
  bool get isPlaying => false;

  @override
  bool get isSeekable => true;

  @override
  bool get isReady => true;

  @override
  double get volume => _volume;

  @override
  double get speed => _speed;

  void setErrorState({required bool hasError, required String message}) {
    _hasPlaybackError = hasError;
    _playerStatusMessage = message;
    notifyListeners();
  }

  @override
  void clearPlaybackError() {
    clearCalls++;
    _hasPlaybackError = false;
    _playerStatusMessage = '';
  }

  @override
  Future<void> togglePlayPause() async {
    toggleCalls++;
  }

  @override
  Future<void> playNext() async {}

  @override
  Future<void> playPrevious() async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  String get title => '测试标题';

  @override
  String get artist => '测试作者';

  @override
  Future<void> setVolume(double volume) async {
    _volume = volume;
    notifyListeners();
  }

  @override
  Future<void> setSpeed(double speed) async {
    _speed = speed;
    notifyListeners();
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget _wrap(AudioProvider provider) {
    return MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(size: Size(360, 640)),
        child: ChangeNotifierProvider<AudioProvider>.value(
          value: provider,
          child: const Scaffold(body: ControlsPanel()),
        ),
      ),
    );
  }

  testWidgets('tap retry calls clearPlaybackError and togglePlayPause', (tester) async {
    final provider = FakeAudioProvider();
    provider.setErrorState(hasError: true, message: '播放失败');

    await tester.pumpWidget(_wrap(provider));
    await tester.tap(find.text('点击重试'));
    await tester.pump();

    expect(provider.clearCalls, 1);
    expect(provider.toggleCalls, 1);
  });
}
