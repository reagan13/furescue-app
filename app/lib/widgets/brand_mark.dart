import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final size = compact ? 22.0 : 28.0;
    final wordmark = Theme.of(context).textTheme.headlineSmall
        ?.copyWith(fontSize: size, fontWeight: FontWeight.w800, height: 1.1);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 36 : 44,
          height: compact ? 36 : 44,
          decoration: BoxDecoration(
            color: tokens.jungle,
            borderRadius: BorderRadius.circular(tokens.radius),
          ),
          child: Icon(
            Icons.pets,
            color: tokens.primaryForeground,
            size: compact ? 20 : 24,
          ),
        ),
        const SizedBox(width: 10),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Fur',
                style: wordmark?.copyWith(color: tokens.ink),
              ),
              TextSpan(
                text: 'escue',
                style: wordmark?.copyWith(color: tokens.jungle),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
