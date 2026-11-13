import 'dart:convert';

import 'package:sqlite3/sqlite3.dart';

import 'api.dart';

/// Стартовый подбор нового пользователя: 24 кандидата (больше одной
/// страницы по 20 — пагинация видна сразу), два контакта и одна встреча.
/// Вызывается из Auth после регистрации.
void seedNewUser(Database db, int userId) {
  final now = nowIso();
  final ids = <int>[];
  for (final c in _candidates) {
    db.execute(
        'INSERT INTO profiles (user_id, name, title, company, industry, city, '
        'goal, experience_years, skills, about, ai_score, ai_reason, '
        'created_at, updated_at) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)',
        [
          userId, c.name, c.title, c.company, c.industry, c.city, c.goal,
          c.exp, jsonEncode(c.skills), c.about, c.score, c.reason, now, now,
        ]);
    ids.add(db.lastInsertRowId);
  }

  void chat(int i, List<(bool, String, String)> messages, int unread) {
    final c = _candidates[i];
    db.execute(
        'INSERT INTO conversations (user_id, profile_id, name, company, '
        'last_message, time, unread, messages, created_at, updated_at) '
        'VALUES (?,?,?,?,?,?,?,?,?,?)',
        [
          userId, ids[i], c.name, c.company, messages.last.$2,
          messages.last.$3, unread,
          jsonEncode([
            for (final m in messages)
              {'from_me': m.$1, 'text': m.$2, 'time': m.$3}
          ]),
          now, now,
        ]);
  }

  chat(2, [
    (true, 'Мария, отправила вам спонсорский пакет форума.', '09:40'),
    (false, 'Спасибо! Передала коллегам из спонсорского отдела', '10:05'),
  ], 0);
  chat(0, [
    (false, 'Добрый день! ИИ показал нам 96% совпадения.', '10:02'),
    (true, 'Здравствуйте, Ирина! Мы строим B2B SaaS для event-индустрии.', '10:05'),
    (false, 'Пришлите, пожалуйста, pitch deck до пятницы', '10:42'),
  ], 1);

  final meetingDate =
      DateTime.now().add(const Duration(days: 7)).toIso8601String();
  db.execute(
      'INSERT INTO meetings (user_id, profile_id, profile_name, topic, date, '
      'duration_min, format, message, created_at, updated_at) '
      'VALUES (?,?,?,?,?,?,?,?,?,?)',
      [
        userId, ids[0], _candidates[0].name, 'Обсуждение seed-раунда',
        meetingDate, 45, 'online', 'Подготовлю pitch deck.', now, now,
      ]);
}

typedef _C = ({
  String name, String title, String company, String industry, String city,
  String goal, int exp, List<String> skills, String about, int score,
  String reason
});

