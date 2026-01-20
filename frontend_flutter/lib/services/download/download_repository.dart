import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

/// 下载状态枚举
enum DownloadStatus {
  pending,
  downloading,
  paused,
  completed,
  failed,
}

/// 下载状态扩展方法
extension DownloadStatusExtension on DownloadStatus {
  String get value {
    switch (this) {
      case DownloadStatus.pending:
        return 'pending';
      case DownloadStatus.downloading:
        return 'downloading';
      case DownloadStatus.paused:
        return 'paused';
      case DownloadStatus.completed:
        return 'completed';
      case DownloadStatus.failed:
        return 'failed';
    }
  }

  static DownloadStatus fromString(String? value) {
    switch (value) {
      case 'pending':
        return DownloadStatus.pending;
      case 'downloading':
        return DownloadStatus.downloading;
      case 'paused':
        return DownloadStatus.paused;
      case 'completed':
        return DownloadStatus.completed;
      case 'failed':
        return DownloadStatus.failed;
      default:
        return DownloadStatus.pending;
    }
  }
}

/// 下载任务数据仓库
///
/// 职责：
/// - 数据库初始化和迁移
/// - 纯数据库 CRUD 操作
/// - 不包含业务逻辑
class DownloadRepository {
  Database? _database;
  bool _isInitialized = false;

  /// 获取数据库实例
  Future<Database> get database async {
    if (_database != null) return _database!;
    await init();
    return _database!;
  }

  /// 初始化数据库
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final dbPath = path.join(directory.path, 'downloads.db');

      debugPrint('【DownloadRepository】初始化数据库: $dbPath');

      _database = await openDatabase(
        dbPath,
        version: 2,
        onCreate: _createDatabase,
        onUpgrade: _upgradeDatabase,
      );

