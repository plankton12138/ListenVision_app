import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:demo/models/audio_model.dart';

/// 音频播放状态管理
///
/// 职责：
/// 1. 核心播放控制（播放/暂停/下一曲/上一曲）
/// 2. AudioPlayer 生命周期管理（事件监听）
/// 3. 播放状态维护（当前播放/位置/时长）
class AudioPlayerProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();

  bool _isPlaying = false;

  Duration _position = Duration.zero;

  Duration _duration = Duration.zero;

  int _currentIndex = -1;

  List<Audio> _playlist = [];

  AudioPlayerProvider() {
    _initListeners();
  }

  void _initListeners() {
    _player.onPositionChanged.listen(_updatePosition);
    _player.onDurationChanged.listen(_updateDuration);
    _player.onPlayerStateChanged.listen(_updatePlayState);
    _player.onPlayerComplete.listen((_) => playNext());
  }

  Future<void> play() async {
    if (_currentIndex < 0 || _playlist.isEmpty) return;

    try {
      await _player.play(UrlSource(_playlist[_currentIndex].url ?? ''));
      _isPlaying = true;
      notifyListeners();
      debugPrint('【AudioPlayerProvider】播放: ${_playlist[_currentIndex].title}');
    } catch (e) {
      debugPrint('【AudioPlayerProvider】播放失败: $e');
    }
  }

  Future<void> pause() async {
    try {
      await _player.pause();
      _isPlaying = false;
      notifyListeners();
      debugPrint('【AudioPlayerProvider】暂停');
    } catch (e) {
      debugPrint('【AudioPlayerProvider】暂停失败: $e');
    }
  }

  void playNext() {
    if (_currentIndex < _playlist.length - 1) {
      _currentIndex++;
      notifyListeners();
      debugPrint('【AudioPlayerProvider】下一曲: ${_playlist[_currentIndex].title}');
    }
  }

  void playPrevious() {
    if (_currentIndex > 0) {
      _currentIndex--;
      notifyListeners();
      debugPrint('【AudioPlayerProvider】上一曲: ${_playlist[_currentIndex].title}');
    }
  }

  void seekToIndex(int index) {
    if (index >= 0 && index < _playlist.length) {
      _currentIndex = index;
      notifyListeners();
      debugPrint('【AudioPlayerProvider】跳转到: ${_playlist[index].title}');
    }
  }

  void setPlaylist(List<Audio> playlist, {int initialIndex = -1}) {
    _playlist = playlist;
    _currentIndex = initialIndex;
    notifyListeners();
    debugPrint('【AudioPlayerProvider】设置播放列表，长度: ${playlist.length}');
  }

  void addToPlaylist(Audio audio) {
    _playlist.add(audio);
    notifyListeners();
    debugPrint('【AudioPlayerProvider】添加音频: ${audio.title}');
  }

  void removeFromPlaylist(Audio audio) {
    _playlist.remove(audio);
    if (_currentIndex >= _playlist.length) {
      _currentIndex = _playlist.length - 1;
    }
    notifyListeners();
    debugPrint('【AudioPlayerProvider】移除音频: ${audio.title}');
  }

  void clearPlaylist() {
    _playlist.clear();
    _currentIndex = -1;
    notifyListeners();
    debugPrint('【AudioPlayerProvider】清空播放列表');
  }

  void _updatePlayState(PlayerState state) {
    _isPlaying = state == PlayerState.playing;
    notifyListeners();
  }

  void _updatePosition(Duration position) {
    _position = position;
    notifyListeners();
  }

  void _updateDuration(Duration duration) {
    _duration = duration;
    notifyListeners();
  }

  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  int get currentIndex => _currentIndex;
  List<Audio> get playlist => _playlist;

  Audio? get currentAudio =>
      _currentIndex >= 0 && _currentIndex < _playlist.length
          ? _playlist[_currentIndex]
          : null;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}