// Зашитые в код данные, общие для нескольких экранов (L2).

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

  const Profile(
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
    this.aiReason,
  );
}

const mockProfiles = [
  Profile(
    'Ирина Чобану',
    'Partner, Venture Capital',
    'Moldova Growth Fund',
    'Финансы',
    'Кишинёв',
    Goal.investor,
    14,
    ['Seed-раунды', 'Due diligence', 'FinTech', 'SaaS'],
    'Инвестирую в B2B SaaS и FinTech на стадии seed: чеки 50–250 тыс. €. '
        'Помогаю с выходом на рынки ЕС и структурой следующих раундов.',
    96,
    'Инвестирует в B2B SaaS на seed — совпадает со стадией и рынком вашего '
        'проекта; 3 общих контакта.',
  ),
  Profile(
    'Андрей Попеску',
    'CTO & Co-founder',
    'LogiTrack SRL',
    'Логистика',
    'Кишинёв',
    Goal.cofounder,
    11,
    ['Flutter', 'Go', 'Kubernetes', 'Архитектура'],
    'Строю платформу трекинга грузов для Восточной Европы. Ищу коммерческого '
        'сооснователя с опытом B2B-продаж.',
    91,
    'Ищет сооснователя с компетенциями продаж, которых нет в его команде; '
        'отрасль B2B, как у вас.',
  ),
  Profile(
    'Мария Русу',
    'Head of Marketing',
    'Orange Moldova',
    'Телеком',
    'Кишинёв',
    Goal.partnership,
    9,
    ['Brand strategy', 'Performance', 'Event-маркетинг'],
    'Отвечаю за партнёрские программы и спонсорство мероприятий. Открыта к '
        'коллаборациям с tech-сообществами.',
    88,
    'Ведёт спонсорские программы — релевантно для вашего ивента; '
        'интерес к tech-аудитории.',
  ),
  Profile(
    'Victor Lungu',
    'Founder',
    'AgroSense',
    'AgriTech',
    'Бэлць',
    Goal.investment,
    7,
    ['IoT', 'Агрономия', 'Продажи фермерам'],
    'Датчики влажности почвы для средних фермерских хозяйств. 120 клиентов, '
        'поднимаем pre-seed 150 тыс. €.',
    84,
    'Привлекает pre-seed; ваш опыт в B2B-продажах закрывает его главный '
        'пробел.',
  ),
  Profile(
    'Елена Морару',
    'HR Director',
    'Endava Moldova',
    'IT-аутсорсинг',
    'Кишинёв',
    Goal.hiring,
    12,
    ['Talent acquisition', 'Employer branding', 'L&D'],
    'Нанимаем 40+ инженеров и тимлидов в 2027 году. Ищу партнёров среди '
        'университетов и профессиональных сообществ.',
    79,
    'Активно нанимает тимлидов — совпадает с вашим профилем и городом.',
  ),
  Profile(
    'Сергей Ботнарь',
    'Managing Director',
    'Bridge Consulting Group',
    'Консалтинг',
    'Яссы',
    Goal.mentoring,
    22,
    ['Стратегия', 'M&A', 'Корпоративное управление'],
    'Два десятилетия в стратегическом консалтинге в Румынии и Молдове. '
        'Менторю основателей на этапе масштабирования.',
    74,
    'Ментор по масштабированию в регионе RO–MD; оценка снижена: '
        'другая отрасль.',
  ),
  Profile(
    'Ana Ceban',
    'Product Manager',
    'Maib',
    'Банкинг',
    'Кишинёв',
    Goal.partnership,
    6,
    ['Mobile banking', 'Open API', 'UX research'],
    'Развиваю мобильный банк и открытые API для партнёров. Ищу финтех-'
        'стартапы для пилотных интеграций.',
    70,
    'Ищет пилоты для open API — возможна интеграция с вашим продуктом.',
  ),
  Profile(
    'Дмитрий Гуцу',
    'Sales Lead',
    'Retail Systems Ltd.',
    'Ритейл',
    'Одесса',
    Goal.hiring,
    8,
    ['B2B-продажи', 'CRM', 'Переговоры'],
    'Расширяем отдел продаж POS-решений на рынки Молдовы и Румынии, ищу '
        'региональных менеджеров.',
    63,
    'Нанимает в продажи; совпадение по навыкам частичное, другой город.',
  ),
];

/// Фильтры экрана подбора (визуальные на L2).
const goalFilters = ['Все', 'Инвестиции', 'Сооснователь', 'Найм', 'Партнёрство', 'Менторство'];

class Conversation {
  final Profile profile;
  final String lastMessage;
  final String time;
  final int unread;

  const Conversation(this.profile, this.lastMessage, this.time, this.unread);
}

final mockConversations = [
  Conversation(mockProfiles[0], 'Пришлите, пожалуйста, pitch deck до пятницы', '10:42', 2),
  Conversation(mockProfiles[1], 'Давайте созвонимся завтра в 15:00?', '09:15', 1),
  Conversation(mockProfiles[2], 'Спасибо! Передала коллегам из спонсорского отдела', 'Вчера', 0),
  Conversation(mockProfiles[3], 'У нас уже 120 платящих ферм, могу показать метрики', 'Вчера', 0),
  Conversation(mockProfiles[4], 'Отличная идея с хакатоном для студентов UTM', 'Пн', 0),
  Conversation(mockProfiles[6], 'Документация по API в приложении к письму', '27 окт', 0),
];

class Message {
  final bool fromMe;
  final String text;
  final String time;

  const Message(this.fromMe, this.text, this.time);
}

const mockMessages = [
  Message(false, 'Добрый день! ИИ показал нам 96% совпадения — интересно познакомиться.', '10:02'),
  Message(true, 'Здравствуйте, Ирина! Взаимно. Мы строим B2B SaaS для event-индустрии.', '10:05'),
  Message(false, 'На какой вы стадии и какой объём раунда планируете?', '10:11'),
  Message(true, 'Pre-seed закрыт, MRR 8 тыс. €, поднимаем seed 200 тыс. €.', '10:20'),
  Message(false, 'Звучит хорошо. Какие рынки в приоритете после Молдовы?', '10:31'),
  Message(true, 'Румыния и Польша — там уже 4 пилотных клиента.', '10:38'),
  Message(false, 'Пришлите, пожалуйста, pitch deck до пятницы', '10:42'),
];

/// Профиль текущего пользователя.
const myProfile = Profile(
  'Анастасия',
  'Business Development Manager',
  'EventFlow SRL',
  'Event-индустрия',
  'Кишинёв',
  Goal.partnership,
  5,
  ['B2B-продажи', 'Партнёрства', 'Организация форумов', 'Переговоры'],
  'Развиваю B2B SaaS для event-индустрии и ищу партнёров, спонсоров и '
      'спикеров из банкинга, телекома и IT.',
  100,
  '',
);
