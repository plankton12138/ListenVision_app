import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:listenvision/data/database/app_database.dart';
import 'package:listenvision/data/database/track_dao.dart';
import 'package:listenvision/data/repositories/track_repository.dart';
import 'package:listenvision/models/cached_track.dart';
import 'package:listenvision/services/bilibili_api_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// v13 tracks 结构独立于生产建表代码，避免迁移测试复用被测实现。
const tracksV13 = '''CREATE TABLE tracks (
 id INTEGER PRIMARY KEY AUTOINCREMENT, source_id TEXT NOT NULL UNIQUE,
 source_type TEXT NOT NULL, title TEXT NOT NULL, artist TEXT, album TEXT,
 duration INTEGER, cover_url TEXT, cover_blob BLOB, bvid TEXT, uploader TEXT,
 uploader_mid TEXT, play_count INTEGER, local_path TEXT,
 is_downloaded INTEGER DEFAULT 0, download_status TEXT DEFAULT '',
 download_progress INTEGER DEFAULT 0, is_favorite INTEGER DEFAULT 0,
 local_play_count INTEGER DEFAULT 0, last_played_at TEXT, position INTEGER,
 playlist_id TEXT, added_at TEXT, updated_at TEXT, created_at TEXT
)''';

class StatusApi extends BilibiliApiService {
  Map<String, bool?> result = {};
  List<String> checked = [];
  @override
  Future<Map<String, bool?>> batchCheckVideosExist(
    List<String> bvids, {
    int concurrency = 5,
  }) async {
    checked = bvids;
    return result;
  }
}

Future<void> seedV13(String path, {bool partial = false}) async {
  final db = await databaseFactoryFfi.openDatabase(
    path,
    options: OpenDatabaseOptions(
      version: 13,
      onCreate: (db, _) async {
        await db.execute(tracksV13);
        if (partial) {
          await db.execute(
            "ALTER TABLE tracks ADD COLUMN online_status TEXT DEFAULT 'unchecked'",
          );
        }
        await db.execute(
          'CREATE TABLE playlists (id INTEGER PRIMARY KEY, name TEXT)',
        );
        await db.execute(
          'CREATE TABLE playlist_items (playlist_id INTEGER, track_id INTEGER, position INTEGER)',
        );
        await db.execute(
          'CREATE TABLE play_history (track_id INTEGER, position INTEGER)',
        );
        await db.execute(
          'CREATE TABLE download_tasks (track_id INTEGER, status TEXT)',
        );
        await db.insert('tracks', {
          'id': 7,
          'source_id': 'BVtest_p12',
          'bvid': 'BVtest',
          'source_type': 'bilibili',
          'title': '保留曲目',
          'is_favorite': 1,
          'local_path': '/music/test.m4a',
          'is_downloaded': 1,
        });
        await db.insert('playlists', {'id': 2, 'name': '保留歌单'});
        await db.insert('playlist_items', {
          'playlist_id': 2,
          'track_id': 7,
          'position': 3,
        });
        await db.insert('play_history', {'track_id': 7, 'position': 60});
        await db.insert('download_tasks', {'track_id': 7, 'status': 'paused'});
      },
    ),
  );
  await db.close();
}

