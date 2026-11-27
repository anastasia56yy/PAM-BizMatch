import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:biz_match/data/api_client.dart';
import 'package:biz_match/data/file_api.dart';
import 'package:biz_match/data/profile.dart';
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

  test('пагинация и поиск уходят в query params', () async {
    Uri? url;
    await repo((req) async {
      url = req.url;
      return _json({'items': [], 'page': 2, 'limit': 20, 'total': 0}, 200);
    }).fetchAll(page: 2, search: 'Телеком');
    expect(url!.path, '/profiles');
    expect(url!.queryParameters,
        {'page': '2', 'limit': '20', 'search': 'Телеком'});
  });

  // ── Задание 7: фото и upload ───────────────────────────────────────────

  test('photo_url: из JSON в Profile и обратно', () {
    final p = Profile.fromJson({..._profile, 'photo_url': '/avatars/01.jpg'});
    expect(p.photoUrl, '/avatars/01.jpg');
    expect(p.toJson()['photo_url'], '/avatars/01.jpg');
    expect(Profile.fromJson(_profile).photoUrl, ''); // старый сервер — без фото
  });

  FileApi files(MockClientHandler handler) => FileApi(
      ApiClient('http://api', tokens, client: MockClient(handler)));

  test('upload: multipart с Bearer на POST /files → относительный url',
      () async {
    final file = File('${Directory.systemTemp.path}/bizmatch_avatar.jpg')
      ..writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xE0, 1, 2, 3]);
    late http.Request seen;
    final r = await files((req) async {
      seen = req;
      return _json({'id': 7, 'url': '/files/7'}, 201);
    }).upload(file.path);
    expect((r as Ok).value, '/files/7');
    expect(seen.url.path, '/files');
    expect(seen.headers['Authorization'], 'Bearer valid-token');
    expect(seen.headers['content-type'], startsWith('multipart/form-data'));
    expect(latin1.decode(seen.bodyBytes), contains('name="file"'));
  });

  test('upload: 400 «больше 5 МБ» → русское сообщение', () async {
    final file = File('${Directory.systemTemp.path}/bizmatch_big.jpg')
      ..writeAsBytesSync([1, 2, 3]);
    final r = await files((_) async => _json(
        {'error': {'code': 'VALIDATION_ERROR', 'message': 'File is larger than 5 MB'}},
        400)).upload(file.path);
    expect((r as Err).msg, 'Отправленные данные недействительны');
  });

  test('upload: файла нет на диске → Err, а не crash', () async {
    final r = await files((_) async => _json({}, 201))
        .upload('${Directory.systemTemp.path}/no_such_file.jpg');
    expect((r as Err).msg, 'Файл не удалось прочитать');
  });
}
