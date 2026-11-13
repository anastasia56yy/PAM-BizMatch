import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sqlite3/sqlite3.dart';

import 'api.dart';
import 'crud.dart';

/// Сущности темы BizMatch — тот же CRUD-модуль, что notes, с другими полями.

/// Таблицы темы: добавляются рядом с notes, у каждой user_id.
const themeSchema = [
  '''CREATE TABLE IF NOT EXISTS profiles (
       id INTEGER PRIMARY KEY AUTOINCREMENT,
       user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
       name TEXT NOT NULL,
       title TEXT NOT NULL,
       company TEXT NOT NULL,
       industry TEXT NOT NULL DEFAULT '',
       city TEXT NOT NULL DEFAULT '',
       goal TEXT NOT NULL,
       experience_years INTEGER NOT NULL DEFAULT 0,
       skills TEXT NOT NULL DEFAULT '[]',
       about TEXT NOT NULL DEFAULT '',
       ai_score INTEGER NOT NULL DEFAULT 0,
       ai_reason TEXT NOT NULL DEFAULT '',
       created_at TEXT NOT NULL,
       updated_at TEXT NOT NULL)''',
  '''CREATE TABLE IF NOT EXISTS conversations (
       id INTEGER PRIMARY KEY AUTOINCREMENT,
       user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
       profile_id INTEGER NOT NULL,
       name TEXT NOT NULL,
       company TEXT NOT NULL DEFAULT '',
       last_message TEXT NOT NULL DEFAULT '',
       time TEXT NOT NULL DEFAULT '',
       unread INTEGER NOT NULL DEFAULT 0,
       messages TEXT NOT NULL DEFAULT '[]',
       created_at TEXT NOT NULL,
       updated_at TEXT NOT NULL)''',
  '''CREATE TABLE IF NOT EXISTS meetings (
       id INTEGER PRIMARY KEY AUTOINCREMENT,
       user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
       profile_id INTEGER NOT NULL,
       profile_name TEXT NOT NULL,
       topic TEXT NOT NULL,
       date TEXT NOT NULL,
       duration_min INTEGER NOT NULL,
       format TEXT NOT NULL,
       message TEXT NOT NULL DEFAULT '',
       created_at TEXT NOT NULL,
       updated_at TEXT NOT NULL)''',
  '''CREATE TABLE IF NOT EXISTS me_profiles (
       user_id INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
       title TEXT NOT NULL DEFAULT '',
       company TEXT NOT NULL DEFAULT '',
       industry TEXT NOT NULL DEFAULT '',
       city TEXT NOT NULL DEFAULT '',
       goal TEXT NOT NULL DEFAULT 'partnership',
       experience_years INTEGER NOT NULL DEFAULT 0,
       skills TEXT NOT NULL DEFAULT '[]',
       about TEXT NOT NULL DEFAULT '',
       email TEXT NOT NULL DEFAULT '',
       phone TEXT NOT NULL DEFAULT '',
       linkedin TEXT NOT NULL DEFAULT '')''',
];

/// GET/POST /profiles, GET/PUT/DELETE /profiles/{id} — подбор кандидатов.
CrudModule profilesModule(Database db) => CrudModule(db,
    table: 'profiles',
    fields: const [
      Field('name', FieldType.text, required: true),
      Field('title', FieldType.text, required: true),
      Field('company', FieldType.text, required: true),
      Field('industry', FieldType.text),
      Field('city', FieldType.text),
      Field('goal', FieldType.text, required: true),
      Field('experience_years', FieldType.integer),
      Field('skills', FieldType.json),
      Field('about', FieldType.text),
      Field('ai_score', FieldType.integer),
      Field('ai_reason', FieldType.text),
    ],
    searchColumns: const ['name', 'title', 'company', 'industry', 'skills'],
    orderBy: 'ai_score DESC, id');

