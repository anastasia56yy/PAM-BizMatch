import 'profile.dart';
import 'result.dart';

/// Контракт собственного профиля: он один, поэтому без id — /me на L5.
abstract class AccountRepository {
  Future<Result<Profile>> fetchMe();
  Future<Result<Profile>> updateMe(Profile me);
}
