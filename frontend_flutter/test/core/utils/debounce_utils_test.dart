import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:demo/core/utils/debounce_utils.dart';

void main() {
  group('Debouncer', () {
    test('debounces rapid calls and executes only last action', () {
      fakeAsync((async) {
        final debouncer = Debouncer(delay: const Duration(milliseconds: 200));
        var count = 0;

        debouncer(() => count++);
        debouncer(() => count++);
        debouncer(() => count++);

        expect(debouncer.isActive, true);
        async.elapse(const Duration(milliseconds: 199));
        expect(count, 0);

        async.elapse(const Duration(milliseconds: 1));
        expect(count, 1);
        expect(debouncer.isActive, false);
      });
    });

    test('cancel prevents pending action', () {
      fakeAsync((async) {
        final debouncer = Debouncer(delay: const Duration(milliseconds: 150));
        var fired = false;

        debouncer(() => fired = true);
        debouncer.cancel();

        async.elapse(const Duration(milliseconds: 200));
        expect(fired, false);
        expect(debouncer.isActive, false);
      });
    });
  });

  group('Throttler', () {
    test('throttles calls within delay window', () {
      fakeAsync((async) {
        final throttler = Throttler(delay: const Duration(milliseconds: 200));
        var count = 0;

        throttler(() => count++);
        throttler(() => count++);
        expect(count, 1);
        expect(throttler.isThrottling, true);

        async.elapse(const Duration(milliseconds: 199));
        throttler(() => count++);
        expect(count, 1);

        async.elapse(const Duration(milliseconds: 1));
        throttler(() => count++);
        expect(count, 2);
      });
    });
  });

  group('OperationLock', () {
    test('serializes concurrent operations', () {
      fakeAsync((async) {
        final lock = OperationLock();
        final events = <String>[];

        unawaited(lock.synchronized(() async {
          events.add('first-start');
          await Future<void>.delayed(const Duration(milliseconds: 50));
          events.add('first-end');
        }));

        unawaited(lock.synchronized(() async {
          events.add('second-start');
          events.add('second-end');
        }));

        async.elapse(const Duration(milliseconds: 49));
        expect(events, ['first-start']);

        async.elapse(const Duration(milliseconds: 1));
        expect(events, ['first-start', 'first-end', 'second-start', 'second-end']);
      });
    });
  });
}
