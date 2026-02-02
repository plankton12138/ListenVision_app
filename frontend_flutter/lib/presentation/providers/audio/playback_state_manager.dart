import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:demo/core/constants/storage_constants.dart';
import 'package:demo/core/constants/playback_config.dart';
import 'package:demo/domain/entities/playable_audio.dart';
import 'package:demo/domain/entities/local_playable.dart';
import 'package:demo/data/managers/playlist_manager.dart';
import 'package:demo/core/utils/app_logger.dart';

/// 播放状态管理器
///
/// 职责：
/// 1. 播放进度定时保存
/// 2. 播放设置持久化（音量、倍速）
/// 3. 播放位置记录（本地音频数据库）
/// 4. 通用键值对持久化
class PlaybackStateManager {
  // ==================== 状态变量 ====================

  /// 播放位置定时器
  Timer? _savePositionTimer;

  /// 保存防抖定时器
  Timer? _saveDebounceTimer;

  /// 是否正在保存
  bool _isSaving = false;

  /// 是否已销毁
  bool _disposed = false;

  // ==================== 回调 ====================

  /// 获取当前状态的回调
  Future<int> Function()? _getCurrentIndex;
  Future<PlayableAudio?> Function()? _getCurrentPlayable;
  Future<Duration> Function()? _getCurrentPosition;
  Future<bool> Function()? _getIsPlaying;

  /// 状态变化回调
  Function()? _onStateChanged;

  // ==================== 播放设置 ====================

  /// 播放音量（0.0 - 1.0）
  double _volume = 1.0;

  /// 播放倍速（0.5x - 2.0x）
  double _speed = 1.0;

  // ==================== 构造函数 ====================

  PlaybackStateManager() {
    _loadPlaybackSettings();
  }

  // ==================== 销毁 ====================

  void dispose() {
    if (_disposed) return;
    _disposed = true;

    _savePositionTimer?.cancel();
    _saveDebounceTimer?.cancel();
    _settingsDebounceTimer?.cancel();
    
    // 立即保存待处理的设置
    _settingsDebounceTimer?.cancel();
    if (_settingsDebounceTimer?.isActive ?? false) {
      _savePlaybackSettings();
    }

    AppLogger.info('PlaybackStateManager', '已释放');
  }

  // ==================== 回调设置 ====================

  /// 设置状态获取回调
  void setStateCallbacks({
    Future<int> Function()? getCurrentIndex,
    Future<PlayableAudio?> Function()? getCurrentPlayable,
    Future<Duration> Function()? getCurrentPosition,
    Future<bool> Function()? getIsPlaying,
  }) {
    _getCurrentIndex = getCurrentIndex;
    _getCurrentPlayable = getCurrentPlayable;
    _getCurrentPosition = getCurrentPosition;
    _getIsPlaying = getIsPlaying;
  }

  /// 设置状态变化回调
  void setOnStateChanged(Function()? callback) {
    _onStateChanged = callback;
  }

  /// 通知状态已变化
  void _notifyChanged() {
    _onStateChanged?.call();
  }

  // ==================== 播放设置管理 ====================

  /// 获取音量
  double get volume => _volume;

  /// 获取倍速
  double get speed => _speed;

  /// 设置音量 - 修复：使用防抖避免频繁保存
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    _notifyChanged();
    AppLogger.debug('PlaybackStateManager', '音量已设置: ${(_volume * 100).toInt()}%');
    
