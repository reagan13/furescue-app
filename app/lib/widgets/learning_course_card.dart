import 'package:flutter/material.dart';

import '../models/learning_content.dart';
import '../models/learning_module.dart';
import '../theme/tokens.dart';
import 'app_card.dart';
import 'learning_style.dart';

class LearningCourseCard extends StatelessWidget {
  const LearningCourseCard({
    super.key,
    required this.module,
    required this.progress,
    this.onTap,
  });

  final LearningModule module;
  final LearningProgress? progress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final excerpt = lessonExcerpt(module.contentBody);
    final row = progress;
    final showBar = row != null && (row.isInProgress || row.isCompleted);
    final accent = learningCategoryColor(tokens, module.category);
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              LearningCategoryLabel(
                category: module.category,
                label: module.categoryLabel,
              ),
              LearningStatusPill(progress: row),
              if (module.isDraft)
                Text(
                  'Draft',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: tokens.stamp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            module.displayTitle,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (excerpt.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              excerpt,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: tokens.mutedForeground),
            ),
          ],
          if (showBar) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: row.fraction,
                minHeight: 6,
                color: accent,
                backgroundColor: tokens.muted,
              ),
            ),
          ],
          if (onTap != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Open course',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: tokens.jungle,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward, size: 18, color: tokens.jungle),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
