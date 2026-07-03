import 'package:flutter_test/flutter_test.dart';
import 'package:listenvision/services/download_service.dart';

void main() {
  group('DownloadStatus', () {
    test('should have all required values', () {
      expect(DownloadStatus.pending, isNotNull);
      expect(DownloadStatus.downloading, isNotNull);
      expect(DownloadStatus.paused, isNotNull);
      expect(DownloadStatus.completed, isNotNull);
      expect(DownloadStatus.failed, isNotNull);
    });
  });

  group('DownloadProgress', () {
    test('should create with default values', () {
      final progress = DownloadProgress(
        percent: 50,
        stage: 'downloading',
        message: 'Halfway there',
      );

      expect(progress.percent, 50);
      expect(progress.stage, 'downloading');
      expect(progress.message, 'Halfway there');
    });

    test('should correctly determine completion status', () {
      final inProgress = DownloadProgress(
        percent: 50,
        stage: 'downloading',
        message: '',
      );
      expect(inProgress.isComplete, false);

      final completed = DownloadProgress(
        percent: 100,
        stage: 'complete',
        message: '',
      );
      expect(completed.isComplete, true);
    });

    test('should correctly determine failure status', () {
      final normal = DownloadProgress(
        percent: 50,
        stage: 'downloading',
        message: '',
      );
      expect(normal.isFailed, false);

      final failed = DownloadProgress(
        percent: 0,
        stage: 'error',
        message: 'Network error',
      );
      expect(failed.isFailed, true);
    });

    test('should correctly determine downloading status', () {
      final fetching = DownloadProgress(
        percent: 10,
        stage: 'fetching',
        message: '',
      );
      expect(fetching.isDownloading, true);

      final converting = DownloadProgress(
        percent: 50,
        stage: 'converting',
        message: '',
      );
      expect(converting.isDownloading, true);

      final transferring = DownloadProgress(
        percent: 95,
        stage: 'transferring',
        message: '',
      );
      expect(transferring.isDownloading, true);

      final completed = DownloadProgress(
        percent: 100,
        stage: 'complete',
        message: '',
      );
      expect(completed.isDownloading, false);
    });

    test('should format toString correctly', () {
      final progress = DownloadProgress(
        percent: 75,
        stage: 'converting',
        message: 'Processing audio',
      );

      final str = progress.toString();
      expect(str, contains('75%'));
      expect(str, contains('converting'));
      expect(str, contains('Processing audio'));
    });
  });

  group('DownloadResult', () {
    test('should create success result', () {
      final result = DownloadResult.success('/path/to/file.mp3');

      expect(result.success, true);
      expect(result.filePath, '/path/to/file.mp3');
      expect(result.error, null);
    });

    test('should create failure result', () {
      final result = DownloadResult.failure('Network error');

      expect(result.success, false);
      expect(result.filePath, null);
      expect(result.error, 'Network error');
    });

    test('should format toString for success', () {
      final result = DownloadResult.success('/path/to/file.mp3');
      expect(result.toString(), contains('下载成功'));
      expect(result.toString(), contains('/path/to/file.mp3'));
    });

    test('should format toString for failure', () {
      final result = DownloadResult.failure('Network error');
      expect(result.toString(), contains('下载失败'));
      expect(result.toString(), contains('Network error'));
    });
  });

  group('DownloadService', () {
    late DownloadService service;

    setUp(() {
      service = DownloadService();
    });

    tearDown(() {
      service.dispose();
    });

    test('should create service with default values', () {
      expect(service, isNotNull);
    });

    test('should sanitize filename when generating', () {
      expect(
        DownloadService.generateFileName('Test/Song:Name'),
        'Test_Song_Name.m4a',
      );
      expect(
        DownloadService.generateFileName('Test<>Song|Name?'),
        'Test__Song_Name_.m4a',
      );
    });

    test('should add extension to filename if missing', () {
      expect(
        DownloadService.generateFileName('TestSong'),
        'TestSong.m4a',
      );
      expect(
        DownloadService.generateFileName('TestSong', format: '.mp3'),
        'TestSong.mp3',
      );
    });

    test('should build save path correctly', () {
      final path = DownloadService.buildSavePath('/Users/music', 'song.mp3');
      expect(path, contains('/Users/music'));
      expect(path, contains('song.mp3'));
    });

    test('should cancel current download without errors', () {
      expect(() => service.cancelCurrent(), returnsNormally);
    });

    test('should dispose without errors', () {
      expect(() => service.dispose(), returnsNormally);
    });

    test('should handle multiple dispose calls', () {
      service.dispose();
      expect(() => service.dispose(), returnsNormally);
    });
  });

  group('CancellationToken', () {
    test('should start in non-cancelled state', () {
      final token = CancellationToken();
      expect(token.isCancelled, false);
      expect(token.cancelToken, isNotNull);
    });

    test('should cancel when cancel is called', () {
      final token = CancellationToken();
      token.cancel();
      expect(token.isCancelled, true);
    });

    test('should handle multiple cancel calls', () {
      final token = CancellationToken();
      token.cancel();
      expect(() => token.cancel(), returnsNormally);
      expect(token.isCancelled, true);
    });
  });
}
