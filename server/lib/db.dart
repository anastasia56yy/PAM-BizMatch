import 'dart:ffi';

import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart';

import 'theme.dart';

/// Открывает SQLite-базу и применяет схему. На Windows используется
/// системная библиотека winsqlite3.dll — ноль настройки.
Database openDatabase(String path) {
  open.overrideFor(
      OperatingSystem.windows, () => DynamicLibrary.open('winsqlite3.dll'));
  final db = sqlite3.open(path);
  db.execute('PRAGMA foreign_keys = ON;');
  for (final statement in [...schema, ...themeSchema]) {
    db.execute(statement);
  }
  return db;
}

/// Схема применяется при каждом запуске. CREATE TABLE IF NOT EXISTS:
/// НОВАЯ таблица появится сама, а изменённые колонки существующей — нет
/// (тогда удалите app.db).
const schema = [
  '''CREATE TABLE IF NOT EXISTS users (
       id INTEGER PRIMARY KEY AUTOINCREMENT,
       email TEXT NOT NULL UNIQUE,
       password_hash TEXT NOT NULL,
       name TEXT NOT NULL,
       created_at TEXT NOT NULL)''',
  '''CREATE TABLE IF NOT EXISTS notes (
       id INTEGER PRIMARY KEY AUTOINCREMENT,
       user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
       title TEXT NOT NULL,
       content TEXT NOT NULL DEFAULT '',
       created_at TEXT NOT NULL,
       updated_at TEXT NOT NULL)''',
  '''CREATE TABLE IF NOT EXISTS files (
       id INTEGER PRIMARY KEY AUTOINCREMENT,
       user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
       filename TEXT NOT NULL,
       mime_type TEXT NOT NULL,
       size INTEGER NOT NULL,
       data BLOB NOT NULL,
       created_at TEXT NOT NULL)''',
];
