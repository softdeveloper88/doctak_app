import 'dart:async';

import 'package:doctak_app/data/apiClient/cme/cme_api_service.dart';
import 'package:doctak_app/routes/app_navigator.dart';
import 'package:doctak_app/data/models/cme/cme_chat_poll_model.dart';
import 'package:doctak_app/data/models/cme/cme_event_model.dart';
import 'package:doctak_app/presentation/cme_module/bloc/cme_live_interaction_bloc.dart';
import 'package:doctak_app/presentation/cme_module/bloc/cme_live_interaction_event.dart';
import 'package:doctak_app/presentation/cme_module/bloc/cme_live_interaction_state.dart';
import 'package:doctak_app/presentation/cme_module/screens/cme_quiz_screen.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CmeLiveInteractionScreen extends StatelessWidget {
  final String eventId;
  final String? eventTitle;
  final bool isHost;
  final List<CmeModule>? modules;
  final bool isEmbedded;

  const CmeLiveInteractionScreen({
    super.key,
    required this.eventId,
    this.eventTitle,
    this.isHost = false,
    this.modules,
    this.isEmbedded = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CmeLiveInteractionBloc()
        ..add(CmeLoadChatMessagesEvent(eventId: eventId))
        ..add(CmeLoadPollsEvent(eventId: eventId))
        ..add(CmeLoadParticipantsEvent(eventId: eventId))
        ..add(CmeJoinEventEvent(eventId: eventId)),
      child: _CmeLiveInteractionView(
        eventId: eventId,
        eventTitle: eventTitle,
        isHost: isHost,
        modules: modules,
        isEmbedded: isEmbedded,
      ),
    );
  }
}

class _CmeLiveInteractionView extends StatefulWidget {
  final String eventId;
  final String? eventTitle;
  final bool isHost;
  final List<CmeModule>? modules;
  final bool isEmbedded;

  const _CmeLiveInteractionView({
    required this.eventId,
    this.eventTitle,
    required this.isHost,
    this.modules,
    this.isEmbedded = false,
  });

  @override
  State<_CmeLiveInteractionView> createState() =>
      _CmeLiveInteractionViewState();
}

