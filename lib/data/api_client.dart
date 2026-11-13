import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_message.dart';
import 'result.dart';
import 'token_store.dart';

/// Скелет каждого запроса к backend-у (fetchNotes с C8, вынесенный в одно
/// место): Bearer, timeout, вердикт по статусу и три слоя отказа → Err(msg).
class ApiClient {
  ApiClient(this.baseUrl, this.tokens,
      {this.onUnauthorized, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final TokenStore tokens;

  /// 401: решает корень композиции (назад на login) — клиент router не знает.
  final void Function()? onUnauthorized;
  final http.Client _client;
  static const _timeout = Duration(seconds: 8);

  /// [okStatus] — «хороший» статус метода: 200, 201 или 204.
  /// [parse] превращает JSON-ответ в данные; на 204 тела нет — parse(null).
  Future<Result<T>> send<T>(
    String method,
    String path, {
    Object? body,
    required int okStatus,
    required T Function(Object? json) parse,
  }) async {
    try {
      final request = http.Request(method, Uri.parse('$baseUrl$path'))
        ..headers.addAll(await _headers());
      if (body != null) request.body = jsonEncode(body);
      final res = await http.Response.fromStream(
          await _client.send(request).timeout(_timeout)); // timeout обязателен

      if (res.statusCode == 401) return Err(await _sessionDied());
      if (res.statusCode != okStatus) {
        return Err(apiMessage(res)); // слой 2: плохая весть сервера
      }
      if (res.statusCode == 204) return Ok(parse(null)); // без jsonDecode!
      return Ok(parse(jsonDecode(utf8.decode(res.bodyBytes))));
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

  Future<Map<String, String>> _headers() async => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await tokens.read() ?? ''}',
      };

  /// 401 = пропуск умер: token выбрасывается (C9), корень навигирует.
  Future<String> _sessionDied() async {
    await tokens.clear();
    onUnauthorized?.call();
    return 'Сессия истекла — войдите снова';
  }
}

/// Пагинированный конверт {items, page, limit, total} → список.
List<T> itemsOf<T>(Object? json, T Function(Map<String, dynamic>) fromJson) => [
      for (final e in (json as Map<String, dynamic>)['items'] as List)
        fromJson(e as Map<String, dynamic>)
    ];
