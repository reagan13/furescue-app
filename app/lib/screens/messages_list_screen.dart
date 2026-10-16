import 'package:flutter/material.dart';

import '../api/api_exception.dart';
import '../api/json_map.dart';
import '../format/display.dart';
import '../models/message_thread.dart';
import '../session/session_scope.dart';
import '../theme/tokens.dart';
import '../widgets/async_body.dart';
import '../widgets/shell_header.dart';
import 'message_compose_screen.dart';
import 'message_thread_screen.dart';

class MessagesListScreen extends StatefulWidget {
  const MessagesListScreen({super.key, this.showAppBar = true});

  /// False when a parent shell already shows the page title.
  final bool showAppBar;

  @override
  State<MessagesListScreen> createState() => _MessagesListScreenState();
}

class _MessagesListScreenState extends State<MessagesListScreen> {
  var _loading = true;
  String? _error;
  List<MessageThread> _items = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await SessionScope.of(context).api
          .get('/api/v1/messages/threads');
      if (!mounted) {
        return;
      }
      setState(() {
        _items = asJsonMapList(data['threads'])
            .map(MessageThread.fromJson)
            .toList();
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Scaffold(
      appBar: widget.showAppBar
          ? const ShellHeader(title: 'Messages', showBack: true)
          : null,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const MessageComposeScreen(),
            ),
          );
          if (mounted) {
            await _load();
          }
        },
        icon: const Icon(Icons.edit_outlined),
        label: const Text('New message'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: AsyncBody(
          loading: _loading,
          error: _error,
          isEmpty: _items.isEmpty,
          onRetry: _load,
          emptyMessage: 'No conversations yet. Tap New message to write City Vet about a report or adoption.',
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: _items.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              thickness: 1,
              indent: 72,
              color: tokens.border,
            ),
            itemBuilder: (context, i) {
              final item = _items[i];
              return _ConversationRow(
                thread: item,
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => MessageThreadScreen(thread: item),
                    ),
                  );
                  if (mounted) {
                    await _load();
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({required this.thread, required this.onTap});

  final MessageThread thread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final name = _personName(thread.otherUserName);
    final when = timeAgo(thread.lastSentAt);
    final preview = thread.lastMessage?.trim();
    final unread = thread.unreadCount > 0;
    final previewStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: unread ? tokens.ink : tokens.stamp,
      fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
    );

    return Material(
      color: tokens.paper,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.sm,
          ),
          child: Row(
            children: [
              _PersonMark(name: name),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (when.isNotEmpty) ...[
                          const SizedBox(width: AppSpace.xs),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 112),
                            child: Text(
                              when,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      thread.contextLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium
                          ?.copyWith(color: tokens.jungle),
                    ),
                    if (preview != null && preview.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              preview,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: previewStyle,
                            ),
                          ),
                          if (unread) ...[
                            const SizedBox(width: AppSpace.xs),
                            _UnreadCount(count: thread.unreadCount),
                          ],
                        ],
                      ),
                    ] else if (unread)
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: _UnreadCount(count: thread.unreadCount),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PersonMark extends StatelessWidget {
  const _PersonMark({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final initial = String.fromCharCode(name.runes.first).toUpperCase();
    return CircleAvatar(
      radius: 22,
      backgroundColor: tokens.jungle.withValues(alpha: 0.12),
      child: Text(
        initial,
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(color: tokens.jungle),
      ),
    );
  }
}

class _UnreadCount extends StatelessWidget {
  const _UnreadCount({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 48, minWidth: 22),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.jungle,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Text(
            '$count',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: tokens.primaryForeground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

String _personName(String? name) {
  final trimmed = name?.trim() ?? '';
  if (trimmed.isEmpty) {
    return 'Conversation';
  }
  return trimmed;
}
