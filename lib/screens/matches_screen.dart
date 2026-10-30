import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_data.dart';
import '../widgets/profile_card.dart';

/// «ИИ-подбор»: рейтинг лучших кандидатов + поиск и фильтр по цели.
class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('ИИ-подбор')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: scheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome,
                          color: scheme.onPrimaryContainer),
                      const SizedBox(width: 8),
                      Text('Ваш запрос к ИИ',
                          style: text.titleMedium?.copyWith(
                              color: scheme.onPrimaryContainer)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '«Инвесторы и партнёры из FinTech и телекома, '
                    'Молдова/Румыния, опыт от 5 лет»',
                    style: text.bodyMedium
                        ?.copyWith(color: scheme.onPrimaryContainer),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.tonalIcon(
                    onPressed: () => context.push('/matches/brief'),
                    icon: const Icon(Icons.edit_note),
                    label: const Text('Уточнить запрос'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const SearchBar(
            hintText: 'Имя, компания или навык',
            leading: Icon(Icons.search),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final (i, f) in goalFilters.indexed)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(f),
                      selected: i == 0,
                      onSelected: (_) {},
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Лучшие кандидаты · ${mockProfiles.length}',
              style: text.titleSmall),
          const SizedBox(height: 8),
          for (final p in mockProfiles)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ProfileCard(
                profile: p,
                showReason: true,
                // зайду и вернусь → push; в адресе путешествует только id
                onTap: () => context.push('/matches/${p.id}'),
              ),
            ),
        ],
      ),
    );
  }
}
