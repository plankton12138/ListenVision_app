import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listenvision/core/storage/shared_storage_service.dart';
import 'package:listenvision/models/audio.dart';
import 'package:listenvision/models/online_playable.dart';
import 'package:listenvision/models/play_queue.dart';
import 'package:listenvision/presentation/viewmodels/player/queue_viewmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 播放队列顺序测试
///
/// 覆盖"正在播放的音乐显示在播放列表第一项"的队列排序规则：
/// 新增并立即播放的音频插入列表首位，普通添加仍追加到末尾。
OnlinePlayable _track(String id, String title) =>
    OnlinePlayable.withProxyUrl(Audio(id: id, title: title));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedStorageService.init();
  });

  /// 创建容器并写入初始队列
  Future<ProviderContainer> createContainer(
    List<OnlinePlayable> tracks, {
    int currentIndex = 0,
  }) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // 等待 build() 中排队的恢复任务执行，避免覆盖测试初始状态
    container.read(queueViewModelProvider);
    await Future<void>.delayed(Duration.zero);

    container.read(queueViewModelProvider.notifier).state = QueueState(
      queue: PlayQueue(tracks: tracks, currentIndex: currentIndex),
    );
    return container;
  }

  List<String> trackIds(ProviderContainer container) => container
      .read(queueViewModelProvider)
      .queue!
      .tracks
      .map((playable) => playable.id)
      .toList();

  group('QueueViewModel 队列排序', () {
    test('新增并立即播放的音频应位于播放列表第一项', () async {
      // Arrange
      final container = await createContainer([
        _track('a', '旧歌A'),
        _track('b', '旧歌B'),
      ], currentIndex: 1);

      // Act
      await container
          .read(queueViewModelProvider.notifier)
          .add(_track('c', '新歌C'), playImmediately: true);

      // Assert
      expect(trackIds(container), ['c', 'a', 'b']);
      expect(container.read(queueViewModelProvider).queue!.currentIndex, 0);
    });

    test('立即播放已存在的音频时应移到播放列表第一项', () async {
      // Arrange
      final container = await createContainer([
        _track('a', '旧歌A'),
        _track('b', '旧歌B'),
      ]);

      // Act
      await container
          .read(queueViewModelProvider.notifier)
          .add(_track('b', '旧歌B'), playImmediately: true);

      // Assert
      expect(trackIds(container), ['b', 'a']);
      expect(container.read(queueViewModelProvider).queue!.currentIndex, 0);
    });

    test('普通添加仍追加到播放列表末尾且不改变当前索引', () async {
      // Arrange
      final container = await createContainer([
        _track('a', '旧歌A'),
        _track('b', '旧歌B'),
      ], currentIndex: 0);

      // Act
      await container
          .read(queueViewModelProvider.notifier)
          .add(_track('c', '新歌C'));

      // Assert
      expect(trackIds(container), ['a', 'b', 'c']);
      expect(container.read(queueViewModelProvider).queue!.currentIndex, 0);
    });

    test('批量添加并播放时整组保持原顺序置于列表首位', () async {
      // Arrange
      final container = await createContainer([
        _track('a', '旧歌A'),
        _track('b', '旧歌B'),
      ], currentIndex: 1);

      // Act
      await container.read(queueViewModelProvider.notifier).addAllAndPlayFirst([
        _track('c', '分P1'),
        _track('d', '分P2'),
      ]);

      // Assert
      expect(trackIds(container), ['c', 'd', 'a', 'b']);
      expect(container.read(queueViewModelProvider).queue!.currentIndex, 0);
    });

    test('批量添加并播放时去除已存在的重复项', () async {
      // Arrange
      final container = await createContainer([
        _track('a', '旧歌A'),
        _track('b', '旧歌B'),
      ]);

      // Act
      await container.read(queueViewModelProvider.notifier).addAllAndPlayFirst([
        _track('b', '旧歌B'),
        _track('c', '分P1'),
        _track('c', '分P1'),
      ]);

      // Assert
      expect(trackIds(container), ['b', 'c', 'a']);
      expect(container.read(queueViewModelProvider).queue!.currentIndex, 0);
    });
  });
}
