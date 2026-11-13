import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sqlite3/sqlite3.dart';

import 'api.dart';

/// Аутентификация: регистрация, вход, JWT (HS256) и middleware,
/// пропускающий к защищённым маршрутам только запросы с валидным Bearer.
class Auth {
  Auth(this.db, this.secret, {this.onUserCreated});

  final Database db;
  final String secret;

  /// Хук для сущностей темы: например, стартовый подбор нового пользователя.
  final void Function(Database db, int userId)? onUserCreated;

  static const tokenLifetime = Duration(days: 7);
  static final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  Router get router => Router()
    ..post('/register', _register)
    ..post('/login', _login);

  Future<Response> _register(Request request) async {
    final body = await readJsonObject(request);
    if (body == null) return validationError('Body must be a JSON object');
    final email = (body['email'] as Object?)?.toString().trim().toLowerCase();
    final password = body['password'];
    final name = (body['name'] as Object?)?.toString().trim();
    if (email == null || !_emailRe.hasMatch(email)) {
      return validationError('A valid email is required');
    }
    if (password is! String || password.length < 6) {
      return validationError('Password must be at least 6 characters');
    }
    if (name == null || name.isEmpty) {
      return validationError('Name is required');
    }
    final exists = db.select('SELECT 1 FROM users WHERE email = ?', [email]);
    if (exists.isNotEmpty) {
      return apiError(409, 'EMAIL_TAKEN', 'Email is already registered');
    }
    db.execute(
        'INSERT INTO users (email, password_hash, name, created_at) '
        'VALUES (?, ?, ?, ?)',
        [email, _hashPassword(password), name, nowIso()]);
    final id = db.lastInsertRowId;
    onUserCreated?.call(db, id);
    return jsonOk(_session(id, email, name), status: 201);
  }

  Future<Response> _login(Request request) async {
    final body = await readJsonObject(request);
    if (body == null) return validationError('Body must be a JSON object');
    final email = (body['email'] as Object?)?.toString().trim().toLowerCase();
    final password = body['password'];
    if (email == null || password is! String) {
      return validationError('Email and password are required');
    }
    final rows = db.select(
        'SELECT id, name, password_hash FROM users WHERE email = ?', [email]);
    // один и тот же ответ для «нет такого email» и «неверный пароль»
    if (rows.isEmpty ||
        !_checkPassword(password, rows.first['password_hash'] as String)) {
      return unauthorized('Invalid email or password');
    }
    final row = rows.first;
    return jsonOk(_session(row['id'] as int, email, row['name'] as String));
  }

  Map<String, Object> _session(int id, String email, String name) => {
        'token': issueToken(id, email),
        'user': {'id': id, 'email': email, 'name': name},
      };

  /// Middleware: Bearer → userId в контексте запроса, иначе 401.
  Middleware get required => (Handler inner) => (Request request) {
        final header = request.headers['authorization'] ?? '';
        if (!header.startsWith('Bearer ')) return unauthorized();
        final userId = verifyToken(header.substring(7));
        if (userId == null) return unauthorized();
        final exists = db.select('SELECT 1 FROM users WHERE id = ?', [userId]);
        if (exists.isEmpty) return unauthorized();
        return inner(request.change(context: {'userId': userId}));
      };

  // ── JWT HS256 ──────────────────────────────────────────────────────────

  String issueToken(int userId, String email) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final header = _b64(utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'})));
    final payload = _b64(utf8.encode(jsonEncode({
      'sub': userId,
      'email': email,
      'iat': now,
      'exp': now + tokenLifetime.inSeconds,
    })));
    return '$header.$payload.${_sign('$header.$payload')}';
  }

  /// id пользователя из валидного token-а; null — подпись или срок не те.
  int? verifyToken(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    if (_sign('${parts[0]}.${parts[1]}') != parts[2]) return null;
    try {
      final payload = jsonDecode(utf8.decode(base64Url.decode(
          base64Url.normalize(parts[1])))) as Map<String, dynamic>;
      final exp = payload['exp'] as int;
      if (exp < DateTime.now().millisecondsSinceEpoch ~/ 1000) return null;
      return payload['sub'] as int;
    } catch (_) {
      return null;
    }
  }

  String _sign(String data) =>
      _b64(Hmac(sha256, utf8.encode(secret)).convert(utf8.encode(data)).bytes);

  static String _b64(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');

  // ── Пароли: PBKDF2-HMAC-SHA256 с солью ─────────────────────────────────

  static const _iterations = 10000;

  static String _hashPassword(String password) {
    final rnd = Random.secure();
    final salt = Uint8List.fromList(List.generate(16, (_) => rnd.nextInt(256)));
    return '${base64.encode(salt)}:${base64.encode(_pbkdf2(password, salt))}';
  }

  static bool _checkPassword(String password, String stored) {
    final parts = stored.split(':');
    if (parts.length != 2) return false;
    final expected = _pbkdf2(password, base64.decode(parts[0]));
    return base64.encode(expected) == parts[1];
  }

  static List<int> _pbkdf2(String password, List<int> salt) {
    final hmac = Hmac(sha256, utf8.encode(password));
    var u = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
    final result = List<int>.from(u);
    for (var i = 1; i < _iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < result.length; j++) {
        result[j] ^= u[j];
      }
    }
    return result;
  }
}
