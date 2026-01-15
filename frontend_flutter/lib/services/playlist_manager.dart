import 'package:demo/models/audio_model.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class PlaylistManager {
  static final PlaylistManager _databaseHandler = PlaylistManager._internal();
  factory PlaylistManager() => _databaseHandler;
  static Database? _database;

  PlaylistManager._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // final directory = await getDatabasesPath();
    final directory = await getApplicationDocumentsDirectory();
    debugPrint('db path: $directory');
    final path = join(directory.path, 'playlist.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // playlists table creation
        await db.execute('''
          CREATE TABLE playlist_audios (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            filePath TEXT UNIQUE,
            title TEXT,
            artist TEXT,
            duration INTEGER,
            albumArt BLOB,
            url TEXT,
            isFavorite INTEGER
          )
        ''');
      },
    );
  }

  // audio table methods //
  Future<int> insertAudio(Audio audio) async {
    final db = await database;
    try {
      return await db.insert('playlist_audios', audio.toMap());
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        return -1;
      }
      rethrow;
    }
  }

  Future<List<Audio>> getAllAudios() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('playlist_audios', orderBy: 'id ASC');
    return List.generate(maps.length, (i) => Audio.fromMap(maps[i]));
  }

  Future<int> deleteAudio(int id) async {
    final db = await database;
    return await db.delete('playlist_audios', where: 'id = ?', whereArgs: [id]);
  }
}