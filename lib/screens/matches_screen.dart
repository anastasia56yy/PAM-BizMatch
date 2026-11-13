import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/profile.dart';
import '../models/profiles_model.dart';
import '../widgets/error_view.dart';
import '../widgets/profile_card.dart';
import '../widgets/shortlist_button.dart';

/// «ИИ-подбор»: рейтинг лучших кандидатов + поиск и фильтр по цели.
class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  // эфемерное: текст в поле поиска и выбранный чип нужны только этому экрану
  late final TextEditingController _searchCtrl;
  Goal? _goal;

  @override
  void initState() {
    super.initState();
    // read — в initState, не в build (C7): поле помнит текущий поиск модели
    _searchCtrl =
        TextEditingController(text: context.read<ProfilesModel>().search);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Поиск идёт НА СЕРВЕРЕ: телефон получает только свой ломоть.
  void _search(String q) => context.read<ProfilesModel>().load(search: q.trim());

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ProfilesModel>(); // watch в build
    final Widget body;
    if (model.isLoading) {
      body = const LoadingView();
    } else if (model.error != null) {
      body = ErrorView(
          message: model.error!,
          onRetry: () => context.read<ProfilesModel>().load()); // поиск сохранён
    } else {
      final list = model.matches
          .where((p) => _goal == null || p.goal == _goal)
          .toList();
      final header = <Widget>[
        _BriefCard(brief: model.brief),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final g in <Goal?>[null, ...Goal.values])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(g?.label ?? 'Все'),
                    selected: _goal == g,
                    onSelected: (_) => setState(() => _goal = g),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
            model.search.isEmpty
                ? 'Лучшие кандидаты · ${list.length}'
                : 'Найдено по «${model.search}» · ${list.length}',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        if (list.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Под этот запрос пока никого нет — '
                'смягчите фильтры или сбросьте запрос к ИИ.',
                textAlign: TextAlign.center),
          ),
      ];
      body = ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        // заголовок + карточки + хвост, который просит следующую страницу
        itemCount: header.length + list.length + (model.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < header.length) return header[index];
          final i = index - header.length;
          if (i == list.length) {
            context.read<ProfilesModel>().loadMore(); // хвост виден → ещё
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                  child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2))),
            );
          }
          final p = list[i];
          return Padding(
            key: ValueKey(p.id),
            padding: const EdgeInsets.only(bottom: 8),
            child: ProfileCard(
              profile: p,
              showReason: true,
              // зайду и вернусь → push; в адресе путешествует только id
              onTap: () => context.push('/matches/${p.id}'),
            ),
          );
        },
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('ИИ-подбор'),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            onPressed: () => context.read<ProfilesModel>().load(),
            icon: const Icon(Icons.refresh),
          ),
          const ShortlistButton(basePath: '/matches'),
        ],
      ),
      body: Column(
        children: [
          // поле поиска вне триады: при загрузке оно не исчезает
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SearchBar(
              controller: _searchCtrl,
              hintText: 'Имя, компания или навык',
              leading: const Icon(Icons.search),
              textInputAction: TextInputAction.search,
              onSubmitted: _search,
              trailing: [
                if (model.search.isNotEmpty)
                  IconButton(
                    tooltip: 'Сбросить поиск',
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _searchCtrl.clear();
                      _search('');
                    },
                  ),
              ],
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// Карточка текущего запроса к ИИ: его пишет форма, читает этот экран.
class _BriefCard extends StatelessWidget {
  final AiBrief? brief;

  const _BriefCard({required this.brief});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final b = brief;
    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: scheme.onPrimaryContainer),
                const SizedBox(width: 8),
                Text('Ваш запрос к ИИ',
                    style: text.titleMedium
                        ?.copyWith(color: scheme.onPrimaryContainer)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              b == null
                  ? 'Запрос не задан — показан общий рейтинг совместимости.'
                  : '«${b.query}»\n${b.goal.label} · ${b.industry} · '
                      'опыт от ${b.minExperience} лет'
                      '${b.city == null ? '' : ' · ${b.city}'}',
              style:
                  text.bodyMedium?.copyWith(color: scheme.onPrimaryContainer),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => context.push('/matches/brief'),
                  icon: const Icon(Icons.edit_note),
                  label: Text(b == null ? 'Задать запрос' : 'Уточнить запрос'),
                ),
                if (b != null)
                  TextButton(
                    onPressed: () => context.read<ProfilesModel>().clearBrief(),
                    child: const Text('Сбросить'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
