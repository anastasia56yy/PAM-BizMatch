import 'api_client.dart';
import 'result.dart';

/// Задание 7: загрузка файла на POST /files (multipart, поле file, до 5 МБ).
/// Ответ 201 несёт ОТНОСИТЕЛЬНЫЙ url вида /files/7 — его хранит сущность,
/// а показ — Image.network('$apiBase$url').
class FileApi {
  FileApi(this._api);
  final ApiClient _api;

  Future<Result<String>> upload(String filePath) => _api.upload('/files',
      field: 'file',
      filePath: filePath,
      okStatus: 201,
      parse: (j) => (j as Map<String, dynamic>)['url'] as String);
}
