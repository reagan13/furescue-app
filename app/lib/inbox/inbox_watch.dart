import 'dart:async';

import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../models/inbox_notification.dart';

/// Polls unread notifications the same way the web does when the PHP
/// dev server cannot hold an EventSource connection.
class InboxWatch extends ChangeNotifier {
  InboxWatch({required this.api});

  final ApiClient api;

  static const interval = Duration(seconds: 30);

  int unread = 0;
  String? latestMessage;
  Timer? _timer;
  var _seen = false;

  void start() {
    _timer?.cancel();
    unawaited(poll());
    _timer = Timer.periodic(interval, (_) => unawaited(poll()));
  }

  Future<void> poll() async {
    try {
      final data = await api.get('/api/v1/notifications/unread-count');
      final count = data['count'];
      final next = count is num ? count.toInt() : int.tryParse('$count') ?? 0;
      String? message;
      if (_seen && next > unread) {
        final rows = await api.getList(
          '/api/v1/notifications?is_read=false&per_page=1',
        );
        if (rows.isNotEmpty) {
          message = InboxNotification.fromJson(rows.first).message;
        }
      }
      _seen = true;
      unread = next;
      latestMessage = message;
      notifyListeners();
    } on ApiException {
      // Badge stays at the last known count.
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class InboxScope extends InheritedNotifier<InboxWatch> {
  const InboxScope({
    super.key,
    required InboxWatch watch,
    required super.child,
  }) : super(notifier: watch);

  static InboxWatch? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<InboxScope>()?.notifier;
  }
}
