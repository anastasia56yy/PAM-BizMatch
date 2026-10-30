import 'package:flutter/material.dart';

import '../data/mock_data.dart';

/// Форма-макет «Запрос к ИИ»: кого именно вы ищете.
class AiBriefScreen extends StatelessWidget {
  const AiBriefScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Запрос к ИИ')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Опишите своими словами, кого вы ищете. ИИ сопоставит запрос '
            'с профилями и выставит оценку совместимости.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: 16),
          const TextField(
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Кого вы ищете?',
              hintText: 'Напр.: инвестор в B2B SaaS на seed-стадии из Румынии',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownMenu<Goal>(
            expandedInsets: EdgeInsets.zero,
            label: const Text('Цель знакомства'),
            dropdownMenuEntries: [
              for (final g in Goal.values)
                DropdownMenuEntry(value: g, label: g.label),
            ],
          ),
          const SizedBox(height: 16),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Отрасль',
              hintText: 'FinTech, телеком, IT…',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Минимальный опыт, лет',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: true,
            onChanged: (_) {},
            title: const Text('Только мой город'),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Подобрать кандидатов'),
          ),
        ],
      ),
    );
  }
}
