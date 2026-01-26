import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:demo/core/utils/app_logger.dart';

/// 播放命令类型
enum PlaybackCommandType {
  /// 播放
  play,

  /// 暂停
  pause,

  /// 停止
  stop,

  /// 跳转
  seek,

  /// 切换曲目
  changeTrack,

  /// 设置音量
  setVolume,

  /// 设置倍速
  setSpeed,
}

/// 播放命令
///
/// 封装播放操作，支持队列执行和错误处理
class PlaybackCommand {
  final PlaybackCommandType type;
  final Map<String, dynamic> params;
  final Completer<void> completer;

  PlaybackCommand({
    required this.type,
    required this.params,
  }) : completer = Completer<void>();

  /// 执行命令
  ///
  /// [executor] 实际执行操作的函数
  Future<void> execute(Future<void> Function(PlaybackCommand) executor) async {
    try {
      await executor(this);
      if (!completer.isCompleted) {
        completer.complete();
      }
    } catch (e) {
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
    }
  }

  /// 获取参数值
  T? getParam<T>(String key) {
    return params[key] as T?;
  }

  /// 检查是否有参数
  bool hasParam(String key) {
    return params.containsKey(key);
  }

  @override
  String toString() {
    return 'PlaybackCommand(type: $type, params: $params)';
  }
}

/// 播放操作队列
///
/// 解决快速点击导致的播放混乱问题
/// - 所有播放操作通过队列串行执行
/// - 支持取消待处理的操作
/// - 提供队列状态查询
class PlaybackQueue {
  /// 待执行的命令队列
  final List<PlaybackCommand> _queue = [];

  /// 是否正在处理队列
  bool _isProcessing = false;

  /// 队列锁（防止并发执行）
  bool _isLocked = false;

  /// 最大队列长度（防止队列无限增长）
  final int maxQueueLength;

  /// 队列状态变化回调
  void Function(PlaybackQueueState)? _onStateChanged;

  PlaybackQueue({
    this.maxQueueLength = 10,
  });

  /// 当前队列状态
  PlaybackQueueState get state {
    if (_isProcessing) {
      return PlaybackQueueState.processing;
    } else if (_queue.isNotEmpty) {
      return PlaybackQueueState.pending;
    }
    return PlaybackQueueState.idle;
  }

  /// 队列长度
  int get length => _queue.length;

  /// 是否正在处理
  bool get isProcessing => _isProcessing;

  /// 是否有待处理的命令
  bool get hasPending => _queue.isNotEmpty;

  /// 设置状态变化回调
  void setOnStateChanged(void Function(PlaybackQueueState)? callback) {
    _onStateChanged = callback;
  }

  /// 通知状态变化
  void _notifyStateChanged() {
    _onStateChanged?.call(state);
  }

  /// 添加命令到队列
  ///
  /// [command] 要添加的命令
  /// [cancelPending] 是否取消待处理的命令（默认 true）
  Future<void> enqueue(
    PlaybackCommand command, {
    bool cancelPending = true,
  }) async {
    // 取消待处理的命令
    if (cancelPending && _queue.isNotEmpty) {
      _cancelPending();
    }

    // 检查队列长度
    if (_queue.length >= maxQueueLength) {
      AppLogger.info('PlaybackQueue', '队列已满，丢弃最旧的命令');
      _queue.removeAt(0);
    }

    _queue.add(command);
    _notifyStateChanged();

    AppLogger.info('PlaybackQueue', '命令已入队: $command, 队列长度: ${_queue.length}');

    // 如果队列未被锁定，开始处理
    if (!_isLocked) {
      await _processQueue();
    }
  }

  /// 取消所有待处理的命令
  void _cancelPending() {
    for (final cmd in _queue) {
      if (!cmd.completer.isCompleted) {
        cmd.completer.completeError('操作被取消');
      }
    }
    _queue.clear();
    AppLogger.info('PlaybackQueue', '已取消所有待处理的命令');
  }

  /// 取消待处理的命令（公共方法）
  void cancelPending() {
    _cancelPending();
    _notifyStateChanged();
  }

  /// 处理队列中的命令
  Future<void> _processQueue() async {
    if (_isProcessing) return;
    if (_queue.isEmpty) return;

    _isProcessing = true;
    _isLocked = true;
    _notifyStateChanged();

    AppLogger.info('PlaybackQueue', '开始处理队列，待处理: ${_queue.length}');

    while (_queue.isNotEmpty) {
      final cmd = _queue.removeAt(0);
      _notifyStateChanged();

      AppLogger.debug('PlaybackQueue', '执行命令: $cmd');

      try {
        // 命令的实际执行由外部提供
        if (!cmd.completer.isCompleted) {
          // 等待命令完成（超时5秒）
          await cmd.completer.future.timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              AppLogger.warn('PlaybackQueue', '命令执行超时: $cmd');
              throw TimeoutException('命令执行超时: $cmd');
            },
          );
        }
      } catch (e) {
        AppLogger.error('PlaybackQueue', '命令执行失败: $cmd, 错误: $e');
        // 继续处理下一个命令
      }
    }

    _isProcessing = false;
    _isLocked = false;
    _notifyStateChanged();

    AppLogger.info('PlaybackQueue', '队列处理完成');
  }

  /// 清空队列
  void clear() {
    _cancelPending();
    _isProcessing = false;
    _isLocked = false;
    _notifyStateChanged();
    AppLogger.info('PlaybackQueue', '队列已清空');
  }

  /// 释放资源
  void dispose() {
    clear();
  }
}

/// 队列状态
enum PlaybackQueueState {
  /// 空闲（队列中无命令，未在处理）
  idle,

  /// 有待处理的命令
  pending,

  /// 正在处理命令
  processing,
}
