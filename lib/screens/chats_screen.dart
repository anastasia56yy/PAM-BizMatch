import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_data.dart';
import '../widgets/initials_avatar.dart';

/// «Контакты»: взаимные знакомства и переписка с ними.
class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Контакты')),
      body: ListView.separated(
        itemCount: mockConversations.length,
        separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
        itemBuilder: (context, index) {
          final c = mockConversations[index];
          return ListTile(
            leading: InitialsAvatar(name: c.profile.name),
            title: Text(c.profile.name),
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
      ),
    );
  }
}
