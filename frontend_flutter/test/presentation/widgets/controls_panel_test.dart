import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:demo/presentation/widgets/controls_panel.dart';
import 'package:demo/presentation/providers/audio/audio_provider.dart';

class FakeAudioProvider extends ChangeNotifier implements AudioProvider {
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isLoading = false;
  bool _isBuffering = false;
  bool _isCompleted = false;
  bool _isIdle = true;
  bool _isPlaying = false;
  String _playerStatusMessage = '';
  bool _hasPlaybackError = false;
  double _volume = 1.0;
  double _speed = 1.0;

  @override
  Duration get duration => _duration;

  @override
  Duration get position => _position;

  @override
  bool get isLoading => _isLoading;

  @override
  bool get isBuffering => _isBuffering;

  @override
  bool get isCompleted => _isCompleted;

  @override
  bool get isIdle => _isIdle;

  @override
  bool get isPlaying => _isPlaying;

  @override
  String get playerStatusMessage => _playerStatusMessage;

  @override
  bool get hasPlaybackError => _hasPlaybackError;

  @override
  bool get isSeekable => true;

  @override
  bool get isReady => true;

  @override
  double get volume => _volume;

  @override
  double get speed => _speed;

  void setState({
    Duration? duration,
    Duration? position,
    bool? isLoading,
    bool? isBuffering,
    bool? isCompleted,
    bool? isIdle,
    bool? isPlaying,
    String? statusMessage,
    bool? hasError,
    double? volume,
    double? speed,
  }) {
    _duration = duration ?? _duration;
    _position = position ?? _position;
    _isLoading = isLoading ?? _isLoading;
    _isBuffering = isBuffering ?? _isBuffering;
    _isCompleted = isCompleted ?? _isCompleted;
    _isIdle = isIdle ?? _isIdle;
    _isPlaying = isPlaying ?? _isPlaying;
    _playerStatusMessage = statusMessage ?? _playerStatusMessage;
    _hasPlaybackError = hasError ?? _hasPlaybackError;
    _volume = volume ?? _volume;
    _speed = speed ?? _speed;
    notifyListeners();
  }

  @override
  void clearPlaybackError() {
    _hasPlaybackError = false;
    _playerStatusMessage = '';
  }

  @override
  Future<void> togglePlayPause() async {
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  @override
  Future<void> playNext() async {}

  @override
  Future<void> playPrevious() async {}

  @override
  Future<void> seek(Duration position) async {
    _position = position;
  }

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

  testWidgets('shows error message and retry UI when playback error', (tester) async {
    final provider = FakeAudioProvider();
    provider.setState(hasError: true, statusMessage: '播放失败', isIdle: false);

    await tester.pumpWidget(_wrap(provider));

    expect(find.text('播放失败'), findsOneWidget);
    expect(find.text('点击重试'), findsOneWidget);
  });

  testWidgets('shows time display when duration and position are valid', (tester) async {
    final provider = FakeAudioProvider();
    provider.setState(
      duration: const Duration(seconds: 120),
      position: const Duration(seconds: 30),
      isLoading: false,
      isIdle: false,
      isPlaying: true,
    );

    await tester.pumpWidget(_wrap(provider));

    expect(find.text('0:00:30 / 0:02:00'), findsOneWidget);
  });

  testWidgets('shows loading message when status message is present', (tester) async {
    final provider = FakeAudioProvider();
    provider.setState(statusMessage: '正在加载...', isIdle: false);

    await tester.pumpWidget(_wrap(provider));
    expect(find.text('正在加载...'), findsOneWidget);
  });
}
