import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/auth_api.dart';
import '../data/result.dart';
import '../models/account_model.dart';
import '../models/chats_model.dart';
import '../models/meetings_model.dart';
import '../models/profiles_model.dart';
import '../utils/validators.dart';

/// Вход и регистрация: валидация L3 + настоящий backend (L5).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isRegister = false; // эфемерное: режим формы
  bool _busy = false; // кнопка гаснет на время запроса — без двойного submit

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return; // валидация L3, нетронута
    setState(() => _busy = true);
    final auth = context.read<AuthApi>();
    final result = _isRegister
        ? await auth.register(_emailCtrl.text.trim(), _passwordCtrl.text,
            _nameCtrl.text.trim())
        : await auth.login(_emailCtrl.text.trim(), _passwordCtrl.text);
    if (!mounted) return; // экран может умереть, пока запрос летит
    setState(() => _busy = false);
    switch (result) {
      case Ok():
        // новый пропуск — данные нового пользователя: перезагрузить модели
        context.read<ProfilesModel>().load();
        context.read<ChatsModel>().load();
        context.read<MeetingsModel>().load();
        context.read<AccountModel>().load();
        context.go('/discover'); // go, НЕ push: login УХОДИТ из стека
      case Err(:final msg):
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.handshake, size: 72, color: scheme.primary),
                  const SizedBox(height: 12),
                  Text('BizMatch',
                      textAlign: TextAlign.center,
                      style: text.headlineMedium),
                  const SizedBox(height: 4),
                  Text(
                    _isRegister
                        ? 'Создайте аккаунт'
                        : 'Деловые знакомства с ИИ-подбором',
                    textAlign: TextAlign.center,
                    style: text.bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 32),
                  if (_isRegister) ...[
                    TextFormField(
                      controller: _nameCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Имя',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => requiredField(v, 'Введите имя'),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon: Icon(Icons.alternate_email),
                      border: OutlineInputBorder(),
                    ),
                    validator: validateEmail,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _busy ? null : _submit(),
                    decoration: const InputDecoration(
                      labelText: 'Пароль',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: validatePassword,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_isRegister ? 'Зарегистрироваться' : 'Войти'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() => _isRegister = !_isRegister),
                    child: Text(_isRegister
                        ? 'Уже есть аккаунт? Войти'
                        : 'Нет аккаунта? Зарегистрируйтесь'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
