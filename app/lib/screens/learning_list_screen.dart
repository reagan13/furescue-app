import 'package:flutter/material.dart';

import '../api/api_exception.dart';
import '../api/json_map.dart';
import '../models/learning_module.dart';
import '../session/session_scope.dart';
import '../widgets/app_card.dart';
import '../widgets/async_body.dart';
import '../widgets/status_chip.dart';
import 'learning_module_screen.dart';

class LearningListScreen extends StatefulWidget {
  const LearningListScreen({super.key});

  @override
  State<LearningListScreen> createState() => _LearningListScreenState();
}

class _LearningListScreenState extends State<LearningListScreen> {
  var _loading = true;
  String? _error;
  List<LearningModule> _items = const [];
  Map<String, LearningProgress> _progress = const {};

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
      final api = SessionScope.of(context).api;
      final rows = await api.getList('/api/v1/elearning/modules?per_page=50');
      final progressData = await api.get('/api/v1/elearning/progress');
      if (!mounted) {
        return;
      }
      final progressRows = asJsonMapList(progressData['progress']);
      setState(() {
        _items = rows.map(LearningModule.fromJson).toList();
        _progress = {
          for (final row in progressRows)
            LearningProgress.fromJson(row).moduleId: LearningProgress.fromJson(
              row,
            ),
        };
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
      appBar: AppBar(title: const Text('Learn')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: AsyncBody(
          loading: _loading,
          error: _error,
          isEmpty: _items.isEmpty,
          onRetry: _load,
          emptyMessage: 'No published modules yet.',
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            itemCount: _items.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              if (i == 0) {
                final total = _items.length;
                final badges = _items.where((m) => _progress[m.id]?.isCompleted == true).length;
                final reading = _items.fold<int>(0, (sum, m) {
                  final row = _progress[m.id];
                  if (row == null) {
                    return sum;
                  }
                  return sum + (row.isCompleted ? 100 : row.readPct);
                });
                final pct = total == 0 ? 0.0 : reading / (total * 100);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$badges of $total badges',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: pct),
                    const SizedBox(height: 8),
                    Text(
                      'The bar fills as you read. A badge is awarded after the end-of-lesson quiz.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                );
              }
              final item = _items[i - 1];
              final progress = _progress[item.id];
              return AppCard(
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => LearningModuleScreen(moduleId: item.id),
                    ),
                  );
                  if (mounted) {
                    await _load();
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusChip(
                      label: progress?.statusLabel ?? 'Not started',
                      status: progress?.status ?? 'not_started',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.categoryLabel,
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
