import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import 'initials_avatar.dart';
import 'match_score_badge.dart';

/// Карточка профиля в списках (ИИ-подбор, поиск, избранное).
class ProfileCard extends StatelessWidget {
  final Profile profile;
  final bool showReason;
  final VoidCallback? onTap;

  const ProfileCard(
      {super.key, required this.profile, this.showReason = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InitialsAvatar(name: profile.name),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile.name,
                            style: text.titleMedium,
                            overflow: TextOverflow.ellipsis),
                        Text(
                          '${profile.title} · ${profile.company}',
                          style: text.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  MatchScoreBadge(score: profile.aiScore),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _Tag(icon: Icons.flag_outlined, label: profile.goal.label),
                  _Tag(icon: Icons.place_outlined, label: profile.city),
                ],
              ),
              if (showReason) ...[
                const SizedBox(height: 8),
                Text(
                  profile.aiReason,
                  style: text.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Tag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: scheme.onSurfaceVariant),
        const SizedBox(width: 2),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: scheme.onSurfaceVariant)),
      ],
    );
  }
}
