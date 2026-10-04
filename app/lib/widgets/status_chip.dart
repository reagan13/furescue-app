import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Tones from web `.rchip--*` in `resident-primitives.css`.
enum StatusChipTone { brand, sky, success, alert, muted }

StatusChipTone statusChipTone(String status) {
  return switch (status) {
    'pending' ||
    'pending_verification' ||
    'pending_review' ||
    'open' ||
    'in_progress' ||
    'not_started' => StatusChipTone.brand,
    'assigned' || 'completed' => StatusChipTone.sky,
    'verified' ||
    'resolved' ||
    'approved' ||
    'available' => StatusChipTone.success,
    'dismissed' || 'rejected' || 'cancelled' => StatusChipTone.alert,
    _ => StatusChipTone.muted,
  };
}

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.status,
    this.onDark = false,
  });

  final String label;
  final String status;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final (fg, bg) = _colors(tokens);
    return Semantics(
      label: label,
      child: Container(
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
      ),
    );
  }

  (Color, Color) _colors(AppTokens tokens) {
    if (onDark) {
      return (
        tokens.primaryForeground,
        tokens.primaryForeground.withValues(alpha: 0.16),
      );
    }
    return switch (statusChipTone(status)) {
      StatusChipTone.brand => (
        tokens.jungle,
        tokens.jungle.withValues(alpha: 0.12),
      ),
      StatusChipTone.sky => (
        tokens.teal,
        tokens.jungle2.withValues(alpha: 0.15),
      ),
      StatusChipTone.success => (
        tokens.chipSuccessFg,
        tokens.chipSuccess.withValues(alpha: 0.12),
      ),
      StatusChipTone.alert => (
        tokens.destructive,
        tokens.destructive.withValues(alpha: 0.1),
      ),
      StatusChipTone.muted => (tokens.stamp, tokens.muted),
    };
  }
}
