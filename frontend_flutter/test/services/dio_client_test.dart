import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listenvision/core/errors/exceptions.dart';
import 'package:listenvision/core/network/dio_client.dart';
import 'package:listenvision/services/bilibili_api_service.dart';

class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.respond);
  final Future<ResponseBody> Function(RequestOptions) respond;
  int calls = 0;
  bool cancelled = false;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? body,
    Future<void>? cancelFuture,
  ) {
    calls++;
    cancelFuture?.then((_) => cancelled = true);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Dio dio;
  setUp(() => dio = DioClient.create());
  tearDown(() => dio.close(force: true));

  test('临时 GET 失败只重试一次，业务错误响应不触发重试', () async {
    var attempt = 0;
    final adapter = FakeAdapter((options) async {
      if (attempt++ == 0) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      }
      return ResponseBody.fromString(
        '{"code":-404,"message":"missing"}',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    });
    dio.httpClientAdapter = adapter;
    await DioClient.get(dio, 'https://example.com', retryDelay: Duration.zero);
    expect(adapter.calls, 2);
    await expectLater(
      BilibiliApiService(dio: dio).getVideoInfo('BVtest'),
      throwsA(isA<BilibiliApiException>()),
    );
    expect(adapter.calls, 3);
  });

  test('403 和限流响应不自动重试', () async {
    for (final status in [403, 429]) {
      final adapter = FakeAdapter(
        (_) async => ResponseBody.fromString('', status),
      );
      dio.httpClientAdapter = adapter;
      await expectLater(
        DioClient.get(dio, 'https://example.com'),
        throwsA(isA<DioException>()),
      );
      expect(adapter.calls, 1);
    }
  });

  test('整次请求预算耗尽会取消底层传输并返回超时错误', () async {
    final adapter = FakeAdapter((_) => Completer<ResponseBody>().future);
    dio.httpClientAdapter = adapter;
    await expectLater(
      DioClient.get(
        dio,
        'https://example.com',
        budget: const Duration(milliseconds: 30),
      ),
      throwsA(
        isA<NetworkException>().having(
          (error) => error.code,
          'code',
          'NETWORK_TIMEOUT',
        ),
      ),
    );
    expect(adapter.cancelled, isTrue);
    expect(adapter.calls, 1);
  });

  test('用户取消立即取消传输且不重试', () async {
    final started = Completer<void>();
    final adapter = FakeAdapter((_) {
      started.complete();
      return Completer<ResponseBody>().future;
    });
    dio.httpClientAdapter = adapter;
    final token = CancelToken();
    final result = DioClient.get(
      dio,
      'https://example.com',
      cancelToken: token,
    );
    final assertion = expectLater(
      result,
      throwsA(isA<TaskCanceledException>()),
    );
    await started.future;
    token.cancel();
    await assertion;
    expect(adapter.cancelled, isTrue);
    expect(adapter.calls, 1);
  });

  test('无法确认视频状态时返回 unknown 而非改为可用或失效', () async {
    dio.httpClientAdapter = FakeAdapter(
      (_) async => ResponseBody.fromString(
        '{"code":-412,"message":"temporary"}',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      ),
    );
    expect(
      await BilibiliApiService(dio: dio).checkVideoExists('BVtest'),
      isNull,
    );
  });
}
