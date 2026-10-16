import 'package:flutter/material.dart';

import '../api/api_exception.dart';
import '../api/json_map.dart';
import '../models/learning_module.dart';
import '../session/session_scope.dart';
import '../widgets/learning_lesson_view.dart';
import '../widgets/shell_header.dart';
import '../widgets/learning_message.dart';

class LearningModuleScreen extends StatefulWidget {
  const LearningModuleScreen({super.key, required this.moduleId});

  final String moduleId;

  @override
  State<LearningModuleScreen> createState() => _LearningModuleScreenState();
}

class _LearningModuleScreenState extends State<LearningModuleScreen> {
  LearningModule? _module;
  LearningProgress? _progress;
  final _answers = <int, int>{};
  var _loading = true;
  String? _busy;
  String? _error;
  String? _notice;
  String? _quizNote;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) {
      return;
    }
    if (widget.moduleId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'This course is missing an id.';
      });
      return;
    }
    setState(() {
      _error = null;
      if (_module == null) {
        _loading = true;
      }
    });
    try {
      final api = SessionScope.of(context).api;
      final data = await api.get(
        '/api/v1/elearning/modules/${widget.moduleId}',
      );
      if (!mounted) {
        return;
      }
      final module = LearningModule.fromJson(asJsonMap(data['module']));
      String? notice;
      var progress = _progress;
      try {
        final progressData = await api.get('/api/v1/elearning/progress');
        if (!mounted) {
          return;
        }
        progress = LearningProgress.byModuleId(
          progressData['progress'],
        )[widget.moduleId];
      } on ApiException catch (e) {
        notice = e.message;
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _module = module;
        _progress = progress;
        _notice = notice;
        _quizNote = null;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        if (_module == null) {
          _error = e.message;
        } else {
          _notice = e.message;
        }
      });
    }
  }

  Future<void> _save(String status) async {
    if (_busy != null || widget.moduleId.isEmpty) {
      return;
    }
    setState(() {
      _busy = 'progress';
      _notice = null;
    });
    try {
      final body = <String, dynamic>{
        'module_id': widget.moduleId,
        'status': status,
      };
      if (status != 'completed') {
        body['read_pct'] = (_progress?.readPct ?? 0).clamp(0, 100);
      }
      final data = await SessionScope.of(context).api
          .post('/api/v1/elearning/progress', body: body);
      if (!mounted) {
        return;
      }
      final row = LearningProgress.fromJson(asJsonMap(data['progress']));
      setState(() {
        _progress = row;
        _busy = null;
      });
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = null;
        _notice = e.message;
      });
    }
  }

  Future<void> _submitQuiz() async {
    final module = _module;
    if (module == null || _busy != null) {
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
      _busy = 'quiz';
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
      final progressRaw = data['progress'];
      final progress = progressRaw == null
          ? _progress
          : LearningProgress.fromJson(asJsonMap(progressRaw));
      setState(() {
        _progress = progress;
        _busy = null;
        _quizNote = passed ? null : _quizRetryCopy(result);
      });
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = null;
        _quizNote = e.message;
      });
    }
  }

  void _answer(int question, int option) {
    setState(() {
      _answers[question] = option;
      _quizNote = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final module = _module;
    final error = _error;
    return Scaffold(
      appBar: ShellHeader(
        title: module?.displayTitle ?? 'Lesson',
        showBack: true,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        // Build the lesson only after the module exists. The previous page
        // evaluated module! while constructing this child, which threw on the
        // first frame before the GET returned.
        child: module == null
            ? LearningMessage(
                loading: _loading,
                title: _loading
                    ? 'Loading lesson'
                    : error != null
                    ? "This lesson didn't load"
                    : 'Lesson not found',
                message: _loading
                    ? null
                    : error ?? 'This course is not available.',
                error: !_loading && error != null,
                onRetry: _loading ? null : _load,
              )
            : LearningLessonView(
                module: module,
                progress: _progress,
                answers: _answers,
                progressBusy: _busy == 'progress',
                quizBusy: _busy == 'quiz',
                notice: _notice,
                quizNote: _quizNote,
                onAnswer: _answer,
                onSubmitQuiz: _submitQuiz,
                onMarkInProgress: () => _save('in_progress'),
                onMarkCompleted: () => _save('completed'),
              ),
      ),
    );
  }
}

String _quizRetryCopy(Map<String, dynamic> result) {
  final score = result['score'];
  final total = result['total'];
  if (score == null || total == null) {
    return 'Not quite. Read the lesson and try the quiz again.';
  }
  return 'Not quite. You scored $score of $total. Read the lesson and try again.';
}
