import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/meeting.dart';
import '../models/meetings_model.dart';
import '../models/profiles_model.dart';
import '../utils/validators.dart';
import '../widgets/initials_avatar.dart';

/// «Предложить встречу»: валидация L3 + запись через MeetingsModel (L4).
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
  bool _busy = false; // эфемерное: кнопка гаснет, пока «запрос» летит

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

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return; // валидация L3, нетронута
    final profile = context.read<ProfilesModel>().byId(widget.profileId);
    if (profile == null) return;
    final draft = Meeting(
      0, // временный id — настоящую идентичность даст хранилище
      profile.id,
      profile.name,
      _topicCtrl.text.trim(),
      _date!,
      int.parse(_durationCtrl.text),
      _format!,
      _messageCtrl.text.trim(),
    );
    setState(() => _busy = true);
    final error = await context.read<MeetingsModel>().add(draft);
    if (!mounted) return; // экран может умереть, пока запрос летит
    setState(() => _busy = false);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error))); // данные остаются
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Запрос на встречу ${_dateCtrl.text} отправлен: '
            '${profile.name}')));
    context.pop(); // «Мои встречи» позади УЖЕ выросли — без лишних вызовов
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ProfilesModel>();
    final profile = model.byId(widget.profileId);
    if (profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Предложить встречу')),
        body: Center(
          child: model.isLoading
              ? const CircularProgressIndicator()
              : const Text('Профиль не существует'),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Предложить встречу')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: InitialsAvatar(
                  name: profile.name, photoUrl: profile.photoUrl),
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
              validator: (v) => validateMinLength(v, 5, 'Тема встречи'),
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
              items: [
                for (final f in Meeting.formats.entries)
                  DropdownMenuItem(value: f.key, child: Text(f.value)),
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
            FilledButton(
                onPressed: _busy ? null : _send,
                child: Text(_busy ? 'Отправляем…' : 'Отправить запрос')),
          ],
        ),
      ),
    );
  }
}
