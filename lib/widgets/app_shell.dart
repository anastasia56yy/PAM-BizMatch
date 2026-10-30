import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Обёртка с постоянными вкладками; текущий индекс знает router.
class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell, // содержимое текущей вкладки
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: navigationShell.goBranch, // переключает вкладку
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
