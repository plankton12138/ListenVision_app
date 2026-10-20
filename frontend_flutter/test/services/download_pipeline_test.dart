import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:listenvision/core/errors/exceptions.dart';
import 'package:listenvision/data/database/app_database.dart';
import 'package:listenvision/data/database/download_task_dao.dart';
import 'package:listenvision/data/database/track_dao.dart';
import 'package:listenvision/data/repositories/download_repository.dart';
import 'package:listenvision/models/download_task.dart';
import 'package:listenvision/services/bilibili_api_service.dart';
import 'package:listenvision/services/bilibili_downloader.dart';
import 'package:listenvision/services/ffmpeg_service.dart';
import 'package:listenvision/services/resumable_download_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class FakeConversionProcess extends Mock implements Process {
  final finished = Completer<int>();
  bool killed = false;
  @override
  Stream<List<int>> get stdout => const Stream.empty();
  @override
  Stream<List<int>> get stderr => const Stream.empty();
  @override
  Future<int> get exitCode => finished.future;
  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    killed = true;
    if (!finished.isCompleted) finished.complete(-1);
    return true;
  }
}

class ControlledDownloader extends BilibiliDownloader {
  ControlledDownloader() : super(BilibiliApiService());
  final started = Completer<void>();
  final finished = Completer<DownloadResult>();
  CancelToken? token;
  void Function(int, String)? progress;
  @override
  Future<DownloadResult> download({
    required String bvid,
    int? cid,
    required String saveDir,
    required String fileName,
    String? albumTitle,
    AudioOutputFormat? format,
    String? tempPath,
    CancelToken? cancelToken,
    bool downloadCover = true,
    void Function(int, String)? onProgress,
  }) {
    token = cancelToken;
    progress = onProgress;
    started.complete();
    // 故意不响应取消，检验 Repository 是否能抵御旧回调及迟到成功结果。
    return finished.future;
  }
}

