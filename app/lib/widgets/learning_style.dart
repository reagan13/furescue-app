import 'package:flutter/material.dart';

import '../models/learning_module.dart';
import '../theme/tokens.dart';

Color learningCategoryColor(AppTokens tokens, String category) {
  return switch (category) {
    'dog_behavior' => tokens.jungle,
    'cat_behavior' => tokens.teal,
    'basic_training' => tokens.coral,
    'general_care' => tokens.stamp,
    _ => tokens.jungle,
  };
}

class LearningCategoryLabel extends StatelessWidget {
  const LearningCategoryLabel({
    super.key,
    required this.category,
    required this.label,
  });

  final String category;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = learningCategoryColor(context.tokens, category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class LearningStatusPill extends StatelessWidget {
  const LearningStatusPill({super.key, required this.progress});

  final LearningProgress? progress;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final row = progress;
    final label = row?.statusLabel ?? 'Not started';
    final (Color fg, Color bg) = row?.isCompleted == true
        ? (tokens.chipSuccessFg, tokens.chipSuccess.withValues(alpha: 0.12))
        : row?.isInProgress == true
        ? (tokens.teal, tokens.jungle2.withValues(alpha: 0.18))
        : (tokens.stamp, tokens.muted);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: fg, fontWeight: FontWeight.w700),
      ),
    );
  }
}