void main() {
  sqfliteFfiInit();
  late Directory temp;
  late AppDatabase appDb;
  late String path;
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('listenvision-migration-');
    path = '${temp.path}/test.db';
    appDb = AppDatabase.forTesting(path: path, factory: databaseFactoryFfi);
  });
  tearDown(() async {
    await appDb.close();
    // 只清理本测试创建、位于系统临时目录下的隔离目录。
    expect(
      temp.absolute.path.startsWith(Directory.systemTemp.absolute.path),
      isTrue,
    );
    await temp.delete(recursive: true);
  });

  test('新建 v14 库可保存在线状态并更新分 P 曲目', () async {
    final dao = TrackDao(appDb);
    await dao.insertOrUpdate(
      CachedTrack(
        id: 0,
        sourceId: 'BVtest_p12',
        bvid: 'BVtest',
        sourceType: TrackSource.bilibili,
        title: '测试曲目',
      ),
    );
    await dao.updateOnlineStatus('BVtest_p12', OnlineStatus.available);
    final track = await dao.getBySourceId('BVtest_p12');
    expect(track!.onlineStatus, OnlineStatus.available);
    expect(track.lastOnlineCheckAt, isNotNull);
    expect(await (await appDb.database).getVersion(), 14);
  });

  test('v13 升级保留收藏、文件路径、歌单顺序、历史和下载记录', () async {
    await seedV13(path);
    final db = await appDb.database;
    final track = (await db.query('tracks')).single;
    expect(track['title'], '保留曲目');
    expect(track['is_favorite'], 1);
    expect(track['local_path'], '/music/test.m4a');
    expect(track['online_status'], 'unchecked');
    expect(track['last_online_check_at'], isNull);
    expect((await db.query('playlist_items')).single, {
      'playlist_id': 2,
      'track_id': 7,
      'position': 3,
    });
    expect((await db.query('playlists')).single['name'], '保留歌单');
    expect((await db.query('play_history')).single['position'], 60);
    expect((await db.query('download_tasks')).single['status'], 'paused');
    expect(await db.getVersion(), 14);
    final indexes = await db.rawQuery('PRAGMA index_list(tracks)');
    expect(
      indexes.any((index) => index['name'] == 'idx_tracks_online_status'),
      isTrue,
    );
  });

  test('已存在部分新字段时迁移可继续且不覆盖已有状态', () async {
    await seedV13(path, partial: true);
    final old = await databaseFactoryFfi.openDatabase(path);
    await old.update('tracks', {'online_status': 'unavailable'});
    await old.close();
    final db = await appDb.database;
    expect((await db.query('tracks')).single['online_status'], 'unavailable');
    expect(
      (await db.rawQuery(
        'PRAGMA table_info(tracks)',
      )).any((column) => column['name'] == 'last_online_check_at'),
      isTrue,
    );
  });

  test('并发初始化共用同一个 Future，关闭后可重新打开', () async {
    final first = appDb.database;
    final second = appDb.database;
    expect(identical(first, second), isTrue);
    expect(identical(await first, await second), isTrue);
    await appDb.close();
    expect(await (await appDb.database).getVersion(), 14);
  });

  test('迁移失败不会提交版本，修复结构后同一实例允许重试', () async {
    final bad = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 13,
        onCreate: (db, _) async {
          await db.execute(
            'CREATE TABLE tracks (id INTEGER, online_status TEXT)',
          );
          // 与索引同名的表使索引创建失败，用于验证 ALTER TABLE 的事务回滚。
          await db.execute(
            'CREATE TABLE idx_tracks_online_status (id INTEGER)',
          );
        },
      ),
    );
    await bad.close();
    await expectLater(appDb.database, throwsA(isA<DatabaseException>()));
    final repaired = await databaseFactoryFfi.openDatabase(path);
    expect(await repaired.getVersion(), 13);
    expect(
      (await repaired.rawQuery(
        'PRAGMA table_info(tracks)',
      )).any((column) => column['name'] == 'last_online_check_at'),
      isFalse,
    );
    await repaired.execute('DROP TABLE idx_tracks_online_status');
    await repaired.close();
    expect(await (await appDb.database).getVersion(), 14);
  });

  test('新建与 v13 升级后的 tracks 字段、默认值和约束一致', () async {
    await seedV13(path);
    final upgraded = await appDb.database;
    final fresh = AppDatabase.forTesting(
      path: '${temp.path}/fresh.db',
      factory: databaseFactoryFfi,
    );
    try {
      Map<String, Map<String, Object?>> columns(
        List<Map<String, Object?>> rows,
      ) => {
        for (final row in rows) row['name'] as String: {...row}..remove('cid'),
      };
      expect(
        columns(await upgraded.rawQuery('PRAGMA table_info(tracks)')),
        columns(
          await (await fresh.database).rawQuery('PRAGMA table_info(tracks)'),
        ),
      );
    } finally {
      await fresh.close();
    }
  });

  test('在线状态批量检查使用原始 BVID，按 source_id 更新分 P，并缓存明确检测结果', () async {
    final dao = TrackDao(appDb);
    for (final part in [12, 13]) {
      await dao.insertOrUpdate(
        CachedTrack(
          id: 0,
          sourceId: 'BVtest_p$part',
          bvid: 'BVtest',
          sourceType: TrackSource.bilibili,
          title: 'part $part',
          onlineStatus: OnlineStatus.unavailable,
        ),
      );
    }
    final api = StatusApi()..result = {'BVtest': null};
    final repository = TrackRepository(trackDao: dao, bilibiliApi: api);
    try {
      expect(
        await repository.batchCheckOnlineStatus(['BVtest_p12', 'BVtest_p13']),
        0,
      );
      expect(
        (await dao.getBySourceId('BVtest_p12'))!.onlineStatus,
        OnlineStatus.unavailable,
      );
      expect(
        (await dao.getBySourceId('BVtest_p12'))!.lastOnlineCheckAt,
        isNull,
      );
      api.result = {'BVtest': true};
      expect(
        await repository.batchCheckOnlineStatus(['BVtest_p12', 'BVtest_p13']),
        2,
      );
      expect(api.checked, ['BVtest']);
      expect(
        (await dao.getBySourceId('BVtest_p13'))!.onlineStatus,
        OnlineStatus.available,
      );
      api.checked = [];
      expect(
        await repository.batchCheckOnlineStatus(['BVtest_p12', 'BVtest_p13']),
        0,
      );
      expect(api.checked, isEmpty);
    } finally {
      repository.dispose();
    }
  });
}
