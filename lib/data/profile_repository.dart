import 'profile.dart';
import 'result.dart';

/// Контракт: ЧТО можно просить о профилях кандидатов, а не КАК.
/// На L5 каждый метод — один REST-маршрут (GET/POST /profiles, GET/PUT/DELETE
/// /profiles/{id}); экраны и модели этого не заметят.
abstract class ProfileRepository {
  /// L5: интерфейс растёт совместимо — необязательные именованные параметры,
  /// старый вызов fetchAll() компилируется без изменений.
  Future<Result<List<Profile>>> fetchAll(
      {int page = 1, int limit = 20, String? search});
  Future<Result<Profile>> fetchById(int id);
  Future<Result<Profile>> create(Profile profile);
  Future<Result<Profile>> update(Profile profile);
  Future<Result<void>> delete(int id);
}
