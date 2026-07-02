import 'package:doctak_app/data/apiClient/cme/cme_node_api_service.dart';
import 'package:doctak_app/routes/app_navigator.dart';
import 'package:doctak_app/data/models/cme/cme_event_model.dart';
import 'package:doctak_app/presentation/cme_module/bloc/cme_event_detail_bloc.dart';
import 'package:doctak_app/presentation/cme_module/bloc/cme_event_detail_event.dart';
import 'package:doctak_app/presentation/cme_module/bloc/cme_event_detail_state.dart';
import 'package:doctak_app/presentation/cme_module/screens/cme_event_creation_screen.dart';
import 'package:doctak_app/presentation/cme_module/utils/cme_live_join.dart';
import 'package:doctak_app/presentation/cme_module/screens/cme_on_demand_screen.dart';
import 'package:doctak_app/presentation/cme_module/screens/cme_quiz_screen.dart';
import 'package:doctak_app/presentation/cme_module/utils/cme_event_certificate_flow.dart';
import 'package:doctak_app/presentation/cme_module/widgets/cme_certificate_bottom_sheet.dart';
import 'package:doctak_app/presentation/cme_module/utils/cme_progress.dart';
import 'package:doctak_app/presentation/cme_module/widgets/cme_credit_badge.dart';
import 'package:doctak_app/presentation/cme_module/widgets/cme_event_detail_shared.dart';
import 'package:doctak_app/presentation/cme_module/widgets/cme_event_detail_tabs.dart';
import 'package:doctak_app/presentation/cme_module/widgets/cme_progress_stepper.dart';
import 'package:doctak_app/presentation/cme_module/widgets/cme_shimmer_loader.dart';
import 'package:doctak_app/presentation/cme_module/widgets/cme_status_badge.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/app_cached_network_image.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class CmeEventDetailScreen extends StatelessWidget {
  const CmeEventDetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CmeEventDetailBloc()
        ..add(CmeLoadEventDetailEvent(eventId: eventId)),
      child: _CmeEventDetailView(eventId: eventId),
    );
  }
}

class _CmeEventDetailView extends StatefulWidget {
  const _CmeEventDetailView({required this.eventId});

  final String eventId;

  @override
  State<_CmeEventDetailView> createState() => _CmeEventDetailViewState();
}

class _CmeEventDetailViewState extends State<_CmeEventDetailView> {
  final _tabsKey = GlobalKey<CmeEventDetailTabsState>();
  bool _certificateSheetPrompted = false;

