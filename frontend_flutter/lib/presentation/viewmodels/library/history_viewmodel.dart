import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_logger.dart';
import '../../../core/storage/shared_storage_service.dart';
import '../../../data/repositories/history_repository.dart';
import '../../../models/play_history.dart';
import '../../../models/audio.dart';

part 'history_viewmodel.freezed.dart';
part 'history_viewmodel.g.dart';

/// 播放历史状态
@freezed
class HistoryState with _$HistoryState {
  /// 初始状态
  const factory HistoryState.initial() = HistoryStateInitial;

  /// 加载中
  const factory HistoryState.loading() = HistoryStateLoading;

  /// 已加载
  const factory HistoryState.loaded({
    required List<PlayHistory> history,
    PlayHistoryStats? stats,
  }) = HistoryStateLoaded;

  /// 错误
  const factory HistoryState.error({
    required String message,
  }) = HistoryStateError;
}

/// 播放历史统计
@freezed
class PlayHistoryStats with _$PlayHistoryStats {
  const factory PlayHistoryStats({
    @Default(0) int totalPlays,
    @Default(0) int uniqueTracks,
    @Default(0) int totalDuration,
    PlayHistory? lastPlayed,
  }) = _PlayHistoryStats;

  factory PlayHistoryStats.fromJson(Map<String, dynamic> json) =>
      _$PlayHistoryStatsFromJson(json);
}

/// 播放历史 ViewModel
///
/// 负责播放历史记录的状态管理
class HistoryViewModel extends StateNotifier<HistoryState> {
  final PlayHistoryRepository _repository;
  final SharedStorageService _storage;

  HistoryViewModel(this._repository, this._storage)
      : super(const HistoryState.initial()) {
    _initialize();
  }

  /// 初始化
  Future<void> _initialize() async {
    try {
      state = const HistoryState.loading();
      await _loadHistoryFromLocal();
    } catch (e) {
      AppLogger.error('HistoryViewModel', '初始化失败: $e');
      state = HistoryState.error(message: e.toString());
    }
  }

  /// 从服务器加载播放历史
  Future<void> loadHistory({int limit = 50}) async {
    try {
      AppLogger.info('HistoryViewModel', '加载播放历史: limit=$limit');

      final history = await _repository.getPlayHistory(
        page: 1,
        pageSize: limit,
      );

      state.maybeWhen(
        loaded: (_, stats) {
          state = HistoryState.loaded(
            history: history,
            stats: stats,
          );
        },
        orElse: () {
          state = HistoryState.loaded(
            history: history,
            stats: null,
          );
        },
      );

      await _saveHistoryToLocal();
      AppLogger.info('HistoryViewModel', '加载播放历史成功: ${history.length}条');
    } catch (e) {
      AppLogger.error('HistoryViewModel', '加载播放历史失败: $e');
      // 尝试从本地加载
      await _loadHistoryFromLocal();
    }
  }

  /// 加载所有历史（不分页）
  Future<void> loadAllHistory() async {
    try {
      AppLogger.info('HistoryViewModel', '加载所有播放历史');

      final history = await _repository.getPlayHistory(
        page: 1,
        pageSize: 1000,
      );

      state.maybeWhen(
        loaded: (_, stats) {
          state = HistoryState.loaded(
            history: history,
            stats: stats,
          );
        },
        orElse: () {
          state = HistoryState.loaded(
            history: history,
            stats: null,
          );
        },
      );

      await _saveHistoryToLocal();
      AppLogger.info('HistoryViewModel', '加载所有播放历史成功: ${history.length}条');
    } catch (e) {
      AppLogger.error('HistoryViewModel', '加载所有播放历史失败: $e');
    }
  }

