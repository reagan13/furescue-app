import 'package:flutter/material.dart';

import '../format/display.dart';
import '../models/message_thread.dart';
import '../theme/tokens.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message, required this.mine});

  final ChatMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final when = timeAgo(message.sentAt);
    final maxWidth = MediaQuery.sizeOf(context).width * 0.75;
    final textColor = mine ? tokens.primaryForeground : tokens.ink;
    return Align(
      alignment: mine
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpace.xs),
          child: Column(
            crossAxisAlignment: mine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: mine ? tokens.jungle : tokens.card,
                  borderRadius: BorderRadius.circular(tokens.radiusXl),
                  border: mine ? null : Border.all(color: tokens.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.sm,
                    vertical: 10,
                  ),
                  child: Text(
                    _wrapWideWords(message.messageText),
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: textColor),
                  ),
                ),
              ),
              if (when.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                  child: Text(
                    when,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lets a long token wrap inside a bubble instead of painting past the edge.
String _wrapWideWords(String text) {
  final buffer = StringBuffer();
  var run = 0;
  for (final rune in text.runes) {
    final isGap =
        rune == 0x20 || rune == 0x0A || rune == 0x09 || rune == 0x200B;
    if (!isGap && run == 18) {
      buffer.writeCharCode(0x200B);
      run = 0;
    }
    buffer.writeCharCode(rune);
    run = isGap ? 0 : run + 1;
  }
  return buffer.toString();
}
