import 'package:flutter/material.dart';

/// Ряд навыков-«чипов» (детали профиля, мой профиль).
class SkillChips extends StatelessWidget {
  final List<String> skills;

  const SkillChips({super.key, required this.skills});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final s in skills)
          Chip(label: Text(s), visualDensity: VisualDensity.compact),
      ],
    );
  }
}
