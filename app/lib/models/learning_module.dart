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
          ? options.map((item) => item.toString()).toList()
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

  final String id;
  final String title;
  final String category;
  final String? contentBody;
  final String? publishedStatus;
  final bool hasQuiz;
  final List<LearningQuizQuestion> quiz;

  String get categoryLabel {
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
        return category;
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
      quiz: asJsonMapList(json['quiz']).map(LearningQuizQuestion.fromJson).toList(),
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
  bool get isInProgress => status == 'in_progress';

  String get statusLabel {
    if (badgeEarned || status == 'completed') {
      return 'Badge';
    }
    switch (status) {
      case 'in_progress':
        return 'In progress';
      case 'not_started':
        return 'Not started';
      default:
        return status;
    }
  }

  factory LearningProgress.fromJson(Map<String, dynamic> json) {
    return LearningProgress(
      moduleId: (json['module_id'] ?? '').toString(),
      status: (json['status'] ?? 'not_started').toString(),
      readPct: asInt(json['read_pct']),
      quizPassed: asBool(json['quiz_passed']),
      badgeEarned: asBool(json['badge_earned']),
    );
  }
}