    // 使用防抖保存，避免频繁写入
    _debounceSaveSettings();
  }

  /// 设置倍速 - 修复：使用防抖避免频繁保存
  Future<void> setSpeed(double speed) async {
    _speed = speed.clamp(0.5, 2.0);
    _notifyChanged();
    AppLogger.debug('PlaybackStateManager', '倍速已设置: ${_speed}x');
    
    // 使用防抖保存，避免频繁写入
    _debounceSaveSettings();
  }
  
  /// 防抖保存定时器
  Timer? _settingsDebounceTimer;

  /// 防抖保存播放设置
  void _debounceSaveSettings() {
    _settingsDebounceTimer?.cancel();
    _settingsDebounceTimer = Timer(PlaybackConfig.settingsDebounceDelay, () async {
      if (_disposed) return;
      await _savePlaybackSettings();
    });
  }

  /// 保存播放设置
  Future<void> _savePlaybackSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(StorageKeys.playbackVolume, _volume);
      await prefs.setDouble(StorageKeys.playbackSpeed, _speed);
      AppLogger.info('PlaybackStateManager', '播放设置已保存: 音量=$_volume 倍速=$_speed');
    } catch (e) {
      AppLogger.error('PlaybackStateManager', '保存播放设置失败: $e');
    }
  }

  /// 加载播放设置
  Future<void> _loadPlaybackSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _volume = prefs.getDouble(StorageKeys.playbackVolume) ?? 1.0;
      _speed = prefs.getDouble(StorageKeys.playbackSpeed) ?? 1.0;
      AppLogger.info('PlaybackStateManager', '播放设置已加载: 音量=${(_volume * 100).toInt()}% 倍速=$_speed');
    } catch (e) {
      AppLogger.error('PlaybackStateManager', '加载播放设置失败: $e');
      _volume = 1.0;
      _speed = 1.0;
    }
  }

  // ==================== 播放位置定时保存 ====================

  /// 启动播放位置定时保存
  void startPositionSaveTimer() {
    _savePositionTimer?.cancel();
    _savePositionTimer = Timer.periodic(PlaybackConfig.positionSaveInterval, (_) async {
      if (_disposed) return;

      final isPlaying = await _getIsPlaying?.call() ?? false;
      final currentIndex = await _getCurrentIndex?.call() ?? -1;

      if (currentIndex >= 0 && isPlaying) {
        await _savePlaybackState();
      }
    });
    AppLogger.info('PlaybackStateManager', '播放位置定时保存已启动');
  }

  /// 停止播放位置定时保存
  void stopPositionSaveTimer() {
    _savePositionTimer?.cancel();
    _savePositionTimer = null;
    AppLogger.info('PlaybackStateManager', '播放位置定时保存已停止');
  }

  /// 保存播放状态到数据库
  ///
  /// 对于本地音频，保存到数据库（记录播放位置）
  Future<void> _savePlaybackState() async {
    if (_disposed) return;

    try {
      final currentIndex = await _getCurrentIndex?.call() ?? -1;
      final currentPlayable = await _getCurrentPlayable?.call();
      final currentPosition = await _getCurrentPosition?.call() ?? Duration.zero;

      if (currentIndex < 0 || currentPlayable == null) return;

      // 对于本地音频，保存到数据库
      if (currentPlayable is LocalPlayable) {
        final audio = currentPlayable.original;
        if (audio.id == null) {
          AppLogger.info('PlaybackStateManager', '音频ID为空，无法保存播放状态');
          return;
        }

        final db = PlaylistManager();
        await db.savePlaybackState(
          audioId: audio.id!,
          position: currentPosition.inSeconds,
          currentIndex: currentIndex,
        );
        AppLogger.info('PlaybackStateManager', '已保存本地音频播放状态: ${audio.title}');
      }
    } catch (e) {
      AppLogger.error('PlaybackStateManager', '保存播放状态失败: $e');
    }
  }

  /// 立即保存播放状态
  Future<void> saveNow() async {
    if (_disposed) return;
    await _savePlaybackState();
  }


  // ==================== 防抖保存 ====================

  /// 防抖保存（用于统一播放列表保存）
  ///
  /// [saveFn] 实际保存函数
  Future<void> debouncedSave(Future<void> Function() saveFn) async {
    // 取消之前的保存计划
    _saveDebounceTimer?.cancel();

    // 延迟执行保存
    _saveDebounceTimer = Timer(PlaybackConfig.saveDebounceDelay, () async {
      if (_disposed || _isSaving) return;

      _isSaving = true;
      try {
        await saveFn();
      } catch (e) {
        AppLogger.error('PlaybackStateManager', '防抖保存失败: $e');
      } finally {
        _isSaving = false;
      }
    });
  }

  /// 立即执行待处理的保存
  Future<void> flushPendingSave() async {
    _saveDebounceTimer?.cancel();

    if (_isSaving) {
      // 等待当前保存完成
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  // ==================== 通用状态持久化 ====================

  /// 保存通用键值对
  Future<void> saveString(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
      AppLogger.info('PlaybackStateManager', '保存 $key');
    } catch (e) {
      AppLogger.error('PlaybackStateManager', '保存 $key 失败: $e');
    }
  }

  /// 获取通用键值对
  Future<String?> getString(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (e) {
      AppLogger.error('PlaybackStateManager', '获取 $key 失败: $e');
      return null;
    }
  }

  /// 保存整数
  Future<void> saveInt(String key, int value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(key, value);
    } catch (e) {
      AppLogger.error('PlaybackStateManager', '保存 $key 失败: $e');
    }
  }

  /// 获取整数
  Future<int?> getInt(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(key);
    } catch (e) {
      AppLogger.error('PlaybackStateManager', '获取 $key 失败: $e');
      return null;
    }
  }

  /// 保存布尔值
  Future<void> saveBool(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e) {
      AppLogger.error('PlaybackStateManager', '保存 $key 失败: $e');
    }
  }

  /// 获取布尔值
  Future<bool?> getBool(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key);
    } catch (e) {
      AppLogger.error('PlaybackStateManager', '获取 $key 失败: $e');
      return null;
    }
  }
}
