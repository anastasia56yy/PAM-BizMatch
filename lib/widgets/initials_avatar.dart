import 'package:flutter/material.dart';

import '../config.dart';

/// Аватар: фото с сервера, а пока его нет (или оно не загрузилось) —
/// инициалы. [photoUrl] — ОТНОСИТЕЛЬНЫЙ путь (/avatars/… или /files/…).
class InitialsAvatar extends StatelessWidget {
  final String name;
  final double radius;
  final String photoUrl;

  const InitialsAvatar(
      {super.key, required this.name, this.radius = 24, this.photoUrl = ''});

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initials = CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primaryContainer,
      child: Text(
        _initials,
        style: TextStyle(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
          fontSize: radius * 0.7,
        ),
      ),
    );
    if (photoUrl.isEmpty) return initials;
    return ClipOval(
      child: Image.network(
        '$apiBase$photoUrl',
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        // сервер выключен или файла нет — молча возвращаемся к инициалам
        errorBuilder: (_, _, _) => initials,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : initials,
      ),
    );
  }
}
