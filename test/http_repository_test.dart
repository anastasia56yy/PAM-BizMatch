import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:biz_match/data/api_client.dart';
import 'package:biz_match/data/http_repositories.dart';
import 'package:biz_match/data/result.dart';
import 'package:biz_match/data/token_store.dart';

const _profile = {
  'id': 7,
  'name': 'Ирина Чобану',
  'title': 'Partner',
  'company': 'Moldova Growth Fund',
  'industry': 'Финансы',
  'city': 'Кишинёв',
  'goal': 'investor',
  'experience_years': 14,
  'skills': ['Seed-раунды'],
  'about': '',
  'ai_score': 96,
  'ai_reason': 'Инвестирует в B2B SaaS',
};

http.Response _json(Object body, int status) => http.Response.bytes(
    utf8.encode(jsonEncode(body)), status,
    headers: {'content-type': 'application/json; charset=utf-8'});

void main() {
  late TokenStore tokens;
  setUp(() async {
    SharedPreferences.setMockInitialValues({'auth_token': 'valid-token'});
    tokens = TokenStore();
  });

  HttpProfileRepository repo(MockClientHandler handler,
          {void Function()? onUnauthorized}) =>
      HttpProfileRepository(ApiClient('http://api', tokens,
          client: MockClient(handler), onUnauthorized: onUnauthorized));

  test('fetchAll: Bearer уходит, конверт разбирается через fromJson', () async {
    String? auth;
    final r = await repo((req) async {
      auth = req.headers['Authorization'];
      return _json({'items': [_profile], 'page': 1, 'limit': 20, 'total': 1}, 200);
    }).fetchAll();
    expect(auth, 'Bearer valid-token');
    expect(r, isA<Ok>());
    final p = (r as Ok).value.single;
    expect(p.name, 'Ирина Чобану');
    expect(p.skills, ['Seed-раунды']);
  });

  test('404 → русское сообщение из конверта', () async {
    final r = await repo((_) async =>
        _json({'error': {'code': 'NOT_FOUND', 'message': 'Profile not found'}}, 404))
        .fetchById(99);
    expect((r as Err).msg, 'Запись не существует');
  });

  test('401 → token стёрт, корень извещён', () async {
    var called = false;
    final r = await repo(
        (_) async => _json({'error': {'code': 'UNAUTHORIZED', 'message': 'x'}}, 401),
        onUnauthorized: () => called = true).fetchAll();
    expect((r as Err).msg, 'Сессия истекла — войдите снова');
    expect(await tokens.read(), isNull);
    expect(called, isTrue);
  });

  test('DELETE 204: пустое тело не парсится → Ok', () async {
    final r = await repo((_) async => http.Response('', 204)).delete(7);
    expect(r, isA<Ok>());
  });

  test('сеть упала → «Нет сети»', () async {
    final r = await repo((_) async => throw http.ClientException('refused'))
        .fetchAll();
    expect((r as Err).msg, 'Нет сети — повторите попытку');
  });

  test('500 с HTML вместо конверта → «Ошибка сервера (500)»', () async {
    final r = await repo((_) async => http.Response('<html>oops</html>', 500))
        .fetchAll();
    expect((r as Err).msg, 'Ошибка сервера (500)');
  });

  test('200, но тело не по контракту → «Ответ не тот, что обещан»', () async {
    final r = await repo((_) async => http.Response('<html>proxy</html>', 200))
        .fetchAll();
    expect((r as Err).msg, 'Ответ не тот, что обещан');
  });
}
