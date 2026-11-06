import 'package:go_router/go_router.dart';

import 'screens/ai_brief_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/chats_screen.dart';
import 'screens/discover_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/login_screen.dart';
import 'screens/matches_screen.dart';
import 'screens/meeting_request_screen.dart';
import 'screens/meetings_screen.dart';
import 'screens/my_profile_screen.dart';
import 'screens/profile_detail_screen.dart';
import 'widgets/app_shell.dart';

/// Под-маршруты профиля, общие для вкладок «Знакомства» и «ИИ-подбор»:
/// `base/favorites` — избранное, `base/:id` — детали, `base/:id/meet` — встреча.
List<RouteBase> _profileRoutes(String base) => [
      GoRoute(
        path: 'favorites', // ФИКСИРОВАННЫЙ — перед ':id'
        builder: (context, state) => FavoritesScreen(basePath: base),
      ),
      GoRoute(
        path: ':id', // полный адрес: /discover/3 или /matches/3
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return ProfileDetailScreen(id: id, basePath: base);
        },
        routes: [
          GoRoute(
            path: 'meet', // полный адрес: /discover/3/meet
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return MeetingRequestScreen(profileId: id);
            },
          ),
        ],
      ),
    ];

/// Финальная карта: login снаружи, четыре раздела — в shell-е.
final router = GoRouter(
  initialLocation: '/login', // приложение стартует в аутентификации
  routes: [
    GoRoute(
      path: '/login', // ВНЕ shell-а: у login нет вкладок
      builder: (context, state) => const LoginScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/discover',
            builder: (context, state) => const DiscoverScreen(),
            routes: _profileRoutes('/discover'),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/matches',
            builder: (context, state) => const MatchesScreen(),
            routes: [
              // ФИКСИРОВАННЫЙ 'brief' — перед ':id', иначе int.parse('brief')
              GoRoute(
                path: 'brief',
                builder: (context, state) => const AiBriefScreen(),
              ),
              ..._profileRoutes('/matches'),
            ],
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/chats',
            builder: (context, state) => const ChatsScreen(),
            routes: [
              GoRoute(
                path: ':id', // полный адрес: /chats/2
                builder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return ChatScreen(conversationId: id);
                },
              ),
            ],
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/profile',
            builder: (context, state) => const MyProfileScreen(),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (context, state) => const EditProfileScreen(),
              ),
              GoRoute(
                path: 'meetings', // /profile/meetings
                builder: (context, state) => const MeetingsScreen(),
              ),
            ],
          ),
        ]),
      ],
    ),
  ],
);
