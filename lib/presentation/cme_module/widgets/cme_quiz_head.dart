import 'package:doctak_app/data/models/cme/cme_quiz_model.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

class CmeQuizHead extends StatelessWidget {
  const CmeQuizHead({
    super.key,
    required this.quiz,
    this.description,
  });

  final CmeQuizData quiz;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final questions = quiz.questions?.length ?? 0;
    final attemptsUsed = quiz.myAttempts?.length ?? quiz.attemptsUsed ?? 0;
    final maxAttempts = quiz.maxAttempts ?? 0;
    final attemptsLabel = maxAttempts >= 999
        ? '∞'
        : '${(maxAttempts - attemptsUsed).clamp(0, maxAttempts)}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.fact_check_outlined, color: theme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quiz.title ?? 'Post-activity assessment',
                      style: theme.titleSmall,
                    ),
                    if ((description ?? quiz.description)?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        description ?? quiz.description!,
                        style: theme.bodySecondary,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _stat(theme, '$questions', 'Questions'),
              _stat(theme, '${quiz.passingScore ?? 70}%', 'To pass'),
              _stat(theme, attemptsLabel, 'Attempts'),
              if (quiz.hasTimeLimit)
                _stat(theme, '${quiz.timeLimit}m', 'Time limit'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(OneUITheme theme, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: theme.textPrimary,
            ),
          ),
          Text(label, style: theme.caption, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
