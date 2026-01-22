import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/dio_provider.dart';
import '../network/api_client.dart';
import '../../data/datasources/local/auth_local_datasource.dart';
import '../../data/datasources/local/download_local_datasource.dart';
import '../../data/datasources/remote/auth_remote_datasource.dart';
import '../../data/datasources/remote/bilibili_remote_datasource.dart';
import '../../data/datasources/remote/playlist_remote_datasource.dart';
import '../../data/datasources/remote/play_history_remote_datasource.dart';
import '../../data/datasources/remote/search_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/bilibili_repository_impl.dart';
import '../../data/repositories/download_repository_impl.dart';
import '../../data/repositories/playlist_repository_impl.dart';
import '../../data/repositories/play_history_repository_impl.dart';
import '../../data/repositories/search_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/bilibili_repository.dart';
import '../../domain/repositories/download_repository.dart';
import '../../domain/repositories/playlist_repository.dart';
import '../../domain/repositories/play_history_repository.dart';
import '../../domain/repositories/search_repository.dart';

/// 服务工厂
///
/// 负责创建和提供应用中的所有 Repository 实例
/// 使用依赖注入模式，解耦组件间的依赖关系
class ServiceFactory {
  /// 单例实例
  static ServiceFactory? _instance;

  /// 共享依赖
  late final Dio _dio;
  late final FlutterSecureStorage _secureStorage;
  late final SharedPreferences _prefs;

  /// 私有构造函数
  ServiceFactory._internal({
    required Dio dio,
    required FlutterSecureStorage secureStorage,
    required SharedPreferences prefs,
  })  : _dio = dio,
        _secureStorage = secureStorage,
        _prefs = prefs;

  /// 获取单例
  static ServiceFactory get instance => _instance!;

  /// 初始化（必须在 main() 中调用）
  static Future<ServiceFactory> init() async {
    if (_instance != null) return _instance!;

    final prefs = await SharedPreferences.getInstance();
    final secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
    );

    _instance = ServiceFactory._internal(
      dio: DioProvider.instance.dio,
      secureStorage: secureStorage,
      prefs: prefs,
    );

    return _instance!;
  }

  /// 获取 Dio 实例
  Dio get dio => _dio;

  /// 获取 SharedPreferences
  SharedPreferences get prefs => _prefs;

  /// 获取 FlutterSecureStorage
  FlutterSecureStorage get secureStorage => _secureStorage;

  /// 获取 ApiClient
  ApiClient get apiClient => ApiClient(dio: _dio);

  // ==================== Local DataSources ====================

  /// 创建 AuthLocalDataSource
  AuthLocalDataSource createAuthLocalDataSource() {
    return AuthLocalDataSource(
      secureStorage: _secureStorage,
      prefs: _prefs,
    );
  }

  /// 创建 DownloadLocalDataSource
  DownloadLocalDatasource createDownloadLocalDatasource() {
    return DownloadLocalDatasource();
  }

  // ==================== Remote DataSources ====================

  /// 创建 AuthRemoteDataSource
  AuthRemoteDataSource createAuthRemoteDataSource() {
    return AuthRemoteDataSource(dio: _dio);
  }

  /// 创建 BilibiliRemoteDataSource
  BilibiliRemoteDataSource createBilibiliRemoteDataSource() {
    return BilibiliRemoteDataSource(dio: _dio);
  }

  /// 创建 PlaylistRemoteDataSource
  PlaylistRemoteDataSource createPlaylistRemoteDataSource() {
    return PlaylistRemoteDataSource(dio: _dio);
  }

  /// 创建 PlayHistoryRemoteDataSource
  PlayHistoryRemoteDataSource createPlayHistoryRemoteDataSource() {
    return PlayHistoryRemoteDataSource(dio: _dio);
  }

  /// 创建 SearchRemoteDataSource
  SearchRemoteDataSource createSearchRemoteDataSource() {
    return SearchRemoteDataSource(dio: _dio);
  }

  /// 创建 DownloadRepository
  DownloadRepository createDownloadRepository() {
    return DownloadRepositoryImpl(
      localDatasource: createDownloadLocalDatasource(),
    );
  }

  // ==================== Repositories ====================

  /// 创建 AuthRepository
  AuthRepository createAuthRepository() {
    return AuthRepositoryImpl(
      remoteDataSource: createAuthRemoteDataSource(),
      localDataSource: createAuthLocalDataSource(),
    );
  }

  /// 创建 BilibiliRepository
  BilibiliRepository createBilibiliRepository() {
    return BilibiliRepositoryImpl(
      remoteDataSource: createBilibiliRemoteDataSource(),
    );
  }

  /// 创建 PlaylistRepository
  PlaylistRepository createPlaylistRepository() {
    return PlaylistRepositoryImpl(
      remoteDataSource: createPlaylistRemoteDataSource(),
    );
  }

  /// 创建 PlayHistoryRepository
  PlayHistoryRepository createPlayHistoryRepository() {
    return PlayHistoryRepositoryImpl(
      remoteDataSource: createPlayHistoryRemoteDataSource(),
    );
  }

  /// 创建 SearchRepository
  SearchRepository createSearchRepository() {
    return SearchRepositoryImpl(
      remoteDataSource: createSearchRemoteDataSource(),
    );
  }

  // ==================== 快捷访问 ====================

  /// AuthRepository 快捷访问
  AuthRepository get authRepository => createAuthRepository();

  /// BilibiliRepository 快捷访问
  BilibiliRepository get bilibiliRepository => createBilibiliRepository();

  /// DownloadRepository 快捷访问
  DownloadRepository get downloadRepository => createDownloadRepository();

  /// PlaylistRepository 快捷访问
  PlaylistRepository get playlistRepository => createPlaylistRepository();

  /// PlayHistoryRepository 快捷访问
  PlayHistoryRepository get playHistoryRepository => createPlayHistoryRepository();

  /// SearchRepository 快捷访问
  SearchRepository get searchRepository => createSearchRepository();
}
