import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/profile.dart';
import '../models/chats_model.dart';
import '../models/profiles_model.dart';
import '../models/shortlist_model.dart';
import '../widgets/info_row.dart';
import '../widgets/initials_avatar.dart';
import '../widgets/match_score_badge.dart';
import '../widgets/skill_chips.dart';

class ProfileDetailScreen extends StatelessWidget {
  final int id;

  /// Вкладка, из которой открыт профиль: '/discover' или '/matches'.
  final String basePath;

  const ProfileDetailScreen(
      {super.key, required this.id, required this.basePath});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    // экран сам ищет свой объект по id из адреса — теперь через модель
    final model = context.watch<ProfilesModel>();
    final profile = model.byId(id);
    if (profile == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: model.isLoading
              ? const CircularProgressIndicator() // список ещё грузится
              : const Text('Профиль не существует'), // загружен — id-а нет
        ),
      );
    }
    final starred = context.watch<ShortlistModel>().contains(id);
    return Scaffold(
      appBar: AppBar(
        title: Text(profile.name),
        actions: [
          IconButton(
            tooltip: 'В избранное',
            onPressed: () {
              final added = context.read<ShortlistModel>().toggle(id);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(added
                      ? '${profile.name} — в избранном'
                      : '${profile.name} — убран(а) из избранного')));
            },
            icon: Icon(starred ? Icons.star : Icons.star_outline),
          ),
          IconButton(
            tooltip: 'Скрыть из подбора',
            onPressed: () => _hide(context, profile),
            icon: const Icon(Icons.visibility_off_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              InitialsAvatar(name: profile.name, radius: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.name, style: text.titleLarge),
                    Text(profile.title, style: text.bodyMedium),
                    const SizedBox(height: 6),
                    MatchScoreBadge(score: profile.aiScore, large: true),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            color: scheme.secondaryContainer,
            child: ListTile(
              leading: Icon(Icons.auto_awesome,
                  color: scheme.onSecondaryContainer),
              title: Text('Почему ИИ рекомендует',
                  style: TextStyle(color: scheme.onSecondaryContainer)),
              subtitle: Text(profile.aiReason,
                  style: TextStyle(color: scheme.onSecondaryContainer)),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                InfoRow(
                    icon: Icons.business,
                    label: 'Компания',
                    value: profile.company),
                InfoRow(
                    icon: Icons.category_outlined,
                    label: 'Отрасль',
                    value: profile.industry),
                InfoRow(
                    icon: Icons.place_outlined,
                    label: 'Город',
                    value: profile.city),
                InfoRow(
                    icon: Icons.flag_outlined,
                    label: 'Цель',
                    value: profile.goal.label),
                InfoRow(
                    icon: Icons.work_history_outlined,
                    label: 'Опыт',
                    value: '${profile.experienceYears} лет'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('О себе', style: text.titleMedium),
          const SizedBox(height: 4),
          Text(profile.about),
          const SizedBox(height: 16),
          Text('Навыки', style: text.titleMedium),
          const SizedBox(height: 8),
          SkillChips(skills: profile.skills),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.push('$basePath/$id/meet'),
            icon: const Icon(Icons.event_available),
            label: const Text('Предложить встречу'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _openChat(context, profile),
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Написать сообщение'),
          ),
        ],
      ),
    );
  }

  /// Нет переписки — сначала создаём контакт, затем прыгаем в «Контакты».
  Future<void> _openChat(BuildContext context, Profile profile) async {
    final chats = context.read<ChatsModel>();
    if (chats.byProfileId(id) == null) {
      final error = await chats.startChat(profile);
      if (!context.mounted) return;
      if (error != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
        return;
      }
    }
    final chat = chats.byProfileId(id)!;
    context.go('/chats/${chat.id}'); // прыжок в другой раздел → go
  }

  /// Деструктивное действие: диалог из L3 получает свой эффект.
  Future<void> _hide(BuildContext context, Profile profile) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Скрыть из подбора?'),
        content: Text('${profile.name} больше не появится в «Знакомствах», '
            '«ИИ-подборе» и избранном.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Отмена')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: const Text('Скрыть')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final error = await context.read<ProfilesModel>().remove(id);
    if (!context.mounted) return; // экран может умереть, пока «запрос» летит
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    context.read<ShortlistModel>().remove(id);
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${profile.name} скрыт(а) из подбора')));
    context.pop(); // объекта больше нет — его экран уходит из стека
  }
}
