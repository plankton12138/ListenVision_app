import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/download_task.dart';

/// 下载仓储接口
///
/// Clean Architecture 中的 Repository 接口
/// 管理音频下载任务
abstract class DownloadRepository {
  // ==================== 任务管理 ====================

  /// 获取所有下载任务
  Future<Either<Failure, List<DownloadTask>>> getAllTasks();

  /// 获取单个任务
  Future<Either<Failure, DownloadTask?>> getTask(int id);

  /// 获取指定状态的任务
  Future<Either<Failure, List<DownloadTask>>> getTasksByStatus(DownloadStatus status);

  /// 创建下载任务
  Future<Either<Failure, int>> createTask({
    required String url,
    required String savePath,
    String? originalUrl,
    String? title,
    String? artist,
    String? coverUrl,
    String? bvid,
  });

  /// 更新任务
  Future<Either<Failure, bool>> updateTask(int id, Map<String, dynamic> data);

  /// 删除任务
  Future<Either<Failure, bool>> deleteTask(int id);

  /// 清空已完成任务
  Future<Either<Failure, int>> clearCompletedTasks();

  // ==================== 状态管理 ====================

  /// 更新任务状态
  Future<Either<Failure, bool>> updateStatus(int id, DownloadStatus status);

  /// 更新下载进度
  Future<Either<Failure, bool>> updateProgress(int id, int downloadedBytes, int totalBytes);

  /// 设置错误信息
  Future<Either<Failure, bool>> setErrorMessage(int id, String errorMessage);

  // ==================== 查询方法 ====================

  /// 检查 BVID 是否已存在
  Future<Either<Failure, bool>> existsByBvid(String bvid);

  /// 获取进行中的任务数量
  Future<Either<Failure, int>> getActiveTaskCount();
}
