import 'package:doctak_app/data/models/cme/cme_event_model.dart';
import 'package:doctak_app/presentation/cme_module/bloc/cme_event_detail_bloc.dart';
import 'package:doctak_app/presentation/cme_module/bloc/cme_event_detail_event.dart';
import 'package:doctak_app/presentation/cme_module/bloc/cme_event_detail_state.dart';
import 'package:doctak_app/presentation/cme_module/screens/cme_live_interaction_screen.dart';
import 'package:doctak_app/presentation/cme_module/screens/cme_live_meeting_screen.dart';
import 'package:doctak_app/presentation/cme_module/screens/cme_on_demand_screen.dart';
import 'package:doctak_app/presentation/cme_module/screens/cme_quiz_screen.dart';
import 'package:doctak_app/presentation/cme_module/widgets/cme_credit_badge.dart';
import 'package:doctak_app/presentation/cme_module/widgets/cme_status_badge.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/app_cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class CmeEventDetailScreen extends StatelessWidget {
  final String eventId;

  const CmeEventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CmeEventDetailBloc()
        ..add(CmeLoadEventDetailEvent(eventId: eventId)),
      child: _CmeEventDetailView(eventId: eventId),
    );
  }
}

class _CmeEventDetailView extends StatelessWidget {
  final String eventId;

