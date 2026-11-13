import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:biz_match/data/api_client.dart';
import 'package:biz_match/data/auth_api.dart';
import 'package:biz_match/data/token_store.dart';
import 'package:biz_match/main.dart';
import 'package:biz_match/router.dart';

const _emptyPage = {'items': [], 'page': 1, 'limit': 20, 'total': 0};

/// Поддельный сервер: верный пароль — secret1, всё остальное — 401;
/// списки пустые, /me — минимальный профиль.
final _fakeServer = MockClient((request) async {
  if (request.method == 'GET') {
    return http.Response(
        jsonEncode(request.url.path == '/me'
            ? {'id': 1, 'name': 'Ana', 'email': 'ana@utm.md'}
            : _emptyPage),
        200);
  }
  final body = jsonDecode(request.body) as Map<String, dynamic>;
  if (body['password'] == 'secret1') {
    return http.Response(
        jsonEncode({
          'token': 'test-token',
          'user': {'id': 1, 'email': body['email'], 'name': 'Ana'}
        }),
        200);
  }
  return http.Response(
      jsonEncode({
        'error': {'code': 'UNAUTHORIZED', 'message': 'Invalid email or password'}
      }),
      401);
});

void main() {
  testWidgets('Вход: валидация, переведённая ошибка сервера, token в prefs',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final tokens = TokenStore();
    router = createRouter(initialLocation: '/login');
    await tester.pumpWidget(MultiProvider(
      providers: [
        Provider<AuthApi>(
            create: (_) => AuthApi('http://test', tokens, client: _fakeServer)),
        ...appProviders(ApiClient('http://test', tokens, client: _fakeServer)),
      ],
      child: const BizMatchApp(),
    ));
    await tester.pumpAndSettle();

    // 1) локальная валидация L3 — запрос даже не уходит
    await tester.tap(find.text('Войти'));
    await tester.pumpAndSettle();
    expect(find.text('Введите e-mail'), findsOneWidget);
    expect(find.text('Введите пароль'), findsOneWidget);

    // 2) неверный пароль: 401 → русское сообщение из конверта
    await tester.enterText(find.byType(TextFormField).at(0), 'ana@utm.md');
    await tester.enterText(find.byType(TextFormField).at(1), 'wrong12');
    await tester.tap(find.text('Войти'));
    await tester.pumpAndSettle();
    expect(find.text('Неверный email или пароль'), findsOneWidget);
    expect(await tokens.read(), isNull);

    // 3) верный пароль: token сохранён, вход во вкладки через go
    await tester.enterText(find.byType(TextFormField).at(1), 'secret1');
    await tester.tap(find.text('Войти'));
    await tester.pumpAndSettle();
    expect(await tokens.read(), 'test-token');
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Знакомства'), findsWidgets);
  });
}
