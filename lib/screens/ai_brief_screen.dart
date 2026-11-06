import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/profile.dart';
import '../models/account_model.dart';
import '../models/profiles_model.dart';
import '../utils/validators.dart';

/// «Запрос к ИИ»: кого именно вы ищете — форма с валидацией (L3).
class AiBriefScreen extends StatefulWidget {
  const AiBriefScreen({super.key});

  @override
  State<AiBriefScreen> createState() => _AiBriefScreenState();
}

class _AiBriefScreenState extends State<AiBriefScreen> {
  final _formKey = GlobalKey<FormState>();
  final _queryCtrl = TextEditingController();
  final _industryCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController(text: '3');
  Goal? _goal;
  bool _sameCity = true;

  @override
  void dispose() {
    _queryCtrl.dispose();
    _industryCtrl.dispose();
    _experienceCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final city = _sameCity ? context.read<AccountModel>().me?.city : null;
    final profiles = context.read<ProfilesModel>()
      ..applyBrief(AiBrief(
        _queryCtrl.text.trim(),
        _goal!,
        _industryCtrl.text.trim(),
        int.parse(_experienceCtrl.text),
        city,
      ));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('ИИ обновил подбор: «${_goal!.label}» — '
            'кандидатов: ${profiles.matches.length}')));
    context.pop(); // «ИИ-подбор» позади уже показывает новый рейтинг
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Запрос к ИИ')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Опишите своими словами, кого вы ищете. ИИ сопоставит запрос '
              'с профилями и выставит оценку совместимости.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _queryCtrl,
              maxLines: 4,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Кого вы ищете?',
                hintText:
                    'Напр.: инвестор в B2B SaaS на seed-стадии из Румынии',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              validator: (v) => validateMinLength(v, 20, 'Запрос'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Goal>(
              initialValue: _goal,
              decoration: const InputDecoration(
                labelText: 'Цель знакомства',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final g in Goal.values)
                  DropdownMenuItem(value: g, child: Text(g.label)),
              ],
              onChanged: (v) => setState(() => _goal = v),
              validator: (v) => v == null ? 'Выберите цель' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _industryCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Отрасль',
                hintText: 'FinTech, телеком, IT…',
                border: OutlineInputBorder(),
              ),
              validator: (v) => requiredField(v, 'Укажите отрасль'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _experienceCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Минимальный опыт, лет',
                border: OutlineInputBorder(),
              ),
              validator: (v) => validateIntRange(v, 0, 40, 'лет'),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _sameCity,
              onChanged: (v) => setState(() => _sameCity = v),
              title: const Text('Только мой город'),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Подобрать кандидатов'),
            ),
          ],
        ),
      ),
    );
  }
}