  const _CmeEventDetailView({required this.eventId});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      body: BlocConsumer<CmeEventDetailBloc, CmeEventDetailState>(
        listener: (context, state) {
          if (state is CmeRegistrationSuccessState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: const Color(0xFF34C759),
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is CmeRegistrationErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: const Color(0xFFFF3B30),
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is CmeWaitlistJoinedState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: const Color(0xFFFF9500),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is CmeEventDetailLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CmeEventDetailErrorState) {
            return _buildError(context, theme, state.errorMessage);
          }

          final bloc = context.read<CmeEventDetailBloc>();
          final event = bloc.eventData;
          if (event == null) {
            return const Center(child: CircularProgressIndicator());
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

  Widget _buildAppBar(
      BuildContext context, OneUITheme theme, CmeEventData event) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: theme.cardBackground,
      foregroundColor: theme.textPrimary,
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
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                  if (event.isLive)
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 56,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3B30),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.fiber_manual_record,
                                size: 10, color: Colors.white),
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

  Widget _buildContent(
      BuildContext context, OneUITheme theme, CmeEventData event) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status + Credits row
          Row(
            children: [
              if (event.status != null) CmeStatusBadge(status: event.status!),
              const SizedBox(width: 8),
              if (event.creditType != null)
                CmeCreditBadge(
                  creditType: event.creditType!,
                  creditAmount: event.creditAmount,
                ),
              const Spacer(),
              if (event.format != null)
                Chip(
                  label: Text(event.format!.toUpperCase(),
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  side: BorderSide(
                      color: theme.textTertiary.withValues(alpha: 0.3)),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Title
          Text(event.title ?? '', style: theme.titleLarge),
          const SizedBox(height: 8),

          // Organizer
          if (event.organizer != null) ...[
            _buildOrganizerRow(theme, event.organizer!),
            const SizedBox(height: 16),
          ],

          // Action buttons
          _buildActionButtons(context, theme, event),
          // Chat & Polls button for registered users
          if (event.isRegistered == true || event.isRegistered == 1) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CmeLiveInteractionScreen(
                          eventId: event.id!,
                          eventTitle: event.title,
                          isHost: event.isHost == true || event.isHost == 1,
                          modules: event.modules,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.chat_outlined, size: 18),
                label: const Text('Chat & Polls',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.primary,
                  side: BorderSide(color: theme.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
          // On-Demand Content button for events with on-demand format
          if (event.id != null && event.format == 'on_demand') ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CmeOnDemandScreen(eventId: event.id!),
                    ),
                  );
                },
                icon: const Icon(Icons.play_circle_outline, size: 18),
                label: const Text('On-Demand Content',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.primary,
                  side: BorderSide(color: theme.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Details section
          _buildDetailsCard(theme, event),
          const SizedBox(height: 16),

          // Description
          if (event.description != null) ...[
            Text('About', style: theme.titleSmall),
            const SizedBox(height: 8),
            Text(event.description!, style: theme.bodyMedium),
            const SizedBox(height: 20),
          ],

          // Speakers
          if (event.speakers != null && event.speakers!.isNotEmpty) ...[
            Text('Speakers', style: theme.titleSmall),
            const SizedBox(height: 10),
            ...event.speakers!.map((s) => _buildSpeakerTile(theme, s)),
            const SizedBox(height: 20),
          ],

          // Modules
          if (event.modules != null && event.modules!.isNotEmpty) ...[
            Text('Modules', style: theme.titleSmall),
            const SizedBox(height: 10),
            ...event.modules!
                .asMap()
                .entries
                .map((e) => _buildModuleTile(context, theme, event, e.value, e.key + 1)),
            const SizedBox(height: 20),
          ],

          // Tags
          if (event.tags != null && event.tags!.isNotEmpty) ...[
            Text('Tags', style: theme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: event.tags!
                  .map((tag) => Chip(
                        label: Text(tag,
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                color: theme.textSecondary)),
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        side: BorderSide(
                            color: theme.textTertiary.withValues(alpha: 0.2)),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildOrganizerRow(OneUITheme theme, CmeOrganizer organizer) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: theme.primary.withValues(alpha: 0.1),
          backgroundImage: organizer.profilePic != null
              ? NetworkImage(organizer.profilePic!)
              : null,
          child: organizer.profilePic == null
              ? Icon(Icons.person, size: 16, color: theme.primary)
              : null,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              organizer.name ?? 'Organizer',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: theme.textPrimary,
              ),
            ),
            if (organizer.specialty != null)
              Text(organizer.specialty!, style: theme.caption),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(
      BuildContext context, OneUITheme theme, CmeEventData event) {
    final isRegistered =
        event.isRegistered == true || event.isRegistered == 1;

    return Row(
      children: [
        // Register / Unregister button
        Expanded(
          child: _buildRegistrationButton(context, theme, event, isRegistered),
        ),
        // Join meeting button (only for live events when registered)
        if (event.isLive && isRegistered) ...[
          const SizedBox(width: 10),
          _buildJoinMeetingButton(context, theme, event),
        ],
      ],
    );
  }

  Widget _buildRegistrationButton(BuildContext context, OneUITheme theme,
      CmeEventData event, bool isRegistered) {
    final bloc = context.read<CmeEventDetailBloc>();

    if (event.isCompleted || event.isCancelled) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.textTertiary.withValues(alpha: 0.2),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: theme.radiusM),
        ),
        child: Text(
          event.isCompleted ? 'Event Ended' : 'Event Cancelled',
          style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: theme.textTertiary),
        ),
      );
    }

    if (isRegistered) {
      return OutlinedButton.icon(
        onPressed: () =>
            bloc.add(CmeUnregisterEvent(eventId: event.id!)),
        icon: const Icon(Icons.check_circle, size: 18),
        label: const Text('Registered',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF34C759),
          side: const BorderSide(color: Color(0xFF34C759)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: theme.radiusM),
        ),
      );
    }

    if (event.isFull) {
      return ElevatedButton.icon(
        onPressed: () =>
            bloc.add(CmeJoinWaitlistEvent(eventId: event.id!)),
        icon: const Icon(Icons.hourglass_empty, size: 18),
        label: const Text('Join Waitlist',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF9500),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: theme.radiusM),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: () =>
          bloc.add(CmeRegisterEvent(eventId: event.id!)),
      icon: const Icon(Icons.app_registration, size: 18),
      label: const Text('Register Now',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
            borderRadius: theme.radiusM),
      ),
    );
  }

