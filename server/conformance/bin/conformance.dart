// Набор тестов соответствия: бьёт по серверу через HTTP так же, как будет
// бить приложение, и проверяет каждую букву контракта.
//
// Запуск: dart run bin/conformance.dart --base-url http://localhost:8080
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;

late String base;
int passed = 0;
final failures = <String>[];

Future<void> main(List<String> args) async {
  final i = args.indexOf('--base-url');
  base = i >= 0 && i + 1 < args.length ? args[i + 1] : 'http://localhost:8080';
  stdout.writeln('Conformance suite → $base\n');

  // уникальные адреса: набор можно гонять повторно на той же базе
  final run = '${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(999)}';
  final emailA = 'a$run@test.md';
  final emailB = 'b$run@test.md';
  late String tokenA, tokenB;
  late int noteId;

  // ── health ───────────────────────────────────────────────────────────
  await check('GET /health → 200 {"status":"ok"}', () async {
    final r = await get('/health');
    return r.statusCode == 200 && body(r)['status'] == 'ok';
  });

  // ── auth ─────────────────────────────────────────────────────────────
  await check('GET /notes без token-а → 401 UNAUTHORIZED', () async {
    return isError(await get('/notes'), 401, 'UNAUTHORIZED');
  });
  await check('GET /notes с мусорным token-ом → 401', () async {
    return isError(await get('/notes', token: 'garbage'), 401, 'UNAUTHORIZED');
  });
  await check('POST /auth/register → 201 token + user', () async {
    final r = await post('/auth/register',
        {'email': emailA, 'password': 'parola123', 'name': 'Ana'});
    final b = body(r);
    if (r.statusCode != 201 || b['token'] is! String) return false;
    tokenA = b['token'] as String;
    final user = b['user'] as Map<String, dynamic>;
    return user['id'] is int && user['email'] == emailA && user['name'] == 'Ana';
  });
  await check('POST /auth/register тот же email → 409 EMAIL_TAKEN', () async {
    final r = await post('/auth/register',
        {'email': emailA, 'password': 'parola123', 'name': 'Ana'});
    return isError(r, 409, 'EMAIL_TAKEN');
  });
  await check('POST /auth/register без name → 400 VALIDATION_ERROR', () async {
    final r = await post(
        '/auth/register', {'email': 'x$run@test.md', 'password': 'parola123'});
    return isError(r, 400, 'VALIDATION_ERROR');
  });
  await check('POST /auth/register пароль < 6 → 400', () async {
    final r = await post('/auth/register',
        {'email': 'y$run@test.md', 'password': '123', 'name': 'Y'});
    return isError(r, 400, 'VALIDATION_ERROR');
  });
  await check('POST /auth/register неверный email → 400', () async {
    final r = await post('/auth/register',
        {'email': 'not-an-email', 'password': 'parola123', 'name': 'Z'});
    return isError(r, 400, 'VALIDATION_ERROR');
  });
  await check('POST /auth/register тело не JSON → 400', () async {
    final r = await http.post(Uri.parse('$base/auth/register'),
        headers: {'Content-Type': 'application/json'}, body: '{oops');
    return isError(r, 400, 'VALIDATION_ERROR');
  });
  await check('POST /auth/login → 200 token', () async {
    final r = await post(
        '/auth/login', {'email': emailA, 'password': 'parola123'});
    return r.statusCode == 200 && body(r)['token'] is String;
  });
  await check('POST /auth/login неверный пароль → 401', () async {
    final r =
        await post('/auth/login', {'email': emailA, 'password': 'wrong-pass'});
    return isError(r, 401, 'UNAUTHORIZED');
  });
  await check('POST /auth/login неизвестный email → 401', () async {
    final r = await post(
        '/auth/login', {'email': 'nobody$run@test.md', 'password': 'parola123'});
    return isError(r, 401, 'UNAUTHORIZED');
  });
  await check('token с подделанной подписью → 401', () async {
    final parts = tokenA.split('.');
    final forged = '${parts[0]}.${parts[1]}.${parts[2].split('').reversed.join()}';
    return isError(await get('/notes', token: forged), 401, 'UNAUTHORIZED');
  });

  // ── notes: CRUD ──────────────────────────────────────────────────────
  await check('GET /notes пустой → конверт {items,page,limit,total}', () async {
    final r = await get('/notes', token: tokenA);
    final b = body(r);
    return r.statusCode == 200 &&
        (b['items'] as List).isEmpty &&
        b['page'] == 1 &&
        b['limit'] == 20 &&
        b['total'] == 0;
  });
  await check('POST /notes → 201, id даёт сервер', () async {
    final r = await post('/notes', {'title': 'Покупки', 'content': 'молоко, хлеб'},
        token: tokenA);
    final b = body(r);
    if (r.statusCode != 201 || b['id'] is! int) return false;
    noteId = b['id'] as int;
    return b['title'] == 'Покупки' && b['content'] == 'молоко, хлеб';
  });
  await check('POST /notes без title → 400', () async {
    return isError(await post('/notes', {'content': 'x'}, token: tokenA), 400,
        'VALIDATION_ERROR');
  });
  await check('POST /notes пустой title → 400', () async {
    return isError(await post('/notes', {'title': '   '}, token: tokenA), 400,
        'VALIDATION_ERROR');
  });
  await check('GET /notes/{id} → 200', () async {
    final r = await get('/notes/$noteId', token: tokenA);
    return r.statusCode == 200 && body(r)['id'] == noteId;
  });
  await check('GET /notes/{несуществующий} → 404 NOT_FOUND', () async {
    return isError(
        await get('/notes/99999999', token: tokenA), 404, 'NOT_FOUND');
  });
  await check('PUT /notes/{id} → 200, данные заменены', () async {
    final r = await put('/notes/$noteId', {'title': 'Покупки на неделю'},
        token: tokenA);
    return r.statusCode == 200 && body(r)['title'] == 'Покупки на неделю';
  });
  await check('PUT /notes/{id} без title → 400', () async {
    return isError(await put('/notes/$noteId', {'content': 'x'}, token: tokenA),
        400, 'VALIDATION_ERROR');
  });
  await check('PUT /notes/{несуществующий} → 404', () async {
    return isError(await put('/notes/99999999', {'title': 'x'}, token: tokenA),
        404, 'NOT_FOUND');
  });

  // ── поиск и пагинация ────────────────────────────────────────────────
  await check('GET /notes?search= (кириллица) находит на сервере', () async {
    final r = await get('/notes?search=${Uri.encodeQueryComponent('Покуп')}',
        token: tokenA);
    final items = body(r)['items'] as List;
    return r.statusCode == 200 && items.length == 1;
  });
  await check('GET /notes?search= без совпадений → пустой список', () async {
    final r = await get('/notes?search=zzz-nothing', token: tokenA);
    return r.statusCode == 200 &&
        (body(r)['items'] as List).isEmpty &&
        body(r)['total'] == 0;
  });
  await check('пагинация: 26 записей, limit=10, page=3 → 6 элементов', () async {
    for (var n = 1; n <= 25; n++) {
      await post('/notes', {'title': 'Заметка $n'}, token: tokenA);
    }
    final r = await get('/notes?page=3&limit=10', token: tokenA);
    final b = body(r);
    return r.statusCode == 200 &&
        (b['items'] as List).length == 6 &&
        b['page'] == 3 &&
        b['limit'] == 10 &&
        b['total'] == 26;
  });
  await check('page=0 → 400', () async {
    return isError(await get('/notes?page=0', token: tokenA), 400,
        'VALIDATION_ERROR');
  });
  await check('limit=1000 → 400', () async {
    return isError(await get('/notes?limit=1000', token: tokenA), 400,
        'VALIDATION_ERROR');
  });

  // ── изоляция пользователей: «не моё» = «не существует» ──────────────
  await check('второй пользователь регистрируется', () async {
    final r = await post('/auth/register',
        {'email': emailB, 'password': 'parola123', 'name': 'Bogdan'});
    tokenB = body(r)['token'] as String? ?? '';
    return r.statusCode == 201;
  });
  await check('чужая заметка: GET → 404, а не 403', () async {
    return isError(
        await get('/notes/$noteId', token: tokenB), 404, 'NOT_FOUND');
  });
  await check('чужая заметка: PUT → 404', () async {
    return isError(await put('/notes/$noteId', {'title': 'взлом'}, token: tokenB),
        404, 'NOT_FOUND');
  });
  await check('чужая заметка: DELETE → 404', () async {
    return isError(
        await delete('/notes/$noteId', token: tokenB), 404, 'NOT_FOUND');
  });
  await check('список второго пользователя пуст', () async {
    return body(await get('/notes', token: tokenB))['total'] == 0;
  });

  // ── удаление ─────────────────────────────────────────────────────────
  await check('DELETE /notes/{id} → 204 с пустым телом', () async {
    final r = await delete('/notes/$noteId', token: tokenA);
    return r.statusCode == 204 && r.bodyBytes.isEmpty;
  });
  await check('удалённая заметка → 404', () async {
    return isError(
        await get('/notes/$noteId', token: tokenA), 404, 'NOT_FOUND');
  });
  await check('total уменьшился до 25', () async {
    return body(await get('/notes', token: tokenA))['total'] == 25;
  });

  // ── файлы ────────────────────────────────────────────────────────────
  late String fileUrl;
  final bytes = utf8.encode('<html>BizMatch test file</html>');
  await check('POST /files без token-а → 401', () async {
    final r = await upload(bytes, 'a.html', token: null);
    return isError(r, 401, 'UNAUTHORIZED');
  });
  await check('POST /files multipart → 201 с относительным url', () async {
    final r = await upload(bytes, 'test.html', token: tokenA);
    final b = body(r);
    fileUrl = b['url'] as String? ?? '';
    return r.statusCode == 201 &&
        b['size'] == bytes.length &&
        RegExp(r'^/files/\d+$').hasMatch(fileUrl);
  });
  await check('GET /files/{id} → те же байты, attachment + CSP', () async {
    final r = await http.get(Uri.parse('$base$fileUrl'));
    return r.statusCode == 200 &&
        utf8.decode(r.bodyBytes) == utf8.decode(bytes) &&
        (r.headers['content-disposition'] ?? '').startsWith('attachment') &&
        r.headers.containsKey('content-security-policy');
  });
  await check('POST /files без поля file → 400', () async {
    final req = http.MultipartRequest('POST', Uri.parse('$base/files'))
      ..headers['Authorization'] = 'Bearer $tokenA'
      ..fields['other'] = 'x';
    final r = await http.Response.fromStream(await req.send());
    return isError(r, 400, 'VALIDATION_ERROR');
  });
  await check('POST /files больше 5 МБ → 400', () async {
    final r = await upload(List.filled(5 * 1024 * 1024 + 10, 65), 'big.bin',
        token: tokenA);
    return isError(r, 400, 'VALIDATION_ERROR');
  });
  await check('GET /files/{несуществующий} → 404', () async {
    return isError(await get('/files/99999999'), 404, 'NOT_FOUND');
  });

  // ── конверт ошибки ───────────────────────────────────────────────────
  await check('неизвестный маршрут → 404 в конверте', () async {
    return isError(await get('/no-such-route'), 404, 'NOT_FOUND');
  });

  final total = passed + failures.length;
  stdout.writeln();
  if (failures.isEmpty) {
    stdout.writeln('PASS — $passed/$total checks passed');
  } else {
    stdout.writeln('FAIL — $passed/$total checks passed');
    for (final f in failures) {
      stdout.writeln('  ✗ $f');
    }
    exitCode = 1;
  }
}

