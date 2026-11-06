import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/mock_repositories.dart';
import '../models/account_model.dart';
import '../models/chats_model.dart';
import '../models/meetings_model.dart';
import '../models/shortlist_model.dart';
import '../widgets/error_view.dart';
import '../widgets/info_row.dart';
import '../widgets/initials_avatar.dart';
import '../widgets/skill_chips.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  bool _visibleInAi = true; // эфемерное: переключатель экрана → setState
  bool _simulateError = false; // эфемерное — тоже setState (C7)

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final account = context.watch<AccountModel>();
    final p = account.me;
    final Widget body;
    if (account.isLoading) {
      body = const LoadingView();
    } else if (account.error != null || p == null) {
      body = Column(
        children: [
          Expanded(
            child: ErrorView(
                message: account.error ?? 'Профиль не загружен',
                onRetry: () => context.read<AccountModel>().load()),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _crashSwitch(scheme), // чтобы аварию можно было выключить
          ),
        ],
      );
    } else {
      // статистика — живая: каждое число читает свою модель
      final chats = context.watch<ChatsModel>();
      final meetings = context.watch<MeetingsModel>();
      final shortlist = context.watch<ShortlistModel>();
      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(child: InitialsAvatar(name: p.name, radius: 48)),
          const SizedBox(height: 12),
          Text(p.name, textAlign: TextAlign.center, style: text.titleLarge),
          Text('${p.title} · ${p.company}',
              textAlign: TextAlign.center,
              style:
                  text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _Stat(
                      value: chats.isLoading
                          ? '…'
                          : '${chats.conversations.length}',
                      label: 'Контактов')),
              Expanded(
                  child: _Stat(
                      value: meetings.isLoading
                          ? '…'
                          : '${meetings.meetings.length}',
                      label: 'Встреч')),
              Expanded(
                  child:
                      _Stat(value: '${shortlist.count}', label: 'В избранном')),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                InfoRow(
                    icon: Icons.flag_outlined,
                    label: 'Цель',
                    value: p.goal.label),
                InfoRow(
                    icon: Icons.category_outlined,
                    label: 'Отрасль',
                    value: p.industry),
                InfoRow(
                    icon: Icons.place_outlined, label: 'Город', value: p.city),
                InfoRow(
                    icon: Icons.work_history_outlined,
                    label: 'Опыт',
                    value: '${p.experienceYears} лет'),
                if (p.email.isNotEmpty)
                  InfoRow(
                      icon: Icons.alternate_email,
                      label: 'E-mail',
                      value: p.email),
                if (p.phone.isNotEmpty)
                  InfoRow(
                      icon: Icons.phone_outlined,
                      label: 'Телефон',
                      value: '+373 ${p.phone}'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.event_note),
              title: const Text('Мои встречи'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/profile/meetings'),
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
            value: _visibleInAi,
            onChanged: (v) => setState(() => _visibleInAi = v),
            title: const Text('Показывать меня в ИИ-подборе'),
          ),
          _crashSwitch(scheme),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            label: const Text('Выйти из аккаунта'),
          ),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мой профиль'),
        actions: [
          if (p != null)
            IconButton(
              onPressed: () => context.push('/profile/edit'),
              icon: const Icon(Icons.edit),
              tooltip: 'Редактировать',
            ),
        ],
      ),
      body: body,
    );
  }

  // Леса демонстрации аварии: единственное место UI, которое знает о mock-е.
  // Умирает на L5 вместе с ним.
  Widget _crashSwitch(ColorScheme scheme) => SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: _simulateError,
        onChanged: (v) {
          setState(() => _simulateError = v);
          context.read<MockNetwork>().simulateError = v;
        },
        title: const Text('Симулировать сбой сети'),
        subtitle: const Text('Все запросы к хранилищу будут падать'),
        secondary:
            Icon(Icons.wifi_off, color: _simulateError ? scheme.error : null),
      );
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
