import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'data/mock_repositories.dart';
import 'models/account_model.dart';
import 'models/chats_model.dart';
import 'models/meetings_model.dart';
import 'models/profiles_model.dart';
import 'models/shortlist_model.dart';
import 'router.dart';

/// Корень композиции: ЗДЕСЬ (и только здесь) выбирается источник данных.
void main() {
  final network = MockNetwork(); // на L5: http-реализации — и всё
  runApp(MultiProvider(
    providers: appProviders(network),
    child: const BizMatchApp(), // MaterialApp.router — нетронут с L3
  ));
}

/// Модели получают хранилища через конструктор (DI) и сразу грузятся.
List<SingleChildWidget> appProviders(MockNetwork network) => [
      // леса демонстрации аварии (переключатель в профиле) — исчезают на L5
      Provider<MockNetwork>.value(value: network),
      ChangeNotifierProvider(
          create: (_) => ProfilesModel(MockProfileRepository(network))..load()),
      ChangeNotifierProvider(
          create: (_) =>
              ChatsModel(MockConversationRepository(network))..load()),
      ChangeNotifierProvider(
          create: (_) => MeetingsModel(MockMeetingRepository(network))..load()),
      ChangeNotifierProvider(
          create: (_) => AccountModel(MockAccountRepository(network))..load()),
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
