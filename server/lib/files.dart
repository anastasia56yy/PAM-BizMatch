import 'dart:typed_data';

import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sqlite3/sqlite3.dart';

import 'api.dart';

/// POST /files — multipart (поле file, до 5 МБ) → 201 с метаданными;
/// GET /files/{id} — байты обратно, только как скачивание.
class FilesModule {
  FilesModule(this.db);

  final Database db;
  static const maxBytes = 5 * 1024 * 1024;

  /// Загрузка — только с token-ом.
  Router get uploadRouter => Router()..post('/', _upload);

  /// Скачивание открыто: Image.network не умеет ставить Bearer.
  Router get downloadRouter => Router()..get('/<id|[0-9]+>', _download);

  Future<Response> _upload(Request request) async {
    final type = request.headers['content-type'];
    final boundary =
        type == null ? null : MediaType.parse(type).parameters['boundary'];
    if (boundary == null || !type!.startsWith('multipart/form-data')) {
      return validationError('Expected multipart/form-data with a file field');
    }
    // Тело читается ДО КОНЦА и только потом отвечаем: ответ посреди
    // недочитанного запроса обрывает соединение у клиента.
    String? filename;
    String? mimeType;
    Uint8List? bytes;
    var tooLarge = false;
    try {
      // request.read() отдаёт Stream<Uint8List>, трансформер ждёт List<int>
      final parts = request
          .read()
          .cast<List<int>>()
          .transform(MimeMultipartTransformer(boundary));
      await for (final part in parts) {
        final disposition = part.headers['content-disposition'] ?? '';
        if (!disposition.contains('name="file"') || bytes != null) {
          await part.drain<void>(); // чужое поле — дочитать и забыть
          continue;
        }
        final builder = BytesBuilder(copy: false);
        await for (final chunk in part) {
          if (tooLarge) continue; // сверх лимита — читаем, но не храним
          builder.add(chunk);
          tooLarge = builder.length > maxBytes;
        }
        filename =
            RegExp(r'filename="([^"]*)"').firstMatch(disposition)?.group(1) ??
                'file';
        mimeType = part.headers['content-type'];
        bytes = builder.takeBytes();
      }
    } on MimeMultipartException {
      return validationError('Malformed multipart body');
    }
    if (tooLarge) return validationError('File is larger than 5 MB');
    if (bytes == null) return validationError('Missing file field');
    if (bytes.isEmpty) return validationError('File is empty');
    final fileType = mimeType ??
        lookupMimeType(filename!, headerBytes: bytes) ??
        'application/octet-stream';
    db.execute(
        'INSERT INTO files (user_id, filename, mime_type, size, data, created_at) '
        'VALUES (?, ?, ?, ?, ?, ?)',
        [userIdOf(request), filename, fileType, bytes.length, bytes, nowIso()]);
    final id = db.lastInsertRowId;
    return jsonOk({
      'id': id,
      'filename': filename,
      'mime_type': fileType,
      'size': bytes.length,
      'url': '/files/$id', // ОТНОСИТЕЛЬНЫЙ путь
    }, status: 201);
  }

  Response _download(Request request, String id) {
    final rows = db.select(
        'SELECT filename, mime_type, data FROM files WHERE id = ?', [int.parse(id)]);
    if (rows.isEmpty) return notFound('File not found');
    final row = rows.first;
    return Response.ok(row['data'] as Uint8List, headers: {
      'content-type': row['mime_type'] as String,
      // скачивание, а не показ: загруженный text/html не выполнится
      // на origin-е API (защита от stored XSS)
      'content-disposition': 'attachment; filename="${row['filename']}"',
      'content-security-policy': "default-src 'none'; sandbox",
      'x-content-type-options': 'nosniff',
    });
  }
}
