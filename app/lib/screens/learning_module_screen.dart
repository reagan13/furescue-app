import 'package:flutter/material.dart';

import '../api/api_exception.dart';
import '../api/json_map.dart';
import '../api/media.dart';
import '../models/learning_module.dart';
import '../session/session_scope.dart';
import '../theme/tokens.dart';
import '../widgets/async_body.dart';
import '../widgets/confirm_action.dart';

class LearningModuleScreen extends StatefulWidget {
  const LearningModuleScreen({super.key, required this.moduleId});

  final String moduleId;

  @override
  State<LearningModuleScreen> createState() => _LearningModuleScreenState();
}

class _LearningModuleScreenState extends State<LearningModuleScreen> {
  final _scroll = ScrollController();
  LearningModule? _module;
  LearningProgress? _progress;
  final _answers = <int, int>{};
  var _loading = true;
  var _saving = false;
  var _readPct = 0;
  var _lastSavedPct = 0;
  String? _error;
  String? _quizNote;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = SessionScope.of(context).api;
      final data = await api.get('/api/v1/elearning/modules/${widget.moduleId}');
      final progressData = await api.get('/api/v1/elearning/progress');
      if (!mounted) {
        return;
      }
      final rows = asJsonMapList(progressData['progress'])
          .map(LearningProgress.fromJson)
          .where((p) => p.moduleId == widget.moduleId);
      final progress = rows.isEmpty ? null : rows.first;
      final module = LearningModule.fromJson(asJsonMap(data['module']));
      if (progress == null) {
        await api.post(
          '/api/v1/elearning/progress',
          body: {'module_id': widget.moduleId, 'status': 'in_progress', 'read_pct': 0},
        );
      }
      setState(() {
        _module = module;
        _progress = progress;
        _readPct = progress?.isCompleted == true ? 100 : (progress?.readPct ?? 0);
        _lastSavedPct = _readPct;
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

  void _onScroll() {
    if (!_scroll.hasClients || _progress?.isCompleted == true) {
      return;
    }
    final max = _scroll.position.maxScrollExtent;
    final pct = max <= 0 ? 100 : ((_scroll.offset / max) * 100).round().clamp(0, 100);
    if (pct == _readPct) {
      return;
    }
    setState(() => _readPct = pct);
    if (pct >= _lastSavedPct + 10 || pct == 100) {
      _lastSavedPct = pct;
      SessionScope.of(context).api.post(
        '/api/v1/elearning/progress',
        body: {
          'module_id': widget.moduleId,
          'status': 'in_progress',
          'read_pct': pct,
        },
      ).then((_) {}, onError: (_) {});
    }
  }

  Future<void> _submitQuiz() async {
    final module = _module;
    if (module == null) {
      return;
    }
    if (module.quiz.asMap().keys.any((i) => !_answers.containsKey(i))) {
      setState(() => _quizNote = 'Answer every question first.');
      return;
    }
    final answers = [
      for (var i = 0; i < module.quiz.length; i++) _answers[i] ?? -1,
    ];
    setState(() {
      _saving = true;
      _quizNote = null;
    });
    try {
      final data = await SessionScope.of(context).api.post(
        '/api/v1/elearning/quiz',
        body: {'module_id': widget.moduleId, 'answers': answers},
      );
      if (!mounted) {
        return;
      }
      final result = asJsonMap(data['result']);
      final passed = asBool(result['passed']);
      setState(() {
        _progress = LearningProgress.fromJson(asJsonMap(data['progress']));
        _saving = false;
        if (passed) {
          _readPct = 100;
          _quizNote = null;
        } else {
          _quizNote =
              'Not quite. You scored ${result['score']}/${result['total']}. Read again and retry.';
        }
      });
      showSnack(
        context,
        passed ? 'Quiz passed — badge earned.' : _quizNote ?? 'Try again.',
      );
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _quizNote = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final module = _module;
    final done = _progress?.isCompleted == true;
    return Scaffold(
      appBar: AppBar(title: Text(module?.title ?? 'Module')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: AsyncBody(
          loading: _loading,
          error: _error,
          isEmpty: module == null,
          onRetry: _load,
          emptyMessage: 'Module not found.',
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            children: [
              LinearProgressIndicator(value: _readPct / 100),
              const SizedBox(height: 16),
              Text(
                module!.categoryLabel,
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              Text(
                module.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text(
                stripHtml(module.contentBody ?? 'No content yet.'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (done) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Icon(Icons.workspace_premium_outlined, color: context.tokens.jungle),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Badge earned — this lesson is complete.',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ] else if (module.quiz.isNotEmpty) ...[
                const SizedBox(height: 28),
                Text('Lesson quiz', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  'A perfect score completes the module and awards the badge.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < module.quiz.length; i++) ...[
                  Text(
                    module.quiz[i].question,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 6),
                  for (var o = 0; o < module.quiz[i].options.length; o++)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        _answers[i] == o
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                      ),
                      title: Text(module.quiz[i].options[o]),
                      onTap: _saving
                          ? null
                          : () => setState(() => _answers[i] = o),
                    ),
                  const SizedBox(height: 8),
                ],
                if (_quizNote != null)
                  Text(
                    _quizNote!,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: context.tokens.destructive),
                  ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _saving ? null : _submitQuiz,
                  child: Text(_saving ? 'Checking…' : 'Submit quiz'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
