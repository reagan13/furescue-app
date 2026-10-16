import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'app_card.dart';
import 'report_feed_image.dart';
import 'status_chip.dart';

/// Phone card for a resident or rescuer list row: photo on top, then status,
/// title, and any extra lines the screen already has.
class ScanCard extends StatelessWidget {
  const ScanCard({
    super.key,
    this.photoPath,
    required this.title,
    this.subtitle,
    this.statusLabel,
    this.status,
    this.onTap,
    this.children = const [],
    this.aspectRatio = 16 / 9,
    this.fillFrame = false,
    this.titleMaxLines = 2,
  });

  final String? photoPath;
  final String title;
  final String? subtitle;
  final String? statusLabel;
  final String? status;
  final VoidCallback? onTap;
  final List<Widget> children;
  final double aspectRatio;
  final bool fillFrame;
  final int titleMaxLines;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final showStatus =
        statusLabel != null &&
        status != null &&
        statusLabel!.isNotEmpty &&
        status!.isNotEmpty;

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : 360.0;
              final hasPhoto =
                  photoPath != null && photoPath!.trim().isNotEmpty;
              final height = hasPhoto || fillFrame
                  ? width / aspectRatio
                  : 96.0;
              return ReportFeedImage(path: photoPath, height: height);
            },
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
                if (showStatus) ...[
                  StatusChip(label: statusLabel!, status: status!),
                  const SizedBox(height: AppSpace.sm),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: titleMaxLines,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (onTap != null) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.chevron_right, color: tokens.stamp),
                    ],
                  ],
                ),
                if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                for (var i = 0; i < children.length; i++) ...[
                  const SizedBox(height: AppSpace.sm),
                  children[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
