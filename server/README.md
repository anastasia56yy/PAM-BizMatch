# BizMatch API — backend для L5

**Язык:** Dart (пакеты shelf + shelf_router, SQLite через sqlite3).
Комплект `05_Backend` от преподавателя отсутствовал, поэтому шаблон написан
по контракту из задания L5: auth с JWT, CRUD с пагинацией и поиском, upload,
единый конверт ошибок, SQLite, ноль настройки.

## Запуск

```bash
cd server
dart pub get
dart run bin/server.dart          # → http://localhost:8080, app.db создаётся сам
```

Переменные окружения: `PORT` (8080), `JWT_SECRET` (dev-secret-change-me),
`DB_PATH` (app.db). На Windows используется системная `winsqlite3.dll`.

## Тесты соответствия

```bash
cd server/conformance
dart pub get
dart run bin/conformance.dart --base-url http://localhost:8080
# → PASS — N/N checks passed
```

## Контракт

| Метод и путь | Ответ |
|---|---|
| `GET /health` | 200 `{"status":"ok"}` |
| `POST /auth/register` `{email,password,name}` | 201 `{token,user}`; 409 `EMAIL_TAKEN`; 400 `VALIDATION_ERROR` |
| `POST /auth/login` `{email,password}` | 200 `{token,user}`; 401 `UNAUTHORIZED` |
| `GET /notes?page=&limit=&search=` | 200 `{items,page,limit,total}` |
| `POST /notes` | 201, id даёт сервер; 400 без title |
| `GET/PUT/DELETE /notes/{id}` | 200 / 200 / 204; 404 — нет или чужая |
| `POST /files` (multipart, поле `file`, ≤ 5 МБ) | 201 `{id,filename,mime_type,size,url}` |
| `GET /files/{id}` | байты, `Content-Disposition: attachment` + CSP |

Все маршруты, кроме `/health`, `/auth/*` и `GET /files/{id}`, требуют
`Authorization: Bearer <token>`. Любая ошибка:
`{"error":{"code":"...","message":"..."}}`.

Чужая запись отвечает 404, а не 403: сервер не раскрывает, что объект существует.

Лабораторная конфигурация, принятая как есть: открытый CORS, секрет JWT по
умолчанию, сервер на ноутбуке без deploy.
