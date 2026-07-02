import 'package:doctak_app/data/apiClient/cme/cme_node_api_service.dart';
import 'package:doctak_app/data/models/cme/cme_event_model.dart';
import 'package:doctak_app/presentation/cme_module/utils/cme_display.dart';
import 'package:doctak_app/presentation/cme_module/utils/cme_progress.dart';
import 'package:doctak_app/presentation/cme_module/widgets/cme_event_detail_shared.dart';
import 'package:doctak_app/presentation/cme_module/widgets/cme_quiz_preview_panel.dart';
import 'package:doctak_app/presentation/cme_module/widgets/cme_shimmer_loader.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/one_ui_tab_bar.dart';
import 'package:flutter/material.dart';

enum CmeDetailTab { about, agenda, speakers, quiz, feedback }

class CmeEventDetailTabs extends StatefulWidget {
  const CmeEventDetailTabs({
    super.key,
    required this.event,
    required this.eventId,
    this.initialTab = CmeDetailTab.about,
    this.onOpenQuiz,
    this.onMutate,
    this.onFeedbackSubmitted,
  });

  final CmeEventData event;
  final String eventId;
  final CmeDetailTab initialTab;
  final VoidCallback? onOpenQuiz;
  final VoidCallback? onMutate;
  final VoidCallback? onFeedbackSubmitted;

  @override
  State<CmeEventDetailTabs> createState() => CmeEventDetailTabsState();
}

class CmeEventDetailTabsState extends State<CmeEventDetailTabs> {
  CmeDetailTab _activeTab = CmeDetailTab.about;
  List<CmeSegment>? _segments;
  List<CmeSpeaker>? _speakers;
  bool _loadingExtra = false;
  String? _extraError;

  bool get _isProvider => widget.event.canManage == true;

  List<CmeDetailTab> get _visibleTabs {
    final tabs = <CmeDetailTab>[CmeDetailTab.about, CmeDetailTab.agenda, CmeDetailTab.speakers];
    if (_isProvider || cmeEventHasQuiz(widget.event)) tabs.add(CmeDetailTab.quiz);
    if (!_isProvider) tabs.add(CmeDetailTab.feedback);
    return tabs;
  }

  @override
  void initState() {
    super.initState();
    _activeTab = _visibleTabs.contains(widget.initialTab)
        ? widget.initialTab
        : CmeDetailTab.about;
    _ensureTabData(_activeTab).catchError((Object e) {
      debugPrint('CME tab data load failed: $e');
    });
  }

