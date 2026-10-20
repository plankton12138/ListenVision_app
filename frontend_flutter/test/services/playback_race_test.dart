import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:listenvision/models/audio.dart';
import 'package:listenvision/models/online_playable.dart';
import 'package:listenvision/presentation/viewmodels/library/history_viewmodel.dart';
import 'package:listenvision/presentation/viewmodels/player/playback_viewmodel.dart';
import 'package:listenvision/services/audio_player_service.dart';
import 'package:listenvision/services/bilibili_api_service.dart';
import 'package:listenvision/services/background_audio_service.dart';

class TestPlaybackState extends PlaybackViewModel {
  @override
  PlaybackState build() => const PlaybackState();
}

class SystemAudioBridge extends BackgroundAudioService {
  SystemAudioBridge() : super(enabled: false);
  final events = StreamController<Map<String, dynamic>>.broadcast();
  @override
  Stream<Map<String, dynamic>> get commands => events.stream;
  @override
  void dispose() {
    events.close();
    super.dispose();
  }
}

class ControlledAudioService extends Mock implements AudioPlayerService {
  final opened = <String>[];
  final played = <String>[];
  final gates = <String, Completer<void>>{};
  final failures = <String>{};
  String? current;
  int stops = 0;
  @override
  Stream<Duration> get positionStream => const Stream.empty();
  @override
  Stream<Duration?> get durationStream => const Stream.empty();
  @override
  Stream<AudioPlaybackState> get playbackStateStream => const Stream.empty();
  @override
  Stream<void> get onPlayerComplete => const Stream.empty();
  @override
  Duration get position => Duration.zero;
  @override
  Duration? get duration => const Duration(minutes: 3);
  @override
  Future<void> setVolume(double value) async {}
  @override
  Future<void> setPlaybackRate(double value) async {}
  @override
  Future<void> setUrlSource(
    String url, {
    Map<String, String>? httpHeaders,
  }) async {
    opened.add(url);
    await gates[url]?.future;
    if (failures.contains(url)) throw StateError('source load failed');
    current = url;
  }

  @override
  Future<void> play() async {
    played.add(current!);
  }

  @override
  Future<void> pause() async {}
  @override
  Future<void> seek(Duration position) async {}
  @override
  Future<void> stop() async {
    current = null;
    stops++;
  }
}

class ControlledStreamApi extends BilibiliApiService {
  final requests = <String, Completer<AudioStreamsData>>{};
  final tokens = <CancelToken>[];
  @override
  Future<AudioStreamsData> getAudioStreams(
    String bvid, {
    int? cid,
    CancelToken? cancelToken,
  }) {
    tokens.add(cancelToken!);
    return (requests[bvid] = Completer<AudioStreamsData>()).future;
  }

  void complete(String bvid) => requests[bvid]!.complete(
    AudioStreamsData(
      bvid: bvid,
      cid: 1,
      title: bvid,
      streams: [
        AudioStreamInfo(
          url: 'https://example.com/$bvid',
          qualityId: 1,
          size: 0,
          codecs: '',
        ),
      ],
    ),
  );
}

class RecordingHistory extends HistoryViewModel {
  final recorded = <String>[];
  @override
  Future<HistoryState> build() async => const HistoryState.loaded(history: []);
  @override
  Future<void> recordPlay({
    String? bvid,
    int? cid,
    String? localPath,
    String? title,
    String? artist,
    String? albumTitle,
    int? duration,
    String? coverUrl,
    String? streamUrl,
    int progress = 0,
    String? sourceType,
    String? sourceId,
  }) async {
    recorded.add(bvid!);
  }
}

