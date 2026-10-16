import 'package:flutter/material.dart';

import '../format/display.dart';
import '../models/report.dart';
import '../theme/tokens.dart';
import 'app_card.dart';
import 'report_feed_image.dart';
import 'status_chip.dart';

class ReportFeedCard extends StatelessWidget {
  const ReportFeedCard({super.key, required this.report, required this.onTap});

  final Report report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final description = report.animalDescription.trim();
    final place = report.addressText?.trim() ?? '';
    final when = timeAgo(report.createdAt);
    final hasPlace = place.isNotEmpty;
    final hasWhen = when.isNotEmpty;
    final meta = [if (hasPlace) place, if (hasWhen) when].join(' · ');

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ReportFeedImage(
                path: report.photoUrls.isEmpty ? null : report.photoUrls.first,
              ),
              if (report.photoUrls.length > 1)
                Positioned(
                  top: AppSpace.sm,
                  right: AppSpace.sm,
                  child: _PhotoCount(count: report.photoUrls.length),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.md,
              AppSpace.sm,
              AppSpace.md,
              AppSpace.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusChip(label: report.statusLabel, status: report.status),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.xs),
                  Row(
                    children: [
                      Icon(
                        hasPlace
                            ? Icons.place_outlined
                            : Icons.schedule_outlined,
                        size: 16,
                        color: tokens.stamp,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoCount extends StatelessWidget {
  const _PhotoCount({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tokens.card.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.photo_library_outlined, size: 14, color: tokens.ink),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: tokens.ink, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
