import 'package:doctak_app/data/models/cme/cme_quiz_model.dart';
import 'package:doctak_app/presentation/cme_module/bloc/cme_quiz_bloc.dart';
import 'package:doctak_app/presentation/cme_module/bloc/cme_quiz_event.dart';
import 'package:doctak_app/presentation/cme_module/bloc/cme_quiz_state.dart';
import 'package:doctak_app/presentation/cme_module/widgets/cme_quiz_head.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CmeQuizScreen extends StatelessWidget {
  const CmeQuizScreen({
    super.key,
    required this.eventId,
    this.moduleId,
    this.quizTitle,
  });

  final String eventId;
  final String? moduleId;
  final String? quizTitle;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CmeQuizBloc()
        ..add(CmeLoadQuizEvent(eventId: eventId, moduleId: moduleId)),
      child: _CmeQuizView(
        eventId: eventId,
        quizTitle: quizTitle,
      ),
    );
  }
}

class _CmeQuizView extends StatelessWidget {
  const _CmeQuizView({
    required this.eventId,
    this.quizTitle,
  });

  final String eventId;
  final String? quizTitle;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: DoctakAppBar(
        title: quizTitle ?? 'Assessment',
        actions: [
          BlocBuilder<CmeQuizBloc, CmeQuizState>(
            builder: (context, state) {
              final bloc = context.read<CmeQuizBloc>();
              if (bloc.quiz?.hasTimeLimit == true &&
                  (bloc.phase == CmeQuizPhase.question || bloc.phase == CmeQuizPhase.review) &&
                  bloc.remainingSeconds > 0) {
                return _TimerChip(theme: theme, bloc: bloc);
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<CmeQuizBloc, CmeQuizState>(
        listener: (context, state) {
          if (state is CmeQuizTimerExpiredState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Time\'s up — quiz submitted.'),
                backgroundColor: theme.warning,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          final bloc = context.read<CmeQuizBloc>();

          if (state is CmeQuizLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CmeQuizErrorState && bloc.quiz == null) {
            return _ErrorView(
              message: state.message,
              onRetry: () => bloc.add(CmeLoadQuizEvent(eventId: eventId)),
            );
          }
          if (bloc.quiz == null) {
            return Center(child: Text('No quiz available.', style: theme.bodySecondary));
          }

          if (bloc.quiz!.attemptsLeft <= 0 && bloc.phase != CmeQuizPhase.result) {
            return _NoAttemptsView(theme: theme);
          }

          return switch (bloc.phase) {
            CmeQuizPhase.intro => _IntroView(bloc: bloc),
            CmeQuizPhase.question => _QuestionView(bloc: bloc, eventId: eventId),
            CmeQuizPhase.review => _ReviewView(bloc: bloc, eventId: eventId),
            CmeQuizPhase.result => _ResultView(bloc: bloc),
          };
        },
      ),
    );
  }
}

class _TimerChip extends StatelessWidget {
  const _TimerChip({required this.theme, required this.bloc});

  final OneUITheme theme;
  final CmeQuizBloc bloc;

  @override
  Widget build(BuildContext context) {
    final urgent = bloc.remainingSeconds < 60;
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: urgent ? theme.error.withValues(alpha: 0.1) : theme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 16, color: urgent ? theme.error : theme.primary),
          const SizedBox(width: 4),
          Text(
            bloc.timerDisplay,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: urgent ? theme.error : theme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroView extends StatelessWidget {
  const _IntroView({required this.bloc});

  final CmeQuizBloc bloc;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final quiz = bloc.quiz!;
    final questions = quiz.questions?.length ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CmeQuizHead(quiz: quiz),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: theme.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Before you begin', style: theme.titleSmall),
                const SizedBox(height: 12),
                _rule(theme, '$questions questions · ${quiz.passingScore ?? 70}% to pass'),
                _rule(theme, '${quiz.attemptsLeft} attempt${quiz.attemptsLeft == 1 ? '' : 's'} available'),
                _rule(
                  theme,
                  quiz.hasTimeLimit
                      ? '${quiz.timeLimit} minute time limit — quiz auto-submits when time runs out'
                      : 'No time limit — take as long as you need',
                ),
                _rule(theme, 'You can review your answers before submitting'),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => bloc.add(CmeBeginQuizEvent()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primary,
                      foregroundColor: theme.buttonPrimaryText,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Begin assessment',
                      style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rule(OneUITheme theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.circle, size: 6, color: theme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: theme.bodyMedium)),
        ],
      ),
    );
  }
}

class _QuestionView extends StatelessWidget {
  const _QuestionView({required this.bloc, required this.eventId});