void main() {
  late ProviderContainer container;
  late ControlledAudioService audio;
  late ControlledStreamApi api;
  late RecordingHistory history;
  late PlaybackViewModel vm;
  late SystemAudioBridge bridge;
  OnlinePlayable track(String id, {bool resolved = false}) => OnlinePlayable(
    Audio(
      id: id,
      title: id,
      streamUrl: resolved ? 'https://example.com/$id' : null,
    ),
  );
  setUp(() async {
    audio = ControlledAudioService();
    api = ControlledStreamApi();
    history = RecordingHistory();
    bridge = SystemAudioBridge();
    container = ProviderContainer(
      overrides: [
        audioPlayerServiceProvider.overrideWithValue(audio),
        bilibiliApiServiceProvider.overrideWithValue(api),
        historyViewModelProvider.overrideWith(() => history),
        backgroundAudioServiceProvider.overrideWithValue(bridge),
      ],
    );
    await container.read(historyViewModelProvider.future);
    vm = container.read(playbackViewModelProvider.notifier);
    final ready = Completer<void>();
    vm.onInitialized(ready.complete);
    await ready.future;
  });
  tearDown(() {
    container.dispose();
    bridge.dispose();
  });

  test('位置变化不通知控制区域，播放状态变化仍通知', () {
    final isolated = ProviderContainer(
      overrides: [
        playbackViewModelProvider.overrideWith(TestPlaybackState.new),
      ],
    );
    var updates = 0;
    final sub = isolated.listen(playbackControlsProvider, (_, _) => updates++);
    final notifier = isolated.read(playbackViewModelProvider.notifier);
    for (var i = 1; i <= 100; i++) {
      notifier.state = notifier.state.copyWith(
        position: Duration(milliseconds: i * 100),
      );
      isolated.read(playbackControlsProvider);
    }
    expect(updates, 0);
    notifier.state = notifier.state.copyWith(isPlaying: true);
    expect(isolated.read(playbackControlsProvider).isPlaying, isTrue);
    expect(updates, 1);
    sub.close();
    isolated.dispose();
  });

  test('A 解析晚于 B，不得设置 A 音源或记录 A 历史', () async {
    final a = vm.play(track('A'));
    final b = vm.play(track('B'));
    expect(api.tokens.first.isCancelled, isTrue);
    api.complete('B');
    await b;
    api.complete('A');
    await a;
    expect(audio.opened, ['https://example.com/B']);
    expect(audio.played, ['https://example.com/B']);
    expect(history.recorded, ['B']);
    expect(container.read(playbackViewModelProvider).title, 'B');
  });

  test('停止后解析才完成，不得重新开始播放', () async {
    final pending = vm.play(track('A'));
    await vm.stop();
    api.complete('A');
    await pending;
    expect(audio.opened, isEmpty);
    expect(audio.played, isEmpty);
    expect(container.read(playbackViewModelProvider).currentPlayable, isNull);
    expect(container.read(playbackViewModelProvider).isLoading, isFalse);
  });

  test('设源进行中切换歌曲，旧音源不会自动播放且新设源串行执行', () async {
    final gate = audio.gates['https://example.com/A'] = Completer<void>();
    final a = vm.play(track('A', resolved: true));
    await Future<void>.delayed(Duration.zero);
    expect(audio.opened, ['https://example.com/A']);
    final b = vm.play(track('B', resolved: true));
    await Future<void>.delayed(Duration.zero);
    expect(audio.opened, ['https://example.com/A']);
    gate.complete();
    await Future.wait([a, b]);
    expect(audio.played, ['https://example.com/B']);
    expect(audio.current, 'https://example.com/B');
    expect(history.recorded, ['B']);
  });

  test('准备音源不会自动播放或写播放历史', () async {
    await vm.prepareSource(track('A', resolved: true), startPosition: 30);
    expect(audio.opened, ['https://example.com/A']);
    expect(audio.played, isEmpty);
    expect(history.recorded, isEmpty);
    expect(container.read(playbackViewModelProvider).isPaused, isTrue);
  });

  test('临时音频中断后恢复，但用户主动暂停取消自动恢复意图', () async {
    await vm.play(track('A', resolved: true));
    bridge.events.add({'action': 'pauseForInterruption'});
    await Future<void>.delayed(Duration.zero);
    expect(container.read(playbackViewModelProvider).isPaused, isTrue);
    bridge.events.add({'action': 'resumeAfterInterruption'});
    await Future<void>.delayed(Duration.zero);
    expect(audio.played.length, 2);
    bridge.events.add({'action': 'pauseForInterruption'});
    await Future<void>.delayed(Duration.zero);
    await vm.pause();
    bridge.events.add({'action': 'resumeAfterInterruption'});
    await Future<void>.delayed(Duration.zero);
    expect(audio.played.length, 2);
    expect(container.read(playbackViewModelProvider).isPlaying, isFalse);
  });

  test('设源尚未完成时停止，完成后也不允许自动播放', () async {
    final gate = audio.gates['https://example.com/A'] = Completer<void>();
    final pending = vm.play(track('A', resolved: true));
    await Future<void>.delayed(Duration.zero);
    final stopping = vm.stop();
    gate.complete();
    await Future.wait([pending, stopping]);
    expect(audio.played, isEmpty);
    expect(audio.current, isNull);
    expect(history.recorded, isEmpty);
    expect(container.read(playbackViewModelProvider).currentPlayable, isNull);
  });

  test('一次设源失败不会阻断后续引擎命令', () async {
    audio.failures.add('https://example.com/A');
    await vm.play(track('A', resolved: true));
    expect(container.read(playbackViewModelProvider).errorMessage, isNotNull);
    await vm.play(track('B', resolved: true));
    expect(audio.played, ['https://example.com/B']);
    expect(container.read(playbackViewModelProvider).errorMessage, isNull);
  });

  test('当前请求失败退出 loading，随后新请求可以正常播放', () async {
    final a = vm.play(track('A'));
    api.requests['A']!.completeError(Exception('timeout'));
    await a;
    expect(container.read(playbackViewModelProvider).isLoading, isFalse);
    expect(container.read(playbackViewModelProvider).errorMessage, isNotNull);
    await vm.play(track('B', resolved: true));
    expect(audio.played.last, 'https://example.com/B');
    expect(container.read(playbackViewModelProvider).errorMessage, isNull);
  });

  test('销毁后旧请求完成不会触发引擎或历史写入', () async {
    final a = vm.play(track('A'));
    container.dispose();
    api.complete('A');
    await a;
    expect(audio.opened, isEmpty);
    expect(history.recorded, isEmpty);
    // 避免 tearDown 重复销毁该 container。
    container = ProviderContainer();
  });
}