const List<_C> _candidates = [
  (name: 'Ирина Чобану', title: 'Partner, Venture Capital', company: 'Moldova Growth Fund', industry: 'Финансы', city: 'Кишинёв', goal: 'investor', exp: 14, skills: ['Seed-раунды', 'Due diligence', 'FinTech', 'SaaS'], about: 'Инвестирую в B2B SaaS и FinTech на стадии seed: чеки 50–250 тыс. €.', score: 96, reason: 'Инвестирует в B2B SaaS на seed — совпадает со стадией и рынком вашего проекта.'),
  (name: 'Андрей Попеску', title: 'CTO & Co-founder', company: 'LogiTrack SRL', industry: 'Логистика', city: 'Кишинёв', goal: 'cofounder', exp: 11, skills: ['Flutter', 'Go', 'Kubernetes', 'Архитектура'], about: 'Строю платформу трекинга грузов. Ищу коммерческого сооснователя.', score: 91, reason: 'Ищет сооснователя с компетенциями продаж, которых нет в его команде.'),
  (name: 'Мария Русу', title: 'Head of Marketing', company: 'Orange Moldova', industry: 'Телеком', city: 'Кишинёв', goal: 'partnership', exp: 9, skills: ['Brand strategy', 'Performance', 'Event-маркетинг'], about: 'Отвечаю за партнёрские программы и спонсорство мероприятий.', score: 88, reason: 'Ведёт спонсорские программы — релевантно для вашего ивента.'),
  (name: 'Victor Lungu', title: 'Founder', company: 'AgroSense', industry: 'AgriTech', city: 'Бэлць', goal: 'investment', exp: 7, skills: ['IoT', 'Агрономия', 'Продажи фермерам'], about: 'Датчики влажности почвы, 120 клиентов, поднимаем pre-seed.', score: 84, reason: 'Привлекает pre-seed; ваш опыт B2B-продаж закрывает его пробел.'),
  (name: 'Елена Морару', title: 'HR Director', company: 'Endava Moldova', industry: 'IT-аутсорсинг', city: 'Кишинёв', goal: 'hiring', exp: 12, skills: ['Talent acquisition', 'Employer branding', 'L&D'], about: 'Нанимаем 40+ инженеров и тимлидов в 2027 году.', score: 79, reason: 'Активно нанимает тимлидов — совпадает с вашим профилем и городом.'),
  (name: 'Сергей Ботнарь', title: 'Managing Director', company: 'Bridge Consulting Group', industry: 'Консалтинг', city: 'Яссы', goal: 'mentoring', exp: 22, skills: ['Стратегия', 'M&A', 'Корпоративное управление'], about: 'Менторю основателей на этапе масштабирования.', score: 74, reason: 'Ментор по масштабированию в регионе RO–MD.'),
  (name: 'Ana Ceban', title: 'Product Manager', company: 'Maib', industry: 'Банкинг', city: 'Кишинёв', goal: 'partnership', exp: 6, skills: ['Mobile banking', 'Open API', 'UX research'], about: 'Развиваю мобильный банк и открытые API для партнёров.', score: 70, reason: 'Ищет пилоты для open API — возможна интеграция с вашим продуктом.'),
  (name: 'Дмитрий Гуцу', title: 'Sales Lead', company: 'Retail Systems Ltd.', industry: 'Ритейл', city: 'Одесса', goal: 'hiring', exp: 8, skills: ['B2B-продажи', 'CRM', 'Переговоры'], about: 'Расширяем отдел продаж POS-решений, ищу региональных менеджеров.', score: 63, reason: 'Нанимает в продажи; совпадение по навыкам частичное.'),
  (name: 'Natalia Rotaru', title: 'CFO', company: 'Moldcell', industry: 'Телеком', city: 'Кишинёв', goal: 'partnership', exp: 15, skills: ['Финансы', 'Бюджетирование', 'Спонсорство'], about: 'Курирую бюджеты партнёрских и спонсорских программ.', score: 86, reason: 'Решает по спонсорским бюджетам телекома — прямой выход на партнёрство.'),
  (name: 'Павел Чиботару', title: 'Angel Investor', company: 'Dragon Capital Club', industry: 'Финансы', city: 'Кишинёв', goal: 'investor', exp: 18, skills: ['Ангельские инвестиции', 'EdTech', 'SaaS'], about: 'Вкладываю 20–50 тыс. € в ранние B2B-проекты.', score: 83, reason: 'Ангел с фокусом на B2B SaaS, чек под ваш раунд.'),
  (name: 'Cristina Bivol', title: 'Event Director', company: 'Moldexpo', industry: 'Event-индустрия', city: 'Кишинёв', goal: 'partnership', exp: 10, skills: ['Выставки', 'Логистика событий', 'Спонсорство'], about: 'Организую крупнейшие выставки страны, ищу tech-партнёров.', score: 82, reason: 'Ваша отрасль: совместные мероприятия и обмен аудиторией.'),
  (name: 'Игорь Сырбу', title: 'CEO', company: 'FinPay', industry: 'FinTech', city: 'Кишинёв', goal: 'cofounder', exp: 13, skills: ['Платежи', 'Регулирование', 'Fundraising'], about: 'Платёжный стартап, ищу сооснователя по продажам в ЕС.', score: 80, reason: 'Ищет коммерческого сооснователя — ваш профиль подходит.'),
  (name: 'Olga Munteanu', title: 'Head of HR', company: 'Pentalog', industry: 'IT-аутсорсинг', city: 'Кишинёв', goal: 'hiring', exp: 9, skills: ['Рекрутинг', 'Onboarding', 'HR-бренд'], about: 'Нанимаем менеджеров проектов и аналитиков.', score: 72, reason: 'Нанимает менеджеров — пересечение по навыкам переговоров.'),
  (name: 'Алексей Друцэ', title: 'Partner', company: 'Gala Ventures', industry: 'Финансы', city: 'Бухарест', goal: 'investor', exp: 16, skills: ['Series A', 'Marketplace', 'B2B'], about: 'Инвестирую в B2B-маркетплейсы региона CEE.', score: 78, reason: 'Фонд CEE, но стадия чуть позже вашей.'),
  (name: 'Doina Ursu', title: 'Marketing Manager', company: 'Kaufland Moldova', industry: 'Ритейл', city: 'Кишинёв', goal: 'partnership', exp: 7, skills: ['Trade marketing', 'Промо', 'Партнёрства'], about: 'Ищу партнёров для совместных промо-кампаний.', score: 69, reason: 'Партнёрские промо — возможен спонсорский пакет.'),
  (name: 'Михаил Казаку', title: 'Founder', company: 'EduSpark', industry: 'EdTech', city: 'Кишинёв', goal: 'investment', exp: 5, skills: ['EdTech', 'Продукт', 'Growth'], about: 'Платформа для подготовки к экзаменам, ищем seed.', score: 67, reason: 'Ранний стартап; полезен как спикер, а не партнёр.'),
  (name: 'Elena Gherman', title: 'COO', company: 'Darwin', industry: 'Ритейл', city: 'Кишинёв', goal: 'mentoring', exp: 17, skills: ['Операции', 'Масштабирование', 'Ритейл'], about: 'Менторю по операционному масштабированию.', score: 76, reason: 'Сильный ментор по операциям для растущей команды.'),
  (name: 'Станислав Попа', title: 'Business Developer', company: 'StarNet', industry: 'Телеком', city: 'Кишинёв', goal: 'partnership', exp: 8, skills: ['B2B-продажи', 'Партнёрства', 'Телеком'], about: 'Развиваю B2B-направление, ищу партнёров среди SaaS.', score: 85, reason: 'Телеком-партнёр для B2B SaaS — высокий шанс сделки.'),
  (name: 'Irina Lupu', title: 'Product Lead', company: 'Ebs Integrator', industry: 'IT-аутсорсинг', city: 'Кишинёв', goal: 'cofounder', exp: 10, skills: ['Product', 'Discovery', 'Agile'], about: 'Готовлю собственный продукт, ищу сооснователя-продажника.', score: 75, reason: 'Ищет коммерческого сооснователя в IT.'),
  (name: 'Василий Ткач', title: 'Investment Manager', company: 'EBRD Star Venture', industry: 'Финансы', city: 'Киев', goal: 'investor', exp: 11, skills: ['Акселерация', 'Гранты', 'Seed'], about: 'Программы поддержки стартапов Восточной Европы.', score: 73, reason: 'Программа поддержки — путь к грантам и связям.'),
  (name: 'Mariana Cojocari', title: 'PR Director', company: 'Agora', industry: 'Медиа', city: 'Кишинёв', goal: 'partnership', exp: 9, skills: ['PR', 'Медиа-партнёрства', 'Контент'], about: 'Медиа-партнёрства для деловых событий.', score: 81, reason: 'Медиа-партнёр для вашего форума.'),
  (name: 'Денис Мельник', title: 'Head of Sales', company: 'Linella', industry: 'Ритейл', city: 'Кишинёв', goal: 'hiring', exp: 12, skills: ['Управление продажами', 'KPI', 'Обучение'], about: 'Ищу руководителей направлений в продажах.', score: 61, reason: 'Найм в ритейле — пересечение небольшое.'),
  (name: 'Tatiana Rusu', title: 'Founder', company: 'GreenBox', industry: 'E-commerce', city: 'Кишинёв', goal: 'investment', exp: 6, skills: ['E-commerce', 'Логистика', 'Маркетинг'], about: 'Сервис доставки фермерских продуктов, ищем инвестиции.', score: 65, reason: 'Привлекает инвестиции; полезен как участник форума.'),
  (name: 'Роман Бэлан', title: 'CTO', company: 'Simpals', industry: 'IT', city: 'Кишинёв', goal: 'mentoring', exp: 20, skills: ['Архитектура', 'Highload', 'Команды'], about: 'Менторю CTO и тимлидов стартапов.', score: 71, reason: 'Технический ментор — пригодится для продукта.'),
];
