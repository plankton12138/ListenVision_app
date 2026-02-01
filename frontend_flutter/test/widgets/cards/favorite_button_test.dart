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
  });
}
