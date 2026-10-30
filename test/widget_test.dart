import 'package:flutter_test/flutter_test.dart';

import 'package:biz_match/main.dart';

void main() {
  testWidgets('Приложение стартует на экране входа', (tester) async {
    await tester.pumpWidget(const BizMatchApp());
    expect(find.text('BizMatch'), findsOneWidget);
    expect(find.text('Войти'), findsOneWidget);
  });
}