  /// 记录播放
  ///
  /// 支持在线音频（bvid）和本地音频（localPath）
  Future<void> recordPlay({
    String? bvid,
    String? localPath,
    String? title,
    String? artist,
    int? duration,
    String? coverUrl,
    int progress = 0,
  }) async {
    // 确定音频标识符（本地音频使用文件路径作为 ID）
    final identifier = bvid ?? localPath ?? '';
    if (identifier.isEmpty) {
      AppLogger.debug('HistoryViewModel', 'bvid 和 localPath 都为空，无法记录播放');
      return;
    }

    try {
      // 先更新本地列表（乐观更新）
      final currentHistory = state.maybeWhen(
        loaded: (history, stats) => history,
        orElse: () => <PlayHistory>[],
      );

      final existingIndex =
          currentHistory.indexWhere((item) => item.audio.id == identifier);

      // 创建新的 Audio 对象
      final audio = Audio(
        id: identifier,
        title: title ?? '',
        artist: artist,
        duration: duration,
        coverUrl: coverUrl,
      );

      final newItem = PlayHistory(
        id: '', // 新建时 ID 由后端生成
        userId: '', // 用户 ID 从 token 获取
        audio: audio,
        playedAt: DateTime.now(),
        progress: progress,
      );

      List<PlayHistory> updatedHistory;
      if (existingIndex >= 0) {
        // 更新现有记录
        updatedHistory = List<PlayHistory>.from(currentHistory);
        updatedHistory[existingIndex] = newItem;
        updatedHistory.sort((a, b) => b.playedAt.compareTo(a.playedAt));
      } else {
        // 添加新记录到开头
        updatedHistory = [newItem, ...currentHistory];
        // 限制历史记录数量
        if (updatedHistory.length > 100) {
          updatedHistory = updatedHistory.sublist(0, 100);
        }
      }

      // 更新统计
      final currentStats = state.maybeWhen(
        loaded: (_, stats) => stats,
        orElse: () => null,
      );

      final updatedStats = currentStats?.copyWith(
        totalPlays: (currentStats?.totalPlays ?? 0) + 1,
      );

      state = HistoryState.loaded(
        history: updatedHistory,
        stats: updatedStats,
      );

      await _saveHistoryToLocal();

      // 异步同步到服务器（非阻塞）
      final token = await _storage.getString('auth_token');
      if (token != null && token.isNotEmpty && bvid != null) {
        _syncPlayToServer(token, bvid, progress).catchError((e) {
          AppLogger.error('HistoryViewModel', '记录播放失败（不影响播放）: $e');
        });
      }

      AppLogger.info('HistoryViewModel', '记录播放成功: $identifier');
    } catch (e) {
      AppLogger.error('HistoryViewModel', '记录播放失败: $e');
    }
  }

  /// 同步播放到服务器
  Future<void> _syncPlayToServer(String token, String bvid, int progress) async {
    try {
      await _repository.addPlayHistory(
        bvid: bvid,
        progress: progress,
      );
    } catch (e) {
      // 静默失败
      AppLogger.debug('HistoryViewModel', '同步播放到服务器失败: $e');
    }
  }

  /// 删除指定记录
  Future<bool> removeHistoryItem(String bvid) async {
    try {
      AppLogger.info('HistoryViewModel', '删除播放记录: $bvid');

      final currentHistory = state.maybeWhen(
        loaded: (history, stats) => history,
        orElse: () => <PlayHistory>[],
      );

      final updatedHistory =
          currentHistory.where((item) => item.audio.id != bvid).toList();

      state.maybeWhen(
        loaded: (_, stats) {
          state = HistoryState.loaded(
            history: updatedHistory,
            stats: stats,
          );
        },
        orElse: () {
          state = HistoryState.loaded(
            history: updatedHistory,
            stats: null,
          );
        },
      );

      await _saveHistoryToLocal();

      // 尝试从服务器删除
      final token = await _storage.getString('auth_token');
      if (token != null && token.isNotEmpty) {
        await _repository.deletePlayHistory(bvid);
      }

      return true;
    } catch (e) {
      AppLogger.error('HistoryViewModel', '删除播放记录失败: $e');
      return false;
    }
  }

