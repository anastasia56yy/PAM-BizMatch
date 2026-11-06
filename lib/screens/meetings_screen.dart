import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/meeting.dart';
import '../models/meetings_model.dart';
import '../utils/validators.dart';
import '../widgets/error_view.dart';
import '../widgets/initials_avatar.dart';

/// «Мои встречи»: всё, что отправлено формой «Предложить встречу».
/// Свайп влево — отменить встречу (с подтверждением).
class MeetingsScreen extends StatelessWidget {
  const MeetingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<MeetingsModel>();
    final Widget body;
    if (model.isLoading) {
      body = const LoadingView();
    } else if (model.error != null) {
      body = ErrorView(
          message: model.error!,
          onRetry: () => context.read<MeetingsModel>().load());
    } else if (model.meetings.isEmpty) {
      body = const Center(
          child: Text('Встреч пока нет — предложите встречу из профиля'));
    } else {
      final meetings = model.meetings;
      body = ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: meetings.length,
        itemBuilder: (context, index) {
          final m = meetings[index];
          return Dismissible(
            key: ValueKey(m.id), // идентичность из данных, не UniqueKey
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              color: Theme.of(context).colorScheme.errorContainer,
              child: const Icon(Icons.event_busy),
            ),
            // удаление через хранилище: true — только если оно удалось
            confirmDismiss: (_) => _cancel(context, m),
            child: Card(
              child: ListTile(
                leading: InitialsAvatar(name: m.profileName),
                title: Text(m.topic),
                subtitle: Text('${m.profileName}\n'
                    '${formatDate(m.date)} · ${m.durationMin} мин · '
                    '${m.formatLabel}'),
                isThreeLine: true,
              ),
            ),
          );
        },
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Мои встречи')),
      body: body,
    );
  }

  Future<bool> _cancel(BuildContext context, Meeting m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Отменить встречу?'),
        content: Text('«${m.topic}» с ${m.profileName}, ${formatDate(m.date)}.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Нет')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: const Text('Отменить встречу')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return false;
    final messenger = ScaffoldMessenger.of(context);
    final error = await context.read<MeetingsModel>().remove(m.id);
    messenger.showSnackBar(SnackBar(
        content: Text(error ?? 'Встреча «${m.topic}» отменена')));
    return error == null;
  }
}
