import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Centered empty state with an optional full-width action.
class EmptyPrompt extends StatelessWidget {
  const EmptyPrompt({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.pets_outlined,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final showAction =
        actionLabel != null && actionLabel!.isNotEmpty && onAction != null;
    return Column(
      children: [
        const SizedBox(height: 24),
        Icon(icon, size: 36, color: tokens.stamp),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (showAction) ...[
          const SizedBox(height: 16),
          FilledButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ],
    );
  }
}
