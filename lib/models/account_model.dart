import 'package:flutter/foundation.dart';

import '../data/account_repository.dart';
import '../data/file_api.dart';
import '../data/profile.dart';
import '../data/result.dart';

/// Собственный профиль: «Мой профиль» показывает, форма редактирования пишет.
class AccountModel extends ChangeNotifier {
  AccountModel(this._repository, [this._files]);

  final AccountRepository _repository;
  final FileApi? _files; // Задание 7: загрузка аватарки

  bool _loading = false;
  String? _error;
  Profile? _me;

  bool _uploading = false;

  bool get isLoading => _loading;

  /// Аватарка летит на сервер — экран показывает индикатор на фото.
  bool get isUploading => _uploading;
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

  /// Новая аватарка: файл → POST /files → url → PUT /me с photo_url.
  /// null — успех, строка — текст ошибки (как в save).
  Future<String?> changePhoto(String filePath) async {
    final me = _me;
    final files = _files;
    if (me == null || files == null || _uploading) return null;
    _uploading = true;
    notifyListeners();
    final String? error;
    switch (await files.upload(filePath)) {
      case Ok(:final value):
        error = await save(me.copyWith(photoUrl: value));
      case Err(:final msg):
        error = msg;
    }
    _uploading = false;
    notifyListeners();
    return error;
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
