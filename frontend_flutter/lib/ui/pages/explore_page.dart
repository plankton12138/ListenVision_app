import 'package:demo/constants/dimens.dart';
import 'package:demo/ui/components/my_drawer.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 发现页面
///
/// 展示推荐内容和分类浏览功能
class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  _ExplorePageState createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 顶部应用栏
      appBar: AppBar(
        title: Text(
          '发现',
          style: TextStyle(
            fontSize: Dimens.fontSizeLarge,
          ),
        ),
        actions: <Widget>[
          // 返回首页按钮
          IconButton(
            icon: const Icon(Icons.home),
            iconSize: Dimens.iconMedium,
            onPressed: () => context.go('/'),
          ),
        ],
      ),

      drawer: const MyDrawer(),
    );
  }
}
