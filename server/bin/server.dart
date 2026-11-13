import 'dart:io';

import 'package:bizmatch_server/api.dart';
import 'package:bizmatch_server/auth.dart';
import 'package:bizmatch_server/crud.dart';
import 'package:bizmatch_server/db.dart';
import 'package:bizmatch_server/files.dart';
import 'package:bizmatch_server/seed.dart';
import 'package:bizmatch_server/theme.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

/// Запуск: dart run bin/server.dart  (PORT, JWT_SECRET, DB_PATH — из env)
Future<void> main() async {
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final secret = Platform.environment['JWT_SECRET'] ?? 'dev-secret-change-me';
  final db = openDatabase(Platform.environment['DB_PATH'] ?? 'app.db');

  final auth = Auth(db, secret, onUserCreated: seedNewUser);
  final files = FilesModule(db);

  // защищённые маршрутизаторы: пропускает только валидный Bearer
  Handler protected(Router r) =>
      const Pipeline().addMiddleware(auth.required).addHandler(r.call);

  final app = Router()
    ..get('/health', (Request _) => jsonOk({'status': 'ok'}))
    ..mount('/auth/', auth.router.call)
    ..mount('/notes', protected(notesModule(db).router))
    // сущности темы — рядом с notes, под тем же auth-middleware
    ..mount('/profiles', protected(profilesModule(db).router))
    ..mount('/conversations', protected(conversationsModule(db).router))
    ..mount('/meetings', protected(meetingsModule(db).router))
    ..mount('/me', protected(MeModule(db).router))
    ..mount('/files', _filesHandler(protected(files.uploadRouter), files));

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(_cors)
      .addMiddleware(_errors)
      .addHandler(app.call);

  final server = await io.serve(handler, InternetAddress.anyIPv4, port);
  print('BizMatch API listening on http://localhost:${server.port}');
}

/// GET /files/{id} открыт, POST /files требует token.
Handler _filesHandler(Handler upload, FilesModule files) => (Request r) =>
    r.method == 'GET' ? files.downloadRouter.call(r) : upload(r);

/// Лабораторная конфигурация: CORS открыт для всех.
Middleware get _cors => (Handler inner) => (Request request) async {
      const headers = {
        'access-control-allow-origin': '*',
        'access-control-allow-methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'access-control-allow-headers': 'Authorization, Content-Type',
      };
      if (request.method == 'OPTIONS') return Response.ok(null, headers: headers);
      final response = await inner(request);
      return response.change(headers: headers);
    };

/// Любое неожиданное исключение → 500 в конверте, а не HTML.
Middleware get _errors => (Handler inner) => (Request request) async {
      try {
        final response = await inner(request);
        // маршрута нет → 404 тоже в конверте
        if (response.statusCode == 404 &&
            response.headers['content-type']?.startsWith('application/json') !=
                true) {
          return notFound('Route not found');
        }
        return response;
      } catch (e, st) {
        stderr.writeln('$e\n$st');
        return apiError(500, 'INTERNAL', 'Internal server error');
      }
    };
