import 'dart:convert';

import 'package:http/http.dart' as http;

/// Вскрывает конверт ошибки {"error":{"code","message"}} и переводит code
/// в русское сообщение — один раз, в одном месте. Английский message
/// сервера на экран не попадает.
String apiMessage(http.Response res, {bool login = false}) {
  try {
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final code = (body['error'] as Map<String, dynamic>)['code'] as String;
    return switch (code) {
      'VALIDATION_ERROR' => 'Отправленные данные недействительны',
      'UNAUTHORIZED' =>
        login ? 'Неверный email или пароль' : 'Сессия истекла — войдите снова',
      'EMAIL_TAKEN' => 'Аккаунт с этим email уже существует',
      'NOT_FOUND' => 'Запись не существует',
      _ => 'Ошибка сервера ($code)',
    };
  } on FormatException {
    // тело вне контракта: HTML от прокси, 500 с текстом и т. п.
    return 'Ошибка сервера (${res.statusCode})';
  } on TypeError {
    return 'Ошибка сервера (${res.statusCode})';
  }
}
