import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class LearningSubjectFilter {
  const LearningSubjectFilter({required this.category, required this.label});

  /// Null selects the full catalog.
  final String? category;
  final String label;
}

class LearningCatalogHeader extends StatelessWidget {
  const LearningCatalogHeader({
    super.key,
    required this.total,
    required this.inProgress,
    required this.completed,
    required this.subjects,
    required this.selected,
    required this.onSelected,
    this.notice,
  });

  final int total;
  final int inProgress;
  final int completed;
  final List<LearningSubjectFilter> subjects;
  final String? selected;
  final ValueChanged<String?> onSelected;
  final String? notice;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final note = notice;
    final courseWord = total == 1 ? 'course' : 'courses';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.school_outlined, color: tokens.jungle),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Course catalog',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Published lessons on dog and cat care in Mati City.',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: tokens.mutedForeground),
        ),
        const SizedBox(height: 12),
        Text(
          '$total $courseWord · $inProgress in progress · $completed completed',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final subject in subjects)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(subject.label),
                    selected: selected == subject.category,
                    onSelected: (_) => onSelected(subject.category),
                  ),
                ),
            ],
          ),
        ),
        if (note != null && note.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            note,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: tokens.destructive),
          ),
        ],
      ],
    );
  }
}