      _isInitialized = true;
      debugPrint('【DownloadRepository】数据库初始化完成');
    } catch (e) {
      debugPrint('【DownloadRepository】数据库初始化失败: $e');
      rethrow;
    }
  }

  /// 创建数据库表（首次安装）
  Future<void> _createDatabase(Database db, int version) async {
    // 创建新结构的 downloads 表
    await db.execute('''
      CREATE TABLE downloads(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        url TEXT,
        save_path TEXT,
        downloaded_bytes INTEGER DEFAULT 0,
        total_bytes INTEGER DEFAULT 0,
        status TEXT CHECK(status IN ('pending', 'downloading', 'paused', 'completed', 'failed')) DEFAULT 'pending',
        original_url TEXT,
        title TEXT,
        artist TEXT,
        cover_url TEXT,
        bvid TEXT,
        error_message TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        updated_at TEXT DEFAULT (datetime('now'))
      )
    ''');

    // 创建索引
    await db.execute('CREATE INDEX idx_downloads_status ON downloads(status)');
    await db.execute('CREATE INDEX idx_downloads_created_at ON downloads(created_at DESC)');

    debugPrint('【DownloadRepository】数据库表创建完成');
  }

  /// 升级数据库（从旧版本迁移）
  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    debugPrint('【DownloadRepository】数据库升级: v$oldVersion -> v$newVersion');

    if (oldVersion < 2) {
      // 版本 1 -> 2: 完全重建表以支持新结构
      // 旧表使用 camelCase (savePath, downloadedBytes 等)
      // 新表使用 snake_case (save_path, downloaded_bytes 等)

      // 1. 备份旧数据
      final oldData = await db.query('downloads');
      debugPrint('【DownloadRepository】备份 ${oldData.length} 条旧数据');

      // 2. 删除旧表
      await db.execute('DROP TABLE IF EXISTS downloads');

      // 3. 创建新表
      await _createDatabase(db, 2);

      // 4. 迁移旧数据（如果需要保留）
      for (var oldTaskMap in oldData) {
        // sqflite 返回的 Map 是只读的，需要创建可写副本
        final oldTask = Map<String, dynamic>.from(oldTaskMap);
        try {
          // 旧字段映射到新字段
          final isPaused = oldTask['isPaused'] as int? ?? 0;
          final downloaded = oldTask['downloadedBytes'] as int? ?? 0;
          final total = oldTask['totalBytes'] as int? ?? 0;

          String status;
          if (total > 0 && downloaded >= total) {
            status = 'completed';
          } else if (isPaused == 1) {
            status = 'paused';
          } else if (downloaded > 0) {
            status = 'downloading';
          } else {
            status = 'pending';
          }

          await db.insert('downloads', {
            'url': oldTask['url'],
            'save_path': oldTask['savePath'],
            'downloaded_bytes': downloaded,
            'total_bytes': total,
            'status': status,
            'original_url': oldTask['originalUrl'],
            'title': oldTask['title'],
            'created_at': oldTask['created_at'],
            'updated_at': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          debugPrint('【DownloadRepository】迁移任务失败: $e');
        }
      }

      debugPrint('【DownloadRepository】数据库迁移完成');
    }
  }

  // ==================== CRUD 操作 ====================

  /// 插入下载任务
  Future<int> insertTask(Map<String, dynamic> task) async {
    final db = await database;
    try {
      final id = await db.insert('downloads', {
        ...task,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      debugPrint('【DownloadRepository】插入任务: $id');
      return id;
    } catch (e) {
      debugPrint('【DownloadRepository】插入任务失败: $e');
      rethrow;
    }
  }

  /// 获取所有下载任务
  Future<List<Map<String, dynamic>>> getAllTasks() async {
    final db = await database;
    try {
      final tasks = await db.query(
        'downloads',
        orderBy: 'created_at DESC',
      );
      debugPrint('【DownloadRepository】获取任务列表: ${tasks.length} 条');
      return tasks;
    } catch (e) {
      debugPrint('【DownloadRepository】获取任务列表失败: $e');
      return [];
    }
  }

  /// 获取单个任务
  Future<Map<String, dynamic>?> getTask(int id) async {
    final db = await database;
    try {
      final result = await db.query(
        'downloads',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      debugPrint('【DownloadRepository】获取任务失败: $e');
      return null;
    }
  }

  /// 更新任务
  Future<bool> updateTask(int id, Map<String, dynamic> data) async {
    final db = await database;
    try {
      final count = await db.update(
        'downloads',
        {
          ...data,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      return count > 0;
    } catch (e) {
      debugPrint('【DownloadRepository】更新任务失败: $e');
      return false;
    }
  }

  /// 删除任务
  Future<bool> deleteTask(int id) async {
    final db = await database;
    try {
      final count = await db.delete(
        'downloads',
        where: 'id = ?',
        whereArgs: [id],
      );
      debugPrint('【DownloadRepository】删除任务: $id');
      return count > 0;
    } catch (e) {
      debugPrint('【DownloadRepository】删除任务失败: $e');
      return false;
    }
  }

  /// 清空已完成任务
  Future<int> clearCompletedTasks() async {
    final db = await database;
    try {
      final count = await db.delete(
        'downloads',
        where: 'status = ?',
        whereArgs: ['completed'],
      );
      debugPrint('【DownloadRepository】清空已完成任务: $count 条');
      return count;
    } catch (e) {
      debugPrint('【DownloadRepository】清空已完成任务失败: $e');
      return 0;
    }
  }

  // ==================== 状态更新 ====================

  /// 更新任务状态
  Future<bool> updateStatus(int id, DownloadStatus status) async {
    return await updateTask(id, {'status': status.value});
  }

  /// 更新下载进度
  Future<bool> updateProgress(int id, int downloadedBytes, int totalBytes) async {
    return await updateTask(id, {
      'downloaded_bytes': downloadedBytes,
      'total_bytes': totalBytes,
    });
  }

  /// 设置错误信息
  Future<bool> setErrorMessage(int id, String errorMessage) async {
    return await updateTask(id, {
      'error_message': errorMessage,
      'status': DownloadStatus.failed.value,
    });
  }

  // ==================== 查询方法 ====================

  /// 获取指定状态的任务
  Future<List<Map<String, dynamic>>> getTasksByStatus(DownloadStatus status) async {
    final db = await database;
    try {
      final tasks = await db.query(
        'downloads',
        where: 'status = ?',
        whereArgs: [status.value],
        orderBy: 'created_at DESC',
      );
      return tasks;
    } catch (e) {
      debugPrint('【DownloadRepository】按状态获取任务失败: $e');
      return [];
    }
  }

  /// 获取进行中的任务数量
  Future<int> getActiveTaskCount() async {
    final db = await database;
    try {
      final result = await db.rawQuery('''
        SELECT COUNT(*) as count
        FROM downloads
        WHERE status IN ('pending', 'downloading')
      ''');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      debugPrint('【DownloadRepository】获取活跃任务数失败: $e');
      return 0;
    }
  }

  /// 检查 BVID 是否已存在
  Future<bool> existsByBvid(String bvid) async {
    final db = await database;
    try {
      final result = await db.query(
        'downloads',
        where: 'bvid = ?',
        whereArgs: [bvid],
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (e) {
      debugPrint('【DownloadRepository】检查 BVID 失败: $e');
      return false;
    }
  }
}
