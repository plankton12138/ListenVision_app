import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:demo/models/audio_model.dart';
import 'package:demo/services/playlist_manager.dart';
import 'package:flutter/foundation.dart';

class AudioProvider extends ChangeNotifier {
  // AudioPlayer
  final _player = AudioPlayer();

  // playlists
  List<Audio> _playlist = [];
  int _currentIndex = -1;


  // listenable variables
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  String _title = "Unknown title";
  String _artist = "Unknown artist";
  Uint8List? _albumArt;

  // Streams
  late StreamSubscription _positonSub;
  late StreamSubscription _durationSub;
  late StreamSubscription _stateSub;

  // Initializer
  AudioProvider() {
    _loadPlaylist();
    _initListeners();

  }

  void _initListeners() {
    _positonSub = _player.onPositionChanged.listen(_updatePosition);
    _durationSub = _player.onDurationChanged.listen(_updateDuration);
    _stateSub = _player.onPlayerStateChanged.listen(_updatePlayState);

    _player.onPlayerComplete.listen((_){
      playNext();
    });
  }

  Future<void> _loadPlaylist() async {
    final db = PlaylistManager();
    _playlist = await db.getAllAudios();
    notifyListeners();
  }

  // Updates
  void _updatePosition(Duration p) {
    _position = p;
    notifyListeners();
  }

  void _updateDuration(Duration d) {
    _duration = d;
    notifyListeners();
  }

  void _updatePlayState(PlayerState state) {
    _isPlaying = state == PlayerState.playing;
    notifyListeners();
  }

  // Getters
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isPlaying => _isPlaying;
  String get title => _title;
  String get artist => _artist;
  Uint8List? get albumArt => _albumArt;
  List<Audio> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  Audio? get currentAudio => _currentIndex >= 0? _playlist[_currentIndex] : null;

  // METHODS //
  // load audio file and set metadata
  Future<void> loadAudio(String filePath) async {
    try {
      debugPrint('【loadAudio】Starting to load audio: $filePath');

      // parse metadata using audio_metadata_reader
      late AudioMetadata metadata;
      Uint8List? coverArt;
      try {
        final audioFile = File(filePath);
        debugPrint('【loadAudio】File exists: ${audioFile.existsSync()}, size: ${audioFile.lengthSync()} bytes');

        metadata = readMetadata(audioFile, getImage: true);

        debugPrint('【loadAudio】metadata: title=${metadata.title}, artist=${metadata.artist}, album=${metadata.album}');
        debugPrint('【loadAudio】pictures count: ${metadata.pictures.length}');

        // Get cover art
        if (metadata.pictures.isNotEmpty) {
          coverArt = metadata.pictures.first.bytes;
          debugPrint('【loadAudio】cover art: ${coverArt?.length ?? 0} bytes');
        }
      } catch (e, s) {
        debugPrint('【loadAudio】readMetadata error: $e');
        debugPrint('【loadAudio】stack trace: $s');
        // Use empty metadata on error
        metadata = AudioMetadata(file: File(filePath))
          ..title = "Unknown title"
          ..artist = "Unknown artist"
          ..album = ""
          ..pictures = [];
        coverArt = null;
      }

      // update state
      _title = metadata.title ?? "Unknown title";
      _artist = metadata.artist ?? "Unknown artist";
      _albumArt = coverArt;
      
      // set audio source
      _position = Duration.zero;
      _duration = Duration.zero;
      await _player.setSource(DeviceFileSource(filePath));
      await _player.resume();

      final existingIndex = _playlist.indexWhere((a) => a.filePath == filePath);
      if (existingIndex != -1) {
        _playlist[existingIndex] = _playlist[existingIndex].copyWith(
          title: _title,
          artist: _artist,
          url: metadata.album ?? "",
          albumArt: _albumArt,
        );
        _currentIndex = existingIndex;
      } else {
        final audio = Audio(
          filePath: filePath,
          title: _title,
          artist: _artist,
          duration: 0,
          albumArt: _albumArt,
          url: metadata.album ?? "",
        );
        // update current audio
        await addToPlaylist(audio);
        _currentIndex = _playlist.length - 1;
      }
      notifyListeners();
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }

  // play/pause audio
  void togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _player.pause();
      } else {
        if (_player.state == PlayerState.completed) {
          await _player.seek(Duration.zero);
        }
        await _player.resume();
      }
    } catch (e) {
      rethrow;
    }
  }

  // seek to a specific position
  void seek(Duration position) => _player.seek(position);

  // add audio to playlist
  Future<void> addToPlaylist(Audio audio) async {
    final db = PlaylistManager();
    final id = await db.insertAudio(audio);
    if (id != -1) {
      await _loadPlaylist();
      notifyListeners();
    }
  }

  // remove audio from playlist
  Future<void> removeFromPlaylist(int id) async {
    final db = PlaylistManager();
    await db.deleteAudio(id);
    _playlist.removeWhere((audio) => audio.id == id);
    notifyListeners();
  }

  // play exact audio
  Future<void> playAudio(int index) async {
    if (index < 0 || index >= _playlist.length) return;

    await _player.stop();
    final audio = _playlist[index];
    await loadAudio(audio.filePath);

    _currentIndex = _playlist.indexWhere((a) => a.filePath == audio.filePath);
    notifyListeners();
  }

  // play next audio
  Future<void> playNext() async {
    if (_playlist.isEmpty) return;
    final nextIndex = (_currentIndex + 1) % _playlist.length;
    await playAudio(nextIndex);
  }

  // play previous audio
  Future<void> playPrevious() async {
    if (_playlist.isEmpty) return;
    final previousIndex = (_currentIndex - 1) % _playlist.length;
    await playAudio(previousIndex);
  }

  // Favorites //




  @override
  void dispose() {
    _positonSub.cancel();
    _durationSub.cancel();
    _stateSub.cancel();
    _player.dispose();
    super.dispose();
  }


}
