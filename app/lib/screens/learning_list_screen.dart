import 'package:flutter/material.dart';

import '../api/api_exception.dart';
import '../models/learning_module.dart';
import '../session/session_scope.dart';
import '../theme/tokens.dart';
import '../widgets/learning_catalog_header.dart';
import '../widgets/learning_course_card.dart';
import '../widgets/learning_message.dart';
import 'learning_module_screen.dart';

class LearningListScreen extends StatefulWidget {
  const LearningListScreen({super.key});

  @override
  State<LearningListScreen> createState() => _LearningListScreenState();
}

class _LearningListScreenState extends State<LearningListScreen> {
  var _loading = true;
  String? _error;
  String? _notice;
  String? _category;
  List<LearningModule> _items = const [];
  Map<String, LearningProgress> _progress = const {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _error = null;
      _notice = null;
      if (_items.isEmpty) {
        _loading = true;
      }
    });
    try {
      final api = SessionScope.of(context).api;
      final rows = await api.getList('/api/v1/elearning/modules?per_page=50');
      if (!mounted) {
        return;
      }
      final items = [for (final row in rows) LearningModule.fromJson(row)];
      String? notice;
      var progress = _progress;
      try {
        final progressData = await api.get('/api/v1/elearning/progress');
        if (!mounted) {
          return;
        }
        progress = LearningProgress.byModuleId(progressData['progress']);
      } on ApiException catch (e) {
        notice = e.message;
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _items = items;
        _progress = progress;
        _notice = notice;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        if (_items.isEmpty) {
          _error = e.message;
        } else {
          _notice = e.message;
        }
      });
    }
  }

  Future<void> _open(LearningModule item) async {
    if (item.id.isEmpty || !mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LearningModuleScreen(moduleId: item.id),
      ),
    );
    if (mounted) {
      await _load();
    }
  }

  List<LearningSubjectFilter> _subjects() {
    final extras = <String>[];
    for (final item in _items) {
      if (item.category.isEmpty) {
        continue;
      }
      if (LearningModule.categoryOrder.contains(item.category)) {
        continue;
      }
      if (extras.contains(item.category)) {
        continue;
      }
      extras.add(item.category);
    }
    return [
      const LearningSubjectFilter(category: null, label: 'All'),
      for (final category in LearningModule.categoryOrder)
        LearningSubjectFilter(
          category: category,
          label: LearningModule.labelFor(category),
        ),
      for (final category in extras)
        LearningSubjectFilter(
          category: category,
          label: LearningModule.labelFor(category),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    final notice = _notice;
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading && _items.isEmpty
            ? const LearningMessage(loading: true, title: 'Loading courses')
            : error != null && _items.isEmpty
            ? LearningMessage(
                title: "Courses didn't load",
                message: error,
                error: true,
                onRetry: _load,
              )
            : _items.isEmpty
            ? LearningMessage(
                title: notice == null
                    ? 'No published courses yet'
                    : "Courses didn't load",
                message:
                    notice ??
                    'Lessons show up here after an admin publishes them.',
                error: notice != null,
                onRetry: notice == null ? null : _load,
              )
            : _catalog(),
      ),
    );
  }

  Widget _catalog() {
    final visible = [
      for (final item in _items)
        if (_category == null || item.category == _category) item,
    ];
    final inProgress = _items
        .where((item) => _progress[item.id]?.isInProgress == true)
        .length;
    final completed = _items
        .where((item) => _progress[item.id]?.isCompleted == true)
        .length;
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md,
        AppSpace.sm,
        AppSpace.md,
        AppSpace.xl,
      ),
      itemCount: 1 + (visible.isEmpty ? 1 : visible.length),
      separatorBuilder: (_, _) => const SizedBox(height: AppSpace.sm),
      itemBuilder: (context, index) {
        if (index == 0) {
          return LearningCatalogHeader(
            total: _items.length,
            inProgress: inProgress,
            completed: completed,
            subjects: _subjects(),
            selected: _category,
            notice: _notice,
            onSelected: (value) => setState(() => _category = value),
          );
        }
        if (visible.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.lg),
            child: Text(
              'No courses in ${LearningModule.labelFor(_category ?? '')}.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }
        final item = visible[index - 1];
        return LearningCourseCard(
          module: item,
          progress: _progress[item.id],
          onTap: item.id.isEmpty ? null : () => _open(item),
        );
      },
    );
  }
}
