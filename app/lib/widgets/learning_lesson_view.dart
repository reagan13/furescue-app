import 'package:flutter/material.dart';

import '../models/learning_content.dart';
import '../models/learning_module.dart';
import '../theme/tokens.dart';
import 'learning_quiz_block.dart';
import 'learning_style.dart';

class LearningLessonView extends StatelessWidget {
  const LearningLessonView({
    super.key,
    required this.module,
    required this.progress,
    required this.answers,
    required this.progressBusy,
    required this.quizBusy,
    required this.onAnswer,
    required this.onSubmitQuiz,
    required this.onMarkInProgress,
    required this.onMarkCompleted,
    this.notice,
    this.quizNote,
  });

  final LearningModule module;
  final LearningProgress? progress;
  final Map<int, int> answers;
  final bool progressBusy;
  final bool quizBusy;
  final void Function(int question, int option) onAnswer;
  final VoidCallback onSubmitQuiz;
  final VoidCallback onMarkInProgress;
  final VoidCallback onMarkCompleted;
  final String? notice;
  final String? quizNote;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final row = progress;
    final paragraphs = lessonParagraphs(module.contentBody);
    final done = row?.isCompleted == true;
    final started = row?.isInProgress == true;
    final hasQuestions = module.quiz.isNotEmpty;
    final quizPassed = row?.quizPassed == true;
    final blockComplete = hasQuestions && !quizPassed;
    final note = notice;
    final accent = learningCategoryColor(tokens, module.category);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md,
        AppSpace.md,
        AppSpace.md,
        AppSpace.xl,
      ),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            LearningCategoryLabel(
              category: module.category,
              label: module.categoryLabel,
            ),
            LearningStatusPill(progress: row),
            if (module.isDraft)
              Text(
                'Draft',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: tokens.stamp,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        if (row != null && (started || done)) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: row.fraction,
              minHeight: 8,
              color: accent,
              backgroundColor: tokens.muted,
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          _courseStateLine(row),
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: tokens.mutedForeground),
        ),
        if (row != null && row.readPct > 0 && !done) ...[
          const SizedBox(height: 4),
          Text(
            '${row.readPct}% read',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: tokens.stamp),
          ),
        ],
        const Divider(),
        Text('Lesson', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        if (paragraphs.isEmpty)
          Text(
            'This lesson has no text yet.',
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: tokens.mutedForeground),
          )
        else
          for (var i = 0; i < paragraphs.length; i++) ...[
            Text(
              paragraphs[i],
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(height: 1.45),
            ),
            if (i != paragraphs.length - 1) const SizedBox(height: 12),
          ],
        if ((module.hasQuiz || hasQuestions) && quizPassed) ...[
          const SizedBox(height: 20),
          Text(
            'Quiz passed.',
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(color: tokens.jungle),
          ),
        ],
        if (hasQuestions && !quizPassed) ...[
          const SizedBox(height: 28),
          LearningQuizBlock(
            questions: module.quiz,
            answers: answers,
            saving: quizBusy,
            note: quizNote,
            onAnswer: onAnswer,
            onSubmit: onSubmitQuiz,
          ),
        ],
        if (module.hasQuiz && !hasQuestions && !quizPassed && !done) ...[
          const SizedBox(height: 16),
          Text(
            'This course has a quiz, but the questions were not included.',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: tokens.mutedForeground),
          ),
        ],
        if (note != null && note.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            note,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: tokens.destructive),
          ),
        ],
        const SizedBox(height: 20),
        if (!done && !started)
          OutlinedButton(
            onPressed: progressBusy || quizBusy ? null : onMarkInProgress,
            child: Text(progressBusy ? 'Saving…' : 'Mark in progress'),
          ),
        if (!done && !started) const SizedBox(height: 12),
        if (!done && !blockComplete)
          FilledButton(
            onPressed: progressBusy || quizBusy ? null : onMarkCompleted,
            child: Text(progressBusy ? 'Saving…' : 'Mark completed'),
          ),
        if (!done && blockComplete) ...[
          Text(
            'Pass the quiz to complete this course.',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: tokens.mutedForeground),
          ),
        ],
      ],
    );
  }
}

String _courseStateLine(LearningProgress? progress) {
  if (progress?.isCompleted == true) {
    return 'You completed this course.';
  }
  if (progress?.isInProgress == true) {
    return 'This course is in progress.';
  }
  return 'This course is not started.';
}