  /// 按ID删除记录
  Future<bool> removeHistoryById(String id) async {
    try {
      AppLogger.info('HistoryViewModel', '按ID删除播放记录: $id');

      final currentHistory = state.maybeWhen(
        loaded: (history, stats) => history,
        orElse: () => <PlayHistory>[],
      );

      final updatedHistory =
          currentHistory.where((item) => item.id != id).toList();

      state.maybeWhen(
        loaded: (_, stats) {
          state = HistoryState.loaded(
            history: updatedHistory,
            stats: stats,
          );
        },
        orElse: () {
          state = HistoryState.loaded(
            history: updatedHistory,
            stats: null,
          );
        },
      );

      await _saveHistoryToLocal();
      return true;
    } catch (e) {
      AppLogger.error('HistoryViewModel', '按ID删除播放记录失败: $e');
      return false;
    }
  }

  /// 清空历史
  Future<bool> clearHistory() async {
    try {
      AppLogger.info('HistoryViewModel', '清空播放历史');

      state = const HistoryState.loaded(
        history: [],
        stats: null,
      );

      await _storage.remove('play_history_cache');

      // 尝试从服务器清空
      final token = await _storage.getString('auth_token');
      if (token != null && token.isNotEmpty) {
        await _repository.clearAllHistory();
      }

      return true;
    } catch (e) {
      AppLogger.error('HistoryViewModel', '清空播放历史失败: $e');
      return false;
    }
  }

  /// 获取去重后的历史（按bvid）
  List<PlayHistory> get uniqueHistory {
    return state.maybeWhen(
      loaded: (history, stats) {
        final seen = <String>{};
        return history.where((item) {
          if (seen.contains(item.audio.id)) {
            return false;
          }
          seen.add(item.audio.id);
          return true;
        }).toList();
      },
      orElse: () => [],
    );
  }

  /// 根据bvid查找历史记录
  PlayHistory? findByBvid(String bvid) {
    return state.maybeWhen(
      loaded: (history, stats) {
        try {
          return history.firstWhere((item) => item.audio.id == bvid);
        } catch (_) {
          return null;
        }
      },
      orElse: () => null,
    );
  }

  /// 清空数据（登出时调用）
  Future<void> clear() async {
    state = const HistoryState.initial();
    await _storage.remove('play_history_cache');
    AppLogger.info('HistoryViewModel', '已清空数据');
  }

  // ==================== 私有方法 ====================

  Future<void> _loadHistoryFromLocal() async {
    try {
      final historyJson = await _storage.getString('play_history_cache');
      if (historyJson != null) {
        final data = jsonDecode(historyJson) as List;
        final history = data
            .map((json) => PlayHistory.fromJson(json as Map<String, dynamic>))
            .toList();

        state = HistoryState.loaded(
          history: history,
          stats: null,
        );

        AppLogger.info('HistoryViewModel', '从本地加载播放历史成功');
      }
    } catch (e) {
      AppLogger.error('HistoryViewModel', '从本地加载播放历史失败: $e');
    }
  }

  Future<void> _saveHistoryToLocal() async {
    try {
      state.maybeWhen(
        loaded: (history, stats) async {
          final json = jsonEncode(history.map((item) => item.toJson()).toList());
          await _storage.setString('play_history_cache', json);
        },
        orElse: () {},
      );
    } catch (e) {
      AppLogger.error('HistoryViewModel', '保存本地播放历史失败: $e');
    }
  }
}

/// Provider 定义
@riverpod
PlayHistoryRepository historyRepository(HistoryRepositoryRef ref) {
  return PlayHistoryRepository();
}

@riverpod
HistoryViewModel historyViewModel(HistoryViewModelRef ref) {
  final repository = ref.watch(historyRepositoryProvider);
  final storage = SharedStorageService.instance;
  return HistoryViewModel(repository, storage);
}

/// 历史状态 Provider - 用于 UI 层监听状态
@riverpod
HistoryState historyState(HistoryStateRef ref) {
  final viewModel = ref.watch(historyViewModelProvider);
  return viewModel.state;
}

