import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../core/errors/exceptions.dart';

class ResumableDownloadService {
  final Dio _dio;
  final bool _ownsDio;
  ResumableDownloadService({Dio? dio})
    : _dio = dio ?? DioClient.create(download: true),
      _ownsDio = dio == null;

  /// 临时文件与验证信息按任务隔离。只有验证过的 Range 才允许追加。
  Future<int> downloadFile({
    required String url,
    required String savePath,
    required CancelToken cancelToken,
    Map<String, String>? headers,
    void Function(int received, int total)? onProgress,
  }) async {
    final file = File(savePath);
    final sidecar = File('$savePath.json');
    await file.parent.create(recursive: true);
    Map<String, dynamic> saved = {};
    if (await sidecar.exists()) {
      try {
        saved =
            jsonDecode(await sidecar.readAsString()) as Map<String, dynamic>;
      } on FormatException {
        saved = {};
      }
    }
    final validator = saved['etag'] ?? saved['lastModified'];
    var offset = validator != null && await file.exists()
        ? await file.length()
        : 0;
    for (var attempt = 0; attempt < 2; attempt++) {
      _check(cancelToken);
      final response = await _dio.get<ResponseBody>(
        url,
        cancelToken: cancelToken,
        options: Options(
          responseType: ResponseType.stream,
          validateStatus: (code) => code == 200 || code == 206 || code == 416,
          headers: {
            ...?headers,
            if (offset > 0) 'Range': 'bytes=$offset-',
            if (offset > 0) 'If-Range': validator,
          },
        ),
      );
      final body = response.data!;
      final range = RegExp(
        r'^bytes (\d+)-(\d+)/(\d+)$',
      ).firstMatch(response.headers.value('content-range') ?? '');
      final etag = response.headers.value('etag');
      final modified = response.headers.value('last-modified');
      final changed =
          offset > 0 &&
          ((saved['etag'] != null && etag != saved['etag']) ||
              (saved['etag'] == null && saved['lastModified'] != modified));
      final invalidRange =
          response.statusCode == 206 &&
          (range == null ||
              int.parse(range.group(1)!) != offset ||
              int.parse(range.group(2)!) < offset ||
              int.parse(range.group(3)!) <= int.parse(range.group(2)!));
      if (response.statusCode == 416 || invalidRange || changed) {
        await body.stream.listen((_) {}).cancel();
        if (attempt == 1) throw const NetworkException('续传响应校验失败');
        offset = 0;
        continue;
      }
      // 服务端忽略 Range 返回 200 时，必须截断旧文件。
      if (response.statusCode == 200) offset = 0;
      final expected = response.statusCode == 206
          ? int.parse(range!.group(3)!)
          : int.tryParse(response.headers.value('content-length') ?? '') ?? 0;
      await sidecar.writeAsString(
        jsonEncode({
          if (etag != null && !etag.startsWith('W/')) 'etag': etag,
          'lastModified': ?modified,
        }),
        flush: true,
      );
      var received = offset;
      var buffered = 0;
      final sink = file.openWrite(
        mode: offset > 0 ? FileMode.append : FileMode.write,
      );
      var lastUpdate = DateTime.fromMillisecondsSinceEpoch(0);
      final chunks = StreamIterator<Uint8List>(body.stream);
      var finished = false;
      unawaited(
        cancelToken.whenCancel.then((_) async {
          if (!finished) await chunks.cancel();
        }),
      );
      try {
        while (await chunks.moveNext()) {
          final chunk = chunks.current;
          _check(cancelToken);
          sink.add(chunk);
          buffered += chunk.length;
          if (buffered >= 1024 * 1024) {
            await sink.flush();
            buffered = 0;
          }
          received += chunk.length;
          final now = DateTime.now();
          if (now.difference(lastUpdate).inMilliseconds >= 300) {
            onProgress?.call(received, expected);
            lastUpdate = now;
          }
        }
        await sink.flush();
      } finally {
        finished = true;
        await chunks.cancel();
        await sink.close();
      }
      _check(cancelToken);
      if (received == 0 || (expected > 0 && received != expected)) {
        throw const NetworkException('下载文件长度不完整');
      }
      onProgress?.call(received, expected);
      return received;
    }
    throw const NetworkException('下载失败');
  }

  void _check(CancelToken token) {
    if (token.isCancelled) throw const TaskCanceledException();
  }

  void dispose() {
    if (_ownsDio) _dio.close(force: true);
  }
}
