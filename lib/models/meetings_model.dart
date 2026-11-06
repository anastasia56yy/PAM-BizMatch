import 'package:flutter/foundation.dart';

import '../data/meeting.dart';
import '../data/meeting_repository.dart';
import '../data/result.dart';

/// Встречи: форма «Предложить встречу» пишет сюда, «Мои встречи»
/// и счётчик в профиле читают отсюда.
class MeetingsModel extends ChangeNotifier {
  MeetingsModel(this._repository);

  final MeetingRepository _repository;

  bool _loading = false;
  String? _error;
  List<Meeting> _meetings = const [];

  bool get isLoading => _loading;
  String? get error => _error;

  /// Ближайшие — сверху.
  List<Meeting> get meetings => List.unmodifiable(_meetings);

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    switch (await _repository.fetchAll()) {
      case Ok(:final value):
        _meetings = _sorted(value);
      case Err(:final msg):
        _error = msg;
    }
    _loading = false;
    notifyListeners();
  }

  Future<String?> add(Meeting draft) async {
    switch (await _repository.create(draft)) {
      case Ok(:final value):
        _meetings = _sorted([..._meetings, value]); // с id от хранилища
        notifyListeners(); // список встреч и счётчик в профиле — узнают все
        return null;
      case Err(:final msg):
        return msg;
    }
  }

  /// Отмена встречи — после диалога подтверждения.
  Future<String?> remove(int id) async {
    switch (await _repository.delete(id)) {
      case Ok():
        _meetings = _meetings.where((m) => m.id != id).toList();
        notifyListeners();
        return null;
      case Err(:final msg):
        return msg;
    }
  }

  static List<Meeting> _sorted(List<Meeting> list) =>
      [...list]..sort((a, b) => a.date.compareTo(b.date));
}
