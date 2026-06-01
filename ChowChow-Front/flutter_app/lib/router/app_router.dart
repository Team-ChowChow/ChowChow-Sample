import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../pages/ai_chat_page.dart';
import '../pages/app_settings_page.dart';
import '../pages/change_password_page.dart';
import '../pages/character_list_page.dart';
import '../pages/character_form_page.dart';
import '../pages/character_raise_page.dart';
import '../pages/character_growth_logs_page.dart';
import '../pages/community_page.dart';
import '../pages/find_id_page.dart';
import '../pages/find_password_page.dart';
import '../pages/home_page.dart';

import '../pages/Notification_Settings_page.dart';
import '../pages/login_page.dart';
import '../pages/notices_page.dart';
import '../pages/post_detail_page.dart';
import '../pages/profile_page.dart';
import '../pages/recipe_detail_page.dart';
import '../pages/recipe_generation_page.dart';
import '../pages/recipe_result_page.dart';
import '../pages/search_page.dart';
import '../pages/signup_page.dart';
import '../data/sample_data.dart';
import '../services/models.dart';
import '../shell/main_shell.dart';
import '../pages/create_post.dart';
import '../pages/tip_detail_page.dart';

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
            builder: (context, state) => const CharacterListPage(),
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
        builder: (context, state) {
          final quickStart = state.uri.queryParameters['quickStart'] == 'true';
          return RecipeGenerationPage(quickStart: quickStart);
        },
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
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/notification-settings',
        builder: (context, state) => const NotificationSettingsPage(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/community/posts/:postId',
        builder: (context, state) {
          final postId =
              int.tryParse(state.pathParameters['postId'] ?? '') ?? 0;
          final initialPost = state.extra is CommunityPost
              ? state.extra as CommunityPost
              : null;
          return PostDetailPage(
            postId: postId,
            initialPost: initialPost,
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/recipes/:recipeId',
        builder: (context, state) {
          final recipeId =
              int.tryParse(state.pathParameters['recipeId'] ?? '') ?? 0;
          final initialRecipe = state.extra is RecipeModel
              ? state.extra as RecipeModel
              : null;
          return RecipeDetailPage(
            recipeId: recipeId,
            initialRecipe: initialRecipe,
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/recipe-result',
        builder: (context, state) => const RecipeResultPage(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/notices',
        builder: (context, state) => const NoticesPage(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/create-post',
        builder: (context, state) => const CreatePostPage(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/character/new',
        builder: (context, state) => const CharacterFormPage(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/character/:characterId/edit',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['characterId'] ?? '') ?? 0;
          return CharacterFormPage(characterId: id);
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/character/:characterId/logs',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['characterId'] ?? '') ?? 0;
          return CharacterGrowthLogsPage(characterId: id);
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/character/:characterId',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['characterId'] ?? '') ?? 0;
          return CharacterRaisePage(characterId: id);
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/tip-detail',
        builder: (context, state) {
          final extra = state.extra as Map<String, String>?;
          return TipDetailPage(
            tip: extra?['tip'] ?? '',
            detail: extra?['detail'] ?? '',
          );
        },
      ),
    ],
  );
}
