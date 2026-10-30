import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_data.dart';
import '../widgets/info_row.dart';
import '../widgets/initials_avatar.dart';
import '../widgets/skill_chips.dart';

class MyProfileScreen extends StatelessWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    const p = myProfile;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мой профиль'),
        actions: [
          IconButton(
            onPressed: () => context.push('/profile/edit'),
            icon: const Icon(Icons.edit),
            tooltip: 'Редактировать',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(child: InitialsAvatar(name: p.name, radius: 48)),
          const SizedBox(height: 12),
          Text(p.name, textAlign: TextAlign.center, style: text.titleLarge),
          Text('${p.title} · ${p.company}',
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(child: _Stat(value: '128', label: 'Просмотров')),
              Expanded(child: _Stat(value: '24', label: 'Контактов')),
              Expanded(child: _Stat(value: '7', label: 'Встреч')),
            ],
          ),
          const SizedBox(height: 16),
          const Card(
            child: Column(
              children: [
                InfoRow(
                    icon: Icons.flag_outlined, label: 'Цель', value: 'Партнёрство'),
                InfoRow(
                    icon: Icons.category_outlined,
                    label: 'Отрасль',
                    value: 'Event-индустрия'),
                InfoRow(
                    icon: Icons.place_outlined, label: 'Город', value: 'Кишинёв'),
                InfoRow(
                    icon: Icons.work_history_outlined,
                    label: 'Опыт',
                    value: '5 лет'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('О себе', style: text.titleMedium),
          const SizedBox(height: 4),
          Text(p.about),
          const SizedBox(height: 16),
          Text('Навыки', style: text.titleMedium),
          const SizedBox(height: 8),
          SkillChips(skills: p.skills),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: true,
            onChanged: (_) => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Настройка видимости сохранена'))),
            title: const Text('Показывать меня в ИИ-подборе'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            label: const Text('Выйти из аккаунта'),
          ),
        ],
      ),
    );
  }
}

/// Блокирующее решение → AlertDialog с результатом.
Future<void> _logout(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: const Text('Выйти из аккаунта?'),
      content: const Text('Подбор и переписка останутся сохранены.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Нет')),
        FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Да, выйти')),
      ],
    ),
  );
  if (ok == true && context.mounted) {
    context.go('/login'); // go: раздел с вкладками уходит из стека
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;

  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(value,
            style: text.titleLarge
                ?.copyWith(color: Theme.of(context).colorScheme.primary)),
        Text(label, style: text.labelMedium),
      ],
    );
  }
}
