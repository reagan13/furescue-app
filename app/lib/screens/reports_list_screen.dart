import 'package:flutter/material.dart';

import '../api/api_exception.dart';
import '../models/report.dart';
import '../session/session_scope.dart';
import '../widgets/app_card.dart';
import '../widgets/async_body.dart';
import '../widgets/status_chip.dart';
import 'report_detail_screen.dart';

class ReportsListScreen extends StatefulWidget {
  const ReportsListScreen({super.key});

  @override
  State<ReportsListScreen> createState() => _ReportsListScreenState();
}

class _ReportsListScreenState extends State<ReportsListScreen> {
  var _loading = true;
  String? _error;
  List<Report> _items = const [];

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
          .getList('/api/v1/reports/me?per_page=50');
      if (!mounted) {
        return;
      }
      setState(() {
        _items = rows.map(Report.fromJson).toList();
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
      appBar: AppBar(title: const Text('My reports')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: AsyncBody(
          loading: _loading,
          error: _error,
          isEmpty: _items.isEmpty,
          onRetry: _load,
          emptyMessage: 'No reports yet. Use the Report tab to pin an animal in Mati City.',
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            itemCount: _items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final report = _items[i];
              return AppCard(
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ReportDetailScreen(reportId: report.id),
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
                      label: report.statusLabel,
                      status: report.status,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      report.animalDescription,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    if (report.addressText != null &&
                        report.addressText!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        report.addressText!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
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
