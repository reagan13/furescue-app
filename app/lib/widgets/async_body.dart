import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class AsyncBody extends StatelessWidget {
  const AsyncBody({
    super.key,
    required this.loading,
    required this.error,
    required this.isEmpty,
    required this.onRetry,
    required this.emptyMessage,
    required this.child,
  });

  final bool loading;
  final String? error;
  final bool isEmpty;
  final Future<void> Function() onRetry;
  final String emptyMessage;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    if (loading && isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }
    if (error != null && isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Text(error!, style: TextStyle(color: tokens.destructive)),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      );
    }
    if (isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Text(emptyMessage, style: Theme.of(context).textTheme.bodyMedium),
        ],
      );
    }
    return child;
  }
}
