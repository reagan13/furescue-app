import 'package:flutter/material.dart';

import '../api/api_exception.dart';
import '../api/json_map.dart';
import '../models/message_thread.dart';
import '../session/session_scope.dart';
import '../theme/tokens.dart';
import '../widgets/confirm_action.dart';
import '../widgets/shell_header.dart';
import 'message_thread_screen.dart';

class ComposeTopic {
  const ComposeTopic({
    required this.relatedType,
    required this.relatedId,
    required this.label,
  });

  final String relatedType;
  final String relatedId;
  final String label;
}

class MessageComposeScreen extends StatefulWidget {
  const MessageComposeScreen({super.key, this.relatedType, this.relatedId});

  final String? relatedType;
  final String? relatedId;

  @override
  State<MessageComposeScreen> createState() => _MessageComposeScreenState();
}

class _MessageComposeScreenState extends State<MessageComposeScreen> {
  final _text = TextEditingController();
  var _loading = true;
  var _sending = false;
  String? _error;
  String? _receiverId;
  String? _receiverName;
  List<ComposeTopic> _topics = const [];
  String? _selectedKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await SessionScope.of(context).api
          .get('/api/v1/messages/compose-targets');
      if (!mounted) {
        return;
      }
      final receiver = asJsonMap(data['receiver']);
      final topics = asJsonMapList(data['topics'])
          .map(
            (row) => ComposeTopic(
              relatedType: (row['related_type'] ?? '').toString(),
              relatedId: (row['related_id'] ?? '').toString(),
              label: (row['label'] ?? 'Topic').toString(),
            ),
          )
          .where((t) => t.relatedId.isNotEmpty)
          .toList();
      String? selectedKey;
      for (final topic in topics) {
        final key = '${topic.relatedType}|${topic.relatedId}';
        if (topic.relatedType == widget.relatedType &&
            topic.relatedId == widget.relatedId) {
          selectedKey = key;
          break;
        }
      }
      setState(() {
        _receiverId = (receiver['id'] ?? '').toString();
        _receiverName = asNullableString(receiver['full_name']) ?? 'City Vet';
        _topics = topics;
        _selectedKey =
            selectedKey ??
            (topics.isEmpty
                ? null
                : '${topics.first.relatedType}|${topics.first.relatedId}');
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

  Future<void> _send() async {
    ComposeTopic? topic;
    for (final item in _topics) {
      if ('${item.relatedType}|${item.relatedId}' == _selectedKey) {
        topic = item;
        break;
      }
    }
    final text = _text.text.trim();
    final receiverId = _receiverId;
    if (topic == null || receiverId == null || text.isEmpty) {
      setState(() => _error = 'Pick a topic and write a message.');
      return;
    }
    final ok = await confirmAction(
      context,
      title: 'Send this message?',
      message: 'This will start a conversation with $_receiverName.',
      confirmLabel: 'Send message',
    );
    if (!ok || !mounted) {
      return;
    }
    setState(() => _sending = true);
    try {
      await SessionScope.of(context).api.post(
        '/api/v1/messages',
        body: {
          'receiver_id': receiverId,
          'related_type': topic.relatedType,
          'related_id': topic.relatedId,
          'message_text': text,
        },
      );
      if (!mounted) {
        return;
      }
      final thread = MessageThread(
        relatedType: topic.relatedType,
        relatedId: topic.relatedId,
        otherUserId: receiverId,
        otherUserName: _receiverName,
        lastMessage: text,
      );
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => MessageThreadScreen(thread: thread),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _sending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ShellHeader(title: 'New message', showBack: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: [
                Text(
                  'Message $_receiverName about one of your reports or adoption applications.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                if (_topics.isEmpty)
                  Text(
                    'File a report or apply to adopt first — then you can message the team about it.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                else ...[
                  Text('About', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    key: ValueKey(_selectedKey),
                    initialValue: _selectedKey,
                    isExpanded: true,
                    items: [
                      for (final topic in _topics)
                        DropdownMenuItem(
                          value: '${topic.relatedType}|${topic.relatedId}',
                          child: Text(
                            topic.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: _sending
                        ? null
                        : (value) => setState(() => _selectedKey = value),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Message',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _text,
                    maxLines: 5,
                    maxLength: 4000,
                    enabled: !_sending,
                    decoration: const InputDecoration(
                      hintText: 'Write the first message…',
                    ),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: context.tokens.destructive),
                  ),
                ],
                if (_topics.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _sending ? null : _send,
                    child: Text(_sending ? 'Sending…' : 'Send'),
                  ),
                ],
              ],
            ),
    );
  }
}
