import 'package:flutter/material.dart';

import '../api/api_exception.dart';
import '../api/json_map.dart';
import '../models/message_thread.dart';
import '../session/session_scope.dart';
import '../theme/tokens.dart';
import '../widgets/app_card.dart';
import '../widgets/async_body.dart';
import 'message_compose_screen.dart';
import 'message_thread_screen.dart';

class MessagesListScreen extends StatefulWidget {
  const MessagesListScreen({super.key});

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
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            itemCount: _items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final item = _items[i];
              return AppCard(
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
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.otherUserName ?? 'Conversation',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.contextLabel,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          if (item.lastMessage != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              item.lastMessage!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (item.unreadCount > 0)
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: context.tokens.jungle,
                        child: Text(
                          '${item.unreadCount}',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: context.tokens.primaryForeground,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
