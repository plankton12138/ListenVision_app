import 'dart:async';
import 'package:flutter/foundation.dart';

class Debouncer {
  final Duration delay;
  Timer? _timer;
  VoidCallback? _action;
  bool _isActive = false;

  Debouncer({required this.delay});

  void call(VoidCallback action) {
    _action = action;
    _timer?.cancel();
    _isActive = true;
    _timer = Timer(delay, () {
      _isActive = false;
      _action?.call();
    });
  }

  void cancel() {
    _timer?.cancel();
    _isActive = false;
    _action = null;
  }

  bool get isActive => _isActive;

  void dispose() {
    cancel();
  }
}

class Throttler {
  final Duration delay;
  Timer? _timer;
  bool _isThrottling = false;

  Throttler({required this.delay});

  void call(VoidCallback action) {
    if (_isThrottling) return;

    action();
    _isThrottling = true;
    _timer = Timer(delay, () {
      _isThrottling = false;
    });
  }

  void reset() {
    _timer?.cancel();
    _isThrottling = false;
  }

  bool get isThrottling => _isThrottling;

  void dispose() {
    reset();
  }
}

class OperationLock {
  bool _isLocked = false;
  final List<Completer<void>> _waiters = [];

  Future<T> synchronized<T>(Future<T> Function() operation) async {
    while (_isLocked) {
      final completer = Completer<void>();
      _waiters.add(completer);
      await completer.future;
    }

    _isLocked = true;
    try {
      return await operation();
    } finally {
      _isLocked = false;
      if (_waiters.isNotEmpty) {
        final waiter = _waiters.removeAt(0);
        waiter.complete();
      }
    }
  }

  bool get isLocked => _isLocked;

  void dispose() {
    for (final waiter in _waiters) {
      waiter.completeError(StateError('OperationLock disposed'));
    }
    _waiters.clear();
  }
}

class AdaptiveProtection {
  final Duration baseDuration;
  final Duration maxDuration;
  double _performanceFactor = 1.0;
  DateTime? _lastOperationTime;
  final List<Duration> _operationDurations = [];
  static const int _maxSamples = 5;

  AdaptiveProtection({
    required this.baseDuration,
    this.maxDuration = const Duration(seconds: 5),
  });

  Duration get protectionDuration {
    final adjusted = Duration(
      milliseconds: (baseDuration.inMilliseconds * _performanceFactor).round(),
    );
    return adjusted > maxDuration ? maxDuration : adjusted;
  }

  void recordOperationStart() {
    _lastOperationTime = DateTime.now();
  }

  void recordOperationEnd() {
    if (_lastOperationTime != null) {
      final duration = DateTime.now().difference(_lastOperationTime!);
      _operationDurations.add(duration);
      if (_operationDurations.length > _maxSamples) {
        _operationDurations.removeAt(0);
      }
      _updatePerformanceFactor();
    }
  }

  void _updatePerformanceFactor() {
    if (_operationDurations.isEmpty) return;

    final avgDuration = _operationDurations.reduce((a, b) => a + b) ~/
        _operationDurations.length;
    final baseMs = baseDuration.inMilliseconds;
    final avgMs = avgDuration.inMilliseconds;

    if (avgMs > baseMs * 1.5) {
      _performanceFactor = (_performanceFactor * 1.2).clamp(1.0, 3.0);
    } else if (avgMs < baseMs * 0.8 && _performanceFactor > 1.0) {
      _performanceFactor = (_performanceFactor * 0.9).clamp(1.0, 3.0);
    }
  }

  bool get isInProtectionPeriod {
    if (_lastOperationTime == null) return false;
    final elapsed = DateTime.now().difference(_lastOperationTime!);
    return elapsed < protectionDuration;
  }

  void reset() {
    _performanceFactor = 1.0;
    _lastOperationTime = null;
    _operationDurations.clear();
  }
}
