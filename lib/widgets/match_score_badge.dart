import 'package:flutter/material.dart';

/// Бейдж «ИИ-совпадение в %». Цвет зависит от силы совпадения.
class MatchScoreBadge extends StatelessWidget {
  final int score;
  final bool large;

  const MatchScoreBadge({super.key, required this.score, this.large = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = score >= 85
        ? (scheme.primary, scheme.onPrimary)
        : score >= 70
            ? (scheme.secondaryContainer, scheme.onSecondaryContainer)
            : (scheme.surfaceContainerHighest, scheme.onSurfaceVariant);
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: large ? 12 : 8, vertical: large ? 6 : 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: large ? 18 : 14, color: fg),
          const SizedBox(width: 4),
          Text(
            '$score%',
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: large ? 16 : 13,
            ),
          ),
        ],
      ),
    );
  }
}
