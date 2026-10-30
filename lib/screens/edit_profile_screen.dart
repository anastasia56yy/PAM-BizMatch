import 'package:flutter/material.dart';

import '../data/mock_data.dart';

/// Форма-макет редактирования профиля.
class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Редактировать профиль')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: TextEditingController(text: myProfile.name),
            decoration: const InputDecoration(
                labelText: 'Имя и фамилия', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: TextEditingController(text: myProfile.title),
            decoration: const InputDecoration(
                labelText: 'Должность', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: TextEditingController(text: myProfile.company),
            decoration: const InputDecoration(
                labelText: 'Компания', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          const TextField(
            decoration: InputDecoration(
                labelText: 'Телефон',
                prefixText: '+373 ',
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          const TextField(
            decoration: InputDecoration(
                labelText: 'Ссылка на LinkedIn',
                hintText: 'https://linkedin.com/in/…',
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          DropdownMenu<Goal>(
            expandedInsets: EdgeInsets.zero,
            initialSelection: myProfile.goal,
            label: const Text('Цель на платформе'),
            dropdownMenuEntries: [
              for (final g in Goal.values)
                DropdownMenuEntry(value: g, label: g.label),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: TextEditingController(
                text: '${myProfile.experienceYears}'),
            decoration: const InputDecoration(
                labelText: 'Опыт, лет', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: TextEditingController(text: myProfile.about),
            maxLines: 4,
            decoration: const InputDecoration(
                labelText: 'О себе',
                alignLabelWithHint: true,
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: () {}, child: const Text('Сохранить')),
        ],
      ),
    );
  }
}
