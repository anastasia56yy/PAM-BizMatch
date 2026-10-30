import 'package:flutter_test/flutter_test.dart';

import 'package:biz_match/utils/validators.dart';

void main() {
  test('e-mail', () {
    expect(validateEmail(''), isNotNull);
    expect(validateEmail('ana.rusu'), isNotNull);
    expect(validateEmail('ana@utm.md'), isNull);
  });

  test('пароль ≥ 6 символов', () {
    expect(validatePassword('12345'), isNotNull);
    expect(validatePassword('123456'), isNull);
  });

  test('телефон +373: 8 цифр, начиная с 6 или 7', () {
    expect(validatePhone('69123456'), isNull);
    expect(validatePhone('22123456'), isNotNull);
    expect(validatePhone('6912345'), isNotNull);
  });

  test('LinkedIn необязателен, но должен быть корректным', () {
    expect(validateLinkedIn(''), isNull);
    expect(validateLinkedIn('https://linkedin.com/in/ana-rusu'), isNull);
    expect(validateLinkedIn('linkedin.com/ana'), isNotNull);
  });

  test('дата встречи — строго в будущем', () {
    final now = DateTime(2026, 10, 30, 12);
    expect(validateFutureDate(null, now: now), isNotNull);
    expect(validateFutureDate(DateTime(2026, 10, 30), now: now), isNotNull);
    expect(validateFutureDate(DateTime(2026, 10, 31), now: now), isNull);
  });

  test('диапазон чисел', () {
    expect(validateIntRange('10', 15, 180, 'минут'), isNotNull);
    expect(validateIntRange('45', 15, 180, 'минут'), isNull);
    expect(validateIntRange('', 15, 180, 'минут'), isNotNull);
  });
}