  @override
  void didUpdateWidget(covariant CmeEventDetailTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_visibleTabs.contains(_activeTab)) {
      setState(() => _activeTab = _visibleTabs.first);
    }
  }

  Future<void> _ensureTabData(CmeDetailTab tab) async {
    if (!mounted) return;
    if (tab == CmeDetailTab.agenda && _segments == null) {
      await _loadSegments();
    } else if (tab == CmeDetailTab.speakers && _speakers == null) {
      await _loadSpeakers();
    }
  }

  Future<void> _loadSegments() async {
    if (!mounted) return;
    setState(() {
      _loadingExtra = true;
      _extraError = null;
    });
    try {
      final rows = await CmeNodeApiService.listSegments(widget.eventId);
      if (mounted) setState(() => _segments = rows);
    } catch (e) {
      if (mounted) setState(() => _extraError = '$e');
    } finally {
      if (mounted) setState(() => _loadingExtra = false);
    }
  }

  Future<void> _loadSpeakers() async {
    if (!mounted) return;
    setState(() {
      _loadingExtra = true;
      _extraError = null;
    });
    try {
      final rows = await CmeNodeApiService.listSpeakers(widget.eventId);
      if (mounted) setState(() => _speakers = rows);
    } catch (e) {
      final preview = widget.event.speakers;
      if (mounted) {
        setState(() {
          _speakers = preview;
          if (preview == null || preview.isEmpty) _extraError = '$e';
        });
      }
    } finally {
      if (mounted) setState(() => _loadingExtra = false);
    }
  }

  void openTab(CmeDetailTab tab) {
    final index = _visibleTabs.indexOf(tab);
    if (index < 0) return;
    _selectTabAt(index);
  }

  void _selectTabAt(int index) {
    if (!mounted) return;
    final tabs = _visibleTabs;
    if (index < 0 || index >= tabs.length) return;
    final tab = tabs[index];
    if (_activeTab == tab) {
      _ensureTabData(tab).catchError((Object e) {
        debugPrint('CME tab data load failed: $e');
      });
      return;
    }
    setState(() => _activeTab = tab);
    _ensureTabData(tab).catchError((Object e) {
      debugPrint('CME tab data load failed: $e');
    });
  }

  void _handleHorizontalSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 280) return;
    final tabs = _visibleTabs;
    final current = tabs.indexOf(_activeTab);
    if (current < 0) return;
    if (velocity < 0 && current < tabs.length - 1) {
      _selectTabAt(current + 1);
    } else if (velocity > 0 && current > 0) {
      _selectTabAt(current - 1);
    }
  }

  String _tabLabel(CmeDetailTab tab) {
    return switch (tab) {
      CmeDetailTab.about => 'About',
      CmeDetailTab.agenda => 'Agenda',
      CmeDetailTab.speakers => 'Speakers',
      CmeDetailTab.quiz => 'Quiz',
      CmeDetailTab.feedback => 'Feedback',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final tabs = _visibleTabs;
    final selectedIndex = tabs.indexOf(_activeTab).clamp(0, tabs.length - 1);
    final labels = tabs.map(_tabLabel).toList();

    final useExpandedTabs = false;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: DecoratedBox(
        decoration: theme.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OneUIProfileTabBar(
              tabs: labels,
              selectedIndex: selectedIndex,
              onSelected: _selectTabAt,
              expandTabs: useExpandedTabs,
              showBottomBorder: true,
              backgroundColor: theme.cardBackground,
              matchAppBar: false,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              tabSpacing: 20,
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragEnd: _handleHorizontalSwipe,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  final slide = Tween<Offset>(
                    begin: const Offset(0.04, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: slide, child: child),
                  );
                },
                child: Padding(
                  key: ValueKey<CmeDetailTab>(_activeTab),
                  padding: const EdgeInsets.all(16),
                  child: _buildPanel(theme, _activeTab),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanel(OneUITheme theme, CmeDetailTab tab) {
    if (_loadingExtra && (tab == CmeDetailTab.agenda || tab == CmeDetailTab.speakers)) {
      return const CmeTabPanelShimmer(rows: 4);
    }
    if (_extraError != null && (tab == CmeDetailTab.agenda || tab == CmeDetailTab.speakers)) {
      return Text(_extraError!, style: TextStyle(color: theme.error));
    }

    return switch (tab) {
      CmeDetailTab.about => _AboutPanel(event: widget.event),
      CmeDetailTab.agenda => _AgendaPanel(segments: _segments ?? const []),
      CmeDetailTab.speakers => _SpeakersPanel(speakers: _speakers ?? widget.event.speakers ?? const []),
      CmeDetailTab.quiz => CmeQuizPreviewPanel(
          event: widget.event,
          eventId: widget.eventId,
          onMutate: widget.onMutate,
        ),
      CmeDetailTab.feedback => _FeedbackPanel(
          eventId: widget.eventId,
          event: widget.event,
          onSubmitted: widget.onFeedbackSubmitted ?? widget.onMutate,
        ),
    };
  }
}

class _AboutPanel extends StatelessWidget {
  const _AboutPanel({required this.event});

  final CmeEventData event;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final objectives = parseCmeLearningObjectives(event.learningObjectives);
    final description = event.description?.trim();
    final hasDescription = description != null && description.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasDescription) ...[
          Text('About this activity', style: theme.titleSmall),
          const SizedBox(height: 8),
          Text(description, style: theme.bodyMedium),
          const SizedBox(height: 16),
        ],
        if (objectives.isNotEmpty) ...[
          Text('Learning objectives', style: theme.titleSmall),
          const SizedBox(height: 8),
          for (final objective in objectives)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline, size: 18, color: theme.primary),
                  const SizedBox(width: 10),
                  Expanded(child: Text(objective, style: theme.bodyMedium)),
                ],
              ),
            ),
        ],
        if (!hasDescription && objectives.isEmpty)
          Text('No description available.', style: theme.bodySecondary),
        if (event.accreditationBody != null || event.creditAmount != null) ...[
          const SizedBox(height: 16),
          Text('Accreditation', style: theme.titleSmall),
          const SizedBox(height: 8),
          Text(
            [
              if (event.accreditationBody != null) 'Accredited by ${event.accreditationBody}',
              if (event.creditAmount != null) event.displayCredits,
            ].join(' · '),
            style: theme.bodyMedium,
          ),
        ],
      ],
    );
  }
}