void main() {
  sqfliteFfiInit();
  late Directory temp;
  setUp(
    () async =>
        temp = await Directory.systemTemp.createTemp('listenvision-pipeline-'),
  );
  tearDown(() async {
    expect(
      temp.absolute.path.startsWith(Directory.systemTemp.absolute.path),
      isTrue,
    );
    await temp.delete(recursive: true);
  });

  group('直连 CDN 续传', () {
    late HttpServer server;
    late ResumableDownloadService transfer;
    late File part;
    late String url;
    setUp(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      url = 'http://127.0.0.1:${server.port}/audio';
      transfer = ResumableDownloadService();
      part = File('${temp.path}/audio.part');
      await part.writeAsString('123');
      await File(
        '${part.path}.json',
      ).writeAsString(jsonEncode({'etag': '"v1"'}));
    });
    tearDown(() async {
      transfer.dispose();
      await server.close(force: true);
    });

    test('匹配的 206 从文件实际长度续传', () async {
      server.listen((request) async {
        expect(request.headers.value('range'), 'bytes=3-');
        expect(request.headers.value('if-range'), '"v1"');
        request.response.statusCode = 206;
        request.response.headers.set('content-range', 'bytes 3-5/6');
        request.response.headers.set('etag', '"v1"');
        request.response.contentLength = 3;
        request.response.write('456');
        await request.response.close();
      });
      expect(
        await transfer.downloadFile(
          url: url,
          savePath: part.path,
          cancelToken: CancelToken(),
        ),
        6,
      );
      expect(await part.readAsString(), '123456');
    });

    test('服务端返回 200 时截断旧文件而非追加', () async {
      server.listen((request) async {
        request.response.contentLength = 6;
        request.response.headers.set('etag', '"v1"');
        request.response.write('abcdef');
        await request.response.close();
      });
      await transfer.downloadFile(
        url: url,
        savePath: part.path,
        cancelToken: CancelToken(),
      );
      expect(await part.readAsString(), 'abcdef');
    });

    test('ETag 改变的 206 不追加，重新请求完整文件', () async {
      var calls = 0;
      server.listen((request) async {
        calls++;
        request.response.headers.set('etag', '"v2"');
        if (calls == 1) {
          request.response.statusCode = 206;
          request.response.headers.set('content-range', 'bytes 3-5/6');
          request.response.contentLength = 3;
          request.response.write('bad');
        } else {
          expect(request.headers.value('range'), isNull);
          request.response.contentLength = 6;
          request.response.write('abcdef');
        }
        await request.response.close();
      });
      await transfer.downloadFile(
        url: url,
        savePath: part.path,
        cancelToken: CancelToken(),
      );
      expect(calls, 2);
      expect(await part.readAsString(), 'abcdef');
    });

    test('未知总大小仍可完成，不计算无效百分比', () async {
      await File('${part.path}.json').delete();
      server.listen((request) async {
        request.response.write('unknown-length');
        await request.response.close();
      });
      final totals = <int>[];
      await transfer.downloadFile(
        url: url,
        savePath: part.path,
        cancelToken: CancelToken(),
        onProgress: (_, total) => totals.add(total),
      );
      expect(await part.readAsString(), 'unknown-length');
      expect(totals, everyElement(0));
    });

    test('传输中取消能中断等待后续数据并保留临时片段', () async {
      await File('${part.path}.json').delete();
      final gotChunk = Completer<void>();
      server.listen((request) async {
        request.response.headers.set('etag', '"v1"');
        request.response.bufferOutput = false;
        request.response.headers.contentType = ContentType.binary;
        request.response.add(utf8.encode('partial'));
        await request.response.flush();
        // 保持响应打开，客户端取消必须能够自行结束下载 Future。
      });
      final token = CancelToken();
      final future = transfer.downloadFile(
        url: url,
        savePath: part.path,
        cancelToken: token,
        onProgress: (_, _) {
          if (!gotChunk.isCompleted) gotChunk.complete();
        },
      );
      final assertion = expectLater(
        future,
        throwsA(anyOf(isA<TaskCanceledException>(), isA<DioException>())),
      );
      await gotChunk.future.timeout(const Duration(seconds: 3));
      token.cancel();
      await assertion.timeout(const Duration(seconds: 3));
      expect(await part.readAsString(), 'partial');
    });
  });

  group('转换进程与文件完整性', () {
    late File input;
    setUp(() async {
      input = File('${temp.path}/audio.m4a');
      await input.writeAsString('source');
    });
    test('残留目标不会直接复用，转换成功后才发布新文件', () async {
      final old = File('${temp.path}/audio.mp3');
      await old.writeAsString('broken-existing-file');
      final converter = FfmpegService(
        supportsConversion: true,
        startProcess: (_, args) async {
          await File(args.last).writeAsString('new-valid-output');
          return FakeConversionProcess()..finished.complete(0);
        },
      );
      final output = await converter.convert(
        inputPath: input.path,
        outputFormat: AudioOutputFormat.mp3,
      );
      expect(output, endsWith('audio (1).mp3'));
      expect(await File(output).readAsString(), 'new-valid-output');
      expect(await old.readAsString(), 'broken-existing-file');
      expect(await input.readAsString(), 'source');
    });
    test('进程失败清理半成品并保留原始音频', () async {
      final converter = FfmpegService(
        supportsConversion: true,
        startProcess: (_, args) async {
          await File(args.last).writeAsString('partial');
          return FakeConversionProcess()..finished.complete(1);
        },
      );
      await expectLater(
        converter.convert(
          inputPath: input.path,
          outputFormat: AudioOutputFormat.mp3,
        ),
        throwsA(isA<FfmpegException>()),
      );
      expect(temp.listSync().length, 1);
      expect(await input.readAsString(), 'source');
    });
    test('启动尚未完成时取消也会终止随后获得的进程', () async {
      final starting = Completer<Process>();
      final process = FakeConversionProcess();
      final converter = FfmpegService(
        supportsConversion: true,
        startProcess: (_, _) => starting.future,
      );
      final token = CancelToken();
      final result = converter.convert(
        inputPath: input.path,
        outputFormat: AudioOutputFormat.mp3,
        cancelToken: token,
      );
      final assertion = expectLater(
        result,
        throwsA(isA<TaskCanceledException>()),
      );
      await Future<void>.delayed(Duration.zero);
      token.cancel();
      starting.complete(process);
      await assertion;
      expect(process.killed, isTrue);
      expect(await input.exists(), isTrue);
    });
    test('超时会终止进程，且不会发布输出', () async {
      final process = FakeConversionProcess();
      final converter = FfmpegService(
        supportsConversion: true,
        timeout: const Duration(milliseconds: 25),
        startProcess: (_, _) async => process,
      );
      await expectLater(
        converter.convert(
          inputPath: input.path,
          outputFormat: AudioOutputFormat.mp3,
        ),
        throwsA(
          isA<FfmpegException>().having(
            (error) => error.message,
            'message',
            contains('超时'),
          ),
        ),
      );
      expect(process.killed, isTrue);
      expect(await File('${temp.path}/audio.mp3').exists(), isFalse);
    });
  });

  group('下载任务提交与取消', () {
    late AppDatabase db;
    late DownloadRepository repo;
    late ControlledDownloader downloader;
    late int taskId;
    setUp(() async {
      db = AppDatabase.forTesting(
        path: '${temp.path}/app.db',
        factory: databaseFactoryFfi,
      );
      downloader = ControlledDownloader();
      repo = DownloadRepository(db: db, downloaderFactory: (_) => downloader);
      taskId = await repo.addDownloadTask(
        bvid: 'BVtest',
        title: 'test',
        savePath: '${temp.path}/requested.m4a',
      );
    });
    tearDown(() async {
      repo.dispose();
      await db.close();
    });
    test('相同任务重复开始共用一次执行，实际结果路径同时写入任务和曲目', () async {
      final run = repo.startDownload(taskId);
      expect(identical(run, repo.startDownload(taskId)), isTrue);
      await downloader.started.future;
      final output = File('${temp.path}/actual.mp3');
      await output.writeAsString('audio');
      downloader.finished.complete(
        DownloadResult(
          success: true,
          filePath: output.path,
          fileSize: 5,
          format: 'mp3',
        ),
      );
      await run;
      final task = (await DownloadTaskDao(db).getById(taskId))!;
      expect(task.status, DownloadStatus.completed);
      expect(task.savePath, output.path);
      final track = (await TrackDao(db).getById(task.trackId!))!;
      expect(track.localPath, output.path);
      expect(track.isDownloaded, isTrue);
    });
    test('暂停后迟到的成功和进度回调不能把任务改回完成', () async {
      final run = repo.startDownload(taskId);
      await downloader.started.future;
      final pausing = repo.pauseDownload(taskId);
      expect(downloader.token!.isCancelled, isTrue);
      downloader.progress?.call(99, 'processing_file');
      final output = File('${temp.path}/late.m4a');
      await output.writeAsString('late');
      downloader.finished.complete(
        DownloadResult(success: true, filePath: output.path, fileSize: 4),
      );
      await Future.wait([run, pausing]);
      final task = (await DownloadTaskDao(db).getById(taskId))!;
      expect(task.status, DownloadStatus.paused);
      expect(task.userPaused, isTrue);
      expect(
        (await TrackDao(db).getById(task.trackId!))!.isDownloaded,
        isFalse,
      );
      expect(await output.exists(), isFalse);
      expect(await File('${task.savePath}.part.m4a').exists(), isTrue);
    });
    test('取消删除任务后，旧执行不能重新创建记录', () async {
      final run = repo.startDownload(taskId);
      await downloader.started.future;
      final cancelling = repo.cancelDownload(taskId);
      downloader.finished.complete(
        DownloadResult(success: false, error: 'cancelled'),
      );
      await Future.wait([run, cancelling]);
      expect(await DownloadTaskDao(db).getById(taskId), isNull);
      expect(repo.activeDownloadCount, 0);
    });
  });
}
