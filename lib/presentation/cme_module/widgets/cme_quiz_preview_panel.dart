import 'package:doctak_app/data/apiClient/cme/cme_node_api_service.dart';
import 'package:doctak_app/data/models/cme/cme_event_model.dart';
import 'package:doctak_app/data/models/cme/cme_quiz_model.dart';
import 'package:doctak_app/presentation/cme_module/screens/cme_quiz_screen.dart';
import 'package:doctak_app/presentation/cme_module/utils/cme_progress.dart';
import 'package:doctak_app/presentation/cme_module/widgets/cme_quiz_head.dart';
import 'package:doctak_app/presentation/cme_module/widgets/cme_shimmer_loader.dart';
import 'package:doctak_app/routes/app_navigator.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

class CmeQuizPreviewPanel extends StatefulWidget {
  const CmeQuizPreviewPanel({
    super.key,
    required this.event,
    required this.eventId,
    this.onMutate,
  });

  final CmeEventData event;
  final String eventId;
  final VoidCallback? onMutate;

  @override
  State<CmeQuizPreviewPanel> createState() => _CmeQuizPreviewPanelState();
}

class _CmeQuizPreviewPanelState extends State<CmeQuizPreviewPanel> {
  CmeQuizData? _quiz;
  bool _loading = true;
  String? _error;

  bool get _isProvider => widget.event.canManage == true;
  bool get _canSubmit => widget.event.capabilities?.canSubmitQuiz == true;
  bool get _isRegistered => cmeIsRegistered(widget.event);
  bool get _hasAttended => cmeHasAttended(widget.event);

  @override
  void initState() {
    super.initState();
    _load().catchError((Object e) {
      debugPrint('CmeQuizPreviewPanel load failed: $e');
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final quiz = await CmeNodeApiService.getQuiz(
        widget.eventId,
        moduleId: widget.event.primaryQuizTarget?.moduleId,
        reveal: _isProvider,
      );
      if (mounted) setState(() => _quiz = quiz);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openRunner() {
    AppNavigator.push(
      context,
      CmeQuizScreen(
        eventId: widget.eventId,
        moduleId: widget.event.primaryQuizTarget?.moduleId,
        quizTitle: _quiz?.title,
      ),
    ).then((_) {
      _load().catchError((Object e) {
        debugPrint('Quiz preview reload failed: $e');
      });
      widget.onMutate?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    if (_loading) return const CmeTabPanelShimmer(rows: 5);
    if (_error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_error!, style: TextStyle(color: theme.error)),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: _load, child: const Text('Retry')),
        ],
      );
    }

    if (_quiz == null) {
      return Text(
        _isProvider
            ? 'No quiz configured yet. Add a post-activity assessment from the provider tools.'
            : 'The organizer has not set up a quiz for this activity yet.',
        style: theme.bodySecondary,
      );
    }

    final quiz = _quiz!;
    final questions = quiz.questions ?? [];
    if (!_isProvider && questions.isEmpty) {
      return Text('No quiz questions are available yet.', style: theme.bodySecondary);
    }

    final attempts = quiz.myAttempts ?? [];
    final passed = quiz.passed;
    final attemptsLeft = quiz.attemptsLeft;
    final timeLabel = quiz.hasTimeLimit
        ? '${quiz.timeLimit} min time limit'
        : 'No time limit';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CmeQuizHead(
          quiz: quiz,
          description: _isProvider
              ? 'Manage your post-test. $timeLabel.'
              : quiz.description ??
                  'Pass to earn your credit. You have ${quiz.maxAttempts != null && quiz.maxAttempts! >= 999 ? 'unlimited' : attemptsLeft} attempt${attemptsLeft == 1 ? '' : 's'}.${quiz.hasTimeLimit ? ' Time limit: ${quiz.timeLimit} minutes.' : ''}',
        ),
        if (_isProvider && questions.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('${questions.length} questions', style: theme.titleSmall),
          const SizedBox(height: 8),
          for (var i = 0; i < questions.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Q${i + 1}', style: theme.caption),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(questions[i].questionText ?? '', style: theme.bodyMedium),
                        Text(
                          '${questions[i].typeHint} · ${questions[i].points ?? 1} pts',
                          style: theme.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
        if (!_isProvider) ...[
          const SizedBox(height: 16),
          if (_canSubmit) ...[
            Text('Ready to take the assessment?', style: theme.titleSmall),
            const SizedBox(height: 8),
            Text(
              'Answer all ${questions.length} question${questions.length == 1 ? '' : 's'} to earn credit.'
              '${quiz.hasTimeLimit ? ' You will have ${quiz.timeLimit} minutes once you begin.' : ' There is no time limit for this quiz.'}',
              style: theme.bodyMedium,
            ),
            const SizedBox(height: 12),
            _fact(theme, '${quiz.passingScore ?? 70}% required to pass'),
            _fact(theme, '$attemptsLeft attempt${attemptsLeft == 1 ? '' : 's'} remaining'),
            _fact(theme, timeLabel),
            const SizedBox(height: 16),
            if (!passed && attemptsLeft > 0)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _openRunner,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    foregroundColor: theme.buttonPrimaryText,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Start assessment',
                    style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                  ),
                ),
              )
            else if (passed)
              Text('You passed this assessment.', style: TextStyle(color: theme.success, fontWeight: FontWeight.w600))
            else
              Text('No attempts remaining.', style: TextStyle(color: theme.warning)),
          ] else ...[
            if (!_isRegistered)
              Text('Register for this activity to unlock the post-test assessment.', style: theme.bodySecondary)
            else if (!_hasAttended)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Attend the live activity first (at least 50% participation) before taking the quiz.',
                      style: theme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Join the live meeting from the event page and stay until attendance is recorded.',
                    style: theme.bodySecondary,
                  ),
                ],
              )
            else
              Text('The assessment is not available right now.', style: theme.bodySecondary),
          ],
          if (_canSubmit && attempts.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Your attempts', style: theme.titleSmall),
            const SizedBox(height: 8),
            for (final attempt in attempts)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Attempt ${attempt.attemptNumber ?? '-'}', style: theme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                          Text(
                            '${attempt.score?.round() ?? '—'}% — ${attempt.passed == true ? 'Passed' : 'Not passed'}',
                            style: theme.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ],
    );
  }

  Widget _fact(OneUITheme theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, size: 16, color: theme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: theme.bodyMedium)),
        ],
      ),
    );
  }
}
