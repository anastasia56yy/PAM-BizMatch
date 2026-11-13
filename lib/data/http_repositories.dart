import 'account_repository.dart';
import 'api_client.dart';
import 'conversation.dart';
import 'conversation_repository.dart';
import 'meeting.dart';
import 'meeting_repository.dart';
import 'profile.dart';
import 'profile_repository.dart';
import 'result.dart';

/// Вторые реализации интерфейсов L4 — на http. Интерфейсы не менялись:
/// каждый метод отображается один-к-одному на REST-маршрут backend-а.

class HttpProfileRepository implements ProfileRepository {
  HttpProfileRepository(this._api);
  final ApiClient _api;

  @override
  Future<Result<List<Profile>>> fetchAll() => _api.send('GET', '/profiles',
      okStatus: 200, parse: (j) => itemsOf(j, Profile.fromJson));

  @override
  Future<Result<Profile>> fetchById(int id) => _api.send('GET', '/profiles/$id',
      okStatus: 200, parse: (j) => Profile.fromJson(j as Map<String, dynamic>));

  @override
  Future<Result<Profile>> create(Profile profile) => _api.send(
      'POST', '/profiles',
      body: profile.toJson(),
      okStatus: 201, // id даёт сервер
      parse: (j) => Profile.fromJson(j as Map<String, dynamic>));

  @override
  Future<Result<Profile>> update(Profile profile) => _api.send(
      'PUT', '/profiles/${profile.id}',
      body: profile.toJson(),
      okStatus: 200,
      parse: (j) => Profile.fromJson(j as Map<String, dynamic>));

  @override
  Future<Result<void>> delete(int id) => _api.send('DELETE', '/profiles/$id',
      okStatus: 204, parse: (_) {}); // пустое тело → Result<void>
}

class HttpConversationRepository implements ConversationRepository {
  HttpConversationRepository(this._api);
  final ApiClient _api;

  @override
  Future<Result<List<Conversation>>> fetchAll() => _api.send(
      'GET', '/conversations?limit=100',
      okStatus: 200, parse: (j) => itemsOf(j, Conversation.fromJson));

  @override
  Future<Result<Conversation>> fetchById(int id) => _api.send(
      'GET', '/conversations/$id',
      okStatus: 200,
      parse: (j) => Conversation.fromJson(j as Map<String, dynamic>));

  @override
  Future<Result<Conversation>> create(Conversation c) => _api.send(
      'POST', '/conversations',
      body: c.toJson(),
      okStatus: 201,
      parse: (j) => Conversation.fromJson(j as Map<String, dynamic>));

  @override
  Future<Result<Conversation>> update(Conversation c) => _api.send(
      'PUT', '/conversations/${c.id}',
      body: c.toJson(),
      okStatus: 200,
      parse: (j) => Conversation.fromJson(j as Map<String, dynamic>));

  @override
  Future<Result<void>> delete(int id) => _api
      .send('DELETE', '/conversations/$id', okStatus: 204, parse: (_) {});
}

class HttpMeetingRepository implements MeetingRepository {
  HttpMeetingRepository(this._api);
  final ApiClient _api;

  @override
  Future<Result<List<Meeting>>> fetchAll() => _api.send(
      'GET', '/meetings?limit=100',
      okStatus: 200, parse: (j) => itemsOf(j, Meeting.fromJson));

  @override
  Future<Result<Meeting>> fetchById(int id) => _api.send('GET', '/meetings/$id',
      okStatus: 200, parse: (j) => Meeting.fromJson(j as Map<String, dynamic>));

  @override
  Future<Result<Meeting>> create(Meeting meeting) => _api.send(
      'POST', '/meetings',
      body: meeting.toJson(),
      okStatus: 201,
      parse: (j) => Meeting.fromJson(j as Map<String, dynamic>));

  @override
  Future<Result<Meeting>> update(Meeting meeting) => _api.send(
      'PUT', '/meetings/${meeting.id}',
      body: meeting.toJson(),
      okStatus: 200,
      parse: (j) => Meeting.fromJson(j as Map<String, dynamic>));

  @override
  Future<Result<void>> delete(int id) =>
      _api.send('DELETE', '/meetings/$id', okStatus: 204, parse: (_) {});
}

class HttpAccountRepository implements AccountRepository {
  HttpAccountRepository(this._api);
  final ApiClient _api;

  @override
  Future<Result<Profile>> fetchMe() => _api.send('GET', '/me',
      okStatus: 200, parse: (j) => Profile.fromJson(j as Map<String, dynamic>));

  @override
  Future<Result<Profile>> updateMe(Profile me) => _api.send('PUT', '/me',
      body: me.toJson(),
      okStatus: 200,
      parse: (j) => Profile.fromJson(j as Map<String, dynamic>));
}
