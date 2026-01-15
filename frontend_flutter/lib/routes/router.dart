
import 'package:demo/ui/pages/download_list_page.dart';
import 'package:demo/ui/pages/explore_page.dart';
import 'package:demo/ui/pages/home_page.dart';
import 'package:demo/ui/pages/login_page.dart';
import 'package:demo/ui/pages/play_list_page.dart';
import 'package:demo/ui/pages/register_page.dart';
import 'package:demo/ui/pages/reset_password_page.dart';
import 'package:demo/ui/pages/search_page.dart';
import 'package:demo/ui/pages/settings_page.dart';
import 'package:go_router/go_router.dart';

final GoRouter router = GoRouter(
  routes: [
    // Home page
    GoRoute(
      path: '/',
      builder: (context, state) => HomePage(),
    ),

    // Settings page
    GoRoute(
      path: '/settings',
      builder: (context, state) => SettingsPage(),
    ),

    // Searche page
    GoRoute(
      path: '/search',
      builder: (context, state) => SearchPage(),
    ),
    
    // Explore page
    GoRoute(
      path : '/explore',
      builder: (context, state) => ExplorePage(),
    ),

    // Playlists page
    GoRoute(
      path: '/playlist',
      builder: (context, state) => PlaylistPage(),
    ),

    // Downloads page
    GoRoute(
      path: '/download_list',
      builder: (context, state) => DownloadListPage(),
    ),

    // Login page
    GoRoute(
      path: '/login',
      builder: (context, state) => LoginPage(),
    ),

    // Register page
    GoRoute(
      path: '/register',
      builder: (context, state) => RegisterPage(),
    ),

    // Reset password page
    GoRoute(
      path: '/reset_password',
      builder: (context, state) => ResetPasswordPage(),
    ),
  ]
);