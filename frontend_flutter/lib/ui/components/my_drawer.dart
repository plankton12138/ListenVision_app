import 'package:demo/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class MyDrawer extends StatelessWidget{
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          _buildDrawerHeader(authProvider),
          _buildMainMenu(context),
          _buildAuthSection(context, authProvider),
        ],
      ) ,
    );
  }

  Widget _buildDrawerHeader(AuthProvider auth) {
    return auth.isLoggedIn
      ? UserAccountsDrawerHeader(
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
          ),
          accountName: Text(
            auth.user?.username ?? 'Unlogged User',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
              ),
          ),
          accountEmail: Text(
            auth.user?.email ?? '',
            style: const TextStyle(color: Colors.blue),
          ),
          currentAccountPicture: CircleAvatar(
            backgroundColor: Colors.blue[100],
            child: Icon(
              Icons.person,
              size: 40,
              color: Colors.blue[800],
            ),
          ),
        )
      : const DrawerHeader(
          child: CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey,
            child: Icon(
              Icons.person_outline,
              size: 50,
              color: Colors.white,
            ),
          ),
        );
  }

  Widget _buildMainMenu(BuildContext context) {
    return Expanded(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildListTile(
            context: context,
            title: 'H O M E',
            icon: Icons.home,
            route: '/',
          ),
          _buildListTile(
            context: context,
            title: 'S E T T I N G S',
            icon: Icons.settings,
            route: '/settings',
          ),
          _buildListTile(
            context: context,
            title: 'D O W N L O A D',
            icon: Icons.download_rounded,
            route: '/download_list',
          ),
        ],
      ),
    );
  }

  Widget _buildAuthSection(BuildContext context, AuthProvider auth) {
    return Column(
      children: [
        const Divider(height: 1),
        if (auth.isLoggedIn)
          _buildListTile(
            context: context,
            title: 'L O G O U T',
            icon: Icons.exit_to_app,
            onTap: () {
              auth.logout();
              Navigator.pop(context);  
              context.go('/');       
            },
          )
        else
          _buildListTile(
            context: context,
            title: 'L O G I N',
            icon: Icons.login,
            onTap: () {
              Navigator.pop(context);
              context.go('/login');
            },
          ),
      ],
    );
  }

  Widget _buildListTile({
    required BuildContext context,
    required String title,
    required IconData icon,
    String? route,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 25, top: 5),
      child: ListTile(
        title: Text(title),
        leading: Icon(icon, color: Theme.of(context).iconTheme.color),
        onTap: onTap ?? () => context.go(route!),
        hoverColor: Colors.blue.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }



}