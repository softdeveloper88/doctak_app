import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/presentation/guideline_module/blocs/guideline_agent/guideline_agent_bloc.dart';
import 'package:doctak_app/presentation/guideline_module/data/models/guideline_chat_model.dart';
import 'package:doctak_app/presentation/guideline_module/data/models/guideline_source_model.dart';
import 'package:doctak_app/presentation/guideline_module/presentation/widgets/guideline_chat_input.dart';
import 'package:doctak_app/presentation/guideline_module/presentation/widgets/guideline_message_bubble.dart';
import 'package:doctak_app/presentation/guideline_module/presentation/widgets/guideline_source_selector.dart';
import 'package:doctak_app/presentation/guideline_module/presentation/widgets/guideline_welcome_view.dart';
import 'package:doctak_app/presentation/guideline_module/presentation/widgets/guideline_history_sheet.dart';
import 'package:doctak_app/presentation/guideline_module/presentation/widgets/guideline_quota_banner.dart';
import 'package:doctak_app/presentation/subscription_screen/subscription_screen.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nb_utils/nb_utils.dart';

class GuidelineAgentScreen extends StatefulWidget {
  const GuidelineAgentScreen({super.key});

  @override
  State<GuidelineAgentScreen> createState() => _GuidelineAgentScreenState();
}

