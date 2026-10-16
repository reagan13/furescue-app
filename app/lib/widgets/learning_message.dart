import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Full-page loading, empty, and error states for Learn.
///
/// Always a scroll view so pull-to-refresh still works.
class LearningMessage extends StatelessWidget {
  const LearningMessage({
    super.key,
    required this.title,
    this.message,
    this.loading = false,
    this.error = false,
    this.onRetry,
  });

  final String title;
  final String? message;
  final bool loading;
  final bool error;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final detail = message;
    final retry = onRetry;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 72, 24, 32),
      children: [
        if (loading)
          const Center(child: CircularProgressIndicator())
        else
          Icon(
            error ? Icons.error_outline : Icons.menu_book_outlined,
            size: 40,
            color: error ? tokens.destructive : tokens.stamp,
          ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (detail != null && detail.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: tokens.mutedForeground),
          ),
        ],
        if (retry != null) ...[
          const SizedBox(height: 16),
          Center(
            child: TextButton(onPressed: retry, child: const Text('Try again')),
          ),
        ],
      ],
    );
  }
}
