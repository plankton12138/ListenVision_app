import 'package:flutter_test/flutter_test.dart';
import 'package:listenvision/services/audio_player_service.dart';

void main() {
  group('AudioPlayerService', () {
    testWidgets('should create service with default values', (tester) async {
      // Arrange & Act: 在 widget 测试环境中创建服务
      final service = AudioPlayerService();

      // Assert
      expect(service.disposed, false);
      expect(service.position, Duration.zero);
      expect(service.duration, null);
      expect(service.isPlaying, false);
      expect(service.isPaused, false);
      expect(service.isStopped, true);
      expect(service.isIdle, true);

      // Cleanup
      service.dispose();
    });

    testWidgets('should provide access to underlying player', (tester) async {
      final service = AudioPlayerService();
      expect(service.player, isNotNull);
      service.dispose();
    });

    testWidgets('should expose position stream', (tester) async {
      final service = AudioPlayerService();
      expect(service.positionStream, isNotNull);
      service.dispose();
    });

    testWidgets('should expose duration stream', (tester) async {
      final service = AudioPlayerService();
      expect(service.durationStream, isNotNull);
      service.dispose();
    });

    testWidgets('should expose player state stream', (tester) async {
      final service = AudioPlayerService();
      expect(service.playerStateStream, isNotNull);
      service.dispose();
    });

    testWidgets('should expose player complete stream', (tester) async {
      final service = AudioPlayerService();
      expect(service.onPlayerComplete, isNotNull);
      service.dispose();
    });

    // Skip: setVolume 和 setPlaybackRate 需要原生插件实现，在单元测试环境中无法完成
    // 这些方法应该在集成测试中测试
    // testWidgets('should update volume when setVolume is called', (tester) async { ... });
    // testWidgets('should clamp volume to valid range', (tester) async { ... });
    // testWidgets('should update playback rate when setPlaybackRate is called', (tester) async { ... });
    // testWidgets('should clamp playback rate to valid range', (tester) async { ... });

    testWidgets('should dispose properly', (tester) async {
      final service = AudioPlayerService();
      expect(service.disposed, false);
      service.dispose();
      expect(service.disposed, true);
    });

    testWidgets('should handle multiple dispose calls', (tester) async {
      final service = AudioPlayerService();
      service.dispose();
      expect(() => service.dispose(), returnsNormally);
      expect(service.disposed, true);
    });

    testWidgets('should be in idle state initially', (tester) async {
      final service = AudioPlayerService();
      expect(service.isIdle, true);
      expect(service.isLoading, false);
      expect(service.isReady, false);
      service.dispose();
    });
  });
}
