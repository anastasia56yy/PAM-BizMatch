import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../widgets/initials_avatar.dart';

/// Форма-макет «Предложить встречу» (валидация придёт на L3).
class MeetingRequestScreen extends StatelessWidget {
  final int profileId;

  const MeetingRequestScreen({super.key, required this.profileId});

  @override
  Widget build(BuildContext context) {
    final profile = profileById(profileId);
    return Scaffold(
      appBar: AppBar(title: const Text('Предложить встречу')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: InitialsAvatar(name: profile.name),
            title: Text(profile.name),
            subtitle: Text('${profile.title} · ${profile.company}'),
          ),
          const SizedBox(height: 16),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Тема встречи',
              hintText: 'Напр.: обсуждение seed-раунда',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Дата (ДД.ММ.ГГГГ)',
              prefixIcon: Icon(Icons.calendar_today),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Длительность, мин',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownMenu<String>(
            expandedInsets: EdgeInsets.zero,
            label: const Text('Формат'),
            dropdownMenuEntries: const [
              DropdownMenuEntry(value: 'online', label: 'Онлайн (Zoom / Meet)'),
              DropdownMenuEntry(value: 'office', label: 'В офисе'),
              DropdownMenuEntry(value: 'coffee', label: 'Бизнес-кофе'),
            ],
          ),
          const SizedBox(height: 16),
          const TextField(
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Сообщение',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: () {}, child: const Text('Отправить запрос')),
        ],
      ),
    );
  }
}
