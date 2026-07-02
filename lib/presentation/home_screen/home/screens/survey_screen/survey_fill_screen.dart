import 'package:doctak_app/data/apiClient/shared_api_service.dart';
import 'package:doctak_app/data/models/survey_model/survey_detail_model.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:doctak_app/widgets/retry_widget.dart';
import 'package:doctak_app/widgets/shimmer_widget/post_shimmer_loader.dart';
import 'package:flutter/material.dart';

class SurveyFillScreen extends StatefulWidget {
  final String surveyId;

  const SurveyFillScreen({super.key, required this.surveyId});

  @override
  State<SurveyFillScreen> createState() => _SurveyFillScreenState();
}

class _SurveyFillScreenState extends State<SurveyFillScreen> {
  final SharedApiService _api = SharedApiService();
  final Map<String, String> _answers = {};

  SurveyDetail? _survey;
  bool _loading = true;
  bool _submitting = false;
  bool _submitted = false;
  String? _error;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await _api.getSurveyDetail(widget.surveyId);
    if (!mounted) return;
    if (!res.success || res.data == null) {
      setState(() {
        _loading = false;
        _error = res.message ?? 'Failed to load survey';
      });
      return;
    }
    setState(() {
      _survey = res.data;
      _loading = false;
    });
  }

  int get _answeredCount =>
      _survey?.questions.where((q) => (_answers[q.id] ?? '').trim().isNotEmpty).length ?? 0;

  Future<void> _submit() async {
    final survey = _survey;
    if (survey == null) return;

    final unanswered =
        survey.questions.where((q) => (_answers[q.id] ?? '').trim().isEmpty).length;
    if (unanswered > 0) {
      setState(() {
        _submitError =
            'Please answer all questions ($unanswered remaining).';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    final payload = survey.questions
        .map((q) => {'questionId': q.id, 'answer': _answers[q.id]!.trim()})
        .toList();

    final res = await _api.submitSurveyResponse(
      surveyId: survey.id,
      answers: payload,
    );

    if (!mounted) return;
    if (!res.success) {
      setState(() {
        _submitting = false;
        _submitError = res.message ?? 'Failed to submit survey';
      });
      return;
    }

    setState(() {
      _submitting = false;
      _submitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: DoctakAppBar(
        title: 'Survey',
        centerTitle: true,
      ),
      body: _buildBody(context, theme),
      bottomNavigationBar: _buildBottomBar(theme),
    );
  }

  Widget? _buildBottomBar(OneUITheme theme) {
    final survey = _survey;
    if (_loading || _error != null || survey == null) return null;
    if (survey.hasResponded || _submitted) return null;

    final total = survey.questions.length;
    final pct = total > 0 ? (_answeredCount / total * 100).round() : 0;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: theme.cardBackground,
          border: Border(top: BorderSide(color: theme.border)),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$_answeredCount of $total answered',
                    style: theme.bodySecondary),
                Text('$pct% complete', style: theme.caption),
              ],
            ),
            const Spacer(),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: theme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: _submitting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Submit responses'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, OneUITheme theme) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: PostShimmerLoader(itemCount: 3),
      );
    }

    if (_error != null) {
      return RetryWidget(
        errorMessage: _error!,
        onRetry: _load,
      );
    }

    final survey = _survey;
    if (survey == null) {
      return _statusPanel(
        theme,
        icon: Icons.error_outline,
        title: 'Survey not available',
        message: 'This survey could not be found.',
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Go back')),
        ],
      );
    }

    if (survey.hasResponded) {
      return _statusPanel(
        theme,
        icon: Icons.check_circle_outline,
        iconColor: theme.primary,
        title: 'Already completed',
        message:
            'You have already responded to "${survey.title}". Each survey can only be completed once.',
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back'),
          ),
        ],
      );
    }

    if (_submitted) {
      return _statusPanel(
        theme,
        icon: Icons.check_circle,
        iconColor: theme.success,
        title: 'Response recorded',
        message:
            'Thank you for completing "${survey.title}". Your ${survey.questions.length} responses have been submitted.',
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Done'),
          ),
        ],
      );
    }

    final total = survey.questions.length;
    final pct = total > 0 ? (_answeredCount / total * 100).round() : 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        _heroCard(theme, survey, pct),
        if (_submitError != null) ...[
          const SizedBox(height: 12),
          _errorBanner(theme, _submitError!),
        ],
        const SizedBox(height: 16),
        ...survey.questions.asMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _questionCard(theme, e.key + 1, e.value),
              ),
            ),
      ],
    );
  }

  Widget _heroCard(OneUITheme theme, SurveyDetail survey, int pct) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: theme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (survey.surveyCategory != null && survey.surveyCategory!.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                survey.surveyCategory!.replaceAll('_', ' ').toUpperCase(),
                style: theme.caption.copyWith(
                  color: theme.primary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          Text(survey.title, style: theme.titleMedium.copyWith(fontSize: 20)),
          if (survey.description != null && survey.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(survey.description!, style: theme.bodySecondary),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.quiz_outlined, size: 16, color: theme.textSecondary),
              const SizedBox(width: 6),
              Text(
                '${survey.questionCount} question${survey.questionCount == 1 ? '' : 's'}',
                style: theme.caption,
              ),
              if (survey.responseCount > 0) ...[
                const SizedBox(width: 12),
                Text(
                  '${survey.responseCount} responses',
                  style: theme.caption,
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 6,
              backgroundColor: theme.border,
              color: theme.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text('$pct% complete', style: theme.caption),
        ],
      ),
    );
  }

  Widget _questionCard(OneUITheme theme, int index, SurveyQuestion question) {
    final answered = (_answers[question.id] ?? '').trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: theme.cardDecoration.copyWith(
        border: Border.all(
          color: answered
              ? theme.primary.withValues(alpha: 0.35)
              : theme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: answered ? theme.primary : theme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$index',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: answered ? Colors.white : theme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(question.question,
                        style: theme.titleSmall.copyWith(height: 1.4)),
                    const SizedBox(height: 4),
                    Text(
                      _typeLabel(question.questionType),
                      style: theme.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: _questionInput(theme, question),
          ),
        ],
      ),
    );
  }

  Widget _questionInput(OneUITheme theme, SurveyQuestion question) {
    switch (question.questionType) {
      case 'boolean':
        return Row(
          children: [
            _choiceChip(theme, question, 'Yes', 'Yes'),
            const SizedBox(width: 10),
            _choiceChip(theme, question, 'No', 'No'),
          ],
        );
      case 'multiple_choice':
        return Column(
          children: question.options
              .map(
                (opt) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _choiceChip(theme, question, opt, opt, fullWidth: true),
                ),
              )
              .toList(),
        );
      case 'rating':
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(
            5,
            (i) => _choiceChip(
              theme,
              question,
              '${i + 1}',
              '${i + 1}',
            ),
          ),
        );
      default:
        return TextField(
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Type your answer…',
            filled: true,
            fillColor: theme.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.border),
            ),
          ),
          onChanged: (v) => setState(() => _answers[question.id] = v),
        );
    }
  }

  Widget _choiceChip(
    OneUITheme theme,
    SurveyQuestion question,
    String label,
    String value, {
    bool fullWidth = false,
  }) {
    final selected = _answers[question.id] == value;
    final chip = Material(
      color: selected
          ? theme.primary.withValues(alpha: 0.12)
          : theme.surfaceVariant,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _answers[question.id] = value),
        child: Container(
          width: fullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? theme.primary : theme.border,
            ),
          ),
          child: Text(
            label,
            style: theme.bodyMedium.copyWith(
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? theme.primary : theme.textPrimary,
            ),
          ),
        ),
      ),
    );
    return chip;
  }

  Widget _errorBanner(OneUITheme theme, String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: theme.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: theme.bodyMedium.copyWith(color: theme.error)),
          ),
        ],
      ),
    );
  }

  Widget _statusPanel(
    OneUITheme theme, {
    required IconData icon,
    Color? iconColor,
    required String title,
    required String message,
    required List<Widget> actions,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: iconColor ?? theme.textSecondary),
            const SizedBox(height: 16),
            Text(title, style: theme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message, style: theme.bodySecondary, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Wrap(spacing: 12, runSpacing: 8, alignment: WrapAlignment.center, children: actions),
          ],
        ),
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'boolean':
        return 'Yes / No';
      case 'multiple_choice':
        return 'Multiple choice';
      case 'rating':
        return 'Rating 1–5';
      default:
        return 'Text response';
    }
  }
}
