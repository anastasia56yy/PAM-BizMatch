# BizMatch — деловые знакомства с ИИ-подбором

Flutter-проект дисциплины **PAM** (Программирование мобильных приложений), UTM FCIM.
Автор: Трачук Анастасия, TI-236.

Смесь LinkedIn (деловой профиль) и Tinder (свайп-карточки) плюс ИИ-оценка совместимости 0–100 %.
Все лабораторные — в этом репозитории: L1 — в папке `lab1/`, L2–L5 — один проект, который растёт от лабораторной к лабораторной; конец каждой отмечен git-тегом и GitHub Release с PDF-отчётом.

## Лабораторные

| ЛР | Тема | Код на конец ЛР | Релиз и отчёт |
|---|---|---|---|
| L1 | Среда разработки, основы Dart, выбор темы | папка [lab1/](lab1) · [tree/L1](https://github.com/anastasia56yy/PAM-BizMatch/tree/L1) | [L1](https://github.com/anastasia56yy/PAM-BizMatch/releases/tag/L1) |
| L2 | Статический UI: виджеты, layout, тема Material 3 | [tree/L2](https://github.com/anastasia56yy/PAM-BizMatch/tree/L2) | [L2](https://github.com/anastasia56yy/PAM-BizMatch/releases/tag/L2) |
| L3 | Навигация go_router, формы, валидация | [tree/L3](https://github.com/anastasia56yy/PAM-BizMatch/tree/L3) · [изменения L2→L3](https://github.com/anastasia56yy/PAM-BizMatch/compare/L2...L3) | [L3](https://github.com/anastasia56yy/PAM-BizMatch/releases/tag/L3) |
| L4 | State (provider) + Repository, mock-хранилища | [tree/L4](https://github.com/anastasia56yy/PAM-BizMatch/tree/L4) · [изменения L3→L4](https://github.com/anastasia56yy/PAM-BizMatch/compare/L3...L4) | [L4](https://github.com/anastasia56yy/PAM-BizMatch/releases/tag/L4) |
| L5 | Собственный backend (Dart + SQLite), JWT, HTTP-хранилища | [tree/L5](https://github.com/anastasia56yy/PAM-BizMatch/tree/L5) · [изменения L4→L5](https://github.com/anastasia56yy/PAM-BizMatch/compare/L4...L5) | [L5](https://github.com/anastasia56yy/PAM-BizMatch/releases/tag/L5) |

## Запуск

Сервер (с L5):
```
cd server
dart pub get
dart run bin/server.dart          # http://localhost:8080, база app.db создаётся сама
```
Тесты соответствия сервера:
```
cd server/conformance
dart run bin/conformance.dart --base-url http://localhost:8080   # PASS — 42/42
```
Приложение:
```
flutter pub get
flutter run      # эмулятор Android видит сервер как http://10.0.2.2:8080
flutter test
```

## Архитектура (L5)

```
экраны → модели (ChangeNotifier) → интерфейсы *Repository → Http*Repository → ApiClient → server/
                                                                    │
                     token в shared_preferences ── Bearer на каждый запрос; 401 → token стёрт → /login
```

```
lib/
├── main.dart              # корень композиции: async main, выбор источника данных, providers
├── router.dart            # go_router: маршруты, стартовый адрес по token-у
├── data/                  # сущности (fromJson/toJson), интерфейсы хранилищ, Http-реализации,
│                          # ApiClient (три слоя отказа), AuthApi, TokenStore, перевод ошибок
├── models/                # ProfilesModel, ChatsModel, MeetingsModel, AccountModel, ShortlistModel
├── screens/               # 12 экранов
├── widgets/               # ProfileCard, MatchScoreBadge, ErrorView, ShortlistButton, …
└── utils/validators.dart  # валидаторы форм
server/
├── bin/server.dart        # маршруты, CORS, конверт ошибок
├── lib/                   # auth (JWT, PBKDF2), crud (общий CRUD-модуль), files, theme (сущности темы)
└── conformance/           # набор тестов соответствия
```

## Маршруты приложения

| Адрес | Экран | Переход |
|---|---|---|
| `/login` | Вход / регистрация (вне shell-а) | после входа `go('/discover')` |
| `/discover` | Знакомства (вкладка 1) | |
| `/discover/:id`, `/discover/:id/meet` | Детали, встреча | `push` |
| `/matches` | ИИ-подбор (вкладка 2), поиск и подгрузка страниц | |
| `/matches/brief` | Запрос к ИИ | `push` |
| `/matches/:id`, `/matches/:id/meet` | Детали, встреча | `push` |
| `/chats`, `/chats/:id` | Контакты (вкладка 3), переписка | `push` |
| `/profile`, `/profile/edit` | Мой профиль (вкладка 4), редактирование | `push`; выход — `go('/login')` |

## API сервера

| Маршрут | Назначение |
|---|---|
| `GET /health` | проверка, что сервер жив |
| `POST /auth/register`, `POST /auth/login` | регистрация и вход → JWT |
| `/notes`, `/profiles`, `/conversations`, `/meetings` | CRUD «на пользователя»: `GET` (`?page=&limit=&search=`), `POST`, `GET/PUT/DELETE /{id}` |
| `GET/PUT /me` | собственный профиль |
| `POST /files`, `GET /files/{id}` | загрузка multipart до 5 МБ и скачивание |

Ошибки всегда приходят в конверте `{"error": {"code": "...", "message": "..."}}`.

## Правила валидации форм

| Форма | Поле | Правило |
|---|---|---|
| Вход | E-mail | непустой, формат `x@y.z` |
| Вход | Пароль | ≥ 6 символов |
| Регистрация | Имя | обязательно |
| Встреча | Тема | ≥ 5 символов |
| Встреча | Дата | строго в будущем |
| Встреча | Длительность | 15–180 мин |
| Запрос к ИИ | Кого ищете | ≥ 20 символов |
| Запрос к ИИ | Мин. опыт | 0–40 лет |
| Профиль | Телефон | 8 цифр, начинается с 6/7 (+373) |
| Профиль | LinkedIn | пусто или `https://linkedin.com/in/…` |
| Профиль | О себе | 30–300 символов |
