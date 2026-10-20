import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:listenvision/services/audio_player_service.dart';

class MockMediaPlayer extends Mock implements Player {}

class EmptyPlayerStreams extends Mock implements PlayerStream {
  @override
  Stream<Duration> get position => const Stream.empty();
  @override
  Stream<Duration> get duration => const Stream.empty();
  @override
  Stream<bool> get completed => const Stream.empty();
}

void main() {
  setUpAll(() => registerFallbackValue(Media('https://example.com/test.m4a')));
  group('准备音源', () {
    late MockMediaPlayer player;
    late AudioPlayerService service;
    setUp(() {
      player = MockMediaPlayer();
      when(() => player.stream).thenReturn(EmptyPlayerStreams());
      when(() => player.open(any(), play: false)).thenAnswer((_) async {});
      when(() => player.dispose()).thenAnswer((_) async {});
      service = AudioPlayerService(player: player);
    });
    tearDown(() => service.dispose());
    test('准备本地音源明确禁用自动播放', () async {
      await service.setSource('/music/test.m4a');
      verify(() => player.open(any(), play: false)).called(1);
    });
    test('准备在线音源禁用自动播放并保留请求头', () async {
      await service.setUrlSource(
        'https://example.com/test.m4a',
        httpHeaders: {'Referer': 'https://www.bilibili.com/'},
      );
      final media =
          verify(() => player.open(captureAny(), play: false)).captured.single
              as Media;
      expect(media.httpHeaders?['Referer'], 'https://www.bilibili.com/');
    });
  });

  group('AudioPlayerService 错误分类测试', () {
    test('classifyError 应正确识别平台错误', () {
      expect(
        classifyError(
          'PlatformException(WindowsAudioError, Failed to set source)',
        ),
        AudioPlayerErrorType.platformError,
      );
      expect(
        classifyError(Exception('windowsaudioerror: something went wrong')),
        AudioPlayerErrorType.platformError,
      );
      expect(
        classifyError('media_kit player error'),
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
      expect(
        classifyError('HTTP 403 Forbidden'),
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
      expect(
        classifyError('Failed to open media'),
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