// ── помощники ──────────────────────────────────────────────────────────

Future<void> check(String name, Future<bool> Function() body) async {
  bool ok;
  try {
    ok = await body();
  } catch (e) {
    ok = false;
    name = '$name  ($e)';
  }
  if (ok) {
    passed++;
    stdout.writeln('  ✓ $name');
  } else {
    failures.add(name);
    stdout.writeln('  ✗ $name');
  }
}

Map<String, String> headers(String? token) => {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

Future<http.Response> get(String path, {String? token}) =>
    http.get(Uri.parse('$base$path'), headers: headers(token));

Future<http.Response> post(String path, Object body, {String? token}) =>
    http.post(Uri.parse('$base$path'),
        headers: headers(token), body: jsonEncode(body));

Future<http.Response> put(String path, Object body, {String? token}) =>
    http.put(Uri.parse('$base$path'),
        headers: headers(token), body: jsonEncode(body));

Future<http.Response> delete(String path, {String? token}) =>
    http.delete(Uri.parse('$base$path'), headers: headers(token));

Future<http.Response> upload(List<int> bytes, String name,
    {required String? token}) async {
  final req = http.MultipartRequest('POST', Uri.parse('$base/files'))
    ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: name));
  if (token != null) req.headers['Authorization'] = 'Bearer $token';
  return http.Response.fromStream(await req.send());
}

Map<String, dynamic> body(http.Response r) =>
    jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;

/// Ответ — ошибка контракта: нужный статус и конверт с нужным code.
bool isError(http.Response r, int status, String code) {
  if (r.statusCode != status) return false;
  final error = body(r)['error'];
  return error is Map && error['code'] == code && error['message'] is String;
}
