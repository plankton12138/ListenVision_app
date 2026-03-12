import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/utils/app_logger.dart';
import '../../models/download_task.dart';
import 'subtitle_dao.dart';

/// 应用数据库 - 统一的本地数据存储
///
/// 这是本地优先架构的核心，统一管理：
/// - tracks: 音轨数据（在线和本地音频的统一实体）
/// - download_tasks: 下载任务
/// - play_history: 播放历史
class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('listen_vision.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    AppLogger.info('AppDatabase', '数据库路径: $path');

    final db = await openDatabase(
      path,
      version: 7,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );

    // 启用 WAL 模式（Write-Ahead Logging）
    // 允许读写并发，减少数据库锁定问题
    // 使用 rawQuery 而不是 execute 来执行 PRAGMA 语句
    await db.rawQuery('PRAGMA journal_mode=WAL');
    await db.rawQuery('PRAGMA synchronous=NORMAL');
    await db.rawQuery('PRAGMA cache_size=-64000');  // 64MB 缓存
    await db.rawQuery('PRAGMA temp_store=MEMORY');

    AppLogger.info('AppDatabase', 'WAL 模式已启用');

    return db;
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textNullableType = 'TEXT';
    const intType = 'INTEGER';
    const blobType = 'BLOB';

    // 创建 tracks 表 - 统一音频实体
    await db.execute('''
      CREATE TABLE tracks (
        id $idType,
        source_id $textType UNIQUE,
        source_type $textType,
        title $textType,
        artist $textNullableType,
        album $textNullableType,
        duration $intType,
        cover_url $textNullableType,
        cover_blob $blobType,
        bvid $textNullableType,
        uploader $textNullableType,
        uploader_mid $textNullableType,
        play_count $intType,
        local_path $textNullableType,
        is_downloaded $intType DEFAULT 0,
        download_status $textNullableType DEFAULT '',
        download_progress $intType DEFAULT 0,
        is_favorite $intType DEFAULT 0,
        local_play_count $intType DEFAULT 0,
        last_played_at $textNullableType,
        position $intType,
        playlist_id $textNullableType,
        added_at $textNullableType,
        updated_at $textNullableType,
        created_at $textNullableType,
        synced_at $textNullableType
      )
    ''');

    // 创建 download_tasks 表
    await db.execute('''
      CREATE TABLE download_tasks (
        id $idType,
        track_id $intType,
        url $textType,
        save_path $textType,
        original_url $textNullableType,
        bvid $textNullableType,
        title $textNullableType,
        artist $textNullableType,
        cover_url $textNullableType,
        status $textNullableType DEFAULT 'pending',
        downloaded_bytes $intType DEFAULT 0,
        total_bytes $intType DEFAULT 0,
        error_message $textNullableType,
        temp_file_path $textNullableType,
        etag $textNullableType,
        last_modified $textNullableType,
        request_id $textNullableType,
        last_heartbeat_at $textNullableType,
        last_progress_at $textNullableType,
        resume_token $textNullableType,
        retry_count $intType DEFAULT 0,
        last_error $textNullableType,
        user_paused $intType DEFAULT 0,
        created_at $textNullableType,
        updated_at $textNullableType,
        completed_at $textNullableType,
        FOREIGN KEY (track_id) REFERENCES tracks(id) ON DELETE CASCADE
      )
    ''');

    // 创建 play_history 表
    await db.execute('''
      CREATE TABLE play_history (
        id $idType,
        track_id $intType,
        source_id $textType,
        title $textType,
        artist $textNullableType,
        cover_url $textNullableType,
        played_at $textType,
        duration $intType,
        position $intType DEFAULT 0,
        is_completed $intType DEFAULT 0,
        FOREIGN KEY (track_id) REFERENCES tracks(id) ON DELETE SET NULL
      )
    ''');

    // 创建 sync_queue 表 - 网络同步重试队列
    await db.execute('''
      CREATE TABLE sync_queue (
        id $idType,
        type $textType NOT NULL,
        track_id $intType,
        bvid $textNullableType,
        playlist_id $textNullableType,
        data $textNullableType,
        status $textType DEFAULT 'pending',
        retry_count $intType DEFAULT 0,
        max_retries $intType DEFAULT 3,
        error_message $textNullableType,
        created_at $textType,
        updated_at $textNullableType,
        completed_at $textNullableType,
        FOREIGN KEY (track_id) REFERENCES tracks(id) ON DELETE CASCADE
      )
    ''');
    
    // 创建 subtitle_cache 表
    await db.execute(SubtitleDao.createTableSql);

    // 创建索引
    await db.execute('''
      CREATE INDEX idx_tracks_source_id ON tracks(source_id)
    ''');
    await db.execute('''
      CREATE INDEX idx_tracks_source_type ON tracks(source_type)
    ''');
    await db.execute('''
      CREATE INDEX idx_tracks_is_downloaded ON tracks(is_downloaded)
    ''');
    await db.execute('''
      CREATE INDEX idx_tracks_is_favorite ON tracks(is_favorite)
    ''');
    await db.execute('''
      CREATE INDEX idx_tracks_playlist ON tracks(playlist_id, position)
    ''');
    await db.execute('''
      CREATE INDEX idx_download_tasks_status ON download_tasks(status)
    ''');
    await db.execute('''
      CREATE INDEX idx_download_tasks_bvid ON download_tasks(bvid)
    ''');
    await db.execute('''
      CREATE INDEX idx_play_history_played_at ON play_history(played_at)
    ''');
    await db.execute('''
      CREATE INDEX idx_sync_queue_status ON sync_queue(status)
    ''');
    await db.execute('''
      CREATE INDEX idx_sync_queue_created_at ON sync_queue(created_at)
    ''');
    await db.execute('''
      CREATE INDEX idx_sync_queue_type ON sync_queue(type)
    ''');

    AppLogger.info('AppDatabase', '数据库表创建完成');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    AppLogger.info('AppDatabase', '数据库升级: $oldVersion -> $newVersion');

    // 版本 1 -> 2: 添加断点续传支持字段 + sync_queue 表
    if (oldVersion < 2) {
      await _upgradeToV2(db);
    }

    // 版本 2 -> 3: 添加 request_id 字段用于断线重连
    if (oldVersion < 3) {
      await _upgradeToV3(db);
    }

    // 版本 3 -> 4: 添加下载可靠性字段
    if (oldVersion < 4) {
      await _upgradeToV4(db);
    }

    if (oldVersion < 5) {
      await _upgradeToV5(db);
    }

    // 版本 5 -> 6: 添加独立的 playlists 和 playlist_items 表
    if (oldVersion < 6) {
      await _upgradeToV6(db);
    }

    // 版本 6 -> 7: 添加 subtitle_cache 表
    if (oldVersion < 7) {
      await _upgradeToV7(db);
    }

    // 未来版本升级在这里继续
  }

  /// 升级到版本 2：添加断点续传支持字段 + sync_queue 表
  Future<void> _upgradeToV2(Database db) async {
    AppLogger.info('AppDatabase', '升级数据库到 V2：添加断点续传字段 + sync_queue 表');

    // 1. 添加新字段到 download_tasks 表
    try {
      await db.execute('''
        ALTER TABLE download_tasks
        ADD COLUMN temp_file_path TEXT
      ''');
      AppLogger.info('AppDatabase', '添加 temp_file_path 字段成功');
    } catch (e) {
      // 字段可能已存在，忽略错误
      AppLogger.debug('AppDatabase', 'temp_file_path 字段可能已存在: $e');
    }

    try {
      await db.execute('''
        ALTER TABLE download_tasks
        ADD COLUMN etag TEXT
      ''');
      AppLogger.info('AppDatabase', '添加 etag 字段成功');
    } catch (e) {
      AppLogger.debug('AppDatabase', 'etag 字段可能已存在: $e');
    }

    try {
      await db.execute('''
        ALTER TABLE download_tasks
        ADD COLUMN last_modified TEXT
      ''');
      AppLogger.info('AppDatabase', '添加 last_modified 字段成功');
    } catch (e) {
      AppLogger.debug('AppDatabase', 'last_modified 字段可能已存在: $e');
    }

    // 2. 创建 sync_queue 表（如果不存在）
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sync_queue (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          type TEXT NOT NULL,
          track_id INTEGER,
          bvid TEXT,
          playlist_id TEXT,
          data TEXT,
          status TEXT DEFAULT 'pending',
          retry_count INTEGER DEFAULT 0,
          max_retries INTEGER DEFAULT 3,
          error_message TEXT,
          created_at TEXT,
          updated_at TEXT,
          completed_at TEXT,
          FOREIGN KEY (track_id) REFERENCES tracks(id) ON DELETE CASCADE
        )
      ''');
      AppLogger.info('AppDatabase', '创建 sync_queue 表成功');
    } catch (e) {
      AppLogger.error('AppDatabase', '创建 sync_queue 表失败: $e');
    }

    // 3. 创建 sync_queue 索引
    try {
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_sync_queue_status ON sync_queue(status)
      ''');
    } catch (e) {
      AppLogger.debug('AppDatabase', '创建 idx_sync_queue_status 索引失败: $e');
    }

    try {
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_sync_queue_created_at ON sync_queue(created_at)
      ''');
    } catch (e) {
      AppLogger.debug('AppDatabase', '创建 idx_sync_queue_created_at 索引失败: $e');
    }

    try {
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_sync_queue_type ON sync_queue(type)
      ''');
    } catch (e) {
      AppLogger.debug('AppDatabase', '创建 idx_sync_queue_type 索引失败: $e');
    }
  }

  /// 升级到版本 3：添加 request_id 字段用于断线重连
  Future<void> _upgradeToV3(Database db) async {
    AppLogger.info('AppDatabase', '升级数据库到 V3：添加 request_id 字段');

    try {
      await db.execute('''
        ALTER TABLE download_tasks
        ADD COLUMN request_id TEXT
      ''');
      AppLogger.info('AppDatabase', '添加 request_id 字段成功');
    } catch (e) {
      // 字段可能已存在，忽略错误
      AppLogger.debug('AppDatabase', 'request_id 字段可能已存在: $e');
    }
  }

  /// 升级到版本 4：添加下载可靠性字段
  Future<void> _upgradeToV4(Database db) async {
    AppLogger.info('AppDatabase', '升级数据库到 V4：添加下载可靠性字段');

    Future<void> addColumn(String sql, String columnName) async {
      try {
        await db.execute(sql);
        AppLogger.info('AppDatabase', '添加 $columnName 字段成功');
      } catch (e) {
        AppLogger.debug('AppDatabase', '$columnName 字段可能已存在: $e');
      }
    }

    await addColumn('''
      ALTER TABLE download_tasks
      ADD COLUMN last_heartbeat_at TEXT
    ''', 'last_heartbeat_at');

    await addColumn('''
      ALTER TABLE download_tasks
      ADD COLUMN last_progress_at TEXT
    ''', 'last_progress_at');

    await addColumn('''
      ALTER TABLE download_tasks
      ADD COLUMN resume_token TEXT
    ''', 'resume_token');

    await addColumn('''
      ALTER TABLE download_tasks
      ADD COLUMN retry_count INTEGER DEFAULT 0
    ''', 'retry_count');

    await addColumn('''
      ALTER TABLE download_tasks
      ADD COLUMN last_error TEXT
    ''', 'last_error');

    await addColumn('''
      ALTER TABLE download_tasks
      ADD COLUMN user_paused INTEGER DEFAULT 0
    ''', 'user_paused');
  }

  Future<void> _upgradeToV5(Database db) async {
    AppLogger.info('AppDatabase', '升级数据库到 V5：消除下载状态冗余');

    final orphanTasks = await db.rawQuery(
      'SELECT * FROM download_tasks WHERE track_id IS NULL',
    );

    for (final task in orphanTasks) {
      final bvid = task['bvid'] as String?;
      if (bvid == null) continue;

      int trackId;
      final existing = await db.query(
        'tracks',
        where: 'source_id = ?',
        whereArgs: [bvid],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        trackId = existing.first['id'] as int;
      } else {
        trackId = await db.insert('tracks', {
          'source_id': bvid,
          'source_type': 'bilibili',
          'title': task['title'] ?? bvid,
          'artist': task['artist'],
          'cover_url': task['cover_url'],
          'bvid': bvid,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      await db.update(
        'download_tasks',
        {'track_id': trackId},
        where: 'id = ?',
        whereArgs: [task['id']],
      );
    }

    await db.execute('''
      CREATE TABLE tracks_new (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        source_id TEXT NOT NULL UNIQUE,
        source_type TEXT NOT NULL,
        title TEXT NOT NULL,
        artist TEXT,
        album TEXT,
        duration INTEGER,
        cover_url TEXT,
        cover_blob BLOB,
        bvid TEXT,
        uploader TEXT,
        uploader_mid TEXT,
        play_count INTEGER,
        local_path TEXT,
        is_downloaded INTEGER DEFAULT 0,
        is_favorite INTEGER DEFAULT 0,
        local_play_count INTEGER DEFAULT 0,
        last_played_at TEXT,
        position INTEGER,
        playlist_id TEXT,
        added_at TEXT,
        updated_at TEXT,
        created_at TEXT,
        synced_at TEXT
      )
    ''');

    await db.execute('''
      INSERT INTO tracks_new 
      SELECT id, source_id, source_type, title, artist, album, duration,
             cover_url, cover_blob, bvid, uploader, uploader_mid, play_count,
             local_path, is_downloaded, is_favorite, local_play_count,
             last_played_at, position, playlist_id, added_at, updated_at,
             created_at, synced_at
      FROM tracks
    ''');

    await db.execute('DROP TABLE tracks');
    await db.execute('ALTER TABLE tracks_new RENAME TO tracks');

    await db.execute('CREATE INDEX idx_tracks_source_id ON tracks(source_id)');
    await db.execute('CREATE INDEX idx_tracks_source_type ON tracks(source_type)');
    await db.execute('CREATE INDEX idx_tracks_is_downloaded ON tracks(is_downloaded)');
    await db.execute('CREATE INDEX idx_tracks_is_favorite ON tracks(is_favorite)');
    await db.execute('CREATE INDEX idx_tracks_playlist ON tracks(playlist_id, position)');

    AppLogger.info('AppDatabase', 'V5 迁移完成');
  }

  /// 升级到版本 6：添加独立的 playlists 和 playlist_items 表
  Future<void> _upgradeToV6(Database db) async {
    AppLogger.info('AppDatabase', '升级数据库到 V6：添加 playlists 和 playlist_items 表');

    try {
      // 1. 创建 playlists 表
      await db.execute('''
        CREATE TABLE playlists (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          server_id TEXT,
          name TEXT NOT NULL,
          description TEXT,
          cover_url TEXT,
          cover_blob BLOB,
          type TEXT DEFAULT 'user',
          system_type TEXT,
          is_public INTEGER DEFAULT 0,
          play_count INTEGER DEFAULT 0,
          item_count INTEGER DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT,
          synced_at TEXT
        )
      ''');
      AppLogger.info('AppDatabase', '创建 playlists 表成功');

      // 2. 创建 playlist_items 表
      await db.execute('''
        CREATE TABLE playlist_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          playlist_id INTEGER NOT NULL,
          track_id INTEGER NOT NULL,
          position INTEGER NOT NULL DEFAULT 0,
          added_at TEXT NOT NULL,
          FOREIGN KEY (playlist_id) REFERENCES playlists(id) ON DELETE CASCADE,
          FOREIGN KEY (track_id) REFERENCES tracks(id) ON DELETE CASCADE,
          UNIQUE(playlist_id, track_id)
        )
      ''');
      AppLogger.info('AppDatabase', '创建 playlist_items 表成功');

      // 3. 创建索引
      await db.execute('CREATE INDEX idx_playlists_type ON playlists(type)');
      await db.execute('CREATE INDEX idx_playlists_system_type ON playlists(system_type)');
      await db.execute('CREATE INDEX idx_playlist_items_playlist ON playlist_items(playlist_id, position)');
      await db.execute('CREATE INDEX idx_playlist_items_track ON playlist_items(track_id)');
      AppLogger.info('AppDatabase', '创建索引成功');

      // 4. 迁移现有 tracks 表中的歌单关联数据
      final existingPlaylists = await db.rawQuery('''
        SELECT DISTINCT playlist_id FROM tracks WHERE playlist_id IS NOT NULL
      ''');

      AppLogger.info('AppDatabase', '发现 ${existingPlaylists.length} 个歌单需要迁移');

      for (final row in existingPlaylists) {
        final playlistId = row['playlist_id'] as String;

        // 为每个歌单创建记录
        final playlistDbId = await db.insert('playlists', {
          'server_id': playlistId,
          'name': '导入的歌单 $playlistId',
          'type': 'user',
          'created_at': DateTime.now().toIso8601String(),
        });

        // 查询该歌单下的所有歌曲
        final tracksInPlaylist = await db.query(
          'tracks',
          where: 'playlist_id = ?',
          whereArgs: [playlistId],
          orderBy: 'position ASC',
        );

        AppLogger.info('AppDatabase', '歌单 $playlistId 有 ${tracksInPlaylist.length} 首歌曲');

        // 创建歌单项关联记录
        for (var i = 0; i < tracksInPlaylist.length; i++) {
          final track = tracksInPlaylist[i];
          await db.insert('playlist_items', {
            'playlist_id': playlistDbId,
            'track_id': track['id'],
            'position': i,
            'added_at': track['added_at'] ?? DateTime.now().toIso8601String(),
          });
        }
      }

      // 5. 重建 tracks 表（移除 playlist_id 和 position 字段）
      AppLogger.info('AppDatabase', '重建 tracks 表（移除 playlist_id 和 position 字段）');

      await db.execute('''
        CREATE TABLE tracks_new (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          source_id TEXT NOT NULL UNIQUE,
          source_type TEXT NOT NULL,
          title TEXT NOT NULL,
          artist TEXT,
          album TEXT,
          duration INTEGER,
          cover_url TEXT,
          cover_blob BLOB,
          bvid TEXT,
          uploader TEXT,
          uploader_mid TEXT,
          play_count INTEGER,
          local_path TEXT,
          is_downloaded INTEGER DEFAULT 0,
          is_favorite INTEGER DEFAULT 0,
          local_play_count INTEGER DEFAULT 0,
          last_played_at TEXT,
          added_at TEXT,
          updated_at TEXT,
          created_at TEXT,
          synced_at TEXT
        )
      ''');

      // 复制数据到新表
      await db.execute('''
        INSERT INTO tracks_new
        SELECT id, source_id, source_type, title, artist, album, duration,
               cover_url, cover_blob, bvid, uploader, uploader_mid, play_count,
               local_path, is_downloaded, is_favorite, local_play_count,
               last_played_at, added_at, updated_at, created_at, synced_at
        FROM tracks
      ''');

      // 删除旧表并重命名
      await db.execute('DROP TABLE tracks');
      await db.execute('ALTER TABLE tracks_new RENAME TO tracks');

      // 重建索引
      await db.execute('CREATE INDEX idx_tracks_source_id ON tracks(source_id)');
      await db.execute('CREATE INDEX idx_tracks_source_type ON tracks(source_type)');
      await db.execute('CREATE INDEX idx_tracks_is_downloaded ON tracks(is_downloaded)');
      await db.execute('CREATE INDEX idx_tracks_is_favorite ON tracks(is_favorite)');

      AppLogger.info('AppDatabase', 'V6 迁移完成');
    } catch (e) {
      AppLogger.error('AppDatabase', 'V6 迁移失败: $e');
      rethrow;
    }
  }

  /// 升级到版本 7：添加字幕缓存表
  Future<void> _upgradeToV7(Database db) async {
    AppLogger.info('AppDatabase', '升级数据库到 V7：添加字幕缓存表');
    try {
      await db.execute(SubtitleDao.createTableSql);
      AppLogger.info('AppDatabase', '字幕缓存表创建成功');
    } catch (e) {
      AppLogger.error('AppDatabase', '字幕缓存表创建失败: $e');
      rethrow;
    }
  }

  // ==================== Tracks CRUD ====================

  /// 插入或更新 Track（UPSERT）
  Future<int> insertOrUpdateTrack(Map<String, dynamic> track) async {
    final db = await database;

    // 兼容旧字段：V6 迁移后 tracks 表可能不含 position/playlist_id
    track.remove('position');
    track.remove('playlist_id');

    try {
      // 先尝试更新
      if (track['source_id'] != null) {
        final existing = await db.query(
          'tracks',
          where: 'source_id = ?',
          whereArgs: [track['source_id']],
          limit: 1,
        );

        if (existing.isNotEmpty) {
          final id = existing.first['id'] as int;
          track['updated_at'] = DateTime.now().toIso8601String();
          await db.update(
            'tracks',
            track,
            where: 'id = ?',
            whereArgs: [id],
          );
          AppLogger.info('AppDatabase', '更新 Track: $id - ${track['title']}');
          return id;
        }
      }

      // 不存在则插入
      track['created_at'] = DateTime.now().toIso8601String();
      track['updated_at'] = DateTime.now().toIso8601String();
      final id = await db.insert('tracks', track);
      AppLogger.info('AppDatabase', '插入 Track: $id - ${track['title']}');
      return id;
    } catch (e) {
      AppLogger.error('AppDatabase', '插入/更新 Track 失败: $e');
      rethrow;
    }
  }

  /// 根据 ID 获取 Track
  Future<Map<String, dynamic>?> getTrackById(int id) async {
    final db = await database;
    final maps = await db.query(
      'tracks',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isNotEmpty ? maps.first : null;
  }

  /// 根据 source_id 获取 Track
  Future<Map<String, dynamic>?> getTrackBySourceId(String sourceId) async {
    final db = await database;
    final maps = await db.query(
      'tracks',
      where: 'source_id = ?',
      whereArgs: [sourceId],
      limit: 1,
    );
    return maps.isNotEmpty ? maps.first : null;
  }

  /// 获取所有 Tracks
  Future<List<Map<String, dynamic>>> getAllTracks() async {
    final db = await database;
    return await db.query(
      'tracks',
      orderBy: 'updated_at DESC',
    );
  }

  /// 获取已下载的 Tracks
  Future<List<Map<String, dynamic>>> getDownloadedTracks() async {
    final db = await database;
    return await db.query(
      'tracks',
      where: 'is_downloaded = ?',
      whereArgs: [1],
      orderBy: 'updated_at DESC',
    );
  }

  /// 获取收藏的 Tracks
  Future<List<Map<String, dynamic>>> getFavoriteTracks() async {
    final db = await database;
    return await db.query(
      'tracks',
      where: 'is_favorite = ?',
      whereArgs: [1],
      orderBy: 'updated_at DESC',
    );
  }

  /// 搜索 Tracks
  Future<List<Map<String, dynamic>>> searchTracks(String keyword) async {
    final db = await database;
    return await db.query(
      'tracks',
      where: 'title LIKE ? OR artist LIKE ?',
      whereArgs: ['%$keyword%', '%$keyword%'],
      orderBy: 'updated_at DESC',
    );
  }

  /// 更新 Track
  Future<void> updateTrack(int id, Map<String, dynamic> data) async {
    final db = await database;
    data['updated_at'] = DateTime.now().toIso8601String();
    await db.update(
      'tracks',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 切换收藏状态
  Future<void> toggleTrackFavorite(int id, bool isFavorite) async {
    await updateTrack(id, {'is_favorite': isFavorite ? 1 : 0});
  }

  /// 标记为已下载
  Future<void> markTrackAsDownloaded(int id, String localPath) async {
    await updateTrack(id, {
      'is_downloaded': 1,
      'local_path': localPath,
    });
  }

  /// 删除 Track
  Future<void> deleteTrack(int id) async {
    final db = await database;
    await db.delete(
      'tracks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== Download Tasks CRUD ====================

  /// 插入下载任务
  Future<int> insertDownloadTask(Map<String, dynamic> task) async {
    final db = await database;
    task['created_at'] = DateTime.now().toIso8601String();
    task['updated_at'] = DateTime.now().toIso8601String();
    final id = await db.insert('download_tasks', task);
    AppLogger.info('AppDatabase', '插入下载任务: $id');
    return id;
  }

  /// 根据 ID 获取下载任务
  Future<Map<String, dynamic>?> getDownloadTaskById(int id) async {
    final db = await database;
    final maps = await db.query(
      'download_tasks',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isNotEmpty ? maps.first : null;
  }

  /// 根据 BVID 获取下载任务
  Future<Map<String, dynamic>?> getDownloadTaskByBvid(String bvid) async {
    final db = await database;
    final maps = await db.query(
      'download_tasks',
      where: 'bvid = ?',
      whereArgs: [bvid],
      limit: 1,
    );
    return maps.isNotEmpty ? maps.first : null;
  }

  /// 获取所有下载任务
  Future<List<Map<String, dynamic>>> getAllDownloadTasks() async {
    final db = await database;
    return await db.query(
      'download_tasks',
      orderBy: 'created_at DESC',
    );
  }

  /// 根据状态获取下载任务
  Future<List<Map<String, dynamic>>> getDownloadTasksByStatus(
    DownloadStatus status,
  ) async {
    final db = await database;
    return await db.query(
      'download_tasks',
      where: 'status = ?',
      whereArgs: [status.value],
      orderBy: 'created_at DESC',
    );
  }

  /// 更新下载任务
  Future<void> updateDownloadTask(int id, Map<String, dynamic> data) async {
    final db = await database;
    data['updated_at'] = DateTime.now().toIso8601String();
    await db.update(
      'download_tasks',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 更新下载进度
  Future<void> updateDownloadProgress(
    int id,
    int downloadedBytes,
    int totalBytes,
  ) async {
    await updateDownloadTask(id, {
      'downloaded_bytes': downloadedBytes,
      'total_bytes': totalBytes,
    });
  }

  /// 更新下载状态
  Future<void> updateDownloadStatus(int id, DownloadStatus status) async {
    final data = <String, dynamic>{
      'status': status.value,
    };
    if (status == DownloadStatus.completed) {
      data['completed_at'] = DateTime.now().toIso8601String();
    }
    await updateDownloadTask(id, data);
  }

  /// 删除下载任务
  Future<void> deleteDownloadTask(int id) async {
    final db = await database;
    await db.delete(
      'download_tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 清空已完成的任务
  Future<void> clearCompletedDownloadTasks() async {
    final db = await database;
    await db.delete(
      'download_tasks',
      where: 'status = ?',
      whereArgs: [DownloadStatus.completed.value],
    );
  }

  // ==================== Play History CRUD ====================

  /// 插入播放历史
  Future<int> insertPlayHistory(Map<String, dynamic> history) async {
    final db = await database;
    history['played_at'] = DateTime.now().toIso8601String();
    return await db.insert('play_history', history);
  }

  /// 获取最近播放
  Future<List<Map<String, dynamic>>> getRecentPlayHistory({int limit = 20}) async {
    final db = await database;
    return await db.query(
      'play_history',
      orderBy: 'played_at DESC',
      limit: limit,
    );
  }

  /// 清空播放历史
  Future<void> clearPlayHistory() async {
    final db = await database;
    await db.delete('play_history');
  }

  // ==================== Sync Queue CRUD ====================

  /// 插入同步任务
  Future<int> insertSyncTask(Map<String, dynamic> task) async {
    final db = await database;
    task['created_at'] = DateTime.now().toIso8601String();
    task['updated_at'] = DateTime.now().toIso8601String();
    final id = await db.insert('sync_queue', task);
    AppLogger.info('AppDatabase', '插入同步任务: $id');
    return id;
  }

  /// 根据 ID 获取同步任务
  Future<Map<String, dynamic>?> getSyncTaskById(int id) async {
    final db = await database;
    final maps = await db.query(
      'sync_queue',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isNotEmpty ? maps.first : null;
  }

  /// 获取待同步的任务列表
  Future<List<Map<String, dynamic>>> getPendingSyncTasks({int limit = 50}) async {
    final db = await database;
    return await db.query(
      'sync_queue',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'created_at ASC',
      limit: limit,
    );
  }

  /// 获取失败但可重试的任务
  Future<List<Map<String, dynamic>>> getRetryableSyncTasks({int limit = 50}) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT * FROM sync_queue
      WHERE status = 'failed'
        AND retry_count < max_retries
      ORDER BY created_at ASC
      LIMIT ?
    ''', [limit]);
  }

  /// 更新同步任务
  Future<void> updateSyncTask(int id, Map<String, dynamic> data) async {
    final db = await database;
    data['updated_at'] = DateTime.now().toIso8601String();
    await db.update(
      'sync_queue',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 标记同步任务为同步中
  Future<void> markSyncTaskSyncing(int id) async {
    await updateSyncTask(id, {'status': 'syncing'});
  }

  /// 标记同步任务为成功
  Future<void> markSyncTaskSucceeded(int id) async {
    await updateSyncTask(id, {
      'status': 'succeeded',
      'completed_at': DateTime.now().toIso8601String(),
    });
  }

  /// 标记同步任务为失败
  Future<void> markSyncTaskFailed(int id, String errorMessage) async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE sync_queue
      SET status = 'failed',
          error_message = ?,
          retry_count = retry_count + 1,
          updated_at = ?
      WHERE id = ?
    ''', [errorMessage, DateTime.now().toIso8601String(), id]);
  }

  /// 删除同步任务
  Future<void> deleteSyncTask(int id) async {
    final db = await database;
    await db.delete(
      'sync_queue',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 清空已完成的同步任务
  Future<void> clearCompletedSyncTasks() async {
    final db = await database;
    await db.delete(
      'sync_queue',
      where: 'status = ?',
      whereArgs: ['succeeded'],
    );
  }

  /// 获取同步任务统计
  Future<Map<String, int>> getSyncStats() async {
    AppLogger.debug('AppDatabase', 'getSyncStats() 开始获取 database');
    final db = await database;
    AppLogger.debug('AppDatabase', 'getSyncStats() database 已获取，开始查询');

    final pendingResult = await db.rawQuery(
      "SELECT COUNT(*) FROM sync_queue WHERE status = 'pending'"
    );
    AppLogger.debug('AppDatabase', 'getSyncStats() pending 查询完成');

    final syncingResult = await db.rawQuery(
      "SELECT COUNT(*) FROM sync_queue WHERE status = 'syncing'"
    );
    AppLogger.debug('AppDatabase', 'getSyncStats() syncing 查询完成');

    final failedResult = await db.rawQuery(
      "SELECT COUNT(*) FROM sync_queue WHERE status = 'failed' AND retry_count < max_retries"
    );
    AppLogger.debug('AppDatabase', 'getSyncStats() failed 查询完成');

    final result = {
      'pending': Sqflite.firstIntValue(pendingResult) ?? 0,
      'syncing': Sqflite.firstIntValue(syncingResult) ?? 0,
      'retryable': Sqflite.firstIntValue(failedResult) ?? 0,
    };
    AppLogger.debug('AppDatabase', 'getSyncStats() 返回: $result');
    return result;
  }

  // ==================== 事务支持 ====================

  /// 执行事务（批量操作）
  ///
  /// 将多个数据库操作包装在一个事务中，避免多次获取锁导致的锁定问题。
  /// 所有操作要么全部成功，要么全部回滚。
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return await db.transaction(action);
  }

  /// 批量操作（非事务，但更高效）
  ///
  /// 适用于不需要原子性的批量操作。
  Future<List<Object?>> batch(List<Future<void> Function(Batch)> actions) async {
    final db = await database;
    final batch = db.batch();
    for (final action in actions) {
      await action(batch);
    }
    return await batch.commit(continueOnError: false);
  }

  // ==================== Utility ====================

  /// 关闭数据库
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// 删除数据库（用于测试或重置）
  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'listen_vision.db');
    await database;
    await close();
    await databaseFactory.deleteDatabase(path);
    AppLogger.info('AppDatabase', '数据库已删除');
  }

  /// 获取数据库统计信息
  Future<Map<String, int>> getStats() async {
    final db = await database;

    final trackResult = await db.rawQuery('SELECT COUNT(*) FROM tracks');
    final downloadResult = await db.rawQuery('SELECT COUNT(*) FROM download_tasks');
    final historyResult = await db.rawQuery('SELECT COUNT(*) FROM play_history');
    final syncResult = await db.rawQuery('SELECT COUNT(*) FROM sync_queue WHERE status != "succeeded"');

    return {
      'tracks': Sqflite.firstIntValue(trackResult) ?? 0,
      'download_tasks': Sqflite.firstIntValue(downloadResult) ?? 0,
      'play_history': Sqflite.firstIntValue(historyResult) ?? 0,
      'sync_queue': Sqflite.firstIntValue(syncResult) ?? 0,
    };
  }
}
