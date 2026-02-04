import 'package:flutter_test/flutter_test.dart';
import 'package:demo/services/metadata_service.dart';

void main() {
  group('MetadataService', () {
    late MetadataService service;

    setUp(() {
      service = MetadataService();
    });

    tearDown(() {
      service.dispose();
    });

    test('should create service with default values', () {
      expect(service.cacheSize, 0);
    });

    test('should extract metadata from path', () {
      const filePath = 'C:/Music/Artist - Title.mp3';
      final result = service.extractMetadataFromPath(filePath);

      expect(result.title, 'Title');
      expect(result.artist, 'Artist');
      expect(result.album, '');
      expect(result.cover, null);
    });

    test('should handle Chinese filenames', () {
      const filePath = 'C:/Music/艺术家 - 标题.mp3';
      final result = service.extractMetadataFromPath(filePath);

      expect(result.title, '标题');
      expect(result.artist, '艺术家');
    });

    test('should handle filename without separator', () {
      const filePath = 'C:/Music/SongTitle.mp3';
      final result = service.extractMetadataFromPath(filePath);

      expect(result.title, 'SongTitle');
      expect(result.artist, '未知艺术家');
    });

    test('should get file extension', () {
      expect(service.getFileExtension('test.mp3'), 'mp3');
      expect(service.getFileExtension('test.MP3'), 'mp3');
      expect(service.getFileExtension('test.flac'), 'flac');
      expect(service.getFileExtension('noextension'), '');
      expect(service.getFileExtension('multiple.dots.name.wav'), 'wav');
    });

    test('should check supported audio formats', () {
      expect(service.isSupportedAudioFormat('test.mp3'), true);
      expect(service.isSupportedAudioFormat('test.flac'), true);
      expect(service.isSupportedAudioFormat('test.wav'), true);
      expect(service.isSupportedAudioFormat('test.txt'), false);
      expect(service.isSupportedAudioFormat('test.doc'), false);
    });

    test('should format duration correctly', () {
      expect(service.formatDuration(0), '00:00');
      expect(service.formatDuration(5), '00:05');
      expect(service.formatDuration(65), '01:05');
      expect(service.formatDuration(3665), '61:05');
    });

    test('should clear cache', () {
      // 缓存初始为空
      expect(service.cacheSize, 0);

      // 清除缓存不会抛出异常
      expect(() => service.clearCache(), returnsNormally);
      expect(service.cacheSize, 0);
    });

    test('should dispose without errors', () {
      expect(() => service.dispose(), returnsNormally);
    });

    test('should handle multiple dispose calls', () {
      service.dispose();
      expect(() => service.dispose(), returnsNormally);
    });

    test('should create MetadataResult with default values', () {
      const result = MetadataResult();

      expect(result.title, '');
      expect(result.artist, '');
      expect(result.album, '');
      expect(result.cover, null);
      expect(result.duration, null);
      expect(result.isEmpty, true);
    });

    test('should create MetadataResult with values', () {
      const result = MetadataResult(
        title: 'Test Title',
        artist: 'Test Artist',
        album: 'Test Album',
        duration: 180,
      );

      expect(result.title, 'Test Title');
      expect(result.artist, 'Test Artist');
      expect(result.album, 'Test Album');
      expect(result.duration, 180);
      expect(result.isEmpty, false);
    });

    test('should convert MetadataResult to Map', () {
      const result = MetadataResult(
        title: 'Test Title',
        artist: 'Test Artist',
      );

      final map = result.toMap();

      expect(map['title'], 'Test Title');
      expect(map['artist'], 'Test Artist');
      expect(map['album'], '');
      expect(map['cover'], null);
    });

    test('should generate correct toString', () {
      const result = MetadataResult(
        title: 'Test Title',
        artist: 'Test Artist',
        cover: null,
      );

      final str = result.toString();
      expect(str, contains('Test Title'));
      expect(str, contains('Test Artist'));
      expect(str, contains('hasCover: false'));
    });
  });
}
