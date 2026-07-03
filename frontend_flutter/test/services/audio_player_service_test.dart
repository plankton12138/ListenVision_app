import 'package:flutter_test/flutter_test.dart';
import 'package:listenvision/services/audio_player_service.dart';

void main() {
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