class _AgendaPanel extends StatelessWidget {
  const _AgendaPanel({required this.segments});

  final List<CmeSegment> segments;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    if (segments.isEmpty) {
      return Text('No agenda segments yet.', style: theme.bodySecondary);
    }
    return Column(
      children: [
        for (var i = 0; i < segments.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: theme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${segments[i].sequenceOrder ?? i + 1}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      color: theme.primary,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(segments[i].title ?? 'Segment', style: theme.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                      if (segments[i].description != null)
                        Text(segments[i].description!, style: theme.caption),
                      if (segments[i].durationMinutes != null)
                        Text('${segments[i].durationMinutes} min', style: theme.caption),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SpeakersPanel extends StatelessWidget {
  const _SpeakersPanel({required this.speakers});

  final List<CmeSpeaker> speakers;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    if (speakers.isEmpty) {
      return Text('No speakers listed.', style: theme.bodySecondary);
    }
    return Column(
      children: speakers.map((s) => CmeSpeakerTile(speaker: s, compact: true)).toList(),
    );
  }
}

class _FeedbackPanel extends StatefulWidget {
  const _FeedbackPanel({
    required this.eventId,
    required this.event,
    this.onSubmitted,
  });

  final String eventId;
  final CmeEventData event;
  final VoidCallback? onSubmitted;

  @override
  State<_FeedbackPanel> createState() => _FeedbackPanelState();
}

class _FeedbackPanelState extends State<_FeedbackPanel> {
  int _overall = 5;
  int _content = 5;
  int _presenter = 5;
  int _relevance = 5;
  final _comments = TextEditingController();
  bool _submitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _comments.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await CmeNodeApiService.submitFeedback(
        widget.eventId,
        overallRating: _overall,
        contentQuality: _content,
        presenterEffectiveness: _presenter,
        relevanceToPractice: _relevance,
        comments: _comments.text.trim().isEmpty ? null : _comments.text.trim(),
      );
      if (mounted) {
        setState(() => _submitted = true);
        widget.onSubmitted?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final progress = widget.event.learnerProgress;
    final canSubmit = widget.event.capabilities?.canLeaveFeedback == true;

    if (_submitted || progress?.feedbackSubmitted == true) {
      return Text(
        'Thank you — your evaluation has been submitted.',
        style: TextStyle(color: theme.success, fontFamily: 'Poppins'),
      );
    }
    if (!canSubmit) {
      final blocker = cmeProgressBlockerMessage(widget.event);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            blocker ??
                'Complete the earlier steps in your progress tracker to unlock the evaluation.',
            style: theme.bodySecondary.copyWith(height: 1.4),
          ),
          if (blocker != null && widget.event.learnerProgress?.quizPendingReview == true) ...[
            const SizedBox(height: 12),
            Text(
              'You finished the session — credit is waiting on quiz approval.',
              style: theme.caption.copyWith(color: theme.textTertiary),
            ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your feedback is required to claim credit (~2 minutes).',
          style: theme.bodyMedium,
        ),
        const SizedBox(height: 16),
        _StarRow(label: 'Overall', value: _overall, onChanged: (v) => setState(() => _overall = v)),
        _StarRow(label: 'Content quality', value: _content, onChanged: (v) => setState(() => _content = v)),
        _StarRow(label: 'Presenter', value: _presenter, onChanged: (v) => setState(() => _presenter = v)),
        _StarRow(label: 'Relevance', value: _relevance, onChanged: (v) => setState(() => _relevance = v)),
        const SizedBox(height: 12),
        TextField(
          controller: _comments,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Comments (optional)',
            border: OutlineInputBorder(borderRadius: theme.radiusM),
          ),
        ),
        const SizedBox(height: 14),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primary,
            foregroundColor: theme.buttonPrimaryText,
          ),
          child: _submitting
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.buttonPrimaryText,
                  ),
                )
              : const Text('Submit evaluation', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.label, required this.value, required this.onChanged});

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.bodyMedium)),
          for (var n = 1; n <= 5; n++)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () => onChanged(n),
              icon: Icon(
                n <= value ? Icons.star_rounded : Icons.star_outline_rounded,
                color: n <= value ? theme.warning : theme.textTertiary,
                size: 22,
              ),
            ),
        ],
      ),
    );
  }
}
