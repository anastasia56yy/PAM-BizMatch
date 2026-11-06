import 'profile.dart';
import 'result.dart';

/// Контракт: ЧТО можно просить о профилях кандидатов, а не КАК.
/// На L5 каждый метод — один REST-маршрут (GET/POST /profiles, GET/PUT/DELETE
/// /profiles/{id}); экраны и модели этого не заметят.
abstract class ProfileRepository {
  Future<Result<List<Profile>>> fetchAll();
  Future<Result<Profile>> fetchById(int id);
  Future<Result<Profile>> create(Profile profile);
  Future<Result<Profile>> update(Profile profile);
  Future<Result<void>> delete(int id);
}
