// Лабораторная работа № 1, Часть B — упражнения E1–E6 на Dart.
// Запуск: dart run exercises.dart

// E1. Переменные и null safety — без оператора !
int parseOrDefault(String? input, int fallback) =>
    int.tryParse(input ?? '') ?? fallback;

// E2. Коллекции и функциональные методы — без циклов
double promotedAverage(List<int> grades) {
  final passed = grades.where((g) => g >= 5);
  if (passed.isEmpty) return 0;
  return passed.fold<int>(0, (sum, g) => sum + g) / passed.length;
}

// E3. Именованные и необязательные параметры
String formatPrice(double amount, {String currency = 'MDL', int decimals = 2}) =>
    '${amount.toStringAsFixed(decimals)} $currency';

// E4. Классы
class Student {
  final String name;
  final String group;

  Student(this.name, this.group);

  Student.guest()
      : name = 'Guest',
        group = '—';

  @override
  String toString() => 'Student($name, $group)';

  @override
  bool operator ==(Object other) =>
      other is Student && other.name == name && other.group == group;

  @override
  int get hashCode => Object.hash(name, group);
}

// E5. Mixin
mixin Loggable {
  void log(String msg) => print('[$runtimeType] $msg');
}

class CartService with Loggable {
  void addItem(String item) => log('товар добавлен: $item');
}

class AuthService with Loggable {
  void login(String username) => log('пользователь вошёл: $username');
}

// E6. Асинхронное программирование
Future<String> fetchProfile(String username) async {
  await Future.delayed(const Duration(seconds: 2));
  return 'Профиль: $username, группа TI-231, решено упражнений: 42';
}

Future<void> main() async {
  print('--- E1');
  print(parseOrDefault('42', 0));
  print(parseOrDefault('abc', 0));
  print(parseOrDefault(null, 7));
  print(parseOrDefault('7.5', -1));

  print('--- E2');
  print(promotedAverage([9, 4, 7, 10, 3, 5]));
  print(promotedAverage([10, 10, 9]));
  print(promotedAverage([3, 4, 2]));

  print('--- E3');
  print(formatPrice(12.5));
  print(formatPrice(12.5, currency: 'MDL'));
  print(formatPrice(99.999, currency: 'EUR'));
  print(formatPrice(7.5, currency: 'USD', decimals: 1));

  print('--- E4');
  print(Student('Ana Rusu', 'TI-231'));
  print(Student.guest());
  print(Student('Ana Rusu', 'TI-231') == Student('Ana Rusu', 'TI-231'));
  print({Student('Ana Rusu', 'TI-231'), Student('Ana Rusu', 'TI-231')}.length);

  print('--- E5');
  CartService().addItem('Paracetamol');
  AuthService().login('ana.rusu');

  print('--- E6');
  print('Загружается профиль пользователя ana.rusu...');
  final profile = await fetchProfile('ana.rusu');
  print(profile);
  print('Готово.');
}
