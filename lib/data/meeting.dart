/// Запрос на встречу — вторая пишущая сущность темы.
class Meeting {
  final int id;
  final int profileId;
  final String profileName; // копия имени: встреча переживёт скрытый профиль
  final String topic;
  final DateTime date;
  final int durationMin;
  final String format; // 'online' | 'office' | 'coffee'
  final String message;

  const Meeting(this.id, this.profileId, this.profileName, this.topic,
      this.date, this.durationMin, this.format, this.message);

  Meeting copyWith({int? id}) => Meeting(id ?? this.id, profileId, profileName,
      topic, date, durationMin, format, message);

  static const formats = {
    'online': 'Онлайн (Zoom / Meet)',
    'office': 'В офисе',
    'coffee': 'Бизнес-кофе',
  };

  String get formatLabel => formats[format] ?? format;
}
