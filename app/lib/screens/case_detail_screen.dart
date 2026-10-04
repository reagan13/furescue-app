import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../api/api_exception.dart';
import '../api/json_map.dart';
import '../models/report.dart';
import '../models/rescue_case.dart';
import '../session/session_scope.dart';
import '../theme/tokens.dart';
import '../widgets/case_action_bar.dart';
import '../widgets/case_detail_view.dart';
import '../widgets/confirm_action.dart';

class CaseDetailScreen extends StatefulWidget {
  const CaseDetailScreen({super.key, required this.caseId});

  final String caseId;

  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen> {
  RescueCase? _item;
  List<CaseActivity> _activity = const [];
  var _loading = true;
  var _busy = false;
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
      final api = SessionScope.of(context).api;
      final data = await api.get('/api/v1/cases/${widget.caseId}');
      var item = RescueCase.fromJson(asJsonMap(data['case']));
      var note = '';
      if (item.reportId != null &&
          (item.animalDescription == null || item.reportPhotos.isEmpty)) {
        try {
          final reportData = await api.get('/api/v1/reports/${item.reportId}');
          final report = Report.fromJson(asJsonMap(reportData['report']));
          item = item.mergeReport(
            animalDescription: report.animalDescription,
            addressText: report.addressText,
            photos: report.photoUrls,
          );
        } catch (_) {
          note = 'Could not load the report.';
        }
      }
      List<CaseActivity> activity = const [];
      try {
        final log = await api.get('/api/v1/cases/${widget.caseId}/activity');
        activity = asJsonMapList(log['activity'])
            .map(CaseActivity.fromJson)
            .toList();
      } catch (_) {
        note = note.isEmpty
            ? 'Could not load activity.'
            : 'Could not load the report or activity.';
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _item = item;
        _activity = activity;
        _loading = false;
      });
      if (note.isNotEmpty) {
        showSnack(context, note);
      }
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

  Future<void> _respond(String action) async {
    final accept = action == 'accept';
    final ok = await confirmAction(
      context,
      title: accept ? 'Accept this case?' : 'Decline this case?',
      message: accept
          ? 'This will accept the rescue case and mark it in progress.'
          : 'This will decline the rescue case so another rescuer can take it.',
      confirmLabel: accept ? 'Accept case' : 'Decline case',
      danger: !accept,
    );
    if (!ok || !mounted) {
      return;
    }
    setState(() => _busy = true);
    try {
      await SessionScope.of(context).api
          .post('/api/v1/cases/${widget.caseId}/$action');
      if (!mounted) {
        return;
      }
      showSnack(context, accept ? 'Case accepted.' : 'Case declined.');
      if (!accept) {
        Navigator.of(context).pop();
        return;
      }
      await _load();
    } on ApiException catch (e) {
      if (mounted) {
        showSnack(context, e.message);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _proof() async {
    final files = await ImagePicker().pickMultiImage(imageQuality: 85);
    if (files.isEmpty || !mounted) {
      return;
    }
    if (files.length > 10) {
      showSnack(context, 'Up to 10 proof photos at a time.');
      return;
    }
    final ok = await confirmAction(
      context,
      title: 'Upload proof?',
      message: 'Attach ${files.length} photo(s) to this case.',
      confirmLabel: 'Upload',
    );
    if (!ok || !mounted) {
      return;
    }
    setState(() => _busy = true);
    try {
      await SessionScope.of(context).api.postMultipart(
        '/api/v1/cases/${widget.caseId}/proof',
        fieldName: 'files[]',
        filePaths: files.map((f) => f.path).toList(),
      );
      if (mounted) {
        showSnack(
          context,
          'Proof uploaded. City Vet resolves the case on the web console.',
        );
        await _load();
      }
    } on ApiException catch (e) {
      if (mounted) {
        showSnack(context, e.message);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final item = _item;
    final overlay = item == null
        ? tokens.systemUi
        : SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: tokens.paper,
            systemNavigationBarIconBrightness: Brightness.dark,
          );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: Scaffold(
        backgroundColor: tokens.paper,
        appBar: item == null ? AppBar(title: const Text('Case')) : null,
        body: RefreshIndicator(
          color: tokens.jungle,
          onRefresh: _load,
          child: item == null
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.only(top: 80),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_error != null)
                      Text(
                        _error!,
                        style: TextStyle(color: tokens.destructive),
                      ),
                  ],
                )
              : CaseDetailView(
                  item: item,
                  activity: _activity,
                  busy: _busy,
                  onAccept: () => _respond('accept'),
                  onDecline: () => _respond('decline'),
                  onProof: _proof,
                ),
        ),
        bottomNavigationBar: item == null
            ? null
            : CaseActionBar(
                item: item,
                busy: _busy,
                onAccept: () => _respond('accept'),
                onDecline: () => _respond('decline'),
                onProof: _proof,
              ),
      ),
    );
  }
}
