import 'package:shared_preferences/shared_preferences.dart';

/// Пропуск (JWT) поверх shared_preferences. Остальной код не знает,
/// где он хранится. Пароль локально не хранится НИКОГДА — только token.
class TokenStore {
  static const _key = 'auth_token'; // ключ: константа, в одном месте

  /// null — пользователь не входил (или его выбросило по 401).
  Future<String?> read() async =>
      (await SharedPreferences.getInstance()).getString(_key);

  /// login / register → setString
  Future<void> save(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, token);
  }

  /// logout И 401: мёртвый пропуск выбрасывается
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
