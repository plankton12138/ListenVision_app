import 'package:flutter_test/flutter_test.dart';

/// 测试覆盖率配置
///
/// 目标：将测试覆盖率从当前水平提升到 70%
class TestConfig {
  /// 目标覆盖率百分比
  static const int coverageTarget = 70;

  /// 已测试的核心模块
  static const List<String> testedModules = [
    'providers/auth/auth_provider.dart',
    'providers/search/search_provider.dart',
    'providers/player/playback_controller.dart',
    'providers/favorites/playlist_provider.dart',
    'core/config/app_config.dart',
    'core/utils/debounce_utils.dart',
    'core/network/adaptive_network_manager.dart',
  ];

  /// 需要测试的实体类
  static const List<String> entitiesToTest = [
    'domain/entities/user.dart',
    'domain/entities/audio.dart',
    'domain/entities/download_task.dart',
  ];

  /// 需要测试的仓储
  static const List<String> repositoriesToTest = [
    'data/repositories/auth_repository_impl.dart',
    'data/repositories/playlist_repository_impl.dart',
  ];

  /// 测试运行命令
  static const String runAllTests = 'flutter test';
  static const String runCoverage = 'flutter test --coverage';

  /// 覆盖率报告生成
  ///
  /// 运行测试后，覆盖率报告生成在 coverage/lcov.info
  /// 可以使用以下工具查看：
  /// - genhtml (Linux/Mac)
  /// - VS Code 扩展 "Coverage Gutters"
  static const String coverageReportPath = 'coverage/lcov.info';
}

/// 测试辅助函数
class TestHelpers {
  /// 创建测试用的 User 实体
  static Map<String, dynamic> createTestUser({
    String id = 'test-user-id',
    String username = 'testuser',
    String email = 'test@example.com',
    String? token,
  }) {
    return {
      'id': id,
      'username': username,
      'email': email,
      if (token != null) 'token': token,
    };
  }

  /// 创建测试用的 Audio 实体
  static Map<String, dynamic> createTestAudio({
    String id = 'BV1xx411c7mD',
    String title = '测试歌曲',
    String? artist = '测试歌手',
    int? duration = 180,
    String? coverUrl,
  }) {
    return {
      'id': id,
      'title': title,
      if (artist != null) 'artist': artist,
      if (duration != null) 'duration': duration,
      if (coverUrl != null) 'cover_url': coverUrl,
    };
  }
}