  Widget _buildJoinMeetingButton(
      BuildContext context, OneUITheme theme, CmeEventData event) {
    return ElevatedButton.icon(
      onPressed: () {
        context.read<CmeEventDetailBloc>().add(
              CmeJoinEventEvent(eventId: event.id!),
            );
        // Navigate to meeting screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CmeLiveMeetingScreen(
              eventId: event.id!,
              eventTitle: event.title,
              isHost: event.isHost == true || event.isHost == 1,
              modules: event.modules,
            ),
          ),
        );
      },
      icon: const Icon(Icons.videocam, size: 18),
      label: const Text('Join Live',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF3B30),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
            borderRadius: theme.radiusM),
      ),
    );
  }

  Widget _buildDetailsCard(OneUITheme theme, CmeEventData event) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: theme.cardDecoration,
      child: Column(
        children: [
          if (event.startDate != null)
            _detailRow(theme, Icons.calendar_today_outlined, 'Date',
                _formatDateRange(event)),
          if (event.venue != null || event.location != null)
            _detailRow(
                theme,
                Icons.location_on_outlined,
                'Location',
                [event.venue, event.city, event.country]
                    .where((e) => e != null)
                    .join(', ')),
          if (event.maxParticipants != null)
            _detailRow(theme, Icons.people_outline, 'Capacity',
                '${event.currentParticipants ?? 0} / ${event.maxParticipants} participants'),
          if (event.accreditationBody != null)
            _detailRow(theme, Icons.verified_outlined, 'Accreditation',
                '${event.accreditationBody} (${event.accreditationNumber ?? ''})'),
          if (event.registrationFee != null)
            _detailRow(theme, Icons.payment_outlined, 'Fee',
                '\$${event.registrationFee}'),
          if (event.registrationDeadline != null)
            _detailRow(theme, Icons.timer_outlined, 'Deadline',
                _formatDate(event.registrationDeadline!)),
          if (event.targetAudience != null)
            _detailRow(theme, Icons.groups_outlined, 'Audience',
                event.targetAudience!),
        ],
      ),
    );
  }

  Widget _detailRow(
      OneUITheme theme, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.textTertiary),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: Text(label, style: theme.caption),
          ),
          Expanded(
            child: Text(value, style: theme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeakerTile(OneUITheme theme, CmeSpeaker speaker) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: theme.cardDecoration,
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: theme.primary.withValues(alpha: 0.1),
            backgroundImage: speaker.profilePic != null
                ? NetworkImage(speaker.profilePic!)
                : null,
            child: speaker.profilePic == null
                ? Icon(Icons.person, size: 20, color: theme.primary)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  speaker.name ?? '',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.textPrimary,
                  ),
                ),
                if (speaker.title != null)
                  Text(speaker.title!, style: theme.caption),
                if (speaker.specialty != null)
                  Text(speaker.specialty!,
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: theme.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleTile(BuildContext context, OneUITheme theme, CmeEventData event, CmeModule module, int index) {
    return GestureDetector(
      onTap: module.quiz != null && module.quiz!.id != null
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CmeQuizScreen(
                    eventId: event.id!,
                    moduleId: module.id!,
                    quizId: module.quiz!.id!,
                    quizTitle: module.quiz!.title,
                  ),
                ),
              );
            }
          : null,
      child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: theme.cardDecoration,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$index',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  module.title ?? '',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: theme.textPrimary,
                  ),
                ),
                if (module.description != null)
                  Text(module.description!,
                      style: theme.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (module.duration != null)
            Text(
              '${module.duration} min',
              style: theme.caption,
            ),
          if (module.quiz != null) ...[
            const SizedBox(width: 8),
            Icon(Icons.quiz_outlined, size: 16, color: theme.primary),
          ],
        ],
      ),
    ),
    );
  }

  Widget _buildError(BuildContext context, OneUITheme theme, String message) {
    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: theme.cardBackground,
        foregroundColor: theme.textPrimary,
        title: const Text('Event Details',
            style: TextStyle(fontFamily: 'Poppins')),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.textTertiary),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center, style: theme.bodySecondary),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context
                  .read<CmeEventDetailBloc>()
                  .add(CmeLoadEventDetailEvent(eventId: eventId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateRange(CmeEventData event) {
    try {
      if (event.startDate == null) return '';
      final start = DateTime.parse(event.startDate!);
      final fmt = DateFormat('MMM d, yyyy · h:mm a');
      if (event.endDate != null) {
        final end = DateTime.parse(event.endDate!);
        return '${fmt.format(start)}\n→ ${fmt.format(end)}';
      }
      return fmt.format(start);
    } catch (_) {
      return event.startDate ?? '';
    }
  }

  String _formatDate(String dateStr) {
    try {
      return DateFormat('MMM d, yyyy').format(DateTime.parse(dateStr));
    } catch (_) {
      return dateStr;
    }
  }
}

/// Placeholder for meeting screen - will be replaced with full Agora integration
class CmeMeetingPlaceholder extends StatelessWidget {
  final CmeEventData event;
  const CmeMeetingPlaceholder({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: theme.cardBackground,
        foregroundColor: theme.textPrimary,
        title: Text(event.title ?? 'CME Meeting',
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 16)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_rounded, size: 64, color: theme.primary),
            const SizedBox(height: 16),
            Text('Live Meeting', style: theme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Channel: ${event.agoraChannel ?? 'cme_event_${event.uuid}'}',
              style: theme.caption,
            ),
            const SizedBox(height: 24),
            Text(
              'Meeting integration will connect\nto Agora calling module',
              textAlign: TextAlign.center,
              style: theme.bodySecondary,
            ),
          ],
        ),
      ),
    );
  }
}
