import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo/presentation/widgets/cards/favorite_button.dart';

void main() {
  group('FavoriteButton', () {
    testWidgets('显示空心爱心图标当未收藏时', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FavoriteButton(
              isFavorited: false,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });

    testWidgets('显示实心爱心图标当已收藏时', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FavoriteButton(
              isFavorited: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      final favoriteIcon = tester.widget<Icon>(find.byType(Icon));
      expect(favoriteIcon.icon, Icons.favorite);
    });

    testWidgets('点击时调用onPressed回调', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FavoriteButton(
              isFavorited: false,
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(pressed, true);
    });

    testWidgets('显示自定义size尺寸', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FavoriteButton(
              isFavorited: false,
              onPressed: () {},
              size: 32,
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, 32);
      expect(sizedBox.height, 32);
    });

    testWidgets('收藏状态变化时触发缩放动画', (tester) async {
      var favorited = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return FavoriteButton(
                  isFavorited: favorited,
                  onPressed: () => setState(() => favorited = true),
                );
              },
            ),
          ),
        ),
      );

      // 初始状态：未收藏
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);

      // 点击收藏
      await tester.tap(find.byType(IconButton));
      await tester.pump(); // 触发状态更新

      // 验证动画控制器被触发（ScaleTransition 存在）
      expect(find.byType(ScaleTransition), findsWidgets);

      // 验证图标变为实心爱心
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsNothing);

      // 模拟动画完成
      await tester.pumpAndSettle();

      // ScaleTransition 依然存在（动画结束后不会移除）
      expect(find.byType(ScaleTransition), findsWidgets);
    });
  });
}
