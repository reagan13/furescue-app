import 'package:flutter/material.dart';

import '../api/api_exception.dart';
import '../format/display.dart';
import '../models/rescue_case.dart';
import '../session/session_scope.dart';
import '../widgets/async_body.dart';
import '../widgets/confirm_action.dart';
import '../widgets/scan_card.dart';
import 'case_detail_screen.dart';

class CasesListScreen extends StatefulWidget {
  const CasesListScreen({super.key});

  @override
  State<CasesListScreen> createState() => _CasesListScreenState();
}

class _CasesListScreenState extends State<CasesListScreen> {
  var _loading = true;
  String? _error;
  List<RescueCase> _items = const [];

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
          .getList('/api/v1/cases?per_page=50');
      if (!mounted) {
        return;
      }
      setState(() {
        _items = rows.map(RescueCase.fromJson).toList();
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

  Future<void> _toggleDuty() async {
    final session = SessionScope.of(context);
    final goingOn = !session.isOnDuty;
    final ok = await confirmAction(
      context,
      title: goingOn ? 'Go on duty?' : 'Go off duty?',
      message: goingOn
          ? 'This will update your rescuer duty status to on duty.'
          : 'This will update your rescuer duty status to off duty.',
      confirmLabel: goingOn ? 'Go on duty' : 'Go off duty',
    );
    if (!ok || !mounted) {
      return;
    }
    try {
      await session.setDuty(goingOn ? 'on_duty' : 'off_duty');
    } on ApiException catch (e) {
      if (mounted) {
        showSnack(context, e.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Cases assigned to you.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                TextButton(
                  onPressed: _toggleDuty,
                  child: Text(session.isOnDuty ? 'On duty' : 'Off duty'),
                ),
              ],
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
                    'No cases assigned yet. Go on duty so City Vet can assign you.',
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  itemCount: _items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final item = _items[i];
                    return _CaseCard(
                      item: item,
                      onOpen: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => CaseDetailScreen(caseId: item.id),
                          ),
                        );
                        if (mounted) {
                          await _load();
                        }
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CaseCard extends StatelessWidget {
  const _CaseCard({required this.item, required this.onOpen});

  final RescueCase item;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final description = item.animalDescription?.trim();
    final place = item.addressText?.trim();
    final when = timeAgo(item.createdAt);
    final meta = <String>[
      if (place != null && place.isNotEmpty) place,
      if (when.isNotEmpty) when,
    ].join(' · ');
    final photo = item.reportPhotos.isEmpty ? null : item.reportPhotos.first;

    return ScanCard(
      photoPath: photo,
      title: description == null || description.isEmpty
          ? 'Rescue case'
          : description,
      titleMaxLines: 3,
      subtitle: meta.isEmpty ? null : meta,
      statusLabel: item.statusLabel,
      status: item.status,
      onTap: onOpen,
    );
  }
}
