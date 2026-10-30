# BizMatch — деловые знакомства с ИИ-подбором

Flutter-проект дисциплины PAM: L2 (статический UI) → L3 (навигация, формы, валидация).
Смесь LinkedIn (деловой профиль) и Tinder (свайп-карточки) плюс ИИ-оценка совместимости 0–100 %.

## Запуск
```
flutter pub get
flutter run            # эмулятор Android / телефон
flutter run -d chrome  # быстрый просмотр в браузере
flutter test
```

## Структура lib/
```
lib/
├── main.dart            # MaterialApp.router + тема (seed 0xFF0F6E8C)
├── router.dart          # карта маршрутов go_router
├── data/mock_data.dart  # Profile, Goal, Conversation, Message + mock-данные
├── utils/validators.dart# валидаторы форм
├── screens/             # 10 экранов
└── widgets/             # ProfileCard, MatchScoreBadge, InitialsAvatar, SkillChips, InfoRow, AppShell
```

## Маршруты
| Адрес | Экран | Переход |
|---|---|---|
| `/login` | Вход (вне shell-а) | после входа `go('/discover')` |
| `/discover` | Знакомства (вкладка 1) | |
| `/discover/:id`, `/discover/:id/meet` | Детали, встреча | `push` |
| `/matches` | ИИ-подбор (вкладка 2) | |
| `/matches/brief` | Запрос к ИИ (стоит перед `:id`) | `push` |
| `/matches/:id`, `/matches/:id/meet` | Детали, встреча | `push` |
| `/chats`, `/chats/:id` | Контакты (вкладка 3), переписка | `push`; из деталей — `go` |
| `/profile`, `/profile/edit` | Мой профиль (вкладка 4), редактирование | `push`; выход — `go('/login')` |

## Правила валидации
| Форма | Поле | Правило | Клавиатура / фильтр |
|---|---|---|---|
| Вход | E-mail | непустой, формат `x@y.z` | emailAddress |
| Вход | Пароль | ≥ 6 символов | obscureText |
| Встреча | Тема | ≥ 5 символов | — |
| Встреча | Дата | строго в будущем | DatePicker |
| Встреча | Длительность | 15–180 мин | number, digitsOnly |
| Встреча | Формат | обязателен | Dropdown |
| Запрос к ИИ | Кого ищете | ≥ 20 символов | — |
| Запрос к ИИ | Цель, отрасль | обязательны | Dropdown / текст |
| Запрос к ИИ | Мин. опыт | 0–40 лет | number, digitsOnly |
| Профиль | E-mail | формат | emailAddress |
| Профиль | Телефон | 8 цифр, начинается с 6/7 (+373) | phone, digitsOnly, длина 8 |
| Профиль | LinkedIn | пусто или `https://linkedin.com/in/…` | url |
| Профиль | Опыт | 0–60 лет | number, digitsOnly |
| Профиль | О себе | ≥ 30 символов, ≤ 300 | — |

Feedback: SnackBar на свайп-действиях, избранном, сохранении форм; диалог подтверждения на «Выйти из аккаунта» и «Удалить контакт».
