import 'dart:convert';

import 'package:shelf/shelf.dart';

/// Общие помощники HTTP: JSON-ответы и единый конверт ошибки контракта
/// {"error": {"code": "...", "message": "..."}}.

const _jsonHeaders = {'content-type': 'application/json; charset=utf-8'};

Response jsonOk(Object? body, {int status = 200}) =>
    Response(status, body: jsonEncode(body), headers: _jsonHeaders);

Response apiError(int status, String code, String message) => Response(status,
    body: jsonEncode({
      'error': {'code': code, 'message': message}
    }),
    headers: _jsonHeaders);

Response validationError(String message) =>
    apiError(400, 'VALIDATION_ERROR', message);

Response notFound([String message = 'Resource not found']) =>
    apiError(404, 'NOT_FOUND', message);

Response unauthorized([String message = 'Missing or invalid token']) =>
    apiError(401, 'UNAUTHORIZED', message);

/// Тело запроса как JSON-объект; null — тело не JSON или не объект.
Future<Map<String, dynamic>?> readJsonObject(Request request) async {
  try {
    final decoded = jsonDecode(await request.readAsString());
    return decoded is Map<String, dynamic> ? decoded : null;
  } on FormatException {
    return null;
  }
}

/// id пользователя, положенный в контекст auth-middleware.
int userIdOf(Request request) => request.context['userId'] as int;

/// Параметры пагинации ?page=&limit=; null — параметры некорректны.
({int page, int limit})? pagination(Request request) {
  final q = request.url.queryParameters;
  final page = int.tryParse(q['page'] ?? '1');
  final limit = int.tryParse(q['limit'] ?? '20');
  if (page == null || limit == null || page < 1 || limit < 1 || limit > 100) {
    return null;
  }
  return (page: page, limit: limit);
}

String nowIso() => DateTime.now().toUtc().toIso8601String();
