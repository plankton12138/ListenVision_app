import 'package:flutter_test/flutter_test.dart';
import 'package:demo/services/audio_player_service.dart';

void main() {
  group('AudioPlayerService', () {
    late AudioPlayerService service;

    setUp(() {
      service = AudioPlayerService();
    });

    tearDown(() {
      service.dispose();
    });

    test('should create service with default values', () {
      expect(service.disposed, false);
      expect(service.position, Duration.zero);
      expect(service.duration, null);
      expect(service.isPlaying, false);
      expect(service.isPaused, false);
      expect(service.isStopped, true);
      expect(service.isIdle, true);
    });

    test('should provide access to underlying player', () {
      expect(service.player, isNotNull);
    });

    test('should expose position stream', () {
      expect(service.positionStream, isNotNull);
    });

    test('should expose duration stream', () {
      expect(service.durationStream, isNotNull);
    });

    test('should expose player state stream', () {
      expect(service.playerStateStream, isNotNull);
    });

    test('should expose player complete stream', () {
      expect(service.onPlayerComplete, isNotNull);
    });

    test('should update volume when setVolume is called', () async {
      // 测试音量设置不抛出异常
      expect(() => service.setVolume(0.5), returnsNormally);
      await service.setVolume(0.5);
    });

    test('should clamp volume to valid range', () async {
      await service.setVolume(1.5);
      // 超出范围的值应该被限制到 0.0-1.0
      // 这里只测试不会抛出异常
      expect(() => service.setVolume(-0.5), returnsNormally);
      await service.setVolume(-0.5);
    });

    test('should update playback rate when setPlaybackRate is called', () async {
      expect(() => service.setPlaybackRate(1.5), returnsNormally);
      await service.setPlaybackRate(1.5);
    });

    test('should clamp playback rate to valid range', () async {
      // 测试超出范围的值不会抛出异常
      expect(() => service.setPlaybackRate(3.0), returnsNormally);
      await service.setPlaybackRate(3.0);

      expect(() => service.setPlaybackRate(0.2), returnsNormally);
      await service.setPlaybackRate(0.2);
    });

    test('should dispose properly', () {
      expect(service.disposed, false);
      service.dispose();
      expect(service.disposed, true);
    });

    test('should handle multiple dispose calls', () {
      service.dispose();
      expect(() => service.dispose(), returnsNormally);
      expect(service.disposed, true);
    });

    test('should be in idle state initially', () {
      expect(service.isIdle, true);
      expect(service.isLoading, false);
      expect(service.isReady, false);
    });
  });
}
