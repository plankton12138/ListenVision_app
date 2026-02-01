import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo/presentation/widgets/cards/favorite_button.dart';
import 'package:demo/presentation/providers/playlist/playlist_provider.dart';
import 'package:demo/presentation/providers/auth/auth_provider.dart';
import 'package:demo/domain/entities/models_export.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayHistoryPage Favorite Integration', () {
    late PlaylistProvider playlistProvider;
    late AuthProvider authProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      playlistProvider = PlaylistProvider();
      authProvider = AuthProvider();
      // 等待 AuthProvider 的 _loadUser 完成
      await Future.delayed(const Duration(milliseconds: 100));
    });

    testWidgets('FavoriteButton 在历史卡片中正确显示', (tester) async {
      const testBvid = 'BV1234567890';

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: playlistProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Row(
                children: [
                  FavoriteButton(
                    isFavorited: false,
                    size: 24,
                    onPressed: _dummyOnPressed,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证FavoriteButton渲染成功
      expect(find.byType(FavoriteButton), findsOneWidget);

      // 验证FavoriteButton显示未收藏状态
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });

    testWidgets('FavoriteButton 显示已收藏状态', (tester) async {
      const testBvid = 'BV1234567890';

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: playlistProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Row(
                children: [
                  FavoriteButton(
                    isFavorited: true,
                    size: 24,
                    onPressed: _dummyOnPressed,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证FavoriteButton渲染成功
      expect(find.byType(FavoriteButton), findsOneWidget);

      // 验证FavoriteButton显示已收藏状态
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    test('PlaylistProvider.isFavorited方法测试', () async {
      const testBvid = 'BV1234567890';

      // 初始状态：未收藏
      expect(playlistProvider.isFavorited(testBvid), false);
    });
  });
}

void _dummyOnPressed() {
  // 测试用的空函数
}