class _CmeLiveInteractionViewState extends State<_CmeLiveInteractionView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _chatController = TextEditingController();
  final _scrollController = ScrollController();
  CmeLiveInteractionBloc? _bloc;
  Timer? _timerRefresh;
  Timer? _participantRefresh;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Refresh timer display every second
    _timerRefresh = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    // Refresh participant count every 30 seconds
    _participantRefresh = Timer.periodic(const Duration(seconds: 30), (_) {
      _bloc?.add(CmeLoadParticipantsEvent(eventId: widget.eventId));
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bloc ??= context.read<CmeLiveInteractionBloc>();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatController.dispose();
    _scrollController.dispose();
    _timerRefresh?.cancel();
    _participantRefresh?.cancel();
    _bloc?.add(CmeLeaveEventEvent(eventId: widget.eventId));
    _bloc?.stopChatPolling();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final bloc = context.read<CmeLiveInteractionBloc>();

    final tabBar = TabBar(
      controller: _tabController,
      labelColor: theme.primary,
      unselectedLabelColor: theme.textTertiary,
      indicatorColor: theme.primary,
      dividerColor: theme.divider,
      labelStyle: const TextStyle(
          fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600),
      tabs: const [
        Tab(icon: Icon(Icons.chat_bubble_outline, size: 18), text: 'Chat'),
        Tab(icon: Icon(Icons.poll_outlined, size: 18), text: 'Polls'),
        Tab(icon: Icon(Icons.view_module_outlined, size: 18), text: 'Modules'),
      ],
    );

    final body = BlocListener<CmeLiveInteractionBloc, CmeLiveInteractionState>(
      listener: (context, state) {
        if (state is CmePollCreatedState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: theme.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state is CmeLiveInteractionErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildChatTab(theme),
          _buildPollsTab(theme),
          _buildModulesTab(theme),
        ],
      ),
    );

    // ─── Embedded mode (inside bottom sheet) ───
    if (widget.isEmbedded) {
      return Column(
        children: [
          Material(
            color: theme.cardBackground,
            child: tabBar,
          ),
          Expanded(child: body),
        ],
      );
    }

    // ─── Standalone mode (full screen) ───
    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: DoctakAppBar(
        title: widget.eventTitle ?? 'Live Session',
        subtitle: _buildSubtitleText(bloc),
        showOnlineIndicator: true,
        actions: [
          if (widget.isHost)
            _buildHostMenuButton(theme),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: tabBar,
        ),
      ),
      body: body,
    );
  }

  String _buildSubtitleText(CmeLiveInteractionBloc bloc) {
    return '${_formatDuration(bloc.sessionSeconds)}  •  ${bloc.totalParticipants} participants';
  }

  Widget _buildHostMenuButton(OneUITheme theme) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: theme.textPrimary),
      color: theme.cardBackground,
      surfaceTintColor: Colors.transparent,
      onSelected: (value) => _handleHostAction(value),
      itemBuilder: (_) => [
        _buildMenuItem(theme, 'mute_all', Icons.volume_off_outlined, 'Mute All'),
        _buildMenuItem(theme, 'manage_modules', Icons.view_module_outlined, 'Manage Modules'),
        _buildMenuItem(theme, 'manage_speakers', Icons.record_voice_over_outlined, 'Manage Speakers'),
        _buildMenuItem(theme, 'create_poll', Icons.poll_outlined, 'Create Poll'),
        _buildMenuItem(theme, 'participants', Icons.people_outline, 'Participants'),
        _buildMenuItem(theme, 'generate_certificates', Icons.workspace_premium_outlined, 'Generate Certificates'),
      ],
    );
  }

  PopupMenuItem<String> _buildMenuItem(
      OneUITheme theme, String value, IconData icon, String label) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.iconColor),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  fontFamily: 'Poppins', fontSize: 14, color: theme.textPrimary)),
        ],
      ),
    );
  }

  void _handleHostAction(String action) {
    switch (action) {
      case 'create_poll':
        _showCreatePollDialog();
        break;
      case 'participants':
        _showParticipantsSheet();
        break;
      case 'mute_all':
        _muteAllParticipants();
        break;
      case 'manage_modules':
        _showManageModulesSheet();
        break;
      case 'manage_speakers':
        _showManageSpeakersSheet();
        break;
      case 'generate_certificates':
        _generateCertificates();
        break;
    }
  }

  // ─── Create Poll Dialog ───

  void _showCreatePollDialog() {
    final theme = OneUITheme.of(context);
    final questionController = TextEditingController();
    final optionControllers = [TextEditingController(), TextEditingController()];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: theme.cardBackground,
              title: Text('Create Poll',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: theme.textPrimary)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: questionController,
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: theme.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Question',
                        labelStyle: TextStyle(fontFamily: 'Poppins', color: theme.textTertiary),
                        filled: true,
                        fillColor: theme.inputBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 14),
                    ...List.generate(optionControllers.length, (i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: optionControllers[i],
                                style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: theme.textPrimary),
                                decoration: InputDecoration(
                                  hintText: 'Option ${i + 1}',
                                  hintStyle: TextStyle(fontFamily: 'Poppins', color: theme.textTertiary),
                                  filled: true,
                                  fillColor: theme.inputBackground,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            if (optionControllers.length > 2)
                              IconButton(
                                icon: Icon(Icons.remove_circle_outline, color: Colors.red.shade400, size: 20),
                                onPressed: () {
                                  setDialogState(() {
                                    optionControllers[i].dispose();
                                    optionControllers.removeAt(i);
                                  });
                                },
                              ),
                          ],
                        ),
                      );
                    }),
                    if (optionControllers.length < 6)
                      TextButton.icon(
                        onPressed: () {
                          setDialogState(() {
                            optionControllers.add(TextEditingController());
                          });
                        },
                        icon: Icon(Icons.add, size: 18, color: theme.primary),
                        label: Text('Add Option',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: theme.primary)),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('Cancel',
                      style: TextStyle(fontFamily: 'Poppins', color: theme.textSecondary)),
                ),
                FilledButton(
                  onPressed: () {
                    final question = questionController.text.trim();
                    final options = optionControllers
                        .map((c) => c.text.trim())
                        .where((o) => o.isNotEmpty)
                        .toList();
                    if (question.isEmpty || options.length < 2) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Question and at least 2 options are required'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                    context.read<CmeLiveInteractionBloc>().add(
                      CmeCreatePollEvent(
                        eventId: widget.eventId,
                        question: question,
                        options: options,
                      ),
                    );
                    Navigator.pop(dialogContext);
                  },
                  style: FilledButton.styleFrom(backgroundColor: theme.primary),
                  child: const Text('Create', style: TextStyle(fontFamily: 'Poppins')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ─── Participants Sheet ───

  void _showParticipantsSheet() {
    final theme = OneUITheme.of(context);
    final bloc = context.read<CmeLiveInteractionBloc>();
    bloc.add(CmeLoadParticipantsEvent(eventId: widget.eventId));

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return BlocProvider.value(
          value: bloc,
          child: BlocBuilder<CmeLiveInteractionBloc, CmeLiveInteractionState>(
            builder: (context, state) {
              final participants = bloc.participants;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Text(
                          'Participants (${bloc.totalParticipants})',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: theme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  SizedBox(
                    height: 300,
                    child: participants.isEmpty
                        ? Center(
                            child: Text('No participants yet',
                                style: theme.bodySecondary),
                          )
                        : ListView.builder(
                            itemCount: participants.length,
                            itemBuilder: (_, i) {
                              final p = participants[i];
                              return ListTile(
                                leading: CircleAvatar(
                                  radius: 18,
                                  backgroundImage: p['profile_pic'] != null
                                      ? NetworkImage(p['profile_pic'])
                                      : null,
                                  child: p['profile_pic'] == null
                                      ? const Icon(Icons.person, size: 18)
                                      : null,
                                ),
                                title: Text(
                                  p['name'] ?? 'User',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    color: theme.textPrimary,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // ─── Mute All ───

  void _muteAllParticipants() {
    final theme = OneUITheme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('All participants have been muted'),
        backgroundColor: theme.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── Generate Certificates ───

  void _generateCertificates() {
    final theme = OneUITheme.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.cardBackground,
        title: Text('Generate Certificates?',
            style: TextStyle(fontFamily: 'Poppins', color: theme.textPrimary)),
        content: Text(
          'This will generate certificates for all eligible attendees. This action cannot be undone.',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: theme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel',
                style: TextStyle(fontFamily: 'Poppins', color: theme.textSecondary)),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                final result =
                    await CmeApiService.generateCertificates(widget.eventId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message'] ?? 'Certificates generated'),
                      backgroundColor: theme.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed: $e'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Generate', style: TextStyle(fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
  }

  // ─── Manage Speakers Sheet ───

  void _showManageSpeakersSheet() {
    final theme = OneUITheme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.8,
        minChildSize: 0.3,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Speakers',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.textPrimary)),
            ),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: CmeApiService.getSpeakers(widget.eventId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final speakers = snapshot.data ?? [];
                  if (speakers.isEmpty) {
                    return Center(
                      child: Text('No speakers assigned',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              color: theme.textTertiary)),
                    );
                  }
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: speakers.length,
                    itemBuilder: (_, i) {
                      final s = speakers[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: s['profile_pic'] != null
                              ? NetworkImage(s['profile_pic'])
                              : null,
                          child: s['profile_pic'] == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(s['name'] ?? '',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                color: theme.textPrimary)),
                        subtitle: Text(s['topic'] ?? s['role'] ?? 'Speaker',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: theme.textTertiary)),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Manage Modules Sheet (host can switch active module) ───

  void _showManageModulesSheet() {
    final theme = OneUITheme.of(context);
    final modules = widget.modules ?? [];
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Switch Module',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.textPrimary)),
            const SizedBox(height: 12),
            if (modules.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text('No modules available',
                      style: TextStyle(
                          fontFamily: 'Poppins', color: theme.textTertiary)),
                ),
              )
            else
              ...modules.map((m) => ListTile(
                    leading: Icon(Icons.view_module,
                        color: (m.isActive ?? false)
                            ? theme.primary
                            : theme.textTertiary),
                    title: Text(m.title ?? 'Module',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            color: theme.textPrimary,
                            fontWeight: (m.isActive ?? false)
                                ? FontWeight.w600
                                : FontWeight.normal)),
                    trailing: (m.isActive ?? false)
                        ? Icon(Icons.check_circle, color: theme.primary)
                        : null,
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      try {
                        await CmeApiService.switchModule(
                            widget.eventId, m.id ?? '');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('Switched to ${m.title ?? "module"}'),
                              backgroundColor: theme.success,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed: $e'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                  )),
          ],
        ),
      ),
    );
  }

  // ─── Chat Tab ───

  Widget _buildChatTab(OneUITheme theme) {
    return Column(
      children: [
        Expanded(
          child: BlocBuilder<CmeLiveInteractionBloc, CmeLiveInteractionState>(
            builder: (context, state) {
              final bloc = context.read<CmeLiveInteractionBloc>();

              if (state is CmeChatLoadingState && bloc.chatMessages.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (bloc.chatMessages.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 48, color: theme.textTertiary),
                      const SizedBox(height: 12),
                      Text('No messages yet', style: theme.bodySecondary),
                      Text('Be the first to say something!',
                          style: theme.caption),
                    ],
                  ),
                );
              }

              return ListView.builder(
                controller: _scrollController,
                reverse: true,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                itemCount: bloc.chatMessages.length,
                itemBuilder: (_, index) {
                  final msg = bloc
                      .chatMessages[bloc.chatMessages.length - 1 - index];
                  return _buildChatBubble(theme, msg);
                },
              );
            },
          ),
        ),
        _buildChatInput(theme),
      ],
    );
  }

  Widget _buildChatBubble(OneUITheme theme, CmeChatMessage msg) {
    final isOwn = msg.isOwn == true;

    return Align(
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isOwn
              ? theme.primary.withValues(alpha: 0.12)
              : theme.cardBackground,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: isOwn
                ? const Radius.circular(14)
                : const Radius.circular(4),
            bottomRight: isOwn
                ? const Radius.circular(4)
                : const Radius.circular(14),
          ),
          border: isOwn
              ? null
              : Border.all(color: theme.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment:
              isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isOwn)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    msg.userName ?? 'User',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.primary,
                    ),
                  ),
                  if (msg.isModerator || msg.isSpeaker) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: msg.isSpeaker
                            ? theme.warning.withValues(alpha: 0.15)
                            : theme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        msg.isSpeaker ? 'Speaker' : 'Host',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: msg.isSpeaker
                              ? theme.warning
                              : theme.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            if (!isOwn) const SizedBox(height: 3),
            Text(
              msg.message ?? '',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: theme.textPrimary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              _formatTime(msg.createdAt),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                color: theme.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatInput(OneUITheme theme) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        border: Border(top: BorderSide(color: theme.divider, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chatController,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: theme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(
                    fontFamily: 'Poppins', color: theme.textTertiary),
                filled: true,
                fillColor: theme.inputBackground,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    context.read<CmeLiveInteractionBloc>().add(
        CmeSendChatMessageEvent(eventId: widget.eventId, message: text));
    _chatController.clear();
  }

  // ─── Polls Tab ───

  Widget _buildPollsTab(OneUITheme theme) {
    return BlocConsumer<CmeLiveInteractionBloc, CmeLiveInteractionState>(
      listener: (context, state) {
        if (state is CmePollVotedState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: theme.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final bloc = context.read<CmeLiveInteractionBloc>();

        if (state is CmePollsLoadingState && bloc.polls.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (bloc.polls.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.poll_outlined,
                    size: 48, color: theme.textTertiary),
                const SizedBox(height: 12),
                Text('No polls yet', style: theme.bodySecondary),
                Text('Polls will appear when the host creates them',
                    style: theme.caption),
                if (widget.isHost) ...[
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _showCreatePollDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Create Poll',
                        style: TextStyle(fontFamily: 'Poppins')),
                    style: FilledButton.styleFrom(backgroundColor: theme.primary),
                  ),
                ],
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            bloc.add(CmeLoadPollsEvent(eventId: widget.eventId));
          },
          child: Column(
            children: [
              if (widget.isHost)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showCreatePollDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Create Poll',
                          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.primary,
                        side: BorderSide(color: theme.primary),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: bloc.polls.length,
                  itemBuilder: (_, index) =>
                      _buildPollCard(theme, bloc.polls[index]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPollCard(OneUITheme theme, CmePollData poll) {
    final hasVoted = poll.hasVoted == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: theme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  poll.question ?? '',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.textPrimary,
                  ),
                ),
              ),
              if (poll.isClosed)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.textTertiary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Closed',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: theme.textTertiary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          ...(poll.options ?? []).map(
            (option) => _buildPollOption(theme, poll, option),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '${poll.totalVotes ?? 0} votes',
                style: theme.caption,
              ),
              if (hasVoted) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline, size: 11, color: theme.success),
                      const SizedBox(width: 3),
                      Text(
                        'You voted',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: theme.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPollOption(
      OneUITheme theme, CmePollData poll, CmePollOption option) {
    final hasVoted = poll.hasVoted == true;
    final votedId = poll.votedOptionId;
    final isVoted = hasVoted &&
        votedId != null &&
        votedId.isNotEmpty &&
        (votedId == option.id || votedId == option.text);
    final pct = option.percentage ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: (!hasVoted && poll.isActive)
            ? () {
                context.read<CmeLiveInteractionBloc>().add(
                      CmeVotePollEvent(
                        eventId: widget.eventId,
                        pollId: poll.id!,
                        optionId: option.text ?? option.id!,
                      ),
                    );
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isVoted
                  ? theme.primary
                  : hasVoted
                      ? theme.border.withValues(alpha: 0.5)
                      : theme.border,
              width: isVoted ? 1.5 : 1,
            ),
            color: isVoted
                ? theme.primary.withValues(alpha: 0.06)
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Stack(
              children: [
                // Percentage fill bar (like X/Facebook)
                if (hasVoted)
                  Positioned.fill(
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: pct / 100,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isVoted
                              ? theme.primary.withValues(alpha: 0.12)
                              : theme.textTertiary.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                  ),
                // Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      if (isVoted)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Icon(Icons.check_circle,
                              size: 16, color: theme.primary),
                        )
                      else if (!hasVoted)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.textTertiary.withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          option.text ?? '',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight:
                                isVoted ? FontWeight.w600 : FontWeight.w400,
                            color: theme.textPrimary,
                          ),
                        ),
                      ),
                      if (hasVoted)
                        Text(
                          '${pct.toStringAsFixed(pct.truncateToDouble() == pct ? 0 : 1)}%',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isVoted ? theme.primary : theme.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Modules Tab ───

  Widget _buildModulesTab(OneUITheme theme) {
    final modules = widget.modules;

    if (modules == null || modules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.view_module_outlined,
                size: 48, color: theme.textTertiary),
            const SizedBox(height: 12),
            Text('No modules', style: theme.bodySecondary),
            Text('This event has no modules yet',
                style: theme.caption),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: modules.length,
      itemBuilder: (_, index) {
        final module = modules[index];
        return _buildModuleCard(theme, module, index + 1);
      },
    );
  }

  Widget _buildModuleCard(OneUITheme theme, CmeModule module, int number) {
    final hasQuiz = module.quiz?.id != null && module.quiz!.id!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: theme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                    '$number',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
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
                      module.title ?? 'Module $number',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.textPrimary,
                      ),
                    ),
                    if (module.description != null &&
                        module.description!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        module.description!,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: theme.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (module.duration != null || hasQuiz) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (module.duration != null) ...[
                  Icon(Icons.access_time, size: 14, color: theme.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    '${module.duration} min',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: theme.textTertiary,
                    ),
                  ),
                ],
                const Spacer(),
                if (hasQuiz)
                  TextButton.icon(
                    onPressed: () {
                      AppNavigator.push(
                        context,
                        CmeQuizScreen(
                          eventId: widget.eventId,
                          moduleId: module.id,
                          quizTitle: module.quiz?.title,
                        ),
                      );
                    },
                    icon: Icon(Icons.quiz_outlined, size: 16, color: theme.primary),
                    label: Text('Take Quiz',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.primary,
                        )),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return '';
    }
  }
}
