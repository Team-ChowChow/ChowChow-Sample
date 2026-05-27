import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../pages/ai_chat_page.dart';
import '../pages/app_settings_page.dart';
import '../pages/change_password_page.dart';
import '../pages/character_page.dart';
import '../pages/community_page.dart';
import '../pages/find_id_page.dart';
import '../pages/find_password_page.dart';
import '../pages/home_page.dart';
import '../pages/login_page.dart';
import '../pages/profile_page.dart';
import '../pages/recipe_generation_page.dart';
import '../pages/search_page.dart';
import '../pages/signup_page.dart';
import '../shell/main_shell.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter({String initialLocation = '/login'}) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HomePage()),
          GoRoute(
            path: '/search',
            builder: (context, state) => const SearchPage(),
          ),
          GoRoute(
            path: '/character',
            builder: (context, state) => const CharacterPage(),
          ),
          GoRoute(
            path: '/community',
            builder: (context, state) => const CommunityPage(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/signup',
        builder: (context, state) => const SignupPage(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/find-id',
        builder: (context, state) => const FindIdPage(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/find-password',
        builder: (context, state) => const FindPasswordPage(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/change-password',
        builder: (context, state) => const ChangePasswordPage(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/recipe-generation',
        builder: (context, state) => const RecipeGenerationPage(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/ai-chat',
        builder: (context, state) => const AiChatPage(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/app-settings',
        builder: (context, state) => const AppSettingsPage(),
      ),
    ],
  );
}
