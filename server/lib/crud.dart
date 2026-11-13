import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sqlite3/sqlite3.dart';

import 'api.dart';

/// Тип поля сущности: как оно проверяется и как хранится в SQLite.
enum FieldType { text, integer, real, json }

class Field {
  const Field(this.name, this.type, {this.required = false});

  final String name; // имя и в JSON, и в колонке таблицы
  final FieldType type;
  final bool required;
}

/// Описание CRUD-модуля «на пользователя»: каждая запись принадлежит
/// своему user_id, чужая запись отвечает 404, как несуществующая.
/// notes — образец; сущности темы — тот же модуль с другими полями.
class CrudModule {
  CrudModule(this.db,
      {required this.table,
      required this.fields,
      required this.searchColumns,
      this.orderBy = 'id DESC'});

  final Database db;
  final String table;
  final List<Field> fields;
  final List<String> searchColumns; // по ним работает ?search=
  final String orderBy;

  Router get router => Router()
    ..get('/', _list)
    ..post('/', _create)
    ..get('/<id|[0-9]+>', _get)
    ..put('/<id|[0-9]+>', _update)
    ..delete('/<id|[0-9]+>', _delete);

  /// GET /table?page=&limit=&search= → пагинированный конверт.
  Response _list(Request request) {
    final p = pagination(request);
    if (p == null) {
      return validationError('page must be ≥ 1, limit must be 1–100');
    }
    final search = request.url.queryParameters['search']?.trim() ?? '';
    final where = StringBuffer('user_id = ?');
    final args = <Object?>[userIdOf(request)];
    if (search.isNotEmpty) {
      where.write(' AND (${searchColumns.map((c) => '$c LIKE ?').join(' OR ')})');
      args.addAll(List.filled(searchColumns.length, '%$search%'));
    }
    final total = db
        .select('SELECT COUNT(*) AS n FROM $table WHERE $where', args)
        .first['n'] as int;
    final rows = db.select(
        'SELECT * FROM $table WHERE $where ORDER BY $orderBy LIMIT ? OFFSET ?',
        [...args, p.limit, (p.page - 1) * p.limit]);
    return jsonOk({
      'items': rows.map(toJson).toList(),
      'page': p.page,
      'limit': p.limit,
      'total': total,
    });
  }

  Future<Response> _create(Request request) async {
    final body = await readJsonObject(request);
    if (body == null) return validationError('Body must be a JSON object');
    final error = validate(body);
    if (error != null) return validationError(error);
    final now = nowIso();
    final cols = fields.map((f) => f.name).toList();
    db.execute(
        'INSERT INTO $table (user_id, ${cols.join(', ')}, created_at, updated_at) '
        'VALUES (?, ${List.filled(cols.length, '?').join(', ')}, ?, ?)',
        [userIdOf(request), ...fields.map((f) => _toDb(f, body)), now, now]);
    return jsonOk(_byId(db.lastInsertRowId, userIdOf(request)), status: 201);
  }

  Response _get(Request request, String id) {
    final row = _byId(int.parse(id), userIdOf(request));
    return row == null ? notFound('${_singular()} not found') : jsonOk(row);
  }

  /// PUT заменяет запись целиком: обязательные поля — снова обязательны.
  Future<Response> _update(Request request, String id) async {
    final userId = userIdOf(request);
    if (_byId(int.parse(id), userId) == null) {
      return notFound('${_singular()} not found');
    }
    final body = await readJsonObject(request);
    if (body == null) return validationError('Body must be a JSON object');
    final error = validate(body);
    if (error != null) return validationError(error);
    db.execute(
        'UPDATE $table SET ${fields.map((f) => '${f.name} = ?').join(', ')}, '
        'updated_at = ? WHERE id = ? AND user_id = ?',
        [...fields.map((f) => _toDb(f, body)), nowIso(), int.parse(id), userId]);
    return jsonOk(_byId(int.parse(id), userId));
  }

  /// DELETE → 204 с пустым телом.
  Response _delete(Request request, String id) {
    final userId = userIdOf(request);
    if (_byId(int.parse(id), userId) == null) {
      return notFound('${_singular()} not found');
    }
    db.execute(
        'DELETE FROM $table WHERE id = ? AND user_id = ?', [int.parse(id), userId]);
    return Response(204);
  }

  Map<String, Object?>? _byId(int id, int userId) {
    final rows = db.select(
        'SELECT * FROM $table WHERE id = ? AND user_id = ?', [id, userId]);
    return rows.isEmpty ? null : toJson(rows.first);
  }

  /// Проверка тела: null — валидно, строка — текст ошибки (400).
  String? validate(Map<String, dynamic> body) {
    for (final f in fields) {
      final v = body[f.name];
      final blank = v == null || (v is String && v.trim().isEmpty);
      if (blank && f.required) return '${f.name} is required';
      if (v == null) continue;
      final ok = switch (f.type) {
        FieldType.text => v is String,
        FieldType.integer => v is int,
        FieldType.real => v is num,
        FieldType.json => v is List || v is Map,
      };
      if (!ok) return '${f.name} has an invalid value';
    }
    return null;
  }

  Object? _toDb(Field f, Map<String, dynamic> body) {
    final v = body[f.name];
    return switch (f.type) {
      FieldType.text => (v as String?)?.trim() ?? '',
      FieldType.integer => v as int? ?? 0,
      FieldType.real => (v as num?)?.toDouble() ?? 0.0,
      FieldType.json => jsonEncode(v ?? const []),
    };
  }

  Map<String, Object?> toJson(Row row) => {
        'id': row['id'],
        for (final f in fields)
          f.name: f.type == FieldType.json
              ? jsonDecode(row[f.name] as String)
              : row[f.name],
        'created_at': row['created_at'],
        'updated_at': row['updated_at'],
      };

  String _singular() {
    final name = table.endsWith('s') ? table.substring(0, table.length - 1) : table;
    return '${name[0].toUpperCase()}${name.substring(1)}';
  }
}

/// Образец модуля: заметки пользователя.
CrudModule notesModule(Database db) => CrudModule(db,
    table: 'notes',
    fields: const [
      Field('title', FieldType.text, required: true),
      Field('content', FieldType.text),
    ],
    searchColumns: const ['title', 'content']);
