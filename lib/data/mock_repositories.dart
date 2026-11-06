import 'account_repository.dart';
import 'conversation.dart';
import 'conversation_repository.dart';
import 'meeting.dart';
import 'meeting_repository.dart';
import 'mock_data.dart'; // единственный клиент seed-а
import 'profile.dart';
import 'profile_repository.dart';
import 'result.dart';

/// «Сеть» mock-а: задержка и переключаемая авария, общие для всех хранилищ.
/// Переключатель аварии в профиле меняет simulateError — и падают все запросы.
class MockNetwork {
  MockNetwork({this.latency = const Duration(milliseconds: 800)});

  final Duration latency;
  bool simulateError = false;

  static const errNetwork = 'Сервер не отвечает — повторите попытку';

  /// Пролог каждого запроса: сеть не отвечает мгновенно — и мы не будем.
  /// null — запрос прошёл, строка — текст аварии.
  Future<String?> roundTrip() async {
    await Future.delayed(latency);
    return simulateError ? errNetwork : null;
  }
}

/// Таблица в памяти с CRUD — общий скелет для всех mock-хранилищ.
class _MockTable<T> {
  _MockTable(this._net, Iterable<T> seed,
      {required this.idOf, required this.withId, required this.notFound})
      : _rows = List.of(seed);

  final MockNetwork _net;
  final List<T> _rows;
  final int Function(T row) idOf;
  final T Function(T row, int id) withId;
  final String notFound; // «404» mock-а
  int _nextId = 1000; // выше любого id из seed-а

  Future<Result<List<T>>> fetchAll() async {
    final fail = await _net.roundTrip();
    if (fail != null) return Err(fail);
    return Ok(List.of(_rows)); // копия — внутренность не отдаётся из рук
  }

  Future<Result<T>> fetchById(int id) async {
    final fail = await _net.roundTrip();
    if (fail != null) return Err(fail);
    final i = _rows.indexWhere((r) => idOf(r) == id);
    return i == -1 ? Err(notFound) : Ok(_rows[i]);
  }

  Future<Result<T>> create(T draft) async {
    final fail = await _net.roundTrip();
    if (fail != null) return Err(fail);
    final created = withId(draft, _nextId++); // id даёт ХРАНИЛИЩЕ
    _rows.add(created);
    return Ok(created);
  }

  Future<Result<T>> update(T row) async {
    final fail = await _net.roundTrip();
    if (fail != null) return Err(fail);
    final i = _rows.indexWhere((r) => idOf(r) == idOf(row));
    if (i == -1) return Err(notFound);
    _rows[i] = row; // заменяет по id — как PUT
    return Ok(row);
  }

  Future<Result<void>> delete(int id) async {
    final fail = await _net.roundTrip();
    if (fail != null) return Err(fail);
    final before = _rows.length;
    _rows.removeWhere((r) => idOf(r) == id);
    // «удалил, отдать нечего» — 204, сказанный в типах через Result<void>
    return _rows.length < before ? const Ok(null) : Err(notFound);
  }
}

class MockProfileRepository implements ProfileRepository {
  MockProfileRepository(MockNetwork net)
      : _t = _MockTable(net, mockProfiles,
            idOf: (p) => p.id,
            withId: (p, id) => p.copyWith(id: id),
            notFound: 'Профиль не существует');
  final _MockTable<Profile> _t;

  @override
  Future<Result<List<Profile>>> fetchAll() => _t.fetchAll();
  @override
  Future<Result<Profile>> fetchById(int id) => _t.fetchById(id);
  @override
  Future<Result<Profile>> create(Profile profile) => _t.create(profile);
  @override
  Future<Result<Profile>> update(Profile profile) => _t.update(profile);
  @override
  Future<Result<void>> delete(int id) => _t.delete(id);
}

class MockConversationRepository implements ConversationRepository {
  MockConversationRepository(MockNetwork net)
      : _t = _MockTable(net, mockConversations,
            idOf: (c) => c.id,
            withId: (c, id) => c.copyWith(id: id),
            notFound: 'Переписка не существует');
  final _MockTable<Conversation> _t;

  @override
  Future<Result<List<Conversation>>> fetchAll() => _t.fetchAll();
  @override
  Future<Result<Conversation>> fetchById(int id) => _t.fetchById(id);
  @override
  Future<Result<Conversation>> create(Conversation c) => _t.create(c);
  @override
  Future<Result<Conversation>> update(Conversation c) => _t.update(c);
  @override
  Future<Result<void>> delete(int id) => _t.delete(id);
}

class MockMeetingRepository implements MeetingRepository {
  MockMeetingRepository(MockNetwork net)
      : _t = _MockTable(net, mockMeetings,
            idOf: (m) => m.id,
            withId: (m, id) => m.copyWith(id: id),
            notFound: 'Встреча не существует');
  final _MockTable<Meeting> _t;

  @override
  Future<Result<List<Meeting>>> fetchAll() => _t.fetchAll();
  @override
  Future<Result<Meeting>> fetchById(int id) => _t.fetchById(id);
  @override
  Future<Result<Meeting>> create(Meeting meeting) => _t.create(meeting);
  @override
  Future<Result<Meeting>> update(Meeting meeting) => _t.update(meeting);
  @override
  Future<Result<void>> delete(int id) => _t.delete(id);
}

class MockAccountRepository implements AccountRepository {
  MockAccountRepository(this._net);
  final MockNetwork _net;
  Profile _me = myProfile;

  @override
  Future<Result<Profile>> fetchMe() async {
    final fail = await _net.roundTrip();
    if (fail != null) return Err(fail);
    return Ok(_me);
  }

  @override
  Future<Result<Profile>> updateMe(Profile me) async {
    final fail = await _net.roundTrip();
    if (fail != null) return Err(fail);
    _me = me;
    return Ok(_me);
  }
}
