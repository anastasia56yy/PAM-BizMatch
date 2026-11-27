// Доменная модель профиля — переживёт mock и перейдёт на L5.

/// Цель знакомства — то, что человек ищет на платформе.
enum Goal {
  investment('Ищу инвестиции'),
  investor('Инвестирую'),
  cofounder('Ищу сооснователя'),
  hiring('Нанимаю'),
  partnership('Партнёрство'),
  mentoring('Менторство');

  final String label;
  const Goal(this.label);
}

class Profile {
  final int id; // L3: идентичность, которая путешествует в адресе /…/:id
  final String name;
  final String title;
  final String company;
  final String industry;
  final String city;
  final Goal goal;
  final int experienceYears;
  final List<String> skills;
  final String about;

  /// Оценка совместимости 0–100, которую выставляет ИИ-подбор.
  final int aiScore;

  /// Короткое объяснение ИИ: почему этот человек вам подходит.
  final String aiReason;

  /// Контакты — заполняются только в собственном профиле.
  final String email;
  final String phone;
  final String linkedIn;

  /// Фото: ОТНОСИТЕЛЬНЫЙ путь на сервере (/avatars/… или /files/…),
  /// пусто — фото нет, показываются инициалы (Задание 7).
  final String photoUrl;

  const Profile(
    this.id,
    this.name,
    this.title,
    this.company,
    this.industry,
    this.city,
    this.goal,
    this.experienceYears,
    this.skills,
    this.about,
    this.aiScore,
    this.aiReason, {
    this.email = '',
    this.phone = '',
    this.linkedIn = '',
    this.photoUrl = '',
  });

  // ── Граница JSON (L5): язык сервера ↔ доменная модель ────────────────

  /// Кандидат с сервера (/profiles) или собственный профиль (/me).
  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        j['id'] as int,
        j['name'] as String,
        j['title'] as String? ?? '',
        j['company'] as String? ?? '',
        j['industry'] as String? ?? '',
        j['city'] as String? ?? '',
        Goal.values.asNameMap()[j['goal']] ?? Goal.partnership,
        j['experience_years'] as int? ?? 0,
        [for (final s in j['skills'] as List? ?? const []) s as String],
        j['about'] as String? ?? '',
        j['ai_score'] as int? ?? 0,
        j['ai_reason'] as String? ?? '',
        email: j['email'] as String? ?? '',
        phone: j['phone'] as String? ?? '',
        linkedIn: j['linkedin'] as String? ?? '',
        photoUrl: j['photo_url'] as String? ?? '',
      );

  /// Без id — идентичность даёт сервер (C8).
  Map<String, dynamic> toJson() => {
        'name': name,
        'title': title,
        'company': company,
        'industry': industry,
        'city': city,
        'goal': goal.name,
        'experience_years': experienceYears,
        'skills': skills,
        'about': about,
        'ai_score': aiScore,
        'ai_reason': aiReason,
        'email': email,
        'phone': phone,
        'linkedin': linkedIn,
        'photo_url': photoUrl,
      };

  /// «Тот же профиль, другие поля»: create даёт id, форма меняет данные.
  Profile copyWith({
    int? id,
    String? name,
    String? title,
    String? company,
    Goal? goal,
    int? experienceYears,
    String? about,
    String? email,
    String? phone,
    String? linkedIn,
    String? photoUrl,
  }) =>
      Profile(
        id ?? this.id,
        name ?? this.name,
        title ?? this.title,
        company ?? this.company,
        industry,
        city,
        goal ?? this.goal,
        experienceYears ?? this.experienceYears,
        skills,
        about ?? this.about,
        aiScore,
        aiReason,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        linkedIn: linkedIn ?? this.linkedIn,
        photoUrl: photoUrl ?? this.photoUrl,
      );
}
