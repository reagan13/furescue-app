import 'package:flutter/material.dart';

import '../api/api_exception.dart';
import '../models/adoption.dart';
import '../session/session_scope.dart';
import '../theme/tokens.dart';
import '../widgets/app_card.dart';
import '../widgets/async_body.dart';
import '../widgets/confirm_action.dart';
import '../widgets/status_chip.dart';
import 'animal_detail_screen.dart';
import 'message_compose_screen.dart';

class AdoptionsListScreen extends StatefulWidget {
  const AdoptionsListScreen({super.key});

  @override
  State<AdoptionsListScreen> createState() => _AdoptionsListScreenState();
}

class _AdoptionsListScreenState extends State<AdoptionsListScreen> {
  var _loading = true;
  String? _error;
  List<Adoption> _items = const [];

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
          .getList('/api/v1/adoptions?per_page=50');
      if (!mounted) {
        return;
      }
      setState(() {
        _items = rows.map(Adoption.fromJson).toList();
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

  Future<void> _cancel(Adoption item) async {
    final ok = await confirmAction(
      context,
      title: 'Cancel this application?',
      message: 'Only pending applications can be cancelled.',
      confirmLabel: 'Cancel application',
      danger: true,
    );
    if (!ok || !mounted) {
      return;
    }
    try {
      await SessionScope.of(context).api
          .post('/api/v1/adoptions/${item.id}/cancel');
      if (mounted) {
        showSnack(context, 'Application cancelled.');
        await _load();
      }
    } on ApiException catch (e) {
      if (mounted) {
        showSnack(context, e.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My adoptions')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: AsyncBody(
          loading: _loading,
          error: _error,
          isEmpty: _items.isEmpty,
          onRetry: _load,
          emptyMessage: 'No applications yet. Apply from Browse when an animal is available.',
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            itemCount: _items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final item = _items[i];
              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusChip(label: item.statusLabel, status: item.status),
                    const SizedBox(height: 8),
                    Text(
                      item.animalName?.isNotEmpty == true
                          ? item.animalName!
                          : 'Adoption application',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (item.message != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.message!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    if (item.rejectionReason != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.rejectionReason!,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: context.tokens.destructive),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    AnimalDetailScreen(animalId: item.animalId),
                              ),
                            );
                          },
                          child: const Text('View animal'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => MessageComposeScreen(
                                  relatedType: 'adoption',
                                  relatedId: item.id,
                                ),
                              ),
                            );
                          },
                          child: const Text('Message'),
                        ),
                        if (item.canCancel)
                          TextButton(
                            onPressed: () => _cancel(item),
                            child: const Text('Cancel'),
                          ),
                      ],
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
