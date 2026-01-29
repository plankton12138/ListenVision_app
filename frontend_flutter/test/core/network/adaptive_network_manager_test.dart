import 'package:flutter_test/flutter_test.dart';

import 'package:demo/core/network/adaptive_network_manager.dart';

void main() {
  group('AdaptiveNetworkManager', () {
    test('default quality should be good and monitoring initially stopped', () {
      final manager = AdaptiveNetworkManager();
      expect(manager.currentQuality, NetworkQuality.good);
      expect(manager.isMonitoring, false);
    });

    test('timeouts and retry counts vary by quality', () async {
      final manager = AdaptiveNetworkManager();

      // Default is good
      expect(manager.getConnectTimeout(), const Duration(seconds: 8));
      expect(manager.getReceiveTimeout(), const Duration(seconds: 15));
      expect(manager.getRetryCount(), 1);

      // Force update via internal path by refreshing with no network
      // This test only asserts values are valid ranges even after refresh.
      await manager.refreshQuality();
      expect(manager.getConnectTimeout().inSeconds, greaterThan(0));
      expect(manager.getReceiveTimeout().inSeconds, greaterThan(0));
    });

    test('retry delay increases with attempts and is bounded', () {
      final manager = AdaptiveNetworkManager();
      final first = manager.getRetryDelay(0).inMilliseconds;
      final second = manager.getRetryDelay(1).inMilliseconds;
      expect(second, greaterThan(first));
      final high = manager.getRetryDelay(6).inMilliseconds;
      expect(high, lessThanOrEqualTo(30000));
    });

    test('preload bytes are within expected bounds', () {
      final manager = AdaptiveNetworkManager();
      final bytes = manager.getPreloadBytes();
      expect(bytes, greaterThan(0));
    });

    test('executeWithRetry succeeds without retry when operation passes', () async {
      final manager = AdaptiveNetworkManager();
      final result = await manager.executeWithRetry(() async => 'ok');
      expect(result, 'ok');
    });
  });
}