/// /conversations — контакты с перепиской; свежие разговоры сверху.
CrudModule conversationsModule(Database db) => CrudModule(db,
    table: 'conversations',
    fields: const [
      Field('profile_id', FieldType.integer, required: true),
      Field('name', FieldType.text, required: true),
      Field('company', FieldType.text),
      Field('last_message', FieldType.text),
      Field('time', FieldType.text),
      Field('unread', FieldType.integer),
      Field('messages', FieldType.json),
    ],
    searchColumns: const ['name', 'company', 'last_message'],
    orderBy: 'updated_at DESC, id DESC');

/// /meetings — запросы на встречу; ближайшие сверху.
CrudModule meetingsModule(Database db) => CrudModule(db,
    table: 'meetings',
    fields: const [
      Field('profile_id', FieldType.integer, required: true),
      Field('profile_name', FieldType.text, required: true),
      Field('topic', FieldType.text, required: true),
      Field('date', FieldType.text, required: true),
      Field('duration_min', FieldType.integer, required: true),
      Field('format', FieldType.text, required: true),
      Field('message', FieldType.text),
    ],
    searchColumns: const ['topic', 'profile_name'],
    orderBy: 'date, id');

/// GET /me, PUT /me — собственный профиль: имя и email из users,
/// остальное — из me_profiles.
class MeModule {
  MeModule(this.db);

  final Database db;

  Router get router => Router()
    ..get('/', _get)
    ..put('/', _put);

  Response _get(Request request) => jsonOk(_load(userIdOf(request)));

  Future<Response> _put(Request request) async {
    final userId = userIdOf(request);
    final body = await readJsonObject(request);
    if (body == null) return validationError('Body must be a JSON object');
    final name = body['name'];
    if (name is! String || name.trim().isEmpty) {
      return validationError('name is required');
    }
    // email здесь — рабочий контакт профиля, адрес входа он не меняет
    const texts = ['title', 'company', 'industry', 'city', 'goal', 'about',
        'email', 'phone', 'linkedin'];
    for (final f in texts) {
      if (body[f] != null && body[f] is! String) {
        return validationError('$f has an invalid value');
      }
    }
    if (body['experience_years'] != null && body['experience_years'] is! int) {
      return validationError('experience_years has an invalid value');
    }
    if (body['skills'] != null && body['skills'] is! List) {
      return validationError('skills has an invalid value');
    }
    db.execute('UPDATE users SET name = ? WHERE id = ?', [name.trim(), userId]);
    db.execute(
        'INSERT OR REPLACE INTO me_profiles (user_id, ${texts.join(', ')}, '
        'experience_years, skills) VALUES (?, ${List.filled(texts.length + 2, '?').join(', ')})',
        [
          userId,
          for (final f in texts) (body[f] as String?)?.trim() ?? '',
          body['experience_years'] ?? 0,
          jsonEncode(body['skills'] ?? const []),
        ]);
    return jsonOk(_load(userId));
  }

  Map<String, Object?> _load(int userId) {
    final user =
        db.select('SELECT name, email FROM users WHERE id = ?', [userId]).first;
    final rows =
        db.select('SELECT * FROM me_profiles WHERE user_id = ?', [userId]);
    final p = rows.isEmpty ? null : rows.first;
    return {
      'id': userId,
      'name': user['name'],
      // рабочий email из профиля, если задан, иначе адрес входа
      'email': (p?['email'] as String?)?.isNotEmpty == true
          ? p!['email']
          : user['email'],
      'title': p?['title'] ?? '',
      'company': p?['company'] ?? '',
      'industry': p?['industry'] ?? '',
      'city': p?['city'] ?? '',
      'goal': p?['goal'] ?? 'partnership',
      'experience_years': p?['experience_years'] ?? 0,
      'skills': p == null ? const [] : jsonDecode(p['skills'] as String),
      'about': p?['about'] ?? '',
      'phone': p?['phone'] ?? '',
      'linkedin': p?['linkedin'] ?? '',
    };
  }
}
