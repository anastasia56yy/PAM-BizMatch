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
  });

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
      );
}
