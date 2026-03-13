import 'package:doctak_app/data/models/cme/cme_quiz_model.dart';
import 'package:doctak_app/presentation/cme_module/bloc/cme_quiz_bloc.dart';
import 'package:doctak_app/presentation/cme_module/bloc/cme_quiz_event.dart';
import 'package:doctak_app/presentation/cme_module/bloc/cme_quiz_state.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CmeQuizScreen extends StatelessWidget {
  final String eventId;
  final String moduleId;
  final String quizId;
  final String? quizTitle;

  const CmeQuizScreen({
    super.key,
    required this.eventId,
    required this.moduleId,
    required this.quizId,
    this.quizTitle,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CmeQuizBloc()
        ..add(CmeLoadQuizEvent(
            eventId: eventId, moduleId: moduleId, quizId: quizId)),
      child: _CmeQuizView(
        eventId: eventId,
        moduleId: moduleId,
        quizId: quizId,
        quizTitle: quizTitle,
      ),
    );
  }
}

class _CmeQuizView extends StatelessWidget {
  final String eventId;
  final String moduleId;
  final String quizId;
  final String? quizTitle;

  const _CmeQuizView({
    required this.eventId,
    required this.moduleId,
    required this.quizId,
    this.quizTitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: _buildAppBar(context, theme),
      body: BlocConsumer<CmeQuizBloc, CmeQuizState>(
        listener: (context, state) {
          if (state is CmeQuizSubmittedState) {
            _showResultsDialog(context, theme);
          } else if (state is CmeQuizTimerExpiredState) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Time\'s up! Quiz auto-submitted.'),
                backgroundColor: Color(0xFFFF9500),
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is CmeQuizAutoSavedState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Progress saved'),
                backgroundColor: theme.primary,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 1),
              ),
            );
          }
        },
        builder: (context, state) {
          final bloc = context.read<CmeQuizBloc>();

          if (state is CmeQuizLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CmeQuizErrorState) {
            return _buildError(context, theme, state.message);
          }

          if (bloc.quiz == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CmeQuizResultsLoadedState || bloc.results != null) {
            return _buildResultsView(context, theme, bloc);
          }

          return _buildQuizBody(context, theme, bloc);
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, OneUITheme theme) {
    return AppBar(
      backgroundColor: theme.cardBackground,
      foregroundColor: theme.textPrimary,
      title: Text(
        quizTitle ?? 'Quiz',
        style: const TextStyle(fontFamily: 'Poppins', fontSize: 16),
      ),
      actions: [
        BlocBuilder<CmeQuizBloc, CmeQuizState>(
          builder: (context, state) {
            final bloc = context.read<CmeQuizBloc>();
            if (bloc.quiz?.hasTimeLimit == true &&
                state is! CmeQuizSubmittedState) {
              return _buildTimer(theme, bloc);
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildTimer(OneUITheme theme, CmeQuizBloc bloc) {
    final isUrgent = bloc.remainingSeconds < 60;
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isUrgent
            ? const Color(0xFFFF3B30).withValues(alpha: 0.1)
            : theme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined,
              size: 16,
              color: isUrgent ? const Color(0xFFFF3B30) : theme.primary),
          const SizedBox(width: 4),
          Text(
            bloc.timerDisplay,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isUrgent ? const Color(0xFFFF3B30) : theme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizBody(
      BuildContext context, OneUITheme theme, CmeQuizBloc bloc) {
    final questions = bloc.quiz!.questions ?? [];
    if (questions.isEmpty) {
      return Center(
        child: Text('No questions available', style: theme.bodySecondary),
      );
    }

    final currentQ = questions[bloc.currentQuestionIndex];

    return Column(
      children: [
        // Progress bar
        _buildProgressBar(theme, bloc, questions.length),
        // Question content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuestionHeader(theme, bloc, questions.length),
                const SizedBox(height: 16),
                _buildQuestionCard(context, theme, currentQ, bloc),
              ],
            ),
          ),
        ),
        // Navigation buttons
        _buildNavigationBar(context, theme, bloc, questions.length),
      ],
    );
  }

  Widget _buildProgressBar(
      OneUITheme theme, CmeQuizBloc bloc, int totalQuestions) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.cardBackground,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${bloc.answeredCount}/$totalQuestions answered',
                style: theme.caption,
              ),
              Text(
                'Question ${bloc.currentQuestionIndex + 1} of $totalQuestions',
                style: theme.caption,
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: totalQuestions > 0
                  ? bloc.answeredCount / totalQuestions
                  : 0,
              backgroundColor: theme.divider,
              valueColor:
                  AlwaysStoppedAnimation<Color>(theme.primary),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionHeader(
      OneUITheme theme, CmeQuizBloc bloc, int totalQuestions) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: theme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'Q${bloc.currentQuestionIndex + 1}',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.primary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (bloc.quiz!.questions![bloc.currentQuestionIndex].points != null)
          Text(
            '${bloc.quiz!.questions![bloc.currentQuestionIndex].points} pts',
            style: theme.caption,
          ),
      ],
    );
  }

  Widget _buildQuestionCard(BuildContext context, OneUITheme theme,
      CmeQuizQuestion question, CmeQuizBloc bloc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: theme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.questionText ?? '',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: theme.textPrimary,
              height: 1.5,
            ),
          ),
          if (question.imageUrl != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                question.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],
          const SizedBox(height: 20),
          if (question.isMultipleChoice || question.isTrueFalse)
            _buildOptions(context, theme, question, bloc),
          if (question.isShortAnswer)
            _buildShortAnswer(context, theme, question, bloc),
        ],
      ),
    );
  }

  Widget _buildOptions(BuildContext context, OneUITheme theme,
      CmeQuizQuestion question, CmeQuizBloc bloc) {
    final options = question.options ?? [];
    final selectedId = bloc.selectedAnswers[question.id];

    return Column(
      children: options.map((option) {
        final isSelected = selectedId == option.id.toString();

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                context.read<CmeQuizBloc>().add(CmeSelectAnswerEvent(
                      questionId: question.id!,
                      answer: option.id.toString(),
                    ));
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.primary.withValues(alpha: 0.08)
                      : theme.scaffoldBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color:
                        isSelected ? theme.primary : theme.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.primary
                            : theme.scaffoldBackground,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? theme.primary
                              : theme.textTertiary,
                          width: 1.5,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check,
                              size: 16, color: Colors.white)
                          : Center(
                              child: Text(
                                option.label ??
                                    String.fromCharCode(65 +
                                        (options.indexOf(option))),
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textTertiary,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        option.text ?? '',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.w500 : FontWeight.w400,
                          color: isSelected
                              ? theme.primary
                              : theme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildShortAnswer(BuildContext context, OneUITheme theme,
      CmeQuizQuestion question, CmeQuizBloc bloc) {
    return TextField(
      onChanged: (value) {
        context.read<CmeQuizBloc>().add(CmeSelectAnswerEvent(
              questionId: question.id!,
              answer: value,
            ));
      },
      decoration: InputDecoration(
        hintText: 'Type your answer here...',
        hintStyle: TextStyle(
            fontFamily: 'Poppins', color: theme.textTertiary),
        filled: true,
        fillColor: theme.inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.primary),
        ),
      ),
      maxLines: 3,
      style: TextStyle(
          fontFamily: 'Poppins', fontSize: 14, color: theme.textPrimary),
    );
  }

  Widget _buildNavigationBar(
      BuildContext context, OneUITheme theme, CmeQuizBloc bloc, int total) {
    final isFirst = bloc.currentQuestionIndex == 0;
    final isLast = bloc.currentQuestionIndex == total - 1;

    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        border: Border(top: BorderSide(color: theme.divider, width: 0.5)),
      ),
      child: Row(
        children: [
          if (!isFirst)
            OutlinedButton.icon(
              onPressed: () => bloc.add(CmeNavigateQuestionEvent(
                  questionIndex: bloc.currentQuestionIndex - 1)),
              icon: const Icon(Icons.chevron_left, size: 18),
              label: const Text('Previous',
                  style: TextStyle(fontFamily: 'Poppins')),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.textSecondary,
                side: BorderSide(color: theme.border),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          const Spacer(),
          if (isLast)
            ElevatedButton.icon(
              onPressed: bloc.allAnswered
                  ? () => _confirmSubmit(context, theme, bloc)
                  : null,
              icon: const Icon(Icons.send, size: 16),
              label: const Text('Submit Quiz',
                  style: TextStyle(
                      fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF34C759),
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    theme.textTertiary.withValues(alpha: 0.2),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: () => bloc.add(CmeNavigateQuestionEvent(
                  questionIndex: bloc.currentQuestionIndex + 1)),
              label: const Text('Next',
                  style: TextStyle(fontFamily: 'Poppins')),
              icon: const Icon(Icons.chevron_right, size: 18),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
        ],
      ),
    );
  }

  void _confirmSubmit(
      BuildContext context, OneUITheme theme, CmeQuizBloc bloc) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Submit Quiz?', style: theme.titleMedium),
        content: Text(
          'You have answered ${bloc.answeredCount} of ${bloc.totalQuestions} questions. '
          'Are you sure you want to submit?',
          style: theme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(
                    fontFamily: 'Poppins', color: theme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              bloc.add(CmeSubmitQuizEvent(
                  eventId: eventId, moduleId: moduleId, quizId: quizId));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF34C759),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Submit',
                style:
                    TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showResultsDialog(BuildContext context, OneUITheme theme) {
    final bloc = context.read<CmeQuizBloc>();
    final results = bloc.results;

    if (results == null) {
      Navigator.pop(context);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: theme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              results.passed == true
                  ? Icons.celebration
                  : Icons.info_outline,
              color: results.passed == true
                  ? const Color(0xFF34C759)
                  : const Color(0xFFFF9500),
            ),
            const SizedBox(width: 8),
            Text(
              results.passed == true ? 'Congratulations!' : 'Quiz Results',
              style: theme.titleMedium,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _resultRow(theme, 'Score', results.displayScore),
            _resultRow(theme, 'Percentage', results.displayPercentage),
            _resultRow(theme, 'Status',
                results.passed == true ? 'Passed' : 'Not Passed'),
            if (results.timeTaken != null)
              _resultRow(theme, 'Time Taken', results.displayTimeTaken),
          ],
        ),
        actions: [
          if (bloc.quiz!.showResults == true)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Show detailed results
              },
              child: Text('View Details',
                  style: TextStyle(
                      fontFamily: 'Poppins', color: theme.primary)),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Done',
                style:
                    TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _resultRow(OneUITheme theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.bodySecondary),
          Text(value,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.textPrimary,
              )),
        ],
      ),
    );
  }

  Widget _buildResultsView(
      BuildContext context, OneUITheme theme, CmeQuizBloc bloc) {
    final results = bloc.results!;
    final answers = results.answers ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Score card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: theme.cardDecoration,
            child: Column(
              children: [
                Icon(
                  results.passed == true
                      ? Icons.emoji_events_rounded
                      : Icons.assignment_outlined,
                  size: 48,
                  color: results.passed == true
                      ? const Color(0xFFFFD700)
                      : theme.primary,
                ),
                const SizedBox(height: 12),
                Text(results.displayPercentage,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: theme.textPrimary,
                    )),
                Text(
                  results.passed == true ? 'Passed!' : 'Not passed',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: results.passed == true
                        ? const Color(0xFF34C759)
                        : const Color(0xFFFF9500),
                  ),
                ),
                const SizedBox(height: 8),
                Text('Score: ${results.displayScore}',
                    style: theme.bodySecondary),
                if (results.timeTaken != null)
                  Text('Time: ${results.displayTimeTaken}',
                      style: theme.caption),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Answer details
          if (answers.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Answer Review', style: theme.titleSmall),
            ),
            const SizedBox(height: 10),
            ...answers.asMap().entries.map((entry) {
              final idx = entry.key;
              final answer = entry.value;
              return _buildAnswerReview(theme, idx + 1, answer);
            }),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Back to Module',
                  style: TextStyle(
                      fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerReview(
      OneUITheme theme, int index, CmeQuizAnswerResult answer) {
    final isCorrect = answer.isCorrect == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCorrect
            ? const Color(0xFF34C759).withValues(alpha: 0.05)
            : const Color(0xFFFF3B30).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCorrect
              ? const Color(0xFF34C759).withValues(alpha: 0.3)
              : const Color(0xFFFF3B30).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                size: 18,
                color: isCorrect
                    ? const Color(0xFF34C759)
                    : const Color(0xFFFF3B30),
              ),
              const SizedBox(width: 6),
              Text(
                'Question $index',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimary,
                ),
              ),
              const Spacer(),
              if (answer.pointsEarned != null)
                Text(
                  '${answer.pointsEarned} pts',
                  style: theme.caption,
                ),
            ],
          ),
          if (!isCorrect && answer.correctAnswer != null) ...[
            const SizedBox(height: 6),
            Text(
              'Correct answer: ${answer.correctAnswer}',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: const Color(0xFF34C759),
              ),
            ),
          ],
          if (answer.explanation != null) ...[
            const SizedBox(height: 6),
            Text(answer.explanation!,
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: theme.textSecondary,
                    fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, OneUITheme theme, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.textTertiary),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center, style: theme.bodySecondary),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<CmeQuizBloc>().add(
                  CmeLoadQuizEvent(
                      eventId: eventId,
                      moduleId: moduleId,
                      quizId: quizId)),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Retry',
                  style: TextStyle(fontFamily: 'Poppins')),
            ),
          ],
        ),
      ),
    );
  }
}
