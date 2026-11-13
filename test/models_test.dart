import 'package:flutter_test/flutter_test.dart';

import 'package:biz_match/data/meeting.dart';
import 'package:biz_match/data/profile.dart';
import 'package:biz_match/models/chats_model.dart';
import 'package:biz_match/models/meetings_model.dart';
import 'package:biz_match/models/profiles_model.dart';
import 'package:biz_match/models/shortlist_model.dart';

import 'fakes.dart';

void main() {
  late FakeNetwork network;
  setUp(() => network = FakeNetwork());

  test('load: «грузится» → данные, извещение на входе и на выходе', () async {
    final model = ProfilesModel(FakeProfileRepository(network));
    var notified = 0;
    model.addListener(() => notified++);

    final future = model.load();
    expect(model.isLoading, isTrue);
    await future;

    expect(model.isLoading, isFalse);
    expect(model.error, isNull);
    expect(model.profiles, isNotEmpty);
    expect(notified, 2);
    // лучший по оценке ИИ — первым
    expect(model.profiles.first.aiScore,
        greaterThanOrEqualTo(model.profiles.last.aiScore));
  });

  test('авария: ошибка вместо данных, retry после выключения', () async {
    final model = ProfilesModel(FakeProfileRepository(network));
    network.simulateError = true;
    await model.load();
    expect(model.error, FakeNetwork.errNetwork);

    network.simulateError = false;
    await model.load();
    expect(model.error, isNull);
    expect(model.profiles, isNotEmpty);
  });

  test('коллекции наружу — только для чтения', () async {
    final model = ProfilesModel(FakeProfileRepository(network));
    await model.load();
    expect(() => model.profiles.removeLast(), throwsUnsupportedError);
  });

  test('remove: профиль исчезает, подписчики извещены', () async {
    final model = ProfilesModel(FakeProfileRepository(network));
    await model.load();
    final id = model.profiles.first.id;
    var notified = false;
    model.addListener(() => notified = true);

    expect(await model.remove(id), isNull);
    expect(model.byId(id), isNull);
    expect(notified, isTrue);
  });

  test('add встречи: id даёт хранилище, список растёт', () async {
    final model = MeetingsModel(FakeMeetingRepository(network));
    await model.load();
    final before = model.meetings.length;

    final error = await model.add(Meeting(0, 1, 'Ирина Чобану', 'Тест',
        DateTime(2027, 1, 10), 30, 'online', ''));

    expect(error, isNull);
    expect(model.meetings.length, before + 1);
    expect(model.meetings.any((m) => m.id >= 1000), isTrue);
  });

  test('add при аварии: сообщение, состояние нетронуто', () async {
    final model = MeetingsModel(FakeMeetingRepository(network));
    await model.load();
    final before = model.meetings.length;
    network.simulateError = true;

    final error = await model.add(Meeting(
        0, 1, 'Ирина Чобану', 'Тест', DateTime(2027, 1, 10), 30, 'online', ''));

    expect(error, FakeNetwork.errNetwork);
    expect(model.meetings.length, before);
  });

  test('избранное: toggle добавляет и убирает', () {
    final model = ShortlistModel();
    expect(model.toggle(3), isTrue);
    expect(model.count, 1);
    expect(model.toggle(3), isFalse);
    expect(model.count, 0);
  });

  test('startChat сразу после создания модели не плодит дубль', () async {
    final chats = ChatsModel(FakeConversationRepository(network));
    chats.load(); // как ..load() в корне: загрузка ещё идёт
    const irina = Profile(1, 'Ирина Чобану', '', 'Moldova Growth Fund', '',
        'Кишинёв', Goal.investor, 14, [], '', 96, '');

    expect(await chats.startChat(irina), isNull);
    expect(chats.conversations.where((c) => c.profileId == 1).length, 1);
  });
}
