import 'package:flutter/foundation.dart';

import '../data/profile.dart';
import '../data/profile_repository.dart';
import '../data/result.dart';

/// Запрос к ИИ: по нему «ИИ-подбор» сужает рейтинг кандидатов.
class AiBrief {
  final String query;
  final Goal goal;
  final String industry;
  final int minExperience;
  final String? city; // null — любой город

  const AiBrief(
      this.query, this.goal, this.industry, this.minExperience, this.city);

  bool accepts(Profile p) =>
      p.goal == goal &&
      p.experienceYears >= minExperience &&
      (city == null || p.city == city);
}

/// Кандидаты: состояние списка + триада loading / data / error (C8).
class ProfilesModel extends ChangeNotifier {
  ProfilesModel(this._repository); // простой DI: хранилище — в конструктор

  final ProfileRepository _repository; // тип — ИНТЕРФЕЙС, а не mock!

  bool _loading = false;
  String? _error;
  List<Profile> _profiles = const [];
  AiBrief? _brief;

  // L5: поиск и ломти с сервера
  static const _limit = 20;
  String _search = '';
  int _page = 1;
  bool _hasMore = false;
  bool _loadingMore = false;

  bool get isLoading => _loading;
  String? get error => _error;

  /// Все кандидаты, лучшие по оценке ИИ — сверху.
  List<Profile> get profiles => List.unmodifiable(_profiles);

  AiBrief? get brief => _brief;

  String get search => _search;

  /// Полная страница → видимо, на сервере есть ещё.
  bool get hasMore => _hasMore;

  /// Рейтинг «ИИ-подбора»: все кандидаты или только подходящие под запрос.
  List<Profile> get matches => List.unmodifiable(
      _brief == null ? _profiles : _profiles.where(_brief!.accepts));

  /// Ищет в загруженном списке; null — такого id нет (или ещё грузится).
  Profile? byId(int id) => _profiles.where((p) => p.id == id).firstOrNull;

  /// Первая страница. [search] — новый фильтр; без него retry сохраняет
  /// прежний, пустая строка — сбросить.
  Future<void> load({String? search}) async {
    _search = search ?? _search;
    _page = 1;
    _loading = true;
    _error = null;
    notifyListeners(); // подписанные экраны входят в состояние «грузится»
    switch (await _repository.fetchAll(limit: _limit, search: _search)) {
      case Ok(:final value):
        _profiles = value; // порядок по оценке ИИ задаёт сервер
        _hasMore = value.length == _limit;
      case Err(:final msg):
        _error = msg;
    }
    _loading = false;
    notifyListeners(); // …и выходят: с данными или с ошибкой — никогда молча
  }

  /// Следующий ломоть. Вызывается из itemBuilder, в разгар build — поэтому
  /// флаг ставится БЕЗ notifyListeners (иначе «markNeedsBuild during build»),
  /// а guard не даёт запросить одну страницу дважды.
  Future<void> loadMore() async {
    if (_loadingMore || _loading || !_hasMore) return;
    _loadingMore = true;
    final result = await _repository.fetchAll(
        page: _page + 1, limit: _limit, search: _search);
    _loadingMore = false;
    switch (result) {
      case Ok(:final value):
        _page += 1;
        _profiles = [..._profiles, ...value]; // страница ПРИКЛЕИВАЕТСЯ
        _hasMore = value.length == _limit;
      case Err():
        _hasMore = false; // хвост гаснет; «Обновить» начнёт заново
    }
    notifyListeners();
  }

  /// «Скрыть из подбора». null — успех, строка — текст ошибки (как validator).
  Future<String?> remove(int id) async {
    switch (await _repository.delete(id)) {
      case Ok():
        _profiles = _profiles.where((p) => p.id != id).toList();
        notifyListeners(); // профиль исчезает из всех экранов сразу
        return null;
      case Err(:final msg):
        return msg; // состояние нетронуто — экран решает, что показать
    }
  }

  /// Форма «Запрос к ИИ»: запрос живёт в модели, его читает «ИИ-подбор».
  void applyBrief(AiBrief brief) {
    _brief = brief;
    notifyListeners();
  }

  void clearBrief() {
    if (_brief == null) return;
    _brief = null;
    notifyListeners();
  }
}
