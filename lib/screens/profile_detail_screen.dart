import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_data.dart';
import '../widgets/info_row.dart';
import '../widgets/initials_avatar.dart';
import '../widgets/match_score_badge.dart';
import '../widgets/skill_chips.dart';

class ProfileDetailScreen extends StatelessWidget {
  final int id;

  const ProfileDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    // экран сам ищет свой объект по id из адреса (L4 — Repository, L5 — API)
    final profile = profileById(id);
    return Scaffold(
      appBar: AppBar(
        title: Text(profile.name),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.star_outline)),
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
            onPressed: () => context.push('/profiles/$id/meet'),
            icon: const Icon(Icons.event_available),
            label: const Text('Предложить встречу'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Написать сообщение'),
          ),
        ],
      ),
    );
  }
}
