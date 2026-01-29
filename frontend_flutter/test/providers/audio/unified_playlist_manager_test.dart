import 'package:flutter_test/flutter_test.dart';
import 'package:demo/presentation/providers/audio/unified_playlist_manager.dart';
import 'package:demo/domain/entities/local_playable.dart';
import 'package:demo/domain/entities/online_playable.dart';
import 'package:demo/domain/entities/local_audio.dart';
import 'package:demo/domain/entities/audio.dart';

void main() {
  group('UnifiedPlaylistManager', () {
    late UnifiedPlaylistManager manager;

    // 测试用的本地音频
    LocalAudio createTestLocalAudio({
      int? id,
      required String title,
      String artist = 'Test Artist',
    }) {
      return LocalAudio(
        filePath: '/test/path/$title.mp3',
        title: title,
        artist: artist,
        duration: 180,
        id: id,
      );
    }

    // 测试用的在线音频
    Audio createTestAudio({
      required String id,
      required String title,
      String artist = 'Test Artist',
    }) {
      return Audio(
        id: id,
        title: title,
        artist: artist,
        duration: 180,
        streamUrl: 'https://example.com/audio.mp3',
        coverUrl: 'https://example.com/cover.jpg',
      );
    }

    setUp(() {
      manager = UnifiedPlaylistManager();
    });

    group('初始化状态', () {
      test('初始状态播放列表应该为空', () {
        expect(manager.playlist, isEmpty);
        expect(manager.isEmpty, true);
        expect(manager.length, 0);
      });

      test('初始索引应该是 -1', () {
        expect(manager.currentIndex, -1);
      });

      test('初始状态 currentPlayable 应该为 null', () {
        expect(manager.currentPlayable, isNull);
      });

      test('初始本地播放列表应该为空', () {
        expect(manager.localPlaylist, isEmpty);
      });
    });

    group('播放列表操作', () {
      test('应该能够设置播放列表', () {
        final audios = [
          LocalPlayable(createTestLocalAudio(id: 1, title: 'Song 1')),
          LocalPlayable(createTestLocalAudio(id: 2, title: 'Song 2')),
        ];

        manager.setPlaylist(audios);

        expect(manager.length, 2);
        expect(manager.playlist.length, 2);
      });

      test('设置播放列表时应该设置初始索引', () {
        final audios = [
          LocalPlayable(createTestLocalAudio(id: 1, title: 'Song 1')),
          LocalPlayable(createTestLocalAudio(id: 2, title: 'Song 2')),
        ];

        manager.setPlaylist(audios, initialIndex: 1);

        expect(manager.currentIndex, 1);
        expect(manager.currentPlayable?.title, 'Song 2');
      });

      test('应该能够添加单个音频到播放列表', () async {
        final audio = LocalPlayable(createTestLocalAudio(id: 1, title: 'Song 1'));

        await manager.add(audio, syncLocal: false);

        expect(manager.length, 1);
        expect(manager.playlist.first.title, 'Song 1');
      });

      test('添加 playImmediately=true 时应该设置当前索引', () async {
        final audio1 = LocalPlayable(createTestLocalAudio(id: 1, title: 'Song 1'));
        final audio2 = LocalPlayable(createTestLocalAudio(id: 2, title: 'Song 2'));

        await manager.add(audio1, syncLocal: false);
        await manager.add(audio2, playImmediately: true, syncLocal: false);

        expect(manager.currentIndex, 1);
        expect(manager.currentPlayable?.title, 'Song 2');
      });

      test('添加已存在的音频（playImmediately=true）应该只更新索引', () async {
        final audio1 = LocalPlayable(createTestLocalAudio(id: 1, title: 'Song 1'));
        final audio2 = LocalPlayable(createTestLocalAudio(id: 2, title: 'Song 2'));

        await manager.add(audio1, syncLocal: false);
        await manager.add(audio2, syncLocal: false);

        // 重新添加 audio1 并立即播放
        await manager.add(audio1, playImmediately: true, syncLocal: false);

        expect(manager.length, 2); // 长度不变
        expect(manager.currentIndex, 0); // 索引指向第一个
      });

      test('添加已存在的音频（playImmediately=false）不应该重复添加', () async {
        final audio1 = LocalPlayable(createTestLocalAudio(id: 1, title: 'Song 1'));

        await manager.add(audio1, syncLocal: false);
        await manager.add(audio1, syncLocal: false);

        expect(manager.length, 1); // 只有一个
      });

      test('应该能够批量添加音频', () async {
        final audios = [
          LocalPlayable(createTestLocalAudio(id: 1, title: 'Song 1')),
          LocalPlayable(createTestLocalAudio(id: 2, title: 'Song 2')),
          LocalPlayable(createTestLocalAudio(id: 3, title: 'Song 3')),
        ];

        await manager.addAll(audios, syncLocal: false);

        expect(manager.length, 3);
      });

      test('批量添加时应该去重', () async {
        final audio1 = LocalPlayable(createTestLocalAudio(id: 1, title: 'Song 1'));
        final audio2 = LocalPlayable(createTestLocalAudio(id: 2, title: 'Song 2'));

        await manager.addAll([audio1, audio2], syncLocal: false);
        await manager.addAll([audio1, audio2], syncLocal: false); // 再次添加相同的

        expect(manager.length, 2); // 去重后只有2个
      });

      test('应该能够移除指定索引的音频', () async {
        final audios = [
          LocalPlayable(createTestLocalAudio(id: 1, title: 'Song 1')),
          LocalPlayable(createTestLocalAudio(id: 2, title: 'Song 2')),
          LocalPlayable(createTestLocalAudio(id: 3, title: 'Song 3')),
        ];

        manager.setPlaylist(audios);
        await manager.removeAt(1);

        expect(manager.length, 2);
        expect(manager.playlist[1].title, 'Song 3');
      });

      test('移除当前播放项时索引应该重置', () async {
        final audios = [
          LocalPlayable(createTestLocalAudio(id: 1, title: 'Song 1')),
          LocalPlayable(createTestLocalAudio(id: 2, title: 'Song 2')),
          LocalPlayable(createTestLocalAudio(id: 3, title: 'Song 3')),
        ];

        manager.setPlaylist(audios, initialIndex: 1);
        await manager.removeAt(1); // 移除当前播放项

        expect(manager.currentIndex, -1);
        expect(manager.currentPlayable, isNull);
      });

      test('移除当前项之前的项时索引应该减一', () async {
        final audios = [
          LocalPlayable(createTestLocalAudio(id: 1, title: 'Song 1')),
          LocalPlayable(createTestLocalAudio(id: 2, title: 'Song 2')),
          LocalPlayable(createTestLocalAudio(id: 3, title: 'Song 3')),
        ];

        manager.setPlaylist(audios, initialIndex: 2);
        await manager.removeAt(0); // 移除第一项

        expect(manager.currentIndex, 1); // 索引从2变为1
      });

      test('移除当前项之后的项时索引不变', () async {
        final audios = [
          LocalPlayable(createTestLocalAudio(id: 1, title: 'Song 1')),
          LocalPlayable(createTestLocalAudio(id: 2, title: 'Song 2')),
          LocalPlayable(createTestLocalAudio(id: 3, title: 'Song 3')),
        ];

        manager.setPlaylist(audios, initialIndex: 0);
        await manager.removeAt(2); // 移除最后一项

        expect(manager.currentIndex, 0); // 索引不变
      });

      test('移除无效索引时不应该报错', () async {
        final audios = [
          LocalPlayable(createTestLocalAudio(id: 1, title: 'Song 1')),
        ];

        manager.setPlaylist(audios);
        await manager.removeAt(-1);
        await manager.removeAt(10);

        expect(manager.length, 1); // 没有变化
      });

      test('应该能够通过ID移除音频', () async {
        final audio1 = LocalPlayable(createTestLocalAudio(id: 1, title: 'Song 1'));
        final audio2 = LocalPlayable(createTestLocalAudio(id: 2, title: 'Song 2'));

        manager.setPlaylist([audio1, audio2]);
        await manager.removeById(audio1.id);

        expect(manager.length, 1);
        expect(manager.playlist.first.title, 'Song 2');
      });

      test('清空播放列表应该重置所有状态', () async {
        final audios = [
          LocalPlayable(createTestLocalAudio(id: 1, title: 'Song 1')),
          LocalPlayable(createTestLocalAudio(id: 2, title: 'Song 2')),
        ];

        manager.setPlaylist(audios, initialIndex: 1);
        await manager.clear();

        expect(manager.length, 0);
        expect(manager.isEmpty, true);
        expect(manager.currentIndex, -1);
        expect(manager.currentPlayable, isNull);
      });
    });

    group('索引管理', () {
      test('setCurrentIndex 应该设置当前索引', () {
        final audios = [
          LocalPlayable(createTestLocalAudio(id: 1, title: 'Song 1')),
          LocalPlayable(createTestLocalAudio(id: 2, title: 'Song 2')),
        ];

        manager.setPlaylist(audios);
        final result = manager.setCurrentIndex(1);

        expect(result, true);
        expect(manager.currentIndex, 1);
        expect(manager.currentPlayable?.title, 'Song 2');
      });

      test('setCurrentIndex 验证模式应该拒绝无效索引', () {
        final audios = [
          LocalPlayable(createTestLocalAudio(id: 1, title: 'Song 1')),
        ];

        manager.setPlaylist(audios);
        final result = manager.setCurrentIndex(5);

        expect(result, false);
        expect(manager.currentIndex, -1); // 索引不变
      });

      test('setCurrentIndex 不验证模式应该允许任何索引', () {
        final audios = [
          LocalPlayable(createTestLocalAudio(id: 1, title: 'Song 1')),
        ];

        manager.setPlaylist(audios);
        manager.setCurrentIndex(5, validate: false);

        expect(manager.currentIndex, 5);
      });

      test('nextIndex 应该返回下一曲索引', () {
        final audios = [
          LocalPlayable(createTestLocalAudio(id: 1, title: 'Song 1')),
          LocalPlayable(createTestLocalAudio(id: 2, title: 'Song 2')),
          LocalPlayable(createTestLocalAudio(id: 3, title: 'Song 3')),
        ];

        manager.setPlaylist(audios, initialIndex: 0);

        expect(manager.nextIndex, 1);
      });

      test('nextIndex 应该在列表末尾循环到开头', () {
        final audios = [
          LocalPlayable(createTestLocalAudio(id: 1, title: 'Song 1')),
          LocalPlayable(createTestLocalAudio(id: 2, title: 'Song 2')),
        ];

        manager.setPlaylist(audios, initialIndex: 1);

        expect(manager.nextIndex, 0); // 循环到开头
      });

      test('空列表的 nextIndex 应该返回 -1', () {
        expect(manager.nextIndex, -1);
      });

      test('previousIndex 应该返回上一曲索引', () {
        final audios = [
          LocalPlayable(createTestLocalAudio(id: 1, title: 'Song 1')),
          LocalPlayable(createTestLocalAudio(id: 2, title: 'Song 2')),
          LocalPlayable(createTestLocalAudio(id: 3, title: 'Song 3')),
        ];

        manager.setPlaylist(audios, initialIndex: 2);

        expect(manager.previousIndex, 1);
      });

      test('previousIndex 应该在列表开头循环到末尾', () {
        final audios = [
          LocalPlayable(createTestLocalAudio(id: 1, title: 'Song 1')),
          LocalPlayable(createTestLocalAudio(id: 2, title: 'Song 2')),
        ];

        manager.setPlaylist(audios, initialIndex: 0);

        expect(manager.previousIndex, 1); // 循环到末尾
      });

      test('空列表的 previousIndex 应该返回 -1', () {
        expect(manager.previousIndex, -1);
      });
    });

    group('拖拽排序', () {
      test('move 应该能够移动音频位置', () {
        final audios = [
          LocalPlayable(createTestLocalAudio(id: 1, title: 'Song 1')),
          LocalPlayable(createTestLocalAudio(id: 2, title: 'Song 2')),
          LocalPlayable(createTestLocalAudio(id: 3, title: 'Song 3')),
        ];

        manager.setPlaylist(audios, initialIndex: 0);
        manager.move(0, 2);

        expect(manager.playlist[0].title, 'Song 2');
        expect(manager.playlist[1].title, 'Song 3');
        expect(manager.playlist[2].title, 'Song 1');
      });

      test('move 当前项时索引应该跟随移动', () {
        final audios = [
          LocalPlayable(createTestLocalAudio(id: 1, title: 'Song 1')),
          LocalPlayable(createTestLocalAudio(id: 2, title: 'Song 2')),
          LocalPlayable(createTestLocalAudio(id: 3, title: 'Song 3')),
        ];

        manager.setPlaylist(audios, initialIndex: 0);
        manager.move(0, 2);

        expect(manager.currentIndex, 2); // 索引跟随移动
      });

      test('move 向前移动时索引应该正确调整', () {
        final audios = [
          LocalPlayable(createTestLocalAudio(id: 1, title: 'Song 1')),
          LocalPlayable(createTestLocalAudio(id: 2, title: 'Song 2')),
          LocalPlayable(createTestLocalAudio(id: 3, title: 'Song 3')),
          LocalPlayable(createTestLocalAudio(id: 4, title: 'Song 4')),
        ];

        manager.setPlaylist(audios, initialIndex: 2);
        manager.move(3, 0); // 将索引3移到0

        // 原索引2现在变成索引3
        expect(manager.currentIndex, 3);
      });

      test('move 向后移动时索引应该正确调整', () {
        final audios = [
          LocalPlayable(createTestLocalAudio(id: 1, title: 'Song 1')),
          LocalPlayable(createTestLocalAudio(id: 2, title: 'Song 2')),
          LocalPlayable(createTestLocalAudio(id: 3, title: 'Song 3')),
          LocalPlayable(createTestLocalAudio(id: 4, title: 'Song 4')),
        ];

        manager.setPlaylist(audios, initialIndex: 1);
        manager.move(0, 2); // 将索引0移到2

        // 原索引1现在变成索引0
        expect(manager.currentIndex, 0);
      });

      test('move 无效索引时不应该报错', () {
        final audios = [
          LocalPlayable(createTestLocalAudio(id: 1, title: 'Song 1')),
        ];

        manager.setPlaylist(audios);
        manager.move(-1, 0);
        manager.move(0, 10);

        expect(manager.length, 1); // 没有变化
      });

      test('move 相同位置时不应该变化', () {
        final audios = [
          LocalPlayable(createTestLocalAudio(id: 1, title: 'Song 1')),
        ];

        manager.setPlaylist(audios, initialIndex: 0);
        manager.move(0, 0);

        expect(manager.currentIndex, 0); // 索引不变
      });
    });

    group('查询方法', () {
      test('indexOf 应该返回正确的索引', () {
        final audio1 = LocalPlayable(createTestLocalAudio(id: 1, title: 'Song 1'));
        final audio2 = LocalPlayable(createTestLocalAudio(id: 2, title: 'Song 2'));

        manager.setPlaylist([audio1, audio2]);

        expect(manager.indexOf(audio1.id), 0);
        expect(manager.indexOf(audio2.id), 1);
      });

      test('indexOf 未找到时应该返回 -1', () {
        final audio1 = LocalPlayable(createTestLocalAudio(id: 1, title: 'Song 1'));

        manager.setPlaylist([audio1]);

        expect(manager.indexOf('non_existent_id'), -1);
      });

      test('contains 应该正确判断音频是否存在', () {
        final audio1 = LocalPlayable(createTestLocalAudio(id: 1, title: 'Song 1'));

        manager.setPlaylist([audio1]);

        expect(manager.contains(audio1.id), true);
        expect(manager.contains('non_existent_id'), false);
      });

      test('[] 操作符应该返回指定索引的音频', () {
        final audios = [
          LocalPlayable(createTestLocalAudio(id: 1, title: 'Song 1')),
          LocalPlayable(createTestLocalAudio(id: 2, title: 'Song 2')),
        ];

        manager.setPlaylist(audios);

        expect(manager[0]?.title, 'Song 1');
        expect(manager[1]?.title, 'Song 2');
      });

      test('[] 操作符越界时应该返回 null', () {
        final audio1 = LocalPlayable(createTestLocalAudio(id: 1, title: 'Song 1'));

        manager.setPlaylist([audio1]);

        expect(manager[-1], isNull);
        expect(manager[10], isNull);
      });
    });

    group('混合播放列表', () {
      test('应该支持混合本地和在线音频', () async {
        final localAudio = LocalPlayable(createTestLocalAudio(id: 1, title: 'Local Song'));
        final onlineAudio = OnlinePlayable(createTestAudio(id: 'bv1', title: 'Online Song'));

        manager.setPlaylist([localAudio, onlineAudio]);

        expect(manager.length, 2);
        expect(manager.playlist[0].isOnline, false);
        expect(manager.playlist[1].isOnline, true);
      });

      test('混合列表中应该能够正确识别类型', () async {
        final audios = [
          LocalPlayable(createTestLocalAudio(id: 1, title: 'Local 1')),
          OnlinePlayable(createTestAudio(id: 'bv1', title: 'Online 1')),
          LocalPlayable(createTestLocalAudio(id: 2, title: 'Local 2')),
        ];

        manager.setPlaylist(audios);

        expect(manager[0]?.isOnline, false);
        expect(manager[1]?.isOnline, true);
        expect(manager[2]?.isOnline, false);
      });
    });

    group('回调机制', () {
      test('setOnPlaylistChanged 应该设置回调', () {
        var callbackCalled = false;

        manager.setOnPlaylistChanged(() {
          callbackCalled = true;
        });

        // 触发变化
        manager.setPlaylist([]);

        expect(callbackCalled, true);
      });

      test('add 操作应该触发回调', () async {
        var callbackCalled = false;

        manager.setOnPlaylistChanged(() {
          callbackCalled = true;
        });

        final audio = LocalPlayable(createTestLocalAudio(id: 1, title: 'Song 1'));
        await manager.add(audio, syncLocal: false);

        expect(callbackCalled, true);
      });

      test('removeAt 操作应该触发回调', () async {
        var callbackCalled = false;
        final audio = LocalPlayable(createTestLocalAudio(id: 1, title: 'Song 1'));

        manager.setOnPlaylistChanged(() {
          callbackCalled = true;
        });

        manager.setPlaylist([audio]);
        callbackCalled = false; // 重置
        await manager.removeAt(0);

        expect(callbackCalled, true);
      });

      test('move 操作应该触发回调', () {
        var callbackCalled = false;
        final audios = [
          LocalPlayable(createTestLocalAudio(id: 1, title: 'Song 1')),
          LocalPlayable(createTestLocalAudio(id: 2, title: 'Song 2')),
        ];

        manager.setOnPlaylistChanged(() {
          callbackCalled = true;
        });

        manager.setPlaylist(audios);
        callbackCalled = false; // 重置
        manager.move(0, 1);

        expect(callbackCalled, true);
      });

      test('setCurrentIndex 操作应该触发回调', () {
        var callbackCalled = false;
        final audios = [
          LocalPlayable(createTestLocalAudio(id: 1, title: 'Song 1')),
        ];

        manager.setOnPlaylistChanged(() {
          callbackCalled = true;
        });

        manager.setPlaylist(audios);
        callbackCalled = false; // 重置
        manager.setCurrentIndex(0);

        expect(callbackCalled, true);
      });

      test('clear 操作应该触发回调', () async {
        var callbackCalled = false;
        final audios = [
          LocalPlayable(createTestLocalAudio(id: 1, title: 'Song 1')),
        ];

        manager.setOnPlaylistChanged(() {
          callbackCalled = true;
        });

        manager.setPlaylist(audios);
        callbackCalled = false; // 重置
        await manager.clear();

        expect(callbackCalled, true);
      });
    });

    group('operator []', () {
      test('应该能够通过索引获取音频', () {
        final audios = [
          LocalPlayable(createTestLocalAudio(id: 1, title: 'Song 1')),
          LocalPlayable(createTestLocalAudio(id: 2, title: 'Song 2')),
        ];

        manager.setPlaylist(audios);

        expect(manager[0]?.title, 'Song 1');
        expect(manager[1]?.title, 'Song 2');
      });

      test('越界访问应该返回 null', () {
        final audios = [
          LocalPlayable(createTestLocalAudio(id: 1, title: 'Song 1')),
        ];

        manager.setPlaylist(audios);

        expect(manager[-1], isNull);
        expect(manager[10], isNull);
      });
    });
  });
}
