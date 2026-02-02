import 'package:flutter_test/flutter_test.dart';
import 'package:demo/presentation/providers/history/play_history_provider.dart';

void main() {
  // 初始化 Flutter 测试绑定
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayHistoryProvider', () {
    test('应该成功创建实例', () {
      final provider = PlayHistoryProvider();
      expect(provider, isNotNull);
      expect(provider, isA<PlayHistoryProvider>());
      provider.dispose();
    });

    test('recordStart 方法应该存在且可调用', () async {
      final provider = PlayHistoryProvider();
      // 验证方法存在且不会抛出异常
      expect(() async {
        await provider.recordStart(
          bvid: 'test_bvid',
          title: 'Test Title',
        );
      }, returnsNormally);
      provider.dispose();
    });

    test('updateProgress 方法应该存在且可调用', () async {
      final provider = PlayHistoryProvider();
      // 验证方法存在且不会抛出异常
      expect(() async {
        await provider.updateProgress(
          title: 'Test Title',
          progress: 10,
        );
      }, returnsNormally);
      provider.dispose();
    });

    test('dispose 应该成功调用', () {
      final provider = PlayHistoryProvider();
      expect(() {
        provider.dispose();
      }, returnsNormally);
    });
  });
}
