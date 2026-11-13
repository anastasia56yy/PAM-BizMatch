import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_message.dart';
import 'result.dart';
import 'token_store.dart';

/// register / login по контракту; token уходит в TokenStore.
class AuthApi {
  AuthApi(this.baseUrl, this.tokens, {http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final TokenStore tokens;
  final http.Client _client;
  static const _timeout = Duration(seconds: 8);

  Future<Result<void>> register(String email, String password, String name) =>
      _post('/auth/register',
          {'email': email, 'password': password, 'name': name});

  Future<Result<void>> login(String email, String password) =>
      _post('/auth/login', {'email': email, 'password': password});

  Future<void> logout() => tokens.clear();

  /// register и login разнятся лишь путём и телом — общий скелет с тремя
  /// слоями отказа (C8).
  Future<Result<void>> _post(String path, Map<String, Object?> body) async {
    try {
      final res = await _client
          .post(Uri.parse('$baseUrl$path'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body))
          .timeout(_timeout);
      if (res.statusCode != 200 && res.statusCode != 201) {
        // слой 2: сервер ответил плохой вестью — 400 / 401 / 409
        return Err(apiMessage(res, login: true));
      }
      final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      await tokens.save(data['token'] as String); // C9: setString
      return const Ok(null);
    } on SocketException {
      return const Err('Нет сети — повторите попытку'); // слой 1: дорога
    } on http.ClientException {
      return const Err('Нет сети — повторите попытку');
    } on TimeoutException {
      return const Err('Сервер не отвечает');
    } on FormatException {
      return const Err('Ответ не тот, что обещан'); // слой 3: тело-сюрприз
    } on TypeError {
      return const Err('Ответ не тот, что обещан');
    }
  }
}
