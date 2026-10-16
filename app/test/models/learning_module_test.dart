import 'package:flutter_test/flutter_test.dart';
import 'package:furescue_app/models/learning_content.dart';
import 'package:furescue_app/models/learning_module.dart';

void main() {
  test('module json with null optional fields does not throw', () {
    final module = LearningModule.fromJson({
      'id': null,
      'title': null,
      'category': null,
      'content_body': null,
      'published_status': null,
      'has_quiz': null,
      'quiz': null,
    });
    expect(module.id, isEmpty);
    expect(module.displayTitle, 'Untitled course');
    expect(module.categoryLabel, 'Course');
    expect(module.contentBody, isNull);
    expect(module.quiz, isEmpty);
    expect(module.hasQuiz, isFalse);
  });

  test('quiz options skip null entries', () {
    final module = LearningModule.fromJson({
      'id': 'm1',
      'title': 'Street dogs',
      'category': 'dog_behavior',
      'quiz': [
        {'q': null, 'options': null},
        {
          'q': 'What first?',
          'options': ['Reach over', null, 'Let it sniff'],
        },
      ],
    });
    expect(module.quiz, hasLength(2));
    expect(module.quiz.first.question, isEmpty);
    expect(module.quiz.first.options, isEmpty);
    expect(module.quiz.last.options, ['Reach over', 'Let it sniff']);
  });

  test('progress json with null fields does not throw', () {
    final progress = LearningProgress.fromJson({
      'module_id': null,
      'status': null,
      'read_pct': null,
      'quiz_passed': null,
      'badge_earned': null,
    });
    expect(progress.moduleId, isEmpty);
    expect(progress.statusLabel, 'Not started');
    expect(progress.readPct, 0);
    expect(LearningProgress.byModuleId(null), isEmpty);
    expect(
      LearningProgress.byModuleId([
        {'module_id': null, 'status': 'completed'},
        {'module_id': 'm1', 'status': 'in_progress', 'read_pct': 40},
      ]).keys,
      ['m1'],
    );
  });

  test('html body becomes paragraphs and an excerpt', () {
    const body =
        '<p>Approach sideways &amp; let the dog sniff.</p><p>Wait for the sniff.</p>';
    expect(lessonParagraphs(null), isEmpty);
    expect(lessonParagraphs(''), isEmpty);
    expect(lessonParagraphs(body), [
      'Approach sideways & let the dog sniff.',
      'Wait for the sniff.',
    ]);
    expect(lessonExcerpt(body), 'Approach sideways & let the dog sniff.');
  });
}
