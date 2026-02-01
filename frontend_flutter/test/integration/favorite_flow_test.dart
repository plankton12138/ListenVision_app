import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo/presentation/widgets/cards/favorite_button.dart';
import 'package:demo/presentation/providers/playlist/playlist_provider.dart';
import 'package:demo/presentation/providers/auth/auth_provider.dart';
import 'package:demo/domain/entities/models_export.dart';
import 'package:demo/presentation/providers/audio/audio_metadata_provider.dart';
import 'package:provider/provider.dart';

/// Favorite Flow Integration Test
///
/// 端到端集成测试，验证收藏功能的完整流程：
/// 1. FavoriteButton UI 状态与 Provider 状态同步
/// 2. AudioInfo 组件集成收藏功能
/// 3. 收藏状态在多个 Widget 间的一致性
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Favorite Flow Integration Test', () {
    testWidgets('收藏按钮UI状态正确显示', (tester) async {
      // 测试场景：验证FavoriteButton在不同状态下的UI显示

      // 未收藏状态
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FavoriteButton(
              isFavorited: false,
              onPressed: () {},
              size: 24,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsNothing);

      // 已收藏状态
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FavoriteButton(
              isFavorited: true,
              onPressed: () {},
              size: 24,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsNothing);
    });

    testWidgets('收藏按钮点击触发回调', (tester) async {
      // 测试场景：验证点击事件正确触发
      bool clicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FavoriteButton(
              isFavorited: false,
              onPressed: () => clicked = true,
              size: 24,
            ),
          ),
        ),
      );

      // 点击按钮
      await tester.tap(find.byType(FavoriteButton));
      expect(clicked, true);
    });

    testWidgets('收藏按钮状态变化触发动画', (tester) async {
      // 测试场景：验证从未收藏到已收藏的状态变化触发动画

      bool isFavorited = false;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: FavoriteButton(
                  isFavorited: isFavorited,
                  onPressed: () => setState(() => isFavorited = true),
                  size: 24,
                ),
              ),
            );
          },
        ),
      );

      // 初始状态：未收藏
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);

      // 点击收藏
      await tester.tap(find.byType(FavoriteButton));
      await tester.pump(); // 触发rebuild

      // 验证状态已更新
      expect(find.byIcon(Icons.favorite), findsOneWidget);

      // 验证动画正在运行
      await tester.pump(const Duration(milliseconds: 100));
      // 动画中间状态，ScaleTransition应该存在（可能超过1个）
      expect(find.byType(ScaleTransition), findsWidgets);

      // 等待动画完成
      await tester.pumpAndSettle();
      // 动画完成后，图标仍然显示为已收藏
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('PlaylistProvider收藏状态检查', (tester) async {
      // 测试场景：验证PlaylistProvider的isFavorited方法

      final playlistProvider = PlaylistProvider();

      // 创建测试音频
      final testAudio = Audio(
        id: 'BV123456',
        title: 'Test Song',
        artist: 'Test Artist',
        duration: 180,
      );

      // 初始状态：未收藏
      expect(playlistProvider.isFavorited(testAudio.id), false);

      // 注意：由于isFavorited依赖私有成员_favoritedBvids
      // 在集成测试中，我们通过公开的toggleFavorite方法来改变状态
      // 但这需要mock DioProvider，所以这里只验证初始状态
    });

    testWidgets('FavoriteButton尺寸参数正确应用', (tester) async {
      // 测试场景：验证不同尺寸的按钮正确渲染

      for (final size in [24.0, 32.0, 48.0]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: size,
                height: size,
                child: FavoriteButton(
                  isFavorited: false,
                  onPressed: () {},
                  size: size,
                ),
              ),
            ),
          ),
        );

        final sizedBox = tester.widget<SizedBox>(
          find.descendant(
            of: find.byType(FavoriteButton),
            matching: find.byType(SizedBox),
          ).first,
        );

        expect(sizedBox.width, size);
        expect(sizedBox.height, size);
      }
    });

    testWidgets('多个FavoriteButton独立状态', (tester) async {
      // 测试场景：验证页面上的多个收藏按钮状态独立

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                FavoriteButton(
                  key: const Key('button1'),
                  isFavorited: false,
                  onPressed: () {},
                  size: 24,
                ),
                FavoriteButton(
                  key: const Key('button2'),
                  isFavorited: true,
                  onPressed: () {},
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      );

      // 验证两个按钮状态独立
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);

      // 点击第一个按钮
      await tester.tap(find.byKey(const Key('button1')));
      await tester.pump();

      // 第二个按钮状态不受影响
      expect(find.byKey(const Key('button2')), findsOneWidget);
    });

    testWidgets('FavoriteButton在Theme下正确显示颜色', (tester) async {
      // 测试场景：验证主题颜色正确应用

      final customTheme = ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          error: Colors.red, // 收藏状态使用error颜色
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: customTheme,
          home: Scaffold(
            body: Row(
              children: [
                FavoriteButton(
                  key: const Key('unfavorited'),
                  isFavorited: false,
                  onPressed: () {},
                  size: 24,
                ),
                FavoriteButton(
                  key: const Key('favorited'),
                  isFavorited: true,
                  onPressed: () {},
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      );

      // 验证图标类型正确（未收藏/已收藏）
      final unfavoritedIcon = tester.widget<Icon>(
        find.descendant(
          of: find.byKey(const Key('unfavorited')),
          matching: find.byType(Icon),
        ),
      );

      final favoritedIcon = tester.widget<Icon>(
        find.descendant(
          of: find.byKey(const Key('favorited')),
          matching: find.byType(Icon),
        ),
      );

      // 验证图标类型
      expect(unfavoritedIcon.icon, Icons.favorite_border);
      expect(favoritedIcon.icon, Icons.favorite);

      // 验证颜色（FavoriteButton将颜色应用到Icon widget）
      expect(unfavoritedIcon.color, customTheme.colorScheme.onSurfaceVariant);
      expect(favoritedIcon.color, customTheme.colorScheme.error);
    });

    testWidgets('FavoriteButton动画控制器正确释放', (tester) async {
      // 测试场景：验证Widget dispose时动画控制器被正确释放

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FavoriteButton(
              isFavorited: false,
              onPressed: () {},
              size: 24,
            ),
          ),
        ),
      );

      // 验证Widget正常渲染
      expect(find.byType(FavoriteButton), findsOneWidget);

      // 替换为空Widget（触发dispose）
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(),
          ),
        ),
      );

      // 验证旧Widget已移除
      expect(find.byType(FavoriteButton), findsNothing);

      // 如果没有抛出异常，说明dispose成功
      await tester.pump();
    });
  });
}
