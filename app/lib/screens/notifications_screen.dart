import 'package:flutter/material.dart';

import '../api/api_exception.dart';
import '../models/inbox_notification.dart';
import '../session/session_scope.dart';
import '../theme/tokens.dart';
import '../widgets/app_card.dart';
import '../widgets/async_body.dart';
import '../widgets/confirm_action.dart';
import '../widgets/shell_header.dart';
import 'adoptions_list_screen.dart';
import 'case_detail_screen.dart';
import 'listings_list_screen.dart';
import 'report_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  var _loading = true;
  String? _error;
  List<InboxNotification> _items = const [];

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
      final rows = await SessionScope.of(context).api
          .getList('/api/v1/notifications?per_page=50');
      if (!mounted) {
        return;
      }
      setState(() {
        _items = rows.map(InboxNotification.fromJson).toList();
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

  Future<void> _markAll() async {
    try {
      await SessionScope.of(context).api.post('/api/v1/notifications/read-all');
      await _load();
    } on ApiException catch (e) {
      if (mounted) {
        showSnack(context, e.message);
      }
    }
  }

  Future<void> _open(InboxNotification item) async {
    if (!item.isRead) {
      try {
        await SessionScope.of(context).api
            .patch('/api/v1/notifications/${item.id}/read');
      } catch (_) {
        if (mounted) {
          showSnack(context, 'Could not mark this notification as read.');
        }
      }
    }
    if (!mounted) {
      return;
    }
    final page = _pageFor(item);
    if (page != null) {
      await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
    }
    if (mounted) await _load();
  }

  Widget? _pageFor(InboxNotification item) {
    final id = item.relatedId;
    if (id == null || id.isEmpty) return null;
    final role = SessionScope.of(context).user?.role;
    switch (item.relatedType) {
      case 'case':
        if (role != 'rescuer') return null;
        return CaseDetailScreen(caseId: id);
      case 'report':
        return ReportDetailScreen(reportId: id);
      case 'adoption':
        return AdoptionsListScreen(focusId: id);
      case 'listing':
      case 'adoption_listing':
        return ListingsListScreen(focusId: id);
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _items.any((n) => !n.isRead);
    return Scaffold(
      appBar: const ShellHeader(title: 'Notifications', showBack: true),
      body: RefreshIndicator(
        onRefresh: _load,
        child: AsyncBody(
          loading: _loading,
          error: _error,
          isEmpty: _items.isEmpty,
          onRetry: _load,
          emptyMessage: 'No notifications yet.',
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            itemCount: _items.length + (hasUnread ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              if (hasUnread && i == 0) {
                return Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _markAll,
                    child: const Text('Read all'),
                  ),
                );
              }
              final item = _items[hasUnread ? i - 1 : i];
              return AppCard(
                onTap: () => _open(item),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.isRead ? 'Read' : 'Unread',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: item.isRead
                            ? context.tokens.stamp
                            : context.tokens.jungle,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.message,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.kindLabel,
                      style: Theme.of(context).textTheme.bodySmall,
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
