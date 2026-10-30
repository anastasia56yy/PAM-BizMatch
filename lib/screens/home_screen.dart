import 'package:flutter/material.dart';

import 'chats_screen.dart';
import 'discover_screen.dart';
import 'matches_screen.dart';
import 'my_profile_screen.dart';

/// Временные «леса» L2: NavigationBar, хранящий только индекс вкладки.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _tabs = [
    DiscoverScreen(),
    MatchesScreen(),
    ChatsScreen(),
    MyProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.style_outlined), label: 'Знакомства'),
          NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined), label: 'ИИ-подбор'),
          NavigationDestination(
              icon: Icon(Icons.forum_outlined), label: 'Контакты'),
          NavigationDestination(
              icon: Icon(Icons.person_outline), label: 'Профиль'),
        ],
      ),
    );
  }
}
