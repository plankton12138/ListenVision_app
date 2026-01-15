import 'package:demo/constants/dimens.dart';
import 'package:demo/providers/theme_provider.dart';
import 'package:demo/ui/components/my_drawer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,

      appBar: AppBar(
        title: Text(
          'SETTINGS',
          style: TextStyle(
            fontSize: Dimens.fontSizeLarge,
          ), 
        ),
        actions: <Widget>[
          // Back Button
          IconButton(
            icon: const Icon(Icons.home),
            iconSize: Dimens.iconMedium,
            onPressed: () => context.go('/'),
          ),
        ],
      ),

      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(15)
        ),
        padding: const EdgeInsets.all(15),
        margin: const EdgeInsets.all(25),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // switch to dark mode
            // text
            const Text(
              'Dark Mode',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            // switch
            CupertinoSwitch(
              value: 
                  Provider.of<ThemeController>(context, listen: false).isDarkMode,
              onChanged: (value) => 
                 Provider.of<ThemeController>(context, listen: false).
                   toggleTheme(),
            ),
          ],
        ),
      ),

      drawer: const MyDrawer(),
    );
  }
}