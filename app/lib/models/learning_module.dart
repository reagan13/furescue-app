import '../api/json_map.dart';

class LearningQuizQuestion {
  const LearningQuizQuestion({required this.question, required this.options});

  final String question;
  final List<String> options;

  factory LearningQuizQuestion.fromJson(Map<String, dynamic> json) {
    final options = json['options'];
    return LearningQuizQuestion(
      question: (json['q'] ?? '').toString(),
      options: options is List
          ? [
              for (final item in options)
                if (item != null && item.toString().trim().isNotEmpty)
                  item.toString(),
            ]
          : const [],
    );
  }
}

class LearningModule {
  const LearningModule({
    required this.id,
    required this.title,
    required this.category,
    this.contentBody,
    this.publishedStatus,
    this.hasQuiz = false,
    this.quiz = const [],
  });

  /// API `category` values, in catalog order.
  static const categoryOrder = [
    'dog_behavior',
    'cat_behavior',
    'basic_training',
    'general_care',
  ];

  final String id;
  final String title;
  final String category;
  final String? contentBody;
  final String? publishedStatus;
  final bool hasQuiz;
  final List<LearningQuizQuestion> quiz;

  String get displayTitle {
    final trimmed = title.trim();
    return trimmed.isEmpty ? 'Untitled course' : trimmed;
  }

  bool get isDraft => publishedStatus == 'draft';

  String get categoryLabel => labelFor(category);

  static String labelFor(String category) {
    switch (category) {
      case 'dog_behavior':
        return 'Dog behavior';
      case 'cat_behavior':
        return 'Cat behavior';
      case 'basic_training':
        return 'Basic training';
      case 'general_care':
        return 'General care';
      default:
        final trimmed = category.trim();
        return trimmed.isEmpty ? 'Course' : trimmed;
    }
  }

  factory LearningModule.fromJson(Map<String, dynamic> json) {
    return LearningModule(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      contentBody: asNullableString(json['content_body']),
      publishedStatus: asNullableString(json['published_status']),
      hasQuiz: asBool(json['has_quiz']),
      quiz: asJsonMapList(json['quiz'])
          .map(LearningQuizQuestion.fromJson)
          .toList(),
    );
  }
}

class LearningProgress {
  const LearningProgress({
    required this.moduleId,
    required this.status,
    this.readPct = 0,
    this.quizPassed = false,
    this.badgeEarned = false,
  });

  final String moduleId;
  final String status;
  final int readPct;
  final bool quizPassed;
  final bool badgeEarned;

  bool get isCompleted => status == 'completed' || badgeEarned;

  bool get isInProgress => status == 'in_progress' && !isCompleted;

  /// 0–1 for a course progress bar. Completed fills the bar.
  double get fraction {
    if (isCompleted) {
      return 1;
    }
    final pct = readPct.clamp(0, 100);
    return pct / 100;
  }

  String get statusLabel {
    if (isCompleted) {
      return 'Completed';
    }
    if (isInProgress) {
      return 'In progress';
    }
    if (status == 'not_started' || status.isEmpty) {
      return 'Not started';
    }
    return status.replaceAll('_', ' ');
  }

  factory LearningProgress.fromJson(Map<String, dynamic> json) {
    return LearningProgress(
      moduleId: (json['module_id'] ?? '').toString(),
      status: (json['status'] ?? 'not_started').toString(),
      readPct: asInt(json['read_pct']).clamp(0, 100),
      quizPassed: asBool(json['quiz_passed']),
      badgeEarned: asBool(json['badge_earned']),
    );
  }

  /// Progress rows keyed by module id. Rows missing an id are skipped.
  static Map<String, LearningProgress> byModuleId(Object? value) {
    final map = <String, LearningProgress>{};
    for (final row in asJsonMapList(value)) {
      final parsed = LearningProgress.fromJson(row);
      if (parsed.moduleId.isEmpty) {
        continue;
      }
      map[parsed.moduleId] = parsed;
    }
    return map;
  }
}
