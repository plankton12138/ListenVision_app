
import 'package:demo/constants/dimens.dart';
import 'package:demo/ui/components/my_drawer.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ExplorePage extends StatefulWidget{
  const ExplorePage({super.key});

  @override
  _ExplorePageState createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage>{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar
      appBar: AppBar(
        title: Text(
          'Explore Page',
          style: TextStyle(
            fontSize: Dimens.fontSizeLarge,
          ),
        ),
        actions: <Widget>[
          // Home Button
          IconButton(
            icon: Icon(Icons.home),
            iconSize: Dimens.iconMedium,
            onPressed: () => context.go('/'),
          ),
        ],
      ),

      drawer: const MyDrawer(),
    );
  }
}