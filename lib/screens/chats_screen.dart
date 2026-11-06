import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/chats_model.dart';
import '../widgets/error_view.dart';
import '../widgets/initials_avatar.dart';

/// «Контакты»: взаимные знакомства и переписка с ними.
class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final model = context.watch<ChatsModel>();
    final Widget body;
    if (model.isLoading) {
      body = const LoadingView();
    } else if (model.error != null) {
      body = ErrorView(
          message: model.error!,
          onRetry: () => context.read<ChatsModel>().load());
    } else if (model.conversations.isEmpty) {
      body = const Center(
          child: Text('Контактов пока нет — начните в «Знакомствах»'));
    } else {
      final chats = model.conversations;
      body = ListView.separated(
        itemCount: chats.length,
        separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
        itemBuilder: (context, index) {
          final c = chats[index];
          return ListTile(
            key: ValueKey(c.id),
            leading: InitialsAvatar(name: c.name),
            title: Text(c.name),
            subtitle: Text(c.lastMessage,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(c.time, style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 4),
                if (c.unread > 0)
                  Badge(
                    label: Text('${c.unread}'),
                    backgroundColor: scheme.primary,
                  ),
              ],
            ),
            onTap: () => context.push('/chats/${c.id}'),
          );
        },
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Контакты'),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            onPressed: () => context.read<ChatsModel>().load(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: body,
    );
  }
}
