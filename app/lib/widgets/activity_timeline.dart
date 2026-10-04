import 'package:flutter/material.dart';

import '../format/display.dart';
import '../models/rescue_case.dart';
import '../theme/tokens.dart';

class ActivityTimeline extends StatelessWidget {
  const ActivityTimeline({super.key, required this.items});

  final List<CaseActivity> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          _ActivityStep(item: items[i], isLast: i == items.length - 1),
      ],
    );
  }
}

class _ActivityStep extends StatelessWidget {
  const _ActivityStep({required this.item, required this.isLast});

  final CaseActivity item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final color = _actionColor(tokens, item.action);
    final when = timeAgo(item.createdAt);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: tokens.card, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.28),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: tokens.border)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activityActionLabel(item.action),
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontSize: 15),
                  ),
                  if (item.notes != null && item.notes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.notes!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  if (when.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(when, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _actionColor(AppTokens tokens, String action) {
    switch (action) {
      case 'resolved':
      case 'accepted':
      case 'proof_added':
        return tokens.statusSuccess;
      case 'assigned':
      case 'opened':
      case 'status_changed':
        return tokens.statusProgress;
      case 'declined':
        return tokens.statusDanger;
      default:
        return tokens.stamp;
    }
  }
}
