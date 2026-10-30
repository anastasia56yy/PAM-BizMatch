import 'package:flutter/material.dart';

/// Аватар-заглушка с инициалами вместо фотографии.
class InitialsAvatar extends StatelessWidget {
  final String name;
  final double radius;

  const InitialsAvatar({super.key, required this.name, this.radius = 24});

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CircleAvatar(
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
  }
}
