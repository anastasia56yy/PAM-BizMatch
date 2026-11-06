import 'package:flutter/foundation.dart';

import '../data/account_repository.dart';
import '../data/profile.dart';
import '../data/result.dart';

/// Собственный профиль: «Мой профиль» показывает, форма редактирования пишет.
class AccountModel extends ChangeNotifier {
  AccountModel(this._repository);

  final AccountRepository _repository;

  bool _loading = false;
  String? _error;
  Profile? _me;

  bool get isLoading => _loading;
  String? get error => _error;
  Profile? get me => _me;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    switch (await _repository.fetchMe()) {
      case Ok(:final value):
        _me = value;
      case Err(:final msg):
        _error = msg;
    }
    _loading = false;
    notifyListeners();
  }

  Future<String?> save(Profile updated) async {
    switch (await _repository.updateMe(updated)) {
      case Ok(:final value):
        _me = value;
        notifyListeners(); // «Мой профиль» обновится сам, ещё до pop формы
        return null;
      case Err(:final msg):
        return msg;
    }
  }
}
