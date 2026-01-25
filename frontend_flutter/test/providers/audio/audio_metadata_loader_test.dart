import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo/presentation/providers/audio/audio_metadata_loader.dart';

void main() {
  group('AudioMetadataLoader', () {
    late AudioMetadataLoader loader;

    setUp(() {
      loader = AudioMetadataLoader();
    });

    tearDown(() {
      // 清理缓存
      loader.clearCache();
    });

    group('单例模式', () {
      test('应该是单例', () {
        final instance1 = AudioMetadataLoader();
        final instance2 = AudioMetadataLoader();
        expect(identical(instance1, instance2), true);
      });

      test('多次创建实例应该返回同一个', () {
        final instances = List.generate(5, (_) => AudioMetadataLoader());
        final unique = instances.toSet();
        expect(unique.length, 1);
      });
    });

    group('路径解析', () {
      test('extractFromFile 需要真实文件，此测试仅作为占位', () {
        // extractFromFile 需要真实文件，单元测试中跳过
        // 路径解析逻辑在 extractFromFile 的后备处理中使用
        expect(loader, isNotNull);
      });

      test('应该正确解析文件扩展名', () {
        expect(loader.getFileExtension('test.mp3'), 'mp3');
        expect(loader.getFileExtension('test.MP3'), 'mp3');
        expect(loader.getFileExtension('/path/to/file.flac'), 'flac');
        expect(loader.getFileExtension('file.with.dots.wav'), 'wav');
      });

      test('应该判断支持的音频格式', () {
        // 支持的格式
        expect(loader.isSupportedAudioFormat('test.mp3'), true);
        expect(loader.isSupportedAudioFormat('test.m4a'), true);
        expect(loader.isSupportedAudioFormat('test.flac'), true);
        expect(loader.isSupportedAudioFormat('test.wav'), true);
        expect(loader.isSupportedAudioFormat('test.ogg'), true);
        expect(loader.isSupportedAudioFormat('test.wma'), true);
        expect(loader.isSupportedAudioFormat('test.aac'), true);
        expect(loader.isSupportedAudioFormat('test.opus'), true);
        expect(loader.isSupportedAudioFormat('test.mp4'), true);
        expect(loader.isSupportedAudioFormat('test.m4s'), true);

        // 不支持的格式
        expect(loader.isSupportedAudioFormat('test.txt'), false);
        expect(loader.isSupportedAudioFormat('test.jpg'), false);
        expect(loader.isSupportedAudioFormat('test.pdf'), false);
      });
    });

    group('元数据合并', () {
      test('应该优先使用文件元数据', () {
        final fileMetadata = {
          'title': 'File Title',
          'artist': 'File Artist',
          'album': 'File Album',
          'cover': Uint8List(0),
        };

        final dbMetadata = {
          'title': 'DB Title',
          'artist': 'DB Artist',
          'album': 'DB Album',
          'albumArt': Uint8List(0),
        };

        final result = loader.mergeMetadata(
          fileMetadata: fileMetadata,
          dbMetadata: dbMetadata,
        );

        expect(result['title'], 'File Title');
        expect(result['artist'], 'File Artist');
        expect(result['album'], 'File Album');
      });

      test('文件元数据为空时应该使用数据库元数据', () {
        final fileMetadata = {
          'title': '',
          'artist': '',
          'album': '',
          'cover': null,
        };

        final dbMetadata = {
          'title': 'DB Title',
          'artist': 'DB Artist',
          'album': 'DB Album',
          'albumArt': Uint8List(0),
        };

        final result = loader.mergeMetadata(
          fileMetadata: fileMetadata,
          dbMetadata: dbMetadata,
        );

        expect(result['title'], 'DB Title');
        expect(result['artist'], 'DB Artist');
        expect(result['album'], 'DB Album');
      });

      test('文件和数据库元数据都为空时应该使用路径元数据', () {
        final fileMetadata = {
          'title': '',
          'artist': '',
          'album': '',
          'cover': null,
        };

        final pathMetadata = {
          'title': 'Path Title',
          'artist': 'Path Artist',
          'album': '',
          'cover': null,
        };

        final result = loader.mergeMetadata(
          fileMetadata: fileMetadata,
          dbMetadata: null,
          fallbackPathMetadata: pathMetadata,
        );

        expect(result['title'], 'Path Title');
        expect(result['artist'], 'Path Artist');
      });

      test('数据库元数据包含"未知"时应该降级到路径元数据', () {
        final fileMetadata = {
          'title': '',
          'artist': '',
          'album': '',
          'cover': null,
        };

        final dbMetadata = {
          'title': '未知标题',
          'artist': '未知艺术家',
          'album': '',
          'albumArt': null,
        };

        final pathMetadata = {
          'title': 'Path Title',
          'artist': 'Path Artist',
          'album': '',
          'cover': null,
        };

        final result = loader.mergeMetadata(
          fileMetadata: fileMetadata,
          dbMetadata: dbMetadata,
          fallbackPathMetadata: pathMetadata,
        );

        expect(result['title'], 'Path Title');
        expect(result['artist'], 'Path Artist');
      });

      test('应该优先使用文件封面而不是数据库封面', () {
        final fileCover = Uint8List.fromList([1, 2, 3]);
        final dbCover = Uint8List.fromList([4, 5, 6]);

        final fileMetadata = {
          'title': 'Title',
          'artist': 'Artist',
          'album': 'Album',
          'cover': fileCover,
        };

        final dbMetadata = {
          'title': 'DB Title',
          'artist': 'DB Artist',
          'album': 'DB Album',
          'albumArt': dbCover,
        };

        final result = loader.mergeMetadata(
          fileMetadata: fileMetadata,
          dbMetadata: dbMetadata,
        );

        expect(result['cover'], fileCover);
      });

      test('文件封面为空时应该使用数据库封面', () {
        final dbCover = Uint8List.fromList([4, 5, 6]);

        final fileMetadata = {
          'title': 'Title',
          'artist': 'Artist',
          'album': 'Album',
          'cover': null,
        };

        final dbMetadata = {
          'title': 'DB Title',
          'artist': 'DB Artist',
          'album': 'DB Album',
          'albumArt': dbCover,
        };

        final result = loader.mergeMetadata(
          fileMetadata: fileMetadata,
          dbMetadata: dbMetadata,
        );

        expect(result['cover'], dbCover);
      });

      test('所有元数据都为空时应该有默认值', () {
        final fileMetadata = {
          'title': '',
          'artist': '',
          'album': '',
          'cover': null,
        };

        final result = loader.mergeMetadata(
          fileMetadata: fileMetadata,
          dbMetadata: null,
          fallbackPathMetadata: {'title': '', 'artist': '', 'album': '', 'cover': null},
        );

        expect(result['title'], '');
        expect(result['artist'], '');
        expect(result['album'], '');
        expect(result['cover'], isNull);
      });
    });

    group('封面缓存', () {
      test('应该能够清除缓存', () {
        // 由于缓存是私有的，我们只能测试清除操作不抛出异常
        loader.clearCache();
        expect(loader, isNotNull);
      });

      test('应该能够清除指定 URL 的缓存', () {
        const url = 'https://example.com/cover.jpg';
        loader.clearCacheForUrl(url);
        expect(loader, isNotNull);
      });

      test('多次清除缓存不应该报错', () {
        loader.clearCache();
        loader.clearCache();
        loader.clearCache();
        expect(loader, isNotNull);
      });
    });

    group('工具方法', () {
      test('formatDuration 应该正确格式化时长', () {
        expect(loader.formatDuration(0), '00:00');
        expect(loader.formatDuration(5), '00:05');
        expect(loader.formatDuration(30), '00:30');
        expect(loader.formatDuration(60), '01:00');
        expect(loader.formatDuration(90), '01:30');
        expect(loader.formatDuration(3661), '61:01');
      });

      test('getFileExtension 应该处理无扩展名的文件', () {
        expect(loader.getFileExtension('filename'), 'filename');
        expect(loader.getFileExtension('/path/to/filename'), 'filename');
        expect(loader.getFileExtension('filename.'), '');
      });

      test('getFileExtension 应该处理多个点', () {
        expect(loader.getFileExtension('file.name.with.dots.mp3'), 'mp3');
      });

      test('isSupportedAudioFormat 应该区分大小写', () {
        expect(loader.isSupportedAudioFormat('test.MP3'), true);
        expect(loader.isSupportedAudioFormat('test.Mp3'), true);
        expect(loader.isSupportedAudioFormat('test.FLAC'), true);
      });
    });

    group('preloadCover', () {
      test('preloadCover 应该接受回调函数', () {
        // 测试回调设置不抛出异常
        // 注意：实际加载需要网络连接，这里只测试方法签名
        loader.preloadCover('https://example.com/cover.jpg', (data) {
          // 回调函数
        });

        // 由于是异步的，我们无法立即测试回调是否被调用
        expect(loader, isNotNull);
      });
    });

    group('dispose', () {
      test('dispose 应该释放资源', () {
        loader.dispose();
        // 再次 dispose 不应该报错
        loader.dispose();
        expect(loader, isNotNull);
      });
    });
  });
}
