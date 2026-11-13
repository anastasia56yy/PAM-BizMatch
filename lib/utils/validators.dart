import 'package:flutter/material.dart' show DateUtils;

// Валидаторы форм: возвращают текст ошибки или null (= ВАЛИДНО).

String? requiredField(String? value, String message) =>
    (value == null || value.trim().isEmpty) ? message : null;

String? validateEmail(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'Введите e-mail';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
    return 'Неверный формат e-mail';
  }
  return null;
}

String? validatePassword(String? value) {
  if (value == null || value.isEmpty) return 'Введите пароль';
  if (value.length < 6) return 'Минимум 6 символов';
  return null;
}

/// Целое число в диапазоне [min, max].
String? validateIntRange(String? value, int min, int max, String unit) {
  final n = int.tryParse(value ?? '');
  if (n == null) return 'Введите число';
  if (n < min || n > max) return 'От $min до $max $unit';
  return null;
}

/// Молдавский мобильный без кода страны: 8 цифр, начинается с 6 или 7.
String? validatePhone(String? value) {
  final v = value ?? '';
  if (v.isEmpty) return 'Введите телефон';
  if (!RegExp(r'^[67]\d{7}$').hasMatch(v)) {
    return '8 цифр, начиная с 6 или 7 (напр. 69123456)';
  }
  return null;
}

/// Необязательная ссылка на LinkedIn: пусто или https://(www.)linkedin.com/in/…
String? validateLinkedIn(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return null;
  if (!RegExp(r'^https://(www\.)?linkedin\.com/in/[\w\-]+/?$').hasMatch(v)) {
    return 'Формат: https://linkedin.com/in/имя';
  }
  return null;
}

/// Дата встречи — строго в будущем (не сегодня и не раньше).
String? validateFutureDate(DateTime? date, {DateTime? now}) {
  if (date == null) return 'Выберите дату';
  final today = DateUtils.dateOnly(now ?? DateTime.now());
  if (!date.isAfter(today)) return 'Дата должна быть в будущем';
  return null;
}

/// Минимальная длина осмысленного текста (запрос к ИИ).
String? validateMinLength(String? value, int min, String what) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'Поле «$what» обязательно';
  if (v.length < min) return 'Опишите подробнее: минимум $min символов';
  return null;
}

String formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
