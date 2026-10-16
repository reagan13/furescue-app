import 'package:flutter/material.dart';

import '../models/learning_module.dart';
import '../theme/tokens.dart';

class LearningQuizBlock extends StatelessWidget {
  const LearningQuizBlock({
    super.key,
    required this.questions,
    required this.answers,
    required this.saving,
    required this.onAnswer,
    required this.onSubmit,
    this.note,
  });

  final List<LearningQuizQuestion> questions;
  final Map<int, int> answers;
  final bool saving;
  final void Function(int question, int option) onAnswer;
  final VoidCallback onSubmit;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final quizNote = note;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quiz', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(
          'A perfect score completes this course.',
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: tokens.mutedForeground),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < questions.length; i++) ...[
          Text(
            questions[i].question.trim().isEmpty
                ? 'Question'
                : questions[i].question.trim(),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          for (var o = 0; o < questions[i].options.length; o++)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                answers[i] == o
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: answers[i] == o ? tokens.jungle : tokens.stamp,
              ),
              title: Text(questions[i].options[o]),
              onTap: saving ? null : () => onAnswer(i, o),
            ),
          const SizedBox(height: 8),
        ],
        if (quizNote != null && quizNote.isNotEmpty) ...[
          Text(
            quizNote,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: tokens.destructive),
          ),
          const SizedBox(height: 8),
        ],
        FilledButton(
          onPressed: saving ? null : onSubmit,
          child: Text(saving ? 'Saving…' : 'Submit quiz'),
        ),
      ],
    );
  }
}
