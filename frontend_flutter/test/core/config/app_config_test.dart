import 'package:flutter_test/flutter_test.dart';
import 'package:demo/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    late AppConfig config;

    setUp(() {
      // 每次测试前重置配置
      AppConfig.reset();
      config = AppConfig();
    });

    tearDown(() {
      AppConfig.reset();
    });

    group('环境配置', () {
      test('默认应该是开发环境', () {
        expect(config.envName, 'dev');
        expect(config.isDev, true);
        expect(config.isProd, false);
      });

      test('apiBaseUrl 应该返回正确的默认值', () {
        expect(config.apiBaseUrl, 'http://127.0.0.1:3000');
      });

      test('fullApiBaseUrl 应该包含 /api 前缀', () {
        expect(config.fullApiBaseUrl, contains('/api'));
        expect(config.fullApiBaseUrl, 'http://127.0.0.1:3000/api');
      });
    });

    group('功能开关', () {
      test('开发环境应该启用调试日志', () {
        expect(config.enableApiLogging, true);
        expect(config.enableDebugLogging, true);
      });

      test('开发环境不应该启用生产环境功能', () {
        expect(config.enableErrorReporting, false);
        expect(config.enableCrashReporting, false);
      });

      test('开发环境 isDebugMode 应该为 true', () {
        expect(config.isDebugMode, true);
      });
    });

    group('超时配置', () {
      test('开发环境应该有较长的超时时间', () {
        expect(config.connectTimeoutSeconds, 60);
        expect(config.receiveTimeoutSeconds, 60);
        expect(config.sendTimeoutSeconds, 60);
      });
    });

    group('工具方法', () {
      test('getEndpointUrl 应该正确拼接 URL', () {
        const endpoint = '/users/1';
        final url = config.getEndpointUrl(endpoint);
        expect(url, 'http://127.0.0.1:3000/api/users/1');
      });

      test('getResourceUrl 应该正确拼接资源 URL', () {
        const path = '/images/cover.jpg';
        final url = config.getResourceUrl(path);
        expect(url, 'http://127.0.0.1:3000/images/cover.jpg');
      });
    });

    group('toString', () {
      test('toString 应该包含环境信息', () {
        final str = config.toString();
        expect(str, contains('AppConfig'));
        expect(str, contains('dev'));
        expect(str, contains('http://127.0.0.1:3000'));
      });
    });
  });
}
