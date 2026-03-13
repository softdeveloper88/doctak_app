import 'dart:io';

import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/app/app_environment.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../bloc/discussion_detail_bloc.dart';
import '../bloc/create_discussion_bloc.dart';
import '../models/case_discussion_models.dart';
import '../repository/case_discussion_repository.dart';
import '../widgets/comment_card.dart';
import '../widgets/comment_input.dart';
import '../widgets/discussion_header.dart';
import '../widgets/shimmer_widgets.dart';
import 'create_discussion_screen.dart';
import 'package:doctak_app/presentation/subscription_screen/subscription_screen.dart';

/// Detail screen for a single case discussion.
/// Shows the full case header, AI summary section, timeline updates,
/// comments with sort tabs, reply support, and the comment input bar.
class DiscussionDetailScreen extends StatefulWidget {
  final int caseId;

  const DiscussionDetailScreen({super.key, required this.caseId});

  @override
  State<DiscussionDetailScreen> createState() => _DiscussionDetailScreenState();
}

class _DiscussionDetailScreenState extends State<DiscussionDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  late DiscussionDetailBloc _bloc;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    _bloc = context.read<DiscussionDetailBloc>();
    _bloc.add(LoadDiscussionDetail(widget.caseId));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final currentState = _bloc.state;
      if (currentState is DiscussionDetailLoaded &&
          currentState.hasMoreComments &&
          !currentState.isLoadingComments) {
        _bloc.add(LoadMoreComments());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return BlocBuilder<DiscussionDetailBloc, DiscussionDetailState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: theme.scaffoldBackground,
          appBar: DoctakAppBar(
            title: 'Case Discussion',
            actions: _buildAppBarActions(state, theme),
          ),
          body: _buildBody(state, theme),
          bottomNavigationBar: state is DiscussionDetailLoaded
              ? CommentInput(
                  onSubmit: (text, tags) {
                    _bloc.add(AddComment(
                      caseId: widget.caseId,
                      comment: text,
                      clinicalTags: tags.isNotEmpty ? tags.join(',') : null,
                    ));
                  },
                  isLoading: state.isAddingComment,
                )
              : null,
        );
      },
    );
  }

  List<Widget> _buildAppBarActions(
      DiscussionDetailState state, OneUITheme theme) {
    if (state is! DiscussionDetailLoaded) return [];
    final discussion = state.discussion;

    return [
      if (discussion.isOwner)
        IconButton(
          icon: Icon(Icons.edit_outlined, color: theme.textPrimary, size: 22),
          onPressed: () => _editCase(discussion),
          tooltip: 'Edit case',
        ),
      PopupMenuButton<String>(
        icon: Icon(Icons.more_vert, color: theme.textPrimary),
        onSelected: (value) {
          switch (value) {
            case 'share':
              _shareCase(discussion);
              break;
            case 'copy_link':
              _copyLink(discussion);
              break;
            case 'report':
              _reportCase(discussion);
              break;
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem(
            value: 'share',
            child: Row(
              children: [
                Icon(Icons.share_outlined, size: 18),
                SizedBox(width: 8),
                Text('Share'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'copy_link',
            child: Row(
              children: [
                Icon(Icons.link, size: 18),
                SizedBox(width: 8),
                Text('Copy link'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'report',
            child: Row(
              children: [
                Icon(Icons.flag_outlined, size: 18, color: Colors.orange),
                SizedBox(width: 8),
                Text('Report'),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  Widget _buildBody(DiscussionDetailState state, OneUITheme theme) {
    if (state is DiscussionDetailLoading) {
      return const CaseDiscussionDetailShimmer();
    }

    if (state is DiscussionDetailError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: theme.textTertiary),
              const SizedBox(height: 16),
              Text(
                state.message,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Poppins',
                  color: theme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  _bloc.add(LoadDiscussionDetail(widget.caseId));
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style:
                    OutlinedButton.styleFrom(foregroundColor: theme.primary),
              ),
            ],
          ),
        ),
      );
    }

    if (state is! DiscussionDetailLoaded) {
      return const SizedBox.shrink();
    }

    final discussion = state.discussion;
    final comments = state.comments;

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // ── Header ──
        SliverToBoxAdapter(
          child: DiscussionHeader(
            discussion: discussion,
            onLike: () {
              _bloc.add(ToggleLikeCase(discussion.id));
            },
            onBookmark: () {
              _bloc.add(ToggleBookmarkCase(discussion.id));
            },
            onFollow: () {
              _bloc.add(ToggleFollowCase(discussion.id));
            },
            onShare: () => _shareCase(discussion),
            onEdit: null,
          ),
        ),

        // ── AI Summary Section ──
        SliverToBoxAdapter(
          child: _AISummarySection(
            discussion: discussion,
            isGenerating: state.isGeneratingAI,
            aiNeedsUpgrade: state.aiNeedsUpgrade,
            aiErrorMessage: state.aiErrorMessage,
            onGenerate: () {
              _bloc.add(GenerateAISummary(discussion.id));
            },
            theme: theme,
          ),
        ),

        // ── Updates Timeline ──
        SliverToBoxAdapter(
          child: _UpdatesTimeline(
            updates: discussion.updates,
            theme: theme,
            isOwner: discussion.isOwner,
            caseId: discussion.id,
            bloc: _bloc,
          ),
        ),

        // ── Comments Header ──
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(
                  'Comments',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${discussion.commentsCount}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                      color: theme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Comments List ──
        if (state.isLoadingComments && comments.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          )
        else if (comments.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.chat_bubble_outline,
                        size: 40, color: theme.textTertiary),
                    const SizedBox(height: 12),
                    Text(
                      'No comments yet',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        color: theme.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Be the first to contribute your clinical insights.',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        color: theme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index >= comments.length) {
                  // Load More button
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: state.isLoadingComments
                        ? const Center(
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : OutlinedButton.icon(
                            onPressed: () {
                              _bloc.add(LoadMoreComments());
                            },
                            icon: const Icon(Icons.expand_more, size: 18),
                            label: const Text('Load More Comments'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                  );
                }

                final comment = comments[index];
                return CommentCard(
                  comment: comment,
                  onLike: () {
                    _bloc.add(ToggleLikeComment(comment.id));
                  },
                  onDelete: () {
                    _bloc.add(DeleteComment(comment.id));
                  },
                  onReply: (text) {
                    _bloc.add(AddReply(
                      commentId: comment.id,
                      reply: text,
                    ));
                  },
                  onLoadReplies: (commentId) {
                    _bloc.add(LoadReplies(commentId));
                  },
                );
              },
              childCount:
                  comments.length + (state.hasMoreComments ? 1 : 0),
            ),
          ),

        // Bottom padding
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }

  void _shareCase(CaseDiscussion discussion) {
    final url = '${AppData.base2}/discuss-case/${discussion.id}';
    SharePlus.instance.share(ShareParams(
      text: '${discussion.title}\n\n$url',
    ));
  }

  void _copyLink(CaseDiscussion discussion) {
    final url = '${AppData.base2}/discuss-case/${discussion.id}';
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied to clipboard')),
    );
  }

  void _reportCase(CaseDiscussion discussion) {
    // Use the action endpoint for report
    final repo = CaseDiscussionRepository(
      baseUrl: AppData.base2,
      getAuthToken: () => AppData.userToken ?? '',
    );
    repo.performCaseAction(caseId: discussion.id, action: 'report').then((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Case reported. Thank you.')),
        );
      }
    }).catchError((_) {});
  }

  void _editCase(CaseDiscussion discussion) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => CreateDiscussionBloc(
            repository: CaseDiscussionRepository(
              baseUrl: AppData.base2,
              getAuthToken: () => AppData.userToken ?? '',
            ),
          ),
          child: CreateDiscussionScreen(existingCase: discussion),
        ),
      ),
    ).then((result) {
      if (result == true) {
        _bloc.add(LoadDiscussionDetail(widget.caseId));
        _bloc.add(LoadComments(widget.caseId));
      }
    });
  }
}

// ── AI Summary Section ──

class _AISummarySection extends StatelessWidget {
  final CaseDiscussion discussion;
  final bool isGenerating;
  final bool aiNeedsUpgrade;
  final String? aiErrorMessage;
  final VoidCallback onGenerate;
  final OneUITheme theme;

  const _AISummarySection({
    required this.discussion,
    required this.isGenerating,
    required this.onGenerate,
    required this.theme,
    this.aiNeedsUpgrade = false,
    this.aiErrorMessage,
  });

  static const _aiPurple = Color(0xFF6C5CE7);
  static const _premiumGold = Color(0xFFFFB830);

  @override
  Widget build(BuildContext context) {
    final isPaid = discussion.isPaid;
    final remaining = discussion.aiSummaryRemaining;
    final dailyLimit = discussion.aiSummaryDailyLimit;
    final quotaExhausted = !isPaid && (remaining != null && remaining <= 0);

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 2, 0, 0),
      decoration: theme.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _aiPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome, size: 18, color: _aiPurple),
              ),
              const SizedBox(width: 10),
              Text(
                'AI Summary',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                  color: theme.textPrimary,
                ),
              ),
              const Spacer(),
              if (isPaid)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFB830), Color(0xFFFF7043)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.workspace_premium, size: 11, color: Colors.white),
                      SizedBox(width: 3),
                      Text(
                        'Premium',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              else if (discussion.aiSummary != null)
                Text(
                  'AI-generated',
                  style: TextStyle(fontSize: 10, fontFamily: 'Poppins', color: theme.textTertiary),
                )
              else if (remaining != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: remaining > 0
                        ? _aiPurple.withValues(alpha: 0.08)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: remaining > 0
                          ? _aiPurple.withValues(alpha: 0.2)
                          : Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '$remaining/$dailyLimit today',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                      color: remaining > 0 ? _aiPurple : Colors.orange.shade700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Loading state ──
          if (isGenerating) ...[_buildLoadingState()]

          // ── Upgrade / quota exhausted ──
          else if (aiNeedsUpgrade || quotaExhausted) ...[_buildUpgradeGate(context)]

          // ── Summary exists ──
          else if (discussion.aiSummary != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _aiPurple.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _aiPurple.withValues(alpha: 0.1)),
              ),
              child: SelectableText(
                discussion.aiSummary!.summary,
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'Poppins',
                  color: theme.textPrimary,
                  height: 1.6,
                ),
              ),
            ),
            if (discussion.aiSummary!.keyPoints.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Key Findings',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                  color: theme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              ...discussion.aiSummary!.keyPoints.map((finding) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Icon(Icons.circle, size: 6, color: theme.primary),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          finding,
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'Poppins',
                            color: theme.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            // Regenerate button for paid users or users with quota remaining
            if (isPaid || (remaining != null && remaining > 0)) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onGenerate,
                  icon: const Icon(Icons.refresh, size: 15),
                  label: Text(
                    isPaid ? 'Regenerate' : 'Regenerate ($remaining left)',
                    style: const TextStyle(fontSize: 12, fontFamily: 'Poppins'),
                  ),
                  style: TextButton.styleFrom(foregroundColor: _aiPurple),
                ),
              ),
            ],
          ]

          // ── Generate button (no summary yet, quota available) ──
          else ...[
            Text(
              'Generate an AI-powered summary of this case discussion including key findings and recommendations.',
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'Poppins',
                color: theme.textTertiary,
                height: 1.5,
              ),
            ),
            if (!isPaid && remaining != null) ...[
              const SizedBox(height: 8),
              Text(
                '$remaining of $dailyLimit free summaries remaining today',
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'Poppins',
                  color: remaining > 0
                      ? _aiPurple.withValues(alpha: 0.7)
                      : Colors.orange.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onGenerate,
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text(
                  'Generate AI Summary',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _aiPurple,
                  side: BorderSide(color: _aiPurple.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: _aiPurple.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _aiPurple.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(_aiPurple),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Generating AI Summary…',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
              color: _aiPurple,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Analysing the case discussion. This may take a few seconds.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'Poppins',
              color: _aiPurple.withValues(alpha: 0.7),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeGate(BuildContext context) {
    final message = aiErrorMessage ??
        'You have reached your daily AI summary limit. Upgrade to Premium for unlimited AI summaries.';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _premiumGold.withValues(alpha: 0.08),
            Colors.orange.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _premiumGold.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.workspace_premium, size: 36, color: _premiumGold),
          const SizedBox(height: 10),
          const Text(
            'Premium Feature',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
              color: Color(0xFFE65100),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'Poppins',
              color: Colors.orange.shade800,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SubscriptionScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.star, size: 16, color: Colors.white),
              label: const Text(
                'Upgrade to Premium',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _premiumGold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Updates Timeline ──

class _UpdatesTimeline extends StatelessWidget {
  final List<CaseUpdate> updates;
  final OneUITheme theme;
  final bool isOwner;
  final int caseId;
  final DiscussionDetailBloc bloc;

  const _UpdatesTimeline({
    required this.updates,
    required this.theme,
    required this.isOwner,
    required this.caseId,
    required this.bloc,
  });

  void _showAddUpdateSheet(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final List<XFile> pickedImages = [];
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Add Case Update',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                        color: theme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Post a timeline update for this case',
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'Poppins',
                        color: theme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Update Title',
                        hintText: 'e.g., Follow-up results, Treatment change...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: theme.cardBackground,
                      ),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: theme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: contentController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Update Content',
                        hintText: 'Describe the update details...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: theme.cardBackground,
                      ),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: theme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // ── Image picker section ───────────────────────────
                    Row(
                      children: [
                        Icon(Icons.image_outlined, size: 18, color: theme.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          'Attach Images',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                            color: theme.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () async {
                            final images = await picker.pickMultiImage(imageQuality: 80);
                            if (images.isNotEmpty) {
                              setState(() => pickedImages.addAll(images));
                            }
                          },
                          icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                          label: const Text('Add', style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                        ),
                      ],
                    ),
                    if (pickedImages.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 90,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: pickedImages.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, i) => Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(pickedImages[i].path),
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: GestureDetector(
                                  onTap: () => setState(() => pickedImages.removeAt(i)),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, size: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          final title = titleController.text.trim();
                          final content = contentController.text.trim();
                          if (title.isEmpty || content.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please fill in both title and content'),
                              ),
                            );
                            return;
                          }
                          bloc.add(AddCaseUpdate(
                            caseId: caseId,
                            updateTitle: title,
                            updateContent: content,
                            imagePaths: pickedImages.map((x) => x.path).toList(),
                          ));
                          Navigator.of(ctx).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Add Update',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditUpdateSheet(BuildContext context, CaseUpdate update) {
    final titleController = TextEditingController(text: update.updateType);
    final contentController = TextEditingController(text: update.content);
    final List<String> existingImages = List<String>.from(update.attachedFiles);
    final List<String> removedImages = [];
    final List<XFile> newImages = [];
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Edit Update',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                        color: theme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Update Title',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: theme.cardBackground,
                      ),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: theme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: contentController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Update Content',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: theme.cardBackground,
                      ),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: theme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // ── Image section ────────────────────────────────
                    Row(
                      children: [
                        Icon(Icons.image_outlined, size: 18, color: theme.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          'Images',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                            color: theme.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () async {
                            final images = await picker.pickMultiImage(imageQuality: 80);
                            if (images.isNotEmpty) {
                              setState(() => newImages.addAll(images));
                            }
                          },
                          icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                          label: const Text('Add', style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                        ),
                      ],
                    ),
                    if (existingImages.isNotEmpty || newImages.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 90,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            // Existing server images
                            ...existingImages.map((url) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      url.startsWith('http') ? url : '${AppEnvironment.imageUrl}$url',
                                      width: 90,
                                      height: 90,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 90,
                                        height: 90,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.image_not_supported_outlined),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 2,
                                    right: 2,
                                    child: GestureDetector(
                                      onTap: () => setState(() {
                                        removedImages.add(url);
                                        existingImages.remove(url);
                                      }),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, size: 16, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                            // Newly picked images
                            ...newImages.asMap().entries.map((entry) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(entry.value.path),
                                      width: 90,
                                      height: 90,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 2,
                                    right: 2,
                                    child: GestureDetector(
                                      onTap: () => setState(() => newImages.removeAt(entry.key)),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, size: 16, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          final title = titleController.text.trim();
                          final content = contentController.text.trim();
                          if (title.isEmpty || content.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please fill in both title and content'),
                              ),
                            );
                            return;
                          }
                          bloc.add(EditCaseUpdate(
                            updateId: update.id,
                            updateTitle: title,
                            updateContent: content,
                            newImagePaths: newImages.map((x) => x.path).toList(),
                            removedImagePaths: removedImages,
                          ));
                          Navigator.of(ctx).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      decoration: theme.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline, size: 18, color: theme.primary),
              const SizedBox(width: 8),
              Text(
                'Case Updates',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                  color: theme.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${updates.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    color: theme.primary,
                  ),
                ),
              ),
              const Spacer(),
              if (isOwner)
                InkWell(
                  onTap: () => _showAddUpdateSheet(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add, size: 16, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          'Add Update',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (updates.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.history,
                      size: 40,
                      color: theme.textTertiary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No updates yet',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Poppins',
                        color: theme.textSecondary,
                      ),
                    ),
                    if (isOwner) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Add the first update for this case',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Poppins',
                          color: theme.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            ...updates.asMap().entries.map((entry) {
              final isLast = entry.key == updates.length - 1;
              final update = entry.value;
              return _TimelineItem(
                update: update,
                isLast: isLast,
                theme: theme,
                isOwner: isOwner,
                onEdit: () => _showEditUpdateSheet(context, update),
                onDelete: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Update'),
                      content: const Text(
                          'Are you sure you want to delete this update?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            bloc.add(DeleteCaseUpdate(update.id));
                            Navigator.of(ctx).pop();
                          },
                          style: TextButton.styleFrom(
                              foregroundColor: Colors.red),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final CaseUpdate update;
  final bool isLast;
  final OneUITheme theme;
  final bool isOwner;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _TimelineItem({
    required this.update,
    required this.isLast,
    required this.theme,
    this.isOwner = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot + line
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: theme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: theme.primary.withValues(alpha: 0.2),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          update.updateType.isNotEmpty
                              ? update.updateType
                              : 'Update',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                            color: theme.textPrimary,
                          ),
                        ),
                      ),
                      if (isOwner)
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          iconSize: 18,
                          icon: Icon(Icons.more_vert,
                              size: 16, color: theme.textTertiary),
                          onSelected: (value) {
                            if (value == 'edit') {
                              onEdit?.call();
                            } else if (value == 'delete') {
                              onDelete?.call();
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 16),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outlined,
                                      size: 16, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete',
                                      style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  if (update.content.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      update.content,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        color: theme.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                  if (update.attachedFiles.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: update.attachedFiles.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 6),
                        itemBuilder: (_, i) {
                          final url = update.attachedFiles[i].startsWith('http')
                              ? update.attachedFiles[i]
                              : '${AppEnvironment.imageUrl}${update.attachedFiles[i]}';
                          return GestureDetector(
                            onTap: () => _showFullScreenImage(
                              context,
                              update.attachedFiles.map((f) => f.startsWith('http') ? f : '${AppEnvironment.imageUrl}$f').toList(),
                              i,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                url,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.image_not_supported_outlined, size: 20),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(update.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: 'Poppins',
                      color: theme.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _showFullScreenImage(BuildContext context, List<String> imageUrls, int initialIndex) {
    final controller = PageController(initialPage: initialIndex);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              '${initialIndex + 1} / ${imageUrls.length}',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          body: PageView.builder(
            controller: controller,
            itemCount: imageUrls.length,
            itemBuilder: (_, i) => InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Image.network(
                  imageUrls[i],
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.image_not_supported_outlined,
                    color: Colors.white54,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
