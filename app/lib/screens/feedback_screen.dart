import 'package:flutter/material.dart';

import '../api/api_exception.dart';
import '../session/session_scope.dart';
import '../theme/tokens.dart';
import '../widgets/confirm_action.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _message = TextEditingController();
  var _sending = false;
  String? _error;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _message.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Please describe the problem.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await SessionScope.of(context).api.post(
        '/api/v1/feedback',
        body: {'message': text, 'page_url': 'mobile/account'},
      );
      if (!mounted) {
        return;
      }
      showSnack(context, 'Thanks — the team was notified.');
      Navigator.of(context).pop();
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
      appBar: AppBar(title: const Text('Report a problem')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          Text(
            'Tell City Vet what went wrong. They will see this in their notification inbox.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _message,
            maxLines: 6,
            maxLength: 2000,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'A short note about the bug or inconvenience.',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: context.tokens.destructive),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _sending ? null : _send,
            child: Text(_sending ? 'Sending…' : 'Send report'),
          ),
        ],
      ),
    );
  }
}