  final CmeQuizBloc bloc;
  final String eventId;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final questions = bloc.quiz!.questions ?? [];
    if (questions.isEmpty) {
      return Center(child: Text('No questions available.', style: theme.bodySecondary));
    }

    final current = questions[bloc.currentQuestionIndex];
    final total = questions.length;

    return Column(
      children: [
        _ProgressHeader(bloc: bloc, total: total),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: theme.cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(current.typeHint, style: theme.caption.copyWith(color: theme.primary)),
                  const SizedBox(height: 8),
                  Text(current.questionText ?? '', style: theme.titleSmall),
                  const SizedBox(height: 4),
                  Text('${current.points ?? 1} pt${current.points == 1 ? '' : 's'}', style: theme.caption),
                  if (current.imageUrl != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(current.imageUrl!, fit: BoxFit.cover),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _QuestionInput(question: current, bloc: bloc),
                ],
              ),
            ),
          ),
        ),
        _QuestionNavBar(bloc: bloc, total: total, eventId: eventId),
      ],
    );
  }
}

class _QuestionInput extends StatelessWidget {
  const _QuestionInput({required this.question, required this.bloc});

  final CmeQuizQuestion question;
  final CmeQuizBloc bloc;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final options = question.options ?? [];

    if (question.isMultipleSelect) {
      final selected = bloc.answerFor(question.id);
      final selectedList = selected is List
          ? selected.map((e) => e.toString()).toList()
          : <String>[];
      return Column(
        children: options.map((option) {
          final value = option.value;
          final isSelected = selectedList.contains(value);
          return _OptionTile(
            theme: theme,
            label: option.label ?? String.fromCharCode(65 + options.indexOf(option)),
            text: option.text ?? value,
            isSelected: isSelected,
            multi: true,
            onTap: () => bloc.add(CmeToggleMultiAnswerEvent(questionId: question.id!, value: value)),
          );
        }).toList(),
      );
    }

    if (question.isMultipleChoice || question.isTrueFalse) {
      final selected = bloc.answerFor(question.id)?.toString();
      return Column(
        children: options.map((option) {
          final value = option.value;
          return _OptionTile(
            theme: theme,
            label: option.label ?? String.fromCharCode(65 + options.indexOf(option)),
            text: option.text ?? value,
            isSelected: selected == value,
            onTap: () => bloc.add(CmeSelectAnswerEvent(questionId: question.id!, answer: value)),
          );
        }).toList(),
      );
    }

    return TextField(
      maxLines: 5,
      onChanged: (value) => bloc.add(CmeSetEssayAnswerEvent(questionId: question.id!, text: value)),
      decoration: InputDecoration(
        hintText: 'Type your answer here…',
        filled: true,
        fillColor: theme.inputBackground,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.theme,
    required this.label,
    required this.text,
    required this.isSelected,
    required this.onTap,
    this.multi = false,
  });

  final OneUITheme theme;
  final String label;
  final String text;
  final bool isSelected;
  final VoidCallback onTap;
  final bool multi;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected ? theme.primary.withValues(alpha: 0.08) : theme.scaffoldBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? theme.primary : theme.border, width: isSelected ? 1.5 : 1),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? theme.primary : theme.scaffoldBackground,
                  shape: multi ? BoxShape.rectangle : BoxShape.circle,
                  borderRadius: multi ? BorderRadius.circular(6) : null,
                  border: Border.all(color: isSelected ? theme.primary : theme.textTertiary),
                ),
                child: isSelected
                    ? Icon(multi ? Icons.check : Icons.check, size: 16, color: theme.buttonPrimaryText)
                    : Text(label, style: theme.caption),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(text, style: theme.bodyMedium)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.bloc, required this.total});

  final CmeQuizBloc bloc;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: theme.cardBackground,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? (bloc.currentQuestionIndex + 1) / total : 0,
              minHeight: 4,
              backgroundColor: theme.divider,
              valueColor: AlwaysStoppedAnimation(theme.primary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Question ${bloc.currentQuestionIndex + 1} of $total · ${bloc.answeredCount} answered',
            style: theme.caption,
          ),
        ],
      ),
    );
  }
}

