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

  group('AudioPlayerService 错误分类测试', () {
    test('classifyError 应正确识别平台错误', () {
      expect(
        classifyError('PlatformException(WindowsAudioError, Failed to set source)'),
        AudioPlayerErrorType.platformError,
      );
      expect(
        classifyError(Exception('windowsaudioerror: something went wrong')),
        AudioPlayerErrorType.platformError,
      );
    });

    test('classifyError 应正确识别网络错误', () {
      expect(
        classifyError('SocketException: Connection failed'),
        AudioPlayerErrorType.networkError,
      );
      expect(
        classifyError('NetworkException: timeout'),
        AudioPlayerErrorType.networkError,
      );
      expect(
        classifyError('Connection refused'),
        AudioPlayerErrorType.networkError,
      );
    });

    test('classifyError 应正确识别文件不存在错误', () {
      expect(
        classifyError('FileSystemException: File not found'),
        AudioPlayerErrorType.fileNotFound,
      );
      expect(
        classifyError('ENOENT: no such file or directory'),
        AudioPlayerErrorType.fileNotFound,
      );
      expect(
        classifyError('Could not find file at path'),
        AudioPlayerErrorType.fileNotFound,
      );
    });

    test('classifyError 应正确识别格式不支持错误', () {
      expect(
        classifyError('FormatException: unsupported codec'),
        AudioPlayerErrorType.formatNotSupported,
      );
      expect(
        classifyError('Invalid audio format'),
        AudioPlayerErrorType.formatNotSupported,
      );
    });

    test('classifyError 应正确识别源加载失败错误', () {
      expect(
        classifyError('Failed to load source'),
        AudioPlayerErrorType.sourceLoadFailed,
      );
      expect(
        classifyError('Source load failed'),
        AudioPlayerErrorType.sourceLoadFailed,
      );
    });

    test('classifyError 对未知错误应返回 unknown', () {
      expect(
        classifyError('Some random error message'),
        AudioPlayerErrorType.unknown,
      );
      expect(
        classifyError(Exception('Unexpected issue')),
        AudioPlayerErrorType.unknown,
      );
    });

    test('getUserFriendlyMessage 应返回可读消息', () {
      expect(
        getUserFriendlyMessage(AudioPlayerErrorType.networkError),
        contains('网络'),
      );
      expect(
        getUserFriendlyMessage(AudioPlayerErrorType.fileNotFound),
        contains('文件'),
      );
      expect(
        getUserFriendlyMessage(AudioPlayerErrorType.platformError),
        contains('播放器'),
      );
      expect(
        getUserFriendlyMessage(AudioPlayerErrorType.formatNotSupported),
        contains('格式'),
      );
      expect(
        getUserFriendlyMessage(AudioPlayerErrorType.sourceLoadFailed),
        contains('加载'),
      );
      expect(
        getUserFriendlyMessage(AudioPlayerErrorType.unknown),
        contains('失败'),
      );
    });
  });
}
