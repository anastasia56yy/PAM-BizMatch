import 'package:biz_match/data/conversation.dart';
import 'package:biz_match/data/conversation_repository.dart';
import 'package:biz_match/data/meeting.dart';
import 'package:biz_match/data/meeting_repository.dart';
import 'package:biz_match/data/profile.dart';
import 'package:biz_match/data/profile_repository.dart';
import 'package:biz_match/data/result.dart';

/// Подделки хранилищ для тестов моделей: в приложении mock умер на L5,
/// а модели по-прежнему проверяются без сети — через тот же интерфейс.
class FakeNetwork {
  bool simulateError = false;
  static const errNetwork = 'Сервер не отвечает — повторите попытку';

  Future<String?> roundTrip() async {
    await Future<void>.delayed(Duration.zero); // ответ всегда асинхронный
    return simulateError ? errNetwork : null;
  }
}

class _Table<T> {
  _Table(this.net, Iterable<T> seed, this.idOf, this.withId)
      : rows = List.of(seed);
  final FakeNetwork net;
  final List<T> rows;
  final int Function(T) idOf;
  final T Function(T, int) withId;
  int nextId = 1000;

  Future<Result<R>> run<R>(R Function() body) async {
    final fail = await net.roundTrip();
    return fail != null ? Err(fail) : Ok(body());
  }

  Future<Result<List<T>>> all() => run(() => List.of(rows));
  Future<Result<T>> one(int id) async {
    final fail = await net.roundTrip();
    if (fail != null) return Err(fail);
    final i = rows.indexWhere((r) => idOf(r) == id);
    return i < 0 ? const Err('Запись не существует') : Ok(rows[i]);
  }

  Future<Result<T>> create(T row) => run(() {
        final created = withId(row, nextId++);
        rows.add(created);
        return created;
      });
  Future<Result<T>> update(T row) => run(() {
        rows[rows.indexWhere((r) => idOf(r) == idOf(row))] = row;
        return row;
      });
  Future<Result<void>> delete(int id) =>
      run(() => rows.removeWhere((r) => idOf(r) == id));
}

Profile _p(int id, String name, Goal goal, int score) =>
    Profile(id, name, 'Title', 'Company', 'Отрасль', 'Кишинёв', goal, 10,
        const [], '', score, '');

class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository(FakeNetwork net)
      : _t = _Table(net, [
          _p(1, 'Ирина Чобану', Goal.investor, 96),
          _p(2, 'Андрей Попеску', Goal.cofounder, 91),
          _p(3, 'Мария Русу', Goal.partnership, 88),
        ], (p) => p.id, (p, id) => p.copyWith(id: id));
  final _Table<Profile> _t;

  @override
  Future<Result<List<Profile>>> fetchAll() => _t.all();
  @override
  Future<Result<Profile>> fetchById(int id) => _t.one(id);
  @override
  Future<Result<Profile>> create(Profile p) => _t.create(p);
  @override
  Future<Result<Profile>> update(Profile p) => _t.update(p);
  @override
  Future<Result<void>> delete(int id) => _t.delete(id);
}

class FakeConversationRepository implements ConversationRepository {
  FakeConversationRepository(FakeNetwork net)
      : _t = _Table(net, const [
          Conversation(1, 1, 'Ирина Чобану', 'Moldova Growth Fund', 'Привет',
              '10:00', 0, []),
        ], (c) => c.id, (c, id) => c.copyWith(id: id));
  final _Table<Conversation> _t;

  @override
  Future<Result<List<Conversation>>> fetchAll() => _t.all();
  @override
  Future<Result<Conversation>> fetchById(int id) => _t.one(id);
  @override
  Future<Result<Conversation>> create(Conversation c) => _t.create(c);
  @override
  Future<Result<Conversation>> update(Conversation c) => _t.update(c);
  @override
  Future<Result<void>> delete(int id) => _t.delete(id);
}

class FakeMeetingRepository implements MeetingRepository {
  FakeMeetingRepository(FakeNetwork net)
      : _t = _Table(net, [
          Meeting(1, 1, 'Ирина Чобану', 'Seed-раунд', DateTime(2027, 1, 5), 45,
              'online', ''),
        ], (m) => m.id, (m, id) => m.copyWith(id: id));
  final _Table<Meeting> _t;

  @override
  Future<Result<List<Meeting>>> fetchAll() => _t.all();
  @override
  Future<Result<Meeting>> fetchById(int id) => _t.one(id);
  @override
  Future<Result<Meeting>> create(Meeting m) => _t.create(m);
  @override
  Future<Result<Meeting>> update(Meeting m) => _t.update(m);
  @override
  Future<Result<void>> delete(int id) => _t.delete(id);
}
