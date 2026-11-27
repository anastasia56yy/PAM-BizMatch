import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/chats_model.dart';
import '../models/profiles_model.dart';
import '../widgets/initials_avatar.dart';

class ChatScreen extends StatefulWidget {
  final int conversationId;

  const ChatScreen({super.key, required this.conversationId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textCtrl = TextEditingController(); // эфемерное: черновик сообщения
  bool _sending = false;

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final error = await context
        .read<ChatsModel>()
        .sendMessage(widget.conversationId, text);
    if (!mounted) return;
    setState(() => _sending = false);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error))); // текст остаётся
      return;
    }
    _textCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final model = context.watch<ChatsModel>();
    final c = model.byId(widget.conversationId);
    if (c == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: model.isLoading
              ? const CircularProgressIndicator()
              : const Text('Переписка не существует'),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: InitialsAvatar(
              name: c.name,
              radius: 18,
              photoUrl: context
                      .watch<ProfilesModel>()
                      .byId(c.profileId)
                      ?.photoUrl ??
                  ''),
          title: Text(c.name, overflow: TextOverflow.ellipsis),
          subtitle: Text(c.company, overflow: TextOverflow.ellipsis),
        ),
        actions: [
          IconButton(
            onPressed: () => _deleteContact(c.name),
            icon: const Icon(Icons.person_remove_outlined),
            tooltip: 'Удалить контакт',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: c.messages.isEmpty
                ? const Center(child: Text('Напишите первое сообщение'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: c.messages.length,
                    itemBuilder: (context, index) {
                      final m = c.messages[index];
                      return Align(
                        alignment: m.fromMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 280),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: m.fromMe
                                ? scheme.primaryContainer
                                : scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(m.text),
                              const SizedBox(height: 2),
                              Text(m.time,
                                  style:
                                      Theme.of(context).textTheme.labelSmall),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textCtrl,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Сообщение…',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                      onPressed: _sending ? null : _send,
                      icon: const Icon(Icons.send)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteContact(String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Удалить контакт?'),
        content: Text('Переписка с $name будет удалена без возможности '
            'восстановления.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Отмена')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: const Text('Удалить')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final error =
        await context.read<ChatsModel>().remove(widget.conversationId);
    if (!mounted) return; // экран может умереть, пока «запрос» летит
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Контакт $name удалён')));
    context.pop(); // объекта больше нет — его экран уходит из стека
  }
}
