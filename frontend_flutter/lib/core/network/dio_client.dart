import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors/exceptions.dart';

final apiDioProvider = Provider<Dio>((ref) {
  final dio = DioClient.create();
  ref.onDispose(() => dio.close(force: true));
  return dio;
});

/// 统一客户端配置。下载单独使用较长的接收空闲超时，不继承 API 重试。
class DioClient {
  DioClient._();
  static final instance = DioClient._();
  Dio? _dio;
  Dio get dio => _dio ??= create();

  static Dio create({bool download = false}) => Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 15),
      receiveTimeout: Duration(seconds: download ? 60 : 15),
    ),
  );

  /// 每次 API 交互共用一个截止时间和取消信号，包括重试及退避。
  static Future<Response<dynamic>> get(
    Dio dio,
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    Duration budget = const Duration(seconds: 30),
    Duration? retryDelay,
  }) async {
    final token = CancelToken();
    var finished = false;
    var timedOut = false;
    if (cancelToken?.isCancelled ?? false) {
      throw const TaskCanceledException();
    }
    unawaited(
      cancelToken?.whenCancel.then((error) {
        if (!finished) token.cancel(error);
      }),
    );
    final timer = Timer(budget, () {
      timedOut = true;
      token.cancel('API request deadline exceeded');
    });
    try {
      for (var attempt = 0; ; attempt++) {
        try {
          return await dio.get<dynamic>(
            url,
            queryParameters: queryParameters,
            options: Options(headers: headers),
            cancelToken: token,
          );
        } on DioException catch (error) {
          final retryable = switch (error.type) {
            DioExceptionType.connectionError ||
            DioExceptionType.connectionTimeout ||
            DioExceptionType.receiveTimeout => true,
            DioExceptionType.badResponse => const [
              502,
              503,
              504,
            ].contains(error.response?.statusCode),
            _ => false,
          };
          if (attempt != 0 || !retryable || token.isCancelled) rethrow;
          await Future.any([
            Future<void>.delayed(
              retryDelay ?? Duration(milliseconds: 500 + Random().nextInt(501)),
            ),
            token.whenCancel.then<void>((_) {}),
          ]);
          if (token.isCancelled) throw token.cancelError!;
        }
      }
    } on DioException catch (error) {
      if (timedOut) throw NetworkException.timeout();
      switch (error.type) {
        case DioExceptionType.cancel:
          throw const TaskCanceledException();
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          throw NetworkException.timeout();
        case DioExceptionType.connectionError:
          throw NetworkException.noConnection();
        default:
          rethrow;
      }
    } finally {
      finished = true;
      timer.cancel();
    }
  }

  void close() {
    _dio?.close(force: true);
    _dio = null;
  }
}
