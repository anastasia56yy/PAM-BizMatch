import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:biz_match/data/mock_repositories.dart';
import 'package:biz_match/main.dart';

void main() {
  testWidgets('Неверный вход показывает ошибки, верный — ведёт во вкладки',
      (tester) async {
    await tester.pumpWidget(MultiProvider(
      providers: appProviders(MockNetwork(latency: Duration.zero)),
      child: const BizMatchApp(),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Войти'));
    await tester.pumpAndSettle();
    expect(find.text('Введите e-mail'), findsOneWidget);
    expect(find.text('Введите пароль'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'ana@utm.md');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret1');
    await tester.tap(find.text('Войти'));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Знакомства'), findsWidgets);
  });
}
