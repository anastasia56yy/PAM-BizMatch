import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_data.dart';
import '../data/profile.dart';
import '../utils/validators.dart';

/// Редактирование профиля — форма с валидацией (L3).
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController(text: myProfile.name);
  final _titleCtrl = TextEditingController(text: myProfile.title);
  final _companyCtrl = TextEditingController(text: myProfile.company);
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _linkedInCtrl = TextEditingController();
  final _experienceCtrl =
      TextEditingController(text: '${myProfile.experienceYears}');
  final _aboutCtrl = TextEditingController(text: myProfile.about);
  Goal? _goal = myProfile.goal;

  @override
  void dispose() {
    _nameCtrl.dispose(); // по одному dispose() на контроллер
    _titleCtrl.dispose();
    _companyCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _linkedInCtrl.dispose();
    _experienceCtrl.dispose();
    _aboutCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Профиль сохранён')));
    context.pop();
  }

  InputDecoration _dec(String label, {String? hint, String? prefix}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefix,
        alignLabelWithHint: true,
        border: const OutlineInputBorder(),
      );

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 16);
    return Scaffold(
      appBar: AppBar(title: const Text('Редактировать профиль')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              textInputAction: TextInputAction.next,
              decoration: _dec('Имя и фамилия'),
              validator: (v) => requiredField(v, 'Имя обязательно'),
            ),
            gap,
            TextFormField(
              controller: _titleCtrl,
              textInputAction: TextInputAction.next,
              decoration: _dec('Должность'),
              validator: (v) => requiredField(v, 'Укажите должность'),
            ),
            gap,
            TextFormField(
              controller: _companyCtrl,
              textInputAction: TextInputAction.next,
              decoration: _dec('Компания'),
              validator: (v) => requiredField(v, 'Укажите компанию'),
            ),
            gap,
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: _dec('Рабочий e-mail'),
              validator: validateEmail,
            ),
            gap,
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(8),
              ],
              textInputAction: TextInputAction.next,
              decoration: _dec('Телефон', prefix: '+373 '),
              validator: validatePhone,
            ),
            gap,
            TextFormField(
              controller: _linkedInCtrl,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
              decoration: _dec('Ссылка на LinkedIn (необязательно)',
                  hint: 'https://linkedin.com/in/…'),
              validator: validateLinkedIn,
            ),
            gap,
            DropdownButtonFormField<Goal>(
              initialValue: _goal,
              decoration: _dec('Цель на платформе'),
              items: [
                for (final g in Goal.values)
                  DropdownMenuItem(value: g, child: Text(g.label)),
              ],
              onChanged: (v) => setState(() => _goal = v),
              validator: (v) => v == null ? 'Выберите цель' : null,
            ),
            gap,
            TextFormField(
              controller: _experienceCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.next,
              decoration: _dec('Опыт, лет'),
              validator: (v) => validateIntRange(v, 0, 60, 'лет'),
            ),
            gap,
            TextFormField(
              controller: _aboutCtrl,
              maxLines: 4,
              maxLength: 300,
              textInputAction: TextInputAction.done,
              decoration: _dec('О себе'),
              validator: (v) => validateMinLength(v, 30, 'Текст'),
            ),
            const SizedBox(height: 8),
            FilledButton(onPressed: _save, child: const Text('Сохранить')),
          ],
        ),
      ),
    );
  }
}
