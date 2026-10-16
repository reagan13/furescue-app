import 'package:flutter/material.dart';

import '../api/api_exception.dart';
import '../format/display.dart';
import '../models/adoption.dart';
import '../session/session_scope.dart';
import '../theme/tokens.dart';
import '../widgets/async_body.dart';
import '../widgets/confirm_action.dart';
import '../widgets/empty_prompt.dart';
import '../widgets/scan_card.dart';
import '../widgets/shell_header.dart';
import 'animal_detail_screen.dart';
import 'animals_list_screen.dart';
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

  void _browse() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AnimalsListScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ShellHeader(title: 'My adoptions', showBack: true),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Text(
              'Track the applications you have submitted.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: AsyncBody(
                loading: _loading,
                error: _error,
                isEmpty: _items.isEmpty,
                onRetry: _load,
                emptyMessage:
                    'No applications here yet. Browse animals to apply.',
                emptyChild: EmptyPrompt(
                  title: 'No applications here yet',
                  message: 'When you apply to adopt an animal, it will show up in this list.',
                  actionLabel: 'Browse animals',
                  onAction: _browse,
                ),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  itemCount: _items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _AdoptionCard(
                    item: _items[i],
                    onCancel: () => _cancel(_items[i]),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdoptionCard extends StatelessWidget {
  const _AdoptionCard({required this.item, required this.onCancel});

  final Adoption item;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final name = item.animalName?.trim();
    final title = name == null || name.isEmpty ? 'An animal' : name;
    final when = timeAgo(item.createdAt);
    final note = item.message?.trim();
    final reason = item.rejectionReason?.trim();

    return ScanCard(
      photoPath: item.photoPath,
      title: title,
      subtitle: when.isEmpty ? null : 'Applied $when',
      statusLabel: item.statusLabel,
      status: item.status,
      children: [
        if (note != null && note.isNotEmpty)
          Text(
            '“$note”',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        if (item.status == 'rejected' && reason != null && reason.isNotEmpty)
          Text(
            'Reason: $reason',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: tokens.destructive),
          ),
        if (item.status == 'approved')
          Text(
            'The shelter will contact you about next steps.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: tokens.jungle, fontWeight: FontWeight.w700),
          ),
        Wrap(
          spacing: 4,
          runSpacing: 0,
          children: [
            TextButton(
              onPressed: () {
                final animalId = item.animalId.trim();
                if (animalId.isEmpty) {
                  showSnack(
                    context,
                    'This application is not linked to an animal.',
                  );
                  return;
                }
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => AnimalDetailScreen(animalId: animalId),
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
              TextButton(onPressed: onCancel, child: const Text('Cancel')),
          ],
        ),
      ],
    );
  }
}