  void _maybeOpenCertificateSheet(BuildContext context, CmeEventData event) {
    if (_certificateSheetPrompted) return;
    final lp = event.learnerProgress;
    if (!cmeIsRegistered(event)) return;
    if (lp?.feedbackSubmitted != true) return;
    final certId = lp?.certificateId;
    if (certId != null && certId.isNotEmpty) return;

    _certificateSheetPrompted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) return;
      await openEventCertificateSheet(context, eventId: widget.eventId);
      if (!context.mounted) return;
      context.read<CmeEventDetailBloc>().add(
            CmeLoadEventDetailEvent(eventId: widget.eventId, silent: true),
          );
    });
  }

  Future<void> _onFeedbackSubmitted(BuildContext context) async {
    _certificateSheetPrompted = true;
    context.read<CmeEventDetailBloc>().add(
          CmeLoadEventDetailEvent(eventId: widget.eventId, silent: true),
        );
    if (!context.mounted) return;
    await openEventCertificateSheet(context, eventId: widget.eventId);
    if (!context.mounted) return;
    context.read<CmeEventDetailBloc>().add(
          CmeLoadEventDetailEvent(eventId: widget.eventId, silent: true),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      body: BlocConsumer<CmeEventDetailBloc, CmeEventDetailState>(
        listener: (context, state) {
          if (state is CmeRegistrationSuccessState) {
            _snack(context, state.message, theme.success);
          } else if (state is CmeRegistrationErrorState) {
            _snack(context, state.message, theme.error);
          } else if (state is CmeWaitlistJoinedState) {
            _snack(context, state.message, theme.warning);
          } else if (state is CmeEventDetailLoadedState) {
            final event = context.read<CmeEventDetailBloc>().eventData;
            if (event != null) _maybeOpenCertificateSheet(context, event);
          }
        },
        builder: (context, state) {
          if (state is CmeEventDetailLoadingState) {
            return const CmeEventDetailShimmer();
          }
          if (state is CmeEventDetailErrorState) {
            return _buildError(context, theme, state.errorMessage);
          }

          final event = context.read<CmeEventDetailBloc>().eventData;
          if (event == null) {
            return const CmeEventDetailShimmer();
          }

          return CustomScrollView(
            slivers: [
              _buildAppBar(context, theme, event),
              SliverToBoxAdapter(child: _buildContent(context, theme, event)),
            ],
          );
        },
      ),
    );
  }

  void _snack(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, OneUITheme theme, CmeEventData event) {
    return DoctakSliverAppBar(
      title: event.title ?? 'Event Details',
      expandedHeight: 220,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: event.bannerImage != null || event.thumbnail != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  AppCachedNetworkImage(
                    imageUrl: event.bannerImage ?? event.thumbnail ?? '',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                      ),
                    ),
                  ),
                  if (event.isLive)
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 56,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.error,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.fiber_manual_record, size: 10, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              'LIVE NOW',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              )
            : Container(color: theme.primary.withValues(alpha: 0.1)),
      ),
    );
  }

  static const _sectionGap = 16.0;
  static const _contentPadding = EdgeInsets.fromLTRB(16, 16, 16, 40);

  Widget _buildContent(BuildContext context, OneUITheme theme, CmeEventData event) {
    final bloc = context.read<CmeEventDetailBloc>();
    final isRegistered = cmeIsRegistered(event);

    return Padding(
      padding: _contentPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSummaryCard(theme, event),
          const SizedBox(height: _sectionGap),
          _buildActionButtons(context, theme, event, bloc),
          if (event.showLearnerProgress && isRegistered) ...[
            const SizedBox(height: _sectionGap),
            CmeProgressStepper(
              event: event,
              onStepTap: (stepId) => _openStep(context, event, stepId, bloc),
              onAction: () => _handleProgressAction(context, event, bloc),
            ),
          ],
          if (event.canManage == true) ...[
            const SizedBox(height: _sectionGap),
            _buildHostManagementCard(context, theme, event),
          ],
          const SizedBox(height: _sectionGap),
          CmeEventDetailTabs(
            key: _tabsKey,
            event: event,
            eventId: widget.eventId,
            onOpenQuiz: () => _openQuiz(context, event),
            onMutate: () => context.read<CmeEventDetailBloc>().add(
                  CmeLoadEventDetailEvent(eventId: widget.eventId, silent: true),
                ),
            onFeedbackSubmitted: () => _onFeedbackSubmitted(context),
          ),
        ],
      ),
    );
  }

  bool _hasEventMeta(CmeEventData event) {
    return event.startDate != null ||
        event.venue != null ||
        event.location != null ||
        event.maxParticipants != null ||
        event.creditAmount != null;
  }

  Widget _buildSummaryCard(OneUITheme theme, CmeEventData event) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: theme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (event.displayStatus != null)
                CmeStatusBadge(
                  status: cmeLearnerCreditInProgress(event) && event.isCompleted
                      ? 'credit_pending'
                      : event.displayStatus!,
                ),
              if (event.creditType != null || event.creditAmount != null)
                CmeCreditBadge(
                  creditType: event.creditType ?? 'CME',
                  creditAmount: event.creditAmount,
                ),
              if (event.format != null) _formatBadge(theme, event.format!),
            ],
          ),
          const SizedBox(height: 12),
          Text(event.title ?? '', style: theme.titleLarge),
          if (event.organizer != null) ...[
            const SizedBox(height: 10),
            CmeOrganizerRow(organizer: event.organizer!),
          ],
          if (_hasEventMeta(event)) ...[
            const SizedBox(height: 14),
            Divider(color: theme.border.withValues(alpha: 0.55), height: 1),
            const SizedBox(height: 8),
            if (event.startDate != null)
              CmeEventDetailRow(
                icon: Icons.calendar_today_outlined,
                label: 'Date',
                value: formatCmeEventDateRange(event),
              ),
            if (event.venue != null || event.location != null)
              CmeEventDetailRow(
                icon: Icons.location_on_outlined,
                label: 'Location',
                value: [event.venue, event.location]
                    .where((e) => e != null && e.toString().isNotEmpty)
                    .join(', '),
              ),
            if (event.maxParticipants != null)
              CmeEventDetailRow(
                icon: Icons.people_outline,
                label: 'Capacity',
                value: '${event.currentParticipants ?? 0} / ${event.maxParticipants} registered',
              ),
          ],
        ],
      ),
    );
  }

  void _openStep(
    BuildContext context,
    CmeEventData event,
    String stepId,
    CmeEventDetailBloc bloc,
  ) {
    final steps = buildCmeProgressSteps(event);
    CmeProgressStep? tapped;
    for (final step in steps) {
      if (step.id == stepId) {
        tapped = step;
        break;
      }
    }
    if (tapped == null || tapped.state == CmeProgressStepState.upcoming) return;

    if (tapped.state == CmeProgressStepState.current) {
      _handleProgressAction(context, event, bloc);
      return;
    }

    switch (stepId) {
      case 'attend':
        if (cmeIsRecordedEvent(event)) {
          AppNavigator.push(context, CmeOnDemandScreen(eventId: widget.eventId));
        } else if (event.isLive && event.isVirtualType) {
          _joinMeeting(context, event);
        }
        break;
      case 'quiz':
        _openQuiz(context, event);
        break;
      case 'feedback':
        _tabsKey.currentState?.openTab(CmeDetailTab.feedback);
        break;
      case 'certificate':
        openEventCertificateSheet(context, eventId: widget.eventId).then((_) {
          if (context.mounted) {
            bloc.add(CmeLoadEventDetailEvent(eventId: widget.eventId, silent: true));
          }
        });
        break;
    }
  }

  void _handleProgressAction(BuildContext context, CmeEventData event, CmeEventDetailBloc bloc) {
    final action = resolveCmeProgressAction(event);
    switch (action.kind) {
      case CmeProgressActionKind.register:
        bloc.add(CmeRegisterEvent(eventId: event.id!));
        break;
      case CmeProgressActionKind.join:
        _joinMeeting(context, event);
        break;
      case CmeProgressActionKind.onDemand:
        AppNavigator.push(context, CmeOnDemandScreen(eventId: widget.eventId));
        break;
      case CmeProgressActionKind.quiz:
        _openQuiz(context, event);
        break;
      case CmeProgressActionKind.feedback:
        _tabsKey.currentState?.openTab(CmeDetailTab.feedback);
        break;
      case CmeProgressActionKind.certificate:
        final existingId = event.learnerProgress?.certificateId;
        if (existingId != null && existingId.isNotEmpty) {
          showCmeCertificateBottomSheet(context, certificateId: existingId).then((_) {
            if (context.mounted) {
              bloc.add(CmeLoadEventDetailEvent(eventId: widget.eventId, silent: true));
            }
          });
        } else {
          openEventCertificateSheet(context, eventId: widget.eventId).then((_) {
            if (context.mounted) {
              bloc.add(CmeLoadEventDetailEvent(eventId: widget.eventId, silent: true));
            }
          });
        }
        break;
      case CmeProgressActionKind.none:
        break;
    }
  }

  void _openQuiz(BuildContext context, CmeEventData event) {
    AppNavigator.push(
      context,
      CmeQuizScreen(
        eventId: widget.eventId,
        moduleId: event.primaryQuizTarget?.moduleId,
        quizTitle: event.primaryQuizTarget?.title,
      ),
    ).then((_) {
      if (context.mounted) {
        context.read<CmeEventDetailBloc>().add(
              CmeLoadEventDetailEvent(eventId: widget.eventId, silent: true),
            );
      }
    });
  }

  Future<void> _joinMeeting(BuildContext context, CmeEventData event) async {
    final joined = await joinCmeLiveMeeting(context, eventId: event.id!);
    if (!context.mounted || !joined) return;
    context.read<CmeEventDetailBloc>().add(
          CmeLoadEventDetailEvent(eventId: event.id!, silent: true),
        );
  }

  Widget _buildActionButtons(
    BuildContext context,
    OneUITheme theme,
    CmeEventData event,
    CmeEventDetailBloc bloc,
  ) {
    final isRegistered = cmeIsRegistered(event);
    final canRegister = event.capabilities?.canRegister ?? !isRegistered;
    final canStartLive = event.capabilities?.canStartLive == true;
    final canJoin = !((event.capabilities?.liveSessionEnded ?? false)) &&
        (event.capabilities?.canJoinLive ??
            (event.isLive && isRegistered && event.isVirtualType));
    final showLiveAction = canJoin || canStartLive;
    final liveLabel = canStartLive && !canJoin
        ? (event.isLive ? 'Join Live Meeting' : 'Start Live Meeting')
        : 'Join Live';

    if (canStartLive) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showLiveAction) _liveBanner(theme, forProvider: !canJoin),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _joinMeeting(context, event),
              icon: const Icon(Icons.videocam, size: 18),
              label: Text(
                liveLabel,
                style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: theme.radiusM),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Opens the shared meeting room so registered learners can join.',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: theme.textSecondary),
          ),
        ],
      );
    }

    return Column(
      children: [
        if (showLiveAction) _liveBanner(theme),
        Row(
          children: [
            Expanded(child: _registrationButton(context, theme, event, bloc, isRegistered, canRegister)),
            if (canJoin) ...[
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () => _joinMeeting(context, event),
                icon: const Icon(Icons.videocam, size: 18),
                label: const Text('Join Live', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: theme.radiusM),
                ),
              ),
            ],
          ],
        ),
        if (event.isBeforeSession && isRegistered && event.isVirtualType)
          _upcomingNotice(theme, event),
      ],
    );
  }

  Widget _registrationButton(
    BuildContext context,
    OneUITheme theme,
    CmeEventData event,
    CmeEventDetailBloc bloc,
    bool isRegistered,
    bool canRegister,
  ) {
    if (event.isCompleted || event.isCancelled) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.textTertiary.withValues(alpha: 0.2),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: theme.radiusM),
        ),
        child: Text(
          event.isCompleted ? 'Event Ended' : 'Event Cancelled',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: theme.textTertiary),
        ),
      );
    }

    if ((event.capabilities?.liveSessionEnded == true) && !isRegistered) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.textTertiary.withValues(alpha: 0.2),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: theme.radiusM),
        ),
        child: Text(
          'Registration closed',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: theme.textTertiary),
        ),
      );
    }

    if (isRegistered) {
      return OutlinedButton.icon(
        onPressed: () => bloc.add(CmeUnregisterEvent(eventId: event.id!)),
        icon: const Icon(Icons.check_circle, size: 18),
        label: const Text('Registered', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.success,
          side: BorderSide(color: theme.success),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: theme.radiusM),
        ),
      );
    }

    if (event.isFull || event.capabilities?.registrationFull == true) {
      return ElevatedButton.icon(
        onPressed: () => bloc.add(CmeJoinWaitlistEvent(eventId: event.id!)),
        icon: const Icon(Icons.hourglass_empty, size: 18),
        label: const Text('Join Waitlist', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.warning,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: theme.radiusM),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: canRegister ? () => bloc.add(CmeRegisterEvent(eventId: event.id!)) : null,
      icon: const Icon(Icons.app_registration, size: 18),
      label: const Text('Register Now', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: theme.radiusM),
      ),
    );
  }

  Widget _liveBanner(OneUITheme theme, {bool forProvider = false}) {
    final message = forProvider
        ? 'READY TO GO LIVE — Start the session for registered learners'
        : 'LIVE NOW — Session is in progress';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [theme.error, theme.error.withValues(alpha: 0.8)]),
        borderRadius: theme.radiusM,
      ),
      child: Row(
        children: [
          const Icon(Icons.fiber_manual_record, size: 10, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _upcomingNotice(OneUITheme theme, CmeEventData event) {
    final start = event.startDate != null ? DateTime.tryParse(event.startDate!) : null;
    final label = start != null
        ? DateFormat('MMM d, yyyy – h:mm a').format(start.toLocal())
        : 'Soon';

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.warning.withValues(alpha: 0.1),
        borderRadius: theme.radiusM,
        border: Border.all(color: theme.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, size: 18, color: theme.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Session starts $label',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w500, color: theme.warning),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHostManagementCard(BuildContext context, OneUITheme theme, CmeEventData event) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: theme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.admin_panel_settings, size: 18, color: theme.primary),
              const SizedBox(width: 8),
              Text('Host Management', style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600, color: theme.primary)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (!event.isCompleted)
                _hostChip(theme, icon: Icons.edit_outlined, label: 'Edit Event', onTap: () async {
                  final result = await AppNavigator.push(
                    context,
                    CmeEventCreationScreen(eventId: event.id?.toString(), initialData: _editPayload(event)),
                  );
                  if (result == true && context.mounted) {
                    context.read<CmeEventDetailBloc>().add(CmeLoadEventDetailEvent(eventId: widget.eventId));
                  }
                }),
              if (event.isVirtualType &&
                  !event.isCompleted &&
                  event.capabilities?.canStartLive == true)
                _hostChip(
                  theme,
                  icon: Icons.videocam,
                  label: 'Start Live Meeting',
                  color: theme.error,
                  onTap: () => _joinMeeting(context, event),
                ),
              if (event.capabilities?.canEndLiveSession == true)
                _hostChip(
                  theme,
                  icon: Icons.stop_circle_outlined,
                  label: 'End Live Session',
                  color: theme.error,
                  onTap: () => _confirmEndLiveSession(context, theme, event),
                ),
              if (event.isCompleted)
                _hostChip(
                  theme,
                  icon: Icons.workspace_premium,
                  label: 'Generate Certificates',
                  color: theme.success,
                  onTap: () => openEventCertificateSheet(context, eventId: event.id!.toString(), generateForAllAttendees: true),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _hostChip(
    OneUITheme theme, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final chipColor = color ?? theme.primary;
    return ActionChip(
      avatar: Icon(icon, size: 16, color: chipColor),
      label: Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w500, color: chipColor)),
      onPressed: onTap,
      side: BorderSide(color: chipColor.withValues(alpha: 0.3)),
      backgroundColor: chipColor.withValues(alpha: 0.08),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _formatBadge(OneUITheme theme, String format) {
    final label = switch (format.toLowerCase()) {
      'in_person' => 'In person',
      'virtual' => 'Virtual',
      'hybrid' => 'Hybrid',
      'on_demand' => 'On demand',
      _ => format.replaceAll('_', ' '),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: theme.textTertiary.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: theme.textSecondary,
        ),
      ),
    );
  }

  Map<String, dynamic> _editPayload(CmeEventData event) => {
        'title': event.title,
        'description': event.description,
        'type': event.type,
        'format': event.format,
        'start_date': event.startDate,
        'end_date': event.endDate,
        'venue': event.venue,
        'location': event.location,
        'credit_type': event.creditType,
        'credit_amount': event.creditAmount,
        'accreditation_body': event.accreditationBody,
        'max_participants': event.maxParticipants,
        'registration_fee': event.registrationFee,
        'meeting_link': event.meetingLink,
        'learning_objectives': event.learningObjectives,
        'status': event.status,
        'banner_image': event.bannerImage,
        'thumbnail': event.thumbnail,
      };

  Future<void> _confirmEndLiveSession(
    BuildContext context,
    OneUITheme theme,
    CmeEventData event,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardBackground,
        title: Text('End live session?', style: theme.titleMedium),
        content: Text(
          'This permanently ends the live session. No one can join or send requests until you start a new one from this page.',
          style: theme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: theme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: theme.error),
            child: const Text('End session', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    try {
      await CmeNodeApiService.endLiveSession(event.id!.toString());
      if (!context.mounted) return;
      _snack(context, 'Live session ended', theme.success);
      context.read<CmeEventDetailBloc>().add(CmeLoadEventDetailEvent(eventId: widget.eventId));
    } catch (e) {
      if (context.mounted) _snack(context, 'Failed to end live session: $e', theme.error);
    }
  }

  Widget _buildError(BuildContext context, OneUITheme theme, String message) {
    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: const DoctakAppBar(title: 'Event Details'),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.textTertiary),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: theme.bodySecondary),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<CmeEventDetailBloc>().add(CmeLoadEventDetailEvent(eventId: widget.eventId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
