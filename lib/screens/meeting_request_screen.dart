import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_data.dart';
import '../utils/validators.dart';
import '../widgets/initials_avatar.dart';

/// «Предложить встречу» — форма, функциональная локально (L3).
class MeetingRequestScreen extends StatefulWidget {
  final int profileId;

  const MeetingRequestScreen({super.key, required this.profileId});

  @override
  State<MeetingRequestScreen> createState() => _MeetingRequestScreenState();
}

class _MeetingRequestScreenState extends State<MeetingRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _topicCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '30');
  final _messageCtrl = TextEditingController();
  DateTime? _date;
  String? _format;

  @override
  void dispose() {
    _topicCtrl.dispose(); // кто создаёт, тот освобождает
    _dateCtrl.dispose();
    _durationCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now.add(const Duration(days: 1)),
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
        _dateCtrl.text = formatDate(picked);
      });
    }
  }

  void _send() {
    if (!_formKey.currentState!.validate()) return; // ошибки уже на экране
    final name = profileById(widget.profileId).name;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Запрос на встречу ${_dateCtrl.text} отправлен: $name')));
    context.pop(); // открыто push-ем → закрывается pop-ом
  }

  @override
  Widget build(BuildContext context) {
    final profile = profileById(widget.profileId);
    return Scaffold(
      appBar: AppBar(title: const Text('Предложить встречу')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: InitialsAvatar(name: profile.name),
              title: Text(profile.name),
              subtitle: Text('${profile.title} · ${profile.company}'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _topicCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Тема встречи',
                hintText: 'Напр.: обсуждение seed-раунда',
                border: OutlineInputBorder(),
              ),
              validator: (v) => validateMinLength(v, 5, 'Тема'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dateCtrl,
              readOnly: true,
              onTap: _pickDate,
              decoration: const InputDecoration(
                labelText: 'Дата',
                prefixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
              ),
              validator: (_) => validateFutureDate(_date),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _durationCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Длительность, мин',
                border: OutlineInputBorder(),
              ),
              validator: (v) => validateIntRange(v, 15, 180, 'минут'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _format,
              decoration: const InputDecoration(
                labelText: 'Формат',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                    value: 'online', child: Text('Онлайн (Zoom / Meet)')),
                DropdownMenuItem(value: 'office', child: Text('В офисе')),
                DropdownMenuItem(value: 'coffee', child: Text('Бизнес-кофе')),
              ],
              onChanged: (v) => setState(() => _format = v),
              validator: (v) => v == null ? 'Выберите формат' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _messageCtrl,
              maxLines: 4,
              maxLength: 500,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Сообщение (необязательно)',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _send, child: const Text('Отправить запрос')),
          ],
        ),
      ),
    );
  }
}
