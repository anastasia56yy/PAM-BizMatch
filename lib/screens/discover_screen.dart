import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/profile.dart';
import '../models/chats_model.dart';
import '../models/profiles_model.dart';
import '../models/shortlist_model.dart';
import '../widgets/error_view.dart';
import '../widgets/initials_avatar.dart';
import '../widgets/match_score_badge.dart';
import '../widgets/shortlist_button.dart';
import '../widgets/skill_chips.dart';

/// «Знакомства»: свайп-карточки в стиле Tinder, отсортированные ИИ.
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  // эфемерное состояние: какая карточка на экране — знает только этот экран
  final _pages = PageController(viewportFraction: 0.9);

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next() => _pages.nextPage(
      duration: const Duration(milliseconds: 300), curve: Curves.easeOut);

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ProfilesModel>(); // watch в build (C7)
    final Widget body;
    if (model.isLoading) {
      body = const LoadingView(); // 1) грузится
    } else if (model.error != null) {
      body = ErrorView(
          message: model.error!, // 2) упало
          onRetry: () => context.read<ProfilesModel>().load()); // read: действие
    } else {
      final profiles = model.profiles; // 3) данные
      body = PageView.builder(
        controller: _pages,
        itemCount: profiles.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 24),
          child: _SwipeCard(profile: profiles[index], onSkip: _next),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Знакомства'),
        actions: const [ShortlistButton(basePath: '/discover')],
      ),
      body: body,
    );
  }
}

void _notify(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

class _SwipeCard extends StatelessWidget {
  final Profile profile;
  final VoidCallback onSkip;

  const _SwipeCard({required this.profile, required this.onSkip});

  Future<void> _meet(BuildContext context) async {
    final error = await context.read<ChatsModel>().startChat(profile);
    if (!context.mounted) return; // экран мог умереть, пока «запрос» летел
    _notify(context, error ?? '${profile.name} — в ваших контактах');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    // watch в build: звезда закрашивается, как только профиль в избранном
    final starred = context.watch<ShortlistModel>().contains(profile.id);
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
                  onPressed: () => context.push('/discover/${profile.id}'),
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
                  onPressed: onSkip,
                  icon: const Icon(Icons.close),
                  tooltip: 'Пропустить',
                ),
                IconButton.filledTonal(
                  iconSize: 28,
                  // read в callback-е: действие
                  onPressed: () => _notify(
                      context,
                      context.read<ShortlistModel>().toggle(profile.id)
                          ? '${profile.name} — в избранном'
                          : '${profile.name} — убран(а) из избранного'),
                  icon: Icon(starred ? Icons.star : Icons.star_outline),
                  tooltip: 'В избранное',
                ),
                IconButton.filled(
                  iconSize: 32,
                  onPressed: () => _meet(context),
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