class _QuestionNavBar extends StatelessWidget {
  const _QuestionNavBar({
    required this.bloc,
    required this.total,
    required this.eventId,
  });

  final CmeQuizBloc bloc;
  final int total;
  final String eventId;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final questions = bloc.quiz!.questions ?? [];

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        border: Border(top: BorderSide(color: theme.divider)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(questions.length, (index) {
              final answered = bloc.isQuestionAnswered(questions[index].id);
              final current = index == bloc.currentQuestionIndex;
              return GestureDetector(
                onTap: () => bloc.add(CmeNavigateQuestionEvent(questionIndex: index)),
                child: Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: current
                        ? theme.primary
                        : answered
                            ? theme.primary.withValues(alpha: 0.35)
                            : theme.divider,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (bloc.currentQuestionIndex > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: bloc.goPreviousQuestion,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Previous'),
                  ),
                ),
              if (bloc.currentQuestionIndex > 0) const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: bloc.goNextQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    foregroundColor: theme.buttonPrimaryText,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    bloc.currentQuestionIndex == total - 1 ? 'Review' : 'Next',
                    style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewView extends StatelessWidget {
  const _ReviewView({required this.bloc, required this.eventId});

  final CmeQuizBloc bloc;
  final String eventId;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final questions = bloc.quiz!.questions ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: theme.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Review your answers', style: theme.titleSmall),
            const SizedBox(height: 8),
            Text(
              'Check everything before submitting. You answered ${bloc.answeredCount} of ${questions.length} questions.',
              style: theme.bodySecondary,
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < questions.length; i++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${i + 1}. ${questions[i].questionText}', style: theme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(
                          bloc.answerSummary(questions[i]).isEmpty ? 'No answer selected' : bloc.answerSummary(questions[i]),
                          style: theme.caption,
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => bloc.add(CmeNavigateQuestionEvent(questionIndex: i)),
                    child: const Text('Edit'),
                  ),
                ],
              ),
              const Divider(),
            ],
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: () => bloc.add(CmeSubmitQuizEvent(eventId: eventId)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    foregroundColor: theme.buttonPrimaryText,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Submit assessment',
                    style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: bloc.goPreviousQuestion,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Back to questions'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.bloc});

  final CmeQuizBloc bloc;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final result = bloc.submissionResult;
    if (result == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (result.pendingEssayReview) {
      return _ResultCard(
        theme: theme,
        icon: Icons.hourglass_top,
        iconColor: theme.warning,
        title: 'Submitted — awaiting review',
        body: 'Provisional score: ${result.score.round()}%\n\nYour written responses need manual grading. Once reviewed, your final score will be updated.',
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back to event'),
          ),
        ],
      );
    }

    final attemptsLeft = bloc.quiz?.attemptsLeft ?? 0;

    return _ResultCard(
      theme: theme,
      icon: result.passed ? Icons.celebration : Icons.info_outline,
      iconColor: result.passed ? theme.success : theme.warning,
      title: result.passed ? 'Congratulations — you passed!' : 'Not quite there yet',
      body: 'Your score: ${result.score.round()}%\n${result.earnedPoints} of ${result.totalPoints} points · Passing score: ${result.passingScore}%'
          '${!result.passed && attemptsLeft > 0 ? '\nYou have $attemptsLeft more attempt${attemptsLeft == 1 ? '' : 's'}.' : ''}',
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Back to event'),
        ),
        if (!result.passed && attemptsLeft > 0)
          OutlinedButton(
            onPressed: () => bloc.add(CmeResetQuizEvent()),
            child: const Text('Try again'),
          ),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.theme,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.actions,
  });

  final OneUITheme theme;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: theme.cardDecoration,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: iconColor),
              const SizedBox(height: 12),
              Text(title, style: theme.titleMedium, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(body, style: theme.bodyMedium, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: actions,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoAttemptsView extends StatelessWidget {
  const _NoAttemptsView({required this.theme});

  final OneUITheme theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No attempts remaining for this assessment.',
          style: theme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center, style: theme.bodySecondary),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