class _GuidelineAgentScreenState extends State<GuidelineAgentScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputController = TextEditingController();
  bool _showWelcome = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GuidelineAgentBloc>().add(LoadGuidelineData());
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(String message) {
    if (message.trim().isEmpty) return;
    setState(() => _showWelcome = false);
    context
        .read<GuidelineAgentBloc>()
        .add(SendGuidelineMessage(message: message.trim()));
    _inputController.clear();
    _scrollToBottom();
  }

  void _showSourceSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bloc = context.read<GuidelineAgentBloc>();
        final state = bloc.state;
        List<GuidelineSourceModel> sources = [];
        List<String> selected = bloc.selectedSources;

        if (state is GuidelineAgentReady) {
          sources = state.sources;
          selected = state.selectedSources;
        }

        return GuidelineSourceSelector(
          sources: sources,
          selectedSources: selected,
          onApply: (newSources) {
            bloc.add(SelectSources(sources: newSources));
          },
        );
      },
    );
  }

  void _showHistory() {
    final bloc = context.read<GuidelineAgentBloc>();
    final state = bloc.state;
    List<GuidelineChatSession> sessions = [];
    if (state is GuidelineAgentReady) {
      sessions = state.sessions;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return GuidelineHistorySheet(
          sessions: sessions,
          onSessionTap: (sessionId) {
            Navigator.pop(ctx);
            setState(() => _showWelcome = false);
            bloc.add(LoadSessionMessages(sessionId: sessionId));
          },
          onSessionDelete: (sessionId) {
            bloc.add(DeleteConversation(sessionId: sessionId));
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: _buildAppBar(theme),
      body: SafeArea(
        child: Column(
          children: [
            // Quota Banner
            BlocBuilder<GuidelineAgentBloc, GuidelineAgentState>(
              buildWhen: (prev, curr) {
                if (prev is GuidelineAgentReady && curr is GuidelineAgentReady) {
                  return prev.usage != curr.usage;
                }
                return true;
              },
              builder: (context, state) {
                if (state is GuidelineAgentReady && state.usage != null) {
                  return GuidelineQuotaBanner(
                    usage: state.usage!,
                    onUpgrade: () {
                      const SubscriptionScreen().launch(context);
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // Active sources bar
            _buildActiveSourcesBar(theme),

            // Main content
            Expanded(
              child: BlocConsumer<GuidelineAgentBloc, GuidelineAgentState>(
                listener: (context, state) {
                  if (state is GuidelineMessageReceived) {
                    _scrollToBottom();
                  }
                  if (state is GuidelineQuotaExceeded) {
                    _showQuotaDialog();
                  }
                  if (state is GuidelineMessageError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.errorMessage),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is GuidelineAgentLoading) {
                    return _buildLoadingView(theme);
                  }

                  if (state is GuidelineAgentError) {
                    return _buildErrorView(theme, state.message);
                  }

                  if (state is GuidelineAgentReady) {
                    if (_showWelcome && state.messages.isEmpty) {
                      return GuidelineWelcomeView(
                        topics: state.topics,
                        onTopicTap: (query) => _sendMessage(query),
                      );
                    }
                    return _buildChatView(theme, state);
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),

            // Suggestion chips
            BlocBuilder<GuidelineAgentBloc, GuidelineAgentState>(
              builder: (context, state) {
                if (state is GuidelineAgentReady &&
                    state.suggestions.isNotEmpty &&
                    state is! GuidelineMessageSending) {
                  return _buildSuggestionChips(theme, state.suggestions);
                }
                return const SizedBox.shrink();
              },
            ),

            // Chat input
            BlocBuilder<GuidelineAgentBloc, GuidelineAgentState>(
              builder: (context, state) {
                final isSending = state is GuidelineMessageSending;
                return GuidelineChatInput(
                  controller: _inputController,
                  isSending: isSending,
                  onSend: _sendMessage,
                  onAttachSource: _showSourceSelector,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(OneUITheme theme) {
    return AppBar(
      backgroundColor: theme.cardBackground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: theme.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF0A84FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.local_hospital_rounded,
              color: Color(0xFF0A84FF),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Medical Guideline Agent',
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF34C759),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'ONLINE • POWERED BY AI',
                      style: TextStyle(
                        color: theme.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.add, color: theme.textPrimary),
          tooltip: 'New Chat',
          onPressed: () {
            setState(() => _showWelcome = true);
            context.read<GuidelineAgentBloc>().add(StartNewChat());
          },
        ),
        IconButton(
          icon: Icon(Icons.history, color: theme.textPrimary),
          tooltip: 'Chat History',
          onPressed: _showHistory,
        ),
      ],
    );
  }

  Widget _buildActiveSourcesBar(OneUITheme theme) {
    return BlocBuilder<GuidelineAgentBloc, GuidelineAgentState>(
      builder: (context, state) {
        List<String> selected = ['WHO'];
        List<GuidelineSourceModel> allSources = [];
        if (state is GuidelineAgentReady) {
          selected = state.selectedSources;
          allSources = state.sources;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.cardBackground,
            border: Border(
              bottom: BorderSide(
                color: theme.border,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.bolt,
                size: 16,
                color: const Color(0xFF0A84FF),
              ),
              const SizedBox(width: 6),
              Text(
                'Active Context',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: selected.map((sourceName) {
                      // Find matching source for country info
                      final source = allSources.cast<GuidelineSourceModel?>().firstWhere(
                        (s) => s?.name == sourceName,
                        orElse: () => null,
                      );
                      final countryName = source?.country?.name;

                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A84FF).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF0A84FF).withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.public,
                                size: 12,
                                color: const Color(0xFF0A84FF),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                countryName != null
                                    ? '$sourceName ($countryName)'
                                    : sourceName,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF0A84FF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              InkWell(
                onTap: _showSourceSelector,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A84FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Change Sources',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChatView(OneUITheme theme, GuidelineAgentReady state) {
    final isSending = state is GuidelineMessageSending;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: state.messages.length + (isSending ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.messages.length && isSending) {
          return _buildTypingIndicator(theme);
        }
        final message = state.messages[index];
        return GuidelineMessageBubble(
          message: message,
          onFeedback: message.id != null && message.isAssistant
              ? (rating) {
                  context.read<GuidelineAgentBloc>().add(
                        SubmitMessageFeedback(
                          messageId: message.id!,
                          rating: rating,
                        ),
                      );
                }
              : null,
        );
      },
    );
  }

  Widget _buildTypingIndicator(OneUITheme theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 8, right: 60),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.cardBackground,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPulsingDot(0),
            const SizedBox(width: 4),
            _buildPulsingDot(1),
            const SizedBox(width: 4),
            _buildPulsingDot(2),
            const SizedBox(width: 8),
            Text(
              'Analyzing guidelines...',
              style: TextStyle(
                color: theme.textSecondary,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPulsingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF0A84FF),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuggestionChips(OneUITheme theme, List<String> suggestions) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: suggestions.map((suggestion) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: Text(
                  suggestion,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF0A84FF),
                  ),
                ),
                avatar: const Icon(
                  Icons.auto_awesome,
                  size: 14,
                  color: Color(0xFF0A84FF),
                ),
                backgroundColor: const Color(0xFF0A84FF).withOpacity(0.08),
                side: BorderSide(
                  color: const Color(0xFF0A84FF).withOpacity(0.2),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                onPressed: () => _sendMessage(suggestion),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLoadingView(OneUITheme theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF0A84FF),
            strokeWidth: 2.5,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading guideline sources...',
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(OneUITheme theme, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: theme.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                context.read<GuidelineAgentBloc>().add(LoadGuidelineData());
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A84FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuotaDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        final theme = OneUITheme.of(ctx);
        return AlertDialog(
          backgroundColor: theme.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.lock_outline,
                color: Color(0xFFFF9500),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Daily Limit Reached',
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            'You\'ve used all your free guideline queries for today. Upgrade to Pro for unlimited access to medical guidelines.',
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Maybe Later',
                style: TextStyle(color: theme.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                const SubscriptionScreen().launch(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A84FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Upgrade Now'),
            ),
          ],
        );
      },
    );
  }
}
