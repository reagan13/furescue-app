import 'package:flutter/material.dart';

import '../models/rescue_case.dart';
import '../theme/tokens.dart';

class CaseActionBar extends StatelessWidget {
  const CaseActionBar({
    super.key,
    required this.item,
    required this.busy,
    this.onAccept,
    this.onDecline,
    this.onProof,
  });

  final RescueCase item;
  final bool busy;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onProof;

  @override
  Widget build(BuildContext context) {
    if (!item.canRespond && !item.canAddProof) {
      return const SizedBox.shrink();
    }
    final tokens = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(color: tokens.card, boxShadow: tokens.shadowMd),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: item.canRespond
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilledButton(
                      onPressed: busy ? null : onAccept,
                      child: const Text('Accept case'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: busy ? null : onDecline,
                      child: const Text('Decline case'),
                    ),
                  ],
                )
              : FilledButton.icon(
                  onPressed: busy ? null : onProof,
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: const Text('Add proof photos'),
                ),
        ),
      ),
    );
  }
}
