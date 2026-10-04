import 'package:flutter/material.dart';

import '../api/api_exception.dart';
import '../api/json_map.dart';
import '../models/report.dart';
import '../session/session_scope.dart';
import '../widgets/async_body.dart';
import '../widgets/photo_strip.dart';
import '../widgets/status_chip.dart';
import 'message_compose_screen.dart';

class ReportDetailScreen extends StatefulWidget {
  const ReportDetailScreen({super.key, required this.reportId});

  final String reportId;

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  Report? _report;
  var _loading = true;
  String? _error;

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
          .get('/api/v1/reports/${widget.reportId}');
      if (!mounted) {
        return;
      }
      setState(() {
        _report = Report.fromJson(asJsonMap(data['report']));
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
    final report = _report;
    return Scaffold(
      appBar: AppBar(title: const Text('Report')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: AsyncBody(
          loading: _loading,
          error: _error,
          isEmpty: report == null,
          onRetry: _load,
          emptyMessage: 'Report not found.',
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              StatusChip(label: report!.statusLabel, status: report.status),
              const SizedBox(height: 12),
              Text(
                report.animalDescription,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (report.addressText != null) ...[
                const SizedBox(height: 12),
                Text(
                  report.addressText!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              if (report.latitude != null && report.longitude != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${report.latitude!.toStringAsFixed(5)}, ${report.longitude!.toStringAsFixed(5)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (report.isFlaggedDuplicate) ...[
                const SizedBox(height: 12),
                Text(
                  'Flagged as a possible duplicate of a nearby report.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (report.photoUrls.isNotEmpty) ...[
                const SizedBox(height: 16),
                PhotoStrip(urls: report.photoUrls),
              ],
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => MessageComposeScreen(
                        relatedType: 'report',
                        relatedId: report.id,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Message City Vet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
