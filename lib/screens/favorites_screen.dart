import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/mock_data.dart';
import '../models/shortlist_model.dart';
import '../widgets/profile_card.dart';

/// «Избранное»: профили, отмеченные звездой. Свайп — убрать из избранного.
class FavoritesScreen extends StatelessWidget {
  /// Вкладка, из которой открыт экран: '/discover' или '/matches'.
  final String basePath;

  const FavoritesScreen({super.key, required this.basePath});

  @override
  Widget build(BuildContext context) {
    final shortlist = context.watch<ShortlistModel>(); // watch в build
    final profiles = [for (final id in shortlist.ids) profileById(id)];
    return Scaffold(
      appBar: AppBar(title: Text('Избранное · ${shortlist.count}')),
      body: profiles.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('Отмечайте звездой интересных людей — '
                    'они появятся здесь.',
                    textAlign: TextAlign.center),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: profiles.length,
              itemBuilder: (context, index) {
                final p = profiles[index];
                return Dismissible(
                  key: ValueKey(p.id), // идентичность из данных, не UniqueKey
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: const Icon(Icons.star_border),
                  ),
                  // read в callback-е: действие, а не показ
                  onDismissed: (_) {
                    context.read<ShortlistModel>().remove(p.id);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('${p.name} — убран(а) из избранного')));
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ProfileCard(
                      profile: p,
                      onTap: () => context.push('$basePath/${p.id}'),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
