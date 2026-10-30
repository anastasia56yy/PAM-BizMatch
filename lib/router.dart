import 'package:go_router/go_router.dart';

import 'screens/ai_brief_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/chats_screen.dart';
import 'screens/discover_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/login_screen.dart';
import 'screens/matches_screen.dart';
import 'screens/meeting_request_screen.dart';
import 'screens/my_profile_screen.dart';
import 'screens/profile_detail_screen.dart';

/// Карта маршрутов: все экраны ТЗ получают адрес.
final router = GoRouter(
  initialLocation: '/login', // приложение стартует в аутентификации
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
        path: '/discover', builder: (context, state) => const DiscoverScreen()),
    GoRoute(
        path: '/matches', builder: (context, state) => const MatchesScreen()),
    // ФИКСИРОВАННЫЙ сегмент — перед ':id', иначе «brief» поймает :id
    GoRoute(
        path: '/matches/brief',
        builder: (context, state) => const AiBriefScreen()),
    GoRoute(
      path: '/profiles/:id', // /profiles/3 — детали профиля № 3
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return ProfileDetailScreen(id: id);
      },
    ),
    GoRoute(
      path: '/profiles/:id/meet',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return MeetingRequestScreen(profileId: id);
      },
    ),
    GoRoute(path: '/chats', builder: (context, state) => const ChatsScreen()),
    GoRoute(
      path: '/chats/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return ChatScreen(conversationId: id);
      },
    ),
    GoRoute(
        path: '/profile', builder: (context, state) => const MyProfileScreen()),
    GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileScreen()),
  ],
);
