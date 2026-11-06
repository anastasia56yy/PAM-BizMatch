import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/profile.dart';
import '../models/account_model.dart';
import '../utils/validators.dart';

/// Редактирование профиля: валидация L3 + запись через AccountModel (L4).
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  // профиль, который правим: берём из модели один раз, при открытии формы
  late final Profile? _me;
  late final _nameCtrl = TextEditingController(text: _me?.name);
  late final _titleCtrl = TextEditingController(text: _me?.title);
  late final _companyCtrl = TextEditingController(text: _me?.company);
  late final _emailCtrl = TextEditingController(text: _me?.email);
  late final _phoneCtrl = TextEditingController(text: _me?.phone);
  late final _linkedInCtrl = TextEditingController(text: _me?.linkedIn);
  late final _experienceCtrl =
      TextEditingController(text: '${_me?.experienceYears ?? ''}');
  late final _aboutCtrl = TextEditingController(text: _me?.about);
  late Goal? _goal = _me?.goal;
  bool _busy = false; // эфемерное: кнопка гаснет, пока «запрос» летит

  @override
  void initState() {
    super.initState();
    _me = context.read<AccountModel>().me; // read — не в build (C7)
  }

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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return; // валидация L3, нетронута
    final updated = _me!.copyWith(
      name: _nameCtrl.text.trim(),
      title: _titleCtrl.text.trim(),
      company: _companyCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text,
      linkedIn: _linkedInCtrl.text.trim(),
      goal: _goal,
      experienceYears: int.parse(_experienceCtrl.text),
      about: _aboutCtrl.text.trim(),
    );
    setState(() => _busy = true);
    final error = await context.read<AccountModel>().save(updated);
    if (!mounted) return; // экран может умереть, пока запрос летит
    setState(() => _busy = false);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error))); // данные остаются
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Профиль сохранён')));
    context.pop(); // «Мой профиль» позади уже показывает новые данные
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
    if (_me == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Редактировать профиль')),
        body: const Center(child: Text('Профиль ещё не загружен')),
      );
    }
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
            FilledButton(
                onPressed: _busy ? null : _save,
                child: Text(_busy ? 'Сохраняем…' : 'Сохранить')),
          ],
        ),
      ),
    );
  }
}
