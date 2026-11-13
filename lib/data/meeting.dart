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

  factory Meeting.fromJson(Map<String, dynamic> j) => Meeting(
        j['id'] as int,
        j['profile_id'] as int,
        j['profile_name'] as String,
        j['topic'] as String,
        DateTime.parse(j['date'] as String),
        j['duration_min'] as int,
        j['format'] as String,
        j['message'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'profile_id': profileId,
        'profile_name': profileName,
        'topic': topic,
        'date': date.toIso8601String(),
        'duration_min': durationMin,
        'format': format,
        'message': message,
      };

  Meeting copyWith({int? id}) => Meeting(id ?? this.id, profileId, profileName,
      topic, date, durationMin, format, message);

  static const formats = {
    'online': 'Онлайн (Zoom / Meet)',
    'office': 'В офисе',
    'coffee': 'Бизнес-кофе',
  };

  String get formatLabel => formats[format] ?? format;
}
