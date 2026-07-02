import 'package:doctak_app/data/apiClient/cme/cme_node_api_service.dart';
import 'package:doctak_app/data/models/cme/cme_event_model.dart';
import 'package:doctak_app/data/models/cme/cme_speaker_invitation_model.dart';
import 'package:doctak_app/presentation/cme_module/screens/cme_event_detail_screen.dart';
import 'package:doctak_app/presentation/cme_module/widgets/cme_event_card.dart';
import 'package:doctak_app/routes/app_navigator.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

class CmeSpeakingScreen extends StatefulWidget {
  const CmeSpeakingScreen({super.key, this.invitationsOnly = false});

  final bool invitationsOnly;

  @override
  State<CmeSpeakingScreen> createState() => _CmeSpeakingScreenState();
}

class _CmeSpeakingScreenState extends State<CmeSpeakingScreen> {
  bool loading = true;
  String? error;
  List<CmeSpeakerInvitation> invitations = [];
  List<CmeEventData> engagements = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final results = await Future.wait([
        CmeNodeApiService.getSpeakerInvitations(),
        if (!widget.invitationsOnly)
          CmeNodeApiService.listEvents(scope: 'speaking', limit: 30)
        else
          Future.value(NodeCmeEventsPage(items: [], total: 0)),
      ]);
      invitations = (results[0] as List<CmeSpeakerInvitation>)
          .where((i) => i.status == 'pending')
          .toList();
      if (!widget.invitationsOnly) {
        engagements = (results[1] as NodeCmeEventsPage).items;
      }
      if (mounted) setState(() => loading = false);
    } catch (e) {
      if (mounted) setState(() {
        error = '$e';
        loading = false;
      });
    }
  }

  Future<void> _respond(CmeSpeakerInvitation inv, bool accept) async {
    try {
      await CmeNodeApiService.respondSpeakerInvitation(inv.id, accept);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(accept ? 'Invitation accepted' : 'Invitation declined')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(error!, style: theme.bodySecondary, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _sectionHeader(theme, 'Pending invitations',
              'Accept or decline speaker requests'),
          if (invitations.isEmpty)
            _empty(theme, 'No pending invitations')
          else
            ...invitations.map((inv) => _invitationCard(theme, inv)),
          if (!widget.invitationsOnly) ...[
            const SizedBox(height: 16),
            _sectionHeader(theme, 'Confirmed engagements',
                'Activities where you are faculty'),
            if (engagements.isEmpty)
              _empty(theme, 'No confirmed speaking engagements yet')
            else
              ...engagements.map(
                (event) => CmeEventCard(
                  event: event,
                  onTap: () => AppNavigator.push(
                    context,
                    CmeEventDetailScreen(eventId: event.id ?? ''),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(OneUITheme theme, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.titleMedium),
          const SizedBox(height: 4),
          Text(subtitle, style: theme.bodySecondary),
        ],
      ),
    );
  }

  Widget _empty(OneUITheme theme, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(message, style: theme.bodySecondary),
    );
  }

  Widget _invitationCard(OneUITheme theme, CmeSpeakerInvitation inv) {
    final event = inv.event;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: theme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(event?.title ?? 'CME activity', style: theme.titleSmall),
          if (inv.role != null) ...[
            const SizedBox(height: 4),
            Text(inv.role!, style: theme.caption),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _respond(inv, false),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => _respond(inv, true),
                  style: FilledButton.styleFrom(backgroundColor: theme.primary),
                  child: const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
