import 'package:flutter/material.dart';

import '../api/api_exception.dart';
import '../api/json_map.dart';
import '../models/message_thread.dart';
import '../session/session_scope.dart';
import '../theme/tokens.dart';
import '../widgets/async_body.dart';
import '../widgets/confirm_action.dart';

class MessageThreadScreen extends StatefulWidget {
  const MessageThreadScreen({super.key, required this.thread});

  final MessageThread thread;

  @override
  State<MessageThreadScreen> createState() => _MessageThreadScreenState();
}

class _MessageThreadScreenState extends State<MessageThreadScreen> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  List<ChatMessage> _items = const [];
  var _loading = true;
  var _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = SessionScope.of(context);
      final type = Uri.encodeQueryComponent(widget.thread.relatedType);
      final id = Uri.encodeQueryComponent(widget.thread.relatedId);
      final data = await session.api.get(
        '/api/v1/messages?related_type=$type&related_id=$id',
      );
      if (!mounted) {
        return;
      }
      final items = asJsonMapList(data['messages'])
          .map(ChatMessage.fromJson)
          .toList();
      final me = session.user?.id;
      var readFailed = false;
      for (final msg in items) {
        if (me != null && msg.receiverId == me && msg.readAt == null) {
          try {
            await session.api.patch('/api/v1/messages/${msg.id}/read');
          } catch (_) {
            readFailed = true;
          }
        }
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _items = items;
        _loading = false;
      });
      if (readFailed) {
        showSnack(context, 'Could not mark messages as read.');
      }
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

  Future<void> _send() async {
    final text = _text.text.trim();
    if (text.isEmpty) {
      return;
    }
    setState(() => _sending = true);
    try {
      await SessionScope.of(context).api.post(
        '/api/v1/messages',
        body: {
          'receiver_id': widget.thread.otherUserId,
          'related_type': widget.thread.relatedType,
          'related_id': widget.thread.relatedId,
          'message_text': text,
        },
      );
      _text.clear();
      await _load();
    } on ApiException catch (e) {
      if (mounted) {
        showSnack(context, e.message);
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = SessionScope.of(context).user?.id;
    final tokens = context.tokens;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.thread.otherUserName ?? widget.thread.contextLabel),
      ),
      body: Column(
        children: [
          Expanded(
            child: AsyncBody(
              loading: _loading,
              error: _error,
              isEmpty: _items.isEmpty,
              onRetry: _load,
              emptyMessage: 'No messages yet. Write the first one.',
              child: ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    itemCount: _items.length,
                    itemBuilder: (context, i) {
                      final msg = _items[i];
                      final mine = msg.senderId == me;
                      return Align(
                        alignment: mine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          constraints: const BoxConstraints(maxWidth: 320),
                          decoration: BoxDecoration(
                            color: mine ? tokens.jungle : tokens.card,
                            borderRadius: BorderRadius.circular(tokens.radius),
                            border: mine
                                ? null
                                : Border.all(color: tokens.border),
                          ),
                          child: Text(
                            msg.messageText,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: mine
                                      ? tokens.primaryForeground
                                      : tokens.ink,
                                ),
                          ),
                        ),
                      );
                    },
                  ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _text,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sending ? null : _send(),
                      decoration: const InputDecoration(
                        hintText: 'Write a message',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
