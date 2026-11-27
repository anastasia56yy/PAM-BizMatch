import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'config.dart';
import 'data/api_client.dart';
import 'data/auth_api.dart';
import 'data/file_api.dart';
import 'data/http_repositories.dart';
import 'data/token_store.dart';
import 'models/account_model.dart';
import 'models/chats_model.dart';
import 'models/meetings_model.dart';
import 'models/profiles_model.dart';
import 'models/shortlist_model.dart';
import 'router.dart';

/// Корень композиции: ЗДЕСЬ (и только здесь) выбирается источник данных.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // prefs до runApp (C9)
  final tokens = TokenStore();
  final loggedIn = await tokens.read() != null; // запуск решает по token-у
  router = createRouter(initialLocation: loggedIn ? '/discover' : '/login');
  final api = ApiClient(apiBase, tokens,
      onUnauthorized: () => router.go('/login')); // 401 → login, в одном месте
  runApp(MultiProvider(
    providers: [
      Provider<AuthApi>(create: (_) => AuthApi(apiBase, tokens)),
      ...appProviders(api),
    ],
    child: const BizMatchApp(), // MaterialApp.router — нетронут с L3
  ));
}

/// Модели получают хранилища через конструктор (DI) — как на L4;
/// поменялся только класс хранилища: Mock… → Http….
List<SingleChildWidget> appProviders(ApiClient api) => [
      ChangeNotifierProvider(
          create: (_) => ProfilesModel(HttpProfileRepository(api))..load()),
      ChangeNotifierProvider(
          create: (_) => ChatsModel(HttpConversationRepository(api))..load()),
      ChangeNotifierProvider(
          create: (_) => MeetingsModel(HttpMeetingRepository(api))..load()),
      ChangeNotifierProvider(
          create: (_) =>
              AccountModel(HttpAccountRepository(api), FileApi(api))..load()),
      ChangeNotifierProvider(create: (_) => ShortlistModel()),
    ];

class BizMatchApp extends StatelessWidget {
  const BizMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    // L3: навигацию принимает router; home: исчезает
    return MaterialApp.router(
      title: 'BizMatch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Глубокий «деловой» сине-бирюзовый: доверие + энергия знакомств
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F6E8C)),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      routerConfig: router,
    );
  }
}
