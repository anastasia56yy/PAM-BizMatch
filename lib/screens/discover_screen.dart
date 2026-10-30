import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../widgets/initials_avatar.dart';
import '../widgets/match_score_badge.dart';
import '../widgets/skill_chips.dart';
import 'profile_detail_screen.dart';

/// «Знакомства»: свайп-карточки в стиле Tinder, отсортированные ИИ.
class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Знакомства'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.tune)),
        ],
      ),
      body: PageView.builder(
        controller: PageController(viewportFraction: 0.9),
        itemCount: mockProfiles.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 24),
          child: _SwipeCard(profile: mockProfiles[index]),
        ),
      ),
    );
  }
}

class _SwipeCard extends StatelessWidget {
  final Profile profile;

  const _SwipeCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Card(
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 180,
            color: scheme.primaryContainer,
            alignment: Alignment.center,
            child: Stack(
              children: [
                Center(child: InitialsAvatar(name: profile.name, radius: 56)),
                Positioned(
                  top: 12,
                  right: 12,
                  child: MatchScoreBadge(score: profile.aiScore, large: true),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(profile.name, style: text.headlineSmall),
                Text('${profile.title} · ${profile.company}',
                    style: text.bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text('${profile.city} · ${profile.industry} · '
                    '${profile.experienceYears} лет опыта',
                    style: text.bodySmall),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.auto_awesome,
                          size: 18, color: scheme.onSecondaryContainer),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(profile.aiReason,
                            style: text.bodySmall?.copyWith(
                                color: scheme.onSecondaryContainer)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SkillChips(skills: profile.skills),
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ProfileDetailScreen(profile: profile)),
                  ),
                  icon: const Icon(Icons.person_search),
                  label: const Text('Подробнее о профиле'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton.outlined(
                  iconSize: 32,
                  onPressed: () {},
                  icon: const Icon(Icons.close),
                  tooltip: 'Пропустить',
                ),
                IconButton.filledTonal(
                  iconSize: 28,
                  onPressed: () {},
                  icon: const Icon(Icons.star_outline),
                  tooltip: 'В избранное',
                ),
                IconButton.filled(
                  iconSize: 32,
                  onPressed: () {},
                  icon: const Icon(Icons.handshake),
                  tooltip: 'Хочу познакомиться',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
