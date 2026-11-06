import 'package:flutter/foundation.dart';

/// «Избранное» — разделяемое состояние: его показывают «Знакомства»,
/// «ИИ-подбор», детали профиля и экран избранного. Чистый Dart, без widget-ов.
class ShortlistModel extends ChangeNotifier {
  final List<int> _ids = []; // id профилей, в порядке добавления

  List<int> get ids => List.unmodifiable(_ids); // наружу — только чтение
  int get count => _ids.length;
  bool contains(int id) => _ids.contains(id);

  void add(int id) {
    if (_ids.contains(id)) return;
    _ids.add(id);
    notifyListeners(); // весть уходит ко ВСЕМ подписчикам
  }

  void remove(int id) {
    if (!_ids.remove(id)) return;
    notifyListeners();
  }

  /// Звезда на карточке: в избранное ↔ из избранного. true — добавлен.
  bool toggle(int id) {
    if (contains(id)) {
      remove(id);
      return false;
    }
    add(id);
    return true;
  }
}
