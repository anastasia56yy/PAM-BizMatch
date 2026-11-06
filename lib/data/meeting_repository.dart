import 'meeting.dart';
import 'result.dart';

/// Контракт встреч: /meetings на L5.
abstract class MeetingRepository {
  Future<Result<List<Meeting>>> fetchAll();
  Future<Result<Meeting>> fetchById(int id);
  Future<Result<Meeting>> create(Meeting meeting);
  Future<Result<Meeting>> update(Meeting meeting);
  Future<Result<void>> delete(int id);
}
