import 'package:flutter/foundation.dart';

import '../data/conversation.dart';
import '../data/conversation_repository.dart';
import '../data/profile.dart';
import '../data/result.dart';

/// Контакты и переписка — разделяемое состояние вкладки «Контакты»,
/// деталей профиля, «Знакомств» и статистики в «Моём профиле».
class ChatsModel extends ChangeNotifier {
  ChatsModel(this._repository);

  final ConversationRepository _repository;

  bool _loading = false;
  String? _error;
  List<Conversation> _conversations = const [];

  bool get isLoading => _loading;
  String? get error => _error;
  List<Conversation> get conversations => List.unmodifiable(_conversations);

  Conversation? byId(int id) =>
      _conversations.where((c) => c.id == id).firstOrNull;

  Conversation? byProfileId(int profileId) =>
      _conversations.where((c) => c.profileId == profileId).firstOrNull;

  Future<void>? _loadDone; // текущая загрузка — её можно дождаться

  Future<void> load() => _loadDone = _load();

  Future<void> _load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    switch (await _repository.fetchAll()) {
      case Ok(:final value):
        _conversations = value;
      case Err(:final msg):
        _error = msg;
    }
    _loading = false;
    notifyListeners();
  }

  /// «Хочу познакомиться»: новый контакт в начале списка.
  /// Уже есть переписка — ничего не создаём.
  Future<String?> startChat(Profile profile) async {
    // модель создаётся лениво: при первом вызове список может ещё грузиться —
    // ждём его, иначе не увидим существующую переписку и создадим дубль
    await (_loadDone ?? load());
    if (_error != null) await load(); // прошлая загрузка упала — ещё раз
    if (_error != null) return _error;
    if (byProfileId(profile.id) != null) return null;
    final draft = Conversation(0, profile.id, profile.name, profile.company,
        'Вы начали знакомство', _now(), 0, const []);
    switch (await _repository.create(draft)) {
      case Ok(:final value):
        _conversations = [value, ..._conversations]; // id — от хранилища
        notifyListeners();
        return null;
      case Err(:final msg):
        return msg;
    }
  }

  Future<String?> sendMessage(int id, String text) async {
    final c = byId(id);
    if (c == null) return 'Переписка не существует';
    final time = _now();
    final updated = c.copyWith(
        messages: [...c.messages, Message(true, text, time)],
        lastMessage: text,
        time: time,
        unread: 0);
    switch (await _repository.update(updated)) {
      case Ok(:final value):
        _conversations = [
          for (final x in _conversations) x.id == id ? value : x
        ];
        notifyListeners();
        return null;
      case Err(:final msg):
        return msg;
    }
  }

  /// «Удалить контакт» — после диалога подтверждения.
  Future<String?> remove(int id) async {
    switch (await _repository.delete(id)) {
      case Ok():
        _conversations = _conversations.where((c) => c.id != id).toList();
        notifyListeners();
        return null;
      case Err(:final msg):
        return msg;
    }
  }

  static String _now() {
    final t = DateTime.now();
    return '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}';
  }
}
