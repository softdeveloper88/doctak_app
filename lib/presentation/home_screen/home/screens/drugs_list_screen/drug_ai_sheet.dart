import 'dart:async';

import 'package:doctak_app/data/apiClient/drugs_v6_api_service.dart';
import 'package:doctak_app/data/models/drugs_model/drug_v6_models.dart';
import 'package:doctak_app/presentation/subscription_screen/subscription_screen.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/ai_data_consent_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:url_launcher/url_launcher.dart';

/// AI Assistant bottom sheet for a specific drug.
/// - Checks AI usage and subscription plan.
/// - Shows a chat-style interface with conversation history.
/// - If daily limit is reached, shows an upgrade prompt.
class DrugAISheet extends StatefulWidget {
  final DrugV6Item drug;
  /// When non-null the question is pre-filled in the input field and sent
  /// automatically once the session is ready.
  final String? initialQuestion;

  const DrugAISheet({super.key, required this.drug, this.initialQuestion});

  static Future<void> show(
    BuildContext context, {
    required DrugV6Item drug,
    String? initialQuestion,
  }) async {
    final agreed = await showAiConsentIfNeeded(context);
    if (!agreed || !context.mounted) return;

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DrugAISheet(drug: drug, initialQuestion: initialQuestion),
    );
  }

  @override
  State<DrugAISheet> createState() => _DrugAISheetState();
}

class _DrugAISheetState extends State<DrugAISheet> {
  final _api = DrugsV6ApiService.instance;
  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();

  DrugAISession? _session;
  DrugAIUsage? _usage;
  bool _loading = true;
  bool _sending = false;
  String? _error;

  // Typing animation state
  bool _isTyping = false;
  String _currentTyped = '';

  // Local message list (mirrors session messages + optimistic UI)
  final List<DrugAIMessage> _messages = [];

  // Quick question suggestions
  static const _quickQuestions = [
    'What are the side effects?',
    'What is the recommended dosage?',
    'Are there any drug interactions?',
    'What are the contraindications?',
    'Can it be used during pregnancy?',
  ];

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final results = await Future.wait([
        _api.createAISession(
          genericName: widget.drug.genericName ?? '',
          tradeName: widget.drug.tradeName,
        ),
        _api.getAIUsage(),
      ]);
      if (!mounted) return;
      setState(() {
        _session = results[0] as DrugAISession;
        _usage = results[1] as DrugAIUsage;
        // When the backend returns an existing session with old messages,
        // always start fresh. The user expects a new conversation each time
        // they open the bottom sheet—not the previous answers.
        _messages.clear();
        _loading = false;
      });
      // Auto-send initialQuestion from quick-question chips
      final iq = widget.initialQuestion;
      if (iq != null && iq.isNotEmpty && _messages.isEmpty) {
        _controller.text = iq;
        await _ask(iq);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to initialise AI: $e';
        _loading = false;
      });
    }
  }

  Future<void> _ask(String question) async {
    if (question.trim().isEmpty || _sending || _usage?.isLimitReached == true) return;

    final userMsg = DrugAIMessage(id: -1, role: 'user', content: question, createdAt: DateTime.now());
    setState(() {
      _messages.add(userMsg);
      _sending = true;
      _controller.clear();
    });
    _scrollToBottom();

    try {
      final resp = await _api.askAI(
        question: question,
        genericName: widget.drug.genericName ?? '',
        tradeName: widget.drug.tradeName,
        sessionId: _session?.id,
      );

      if (!mounted) return;

      if (resp.limitReached) {
        setState(() {
          _messages.add(DrugAIMessage(
            id: -2,
            role: 'assistant',
            content: '⚠️ **Daily AI limit reached** for your **${_usage?.planName ?? 'Free'}** plan.\n\nPlease upgrade to continue asking questions.',
            createdAt: DateTime.now(),
          ));
          _sending = false;
          if (resp.aiRemaining != null && _usage != null) {
            _usage = DrugAIUsage(
              success: true,
              planSlug: _usage!.planSlug,
              planName: _usage!.planName,
              dailyLimit: _usage!.dailyLimit,
              dailyUsed: _usage!.dailyLimit,
              dailyRemaining: 0,
              canUse: false,
            );
          }
        });
      } else {
        final fullText = resp.message;
        DrugAIUsage? updatedUsage;
        if (resp.aiRemaining != null && _usage != null) {
          final remaining = resp.aiRemaining!;
          updatedUsage = DrugAIUsage(
            success: true,
            planSlug: _usage!.planSlug,
            planName: _usage!.planName,
            dailyLimit: _usage!.dailyLimit,
            dailyUsed: _usage!.dailyLimit - remaining,
            dailyRemaining: remaining,
            // For unlimited plans, always allow. For limited plans, check remaining.
            canUse: _usage!.isUnlimited || remaining > 0,
          );
        }
        setState(() {
          _messages.add(DrugAIMessage(id: -2, role: 'assistant', content: fullText, createdAt: DateTime.now(), sources: resp.sources));
          _sending = false;
          if (updatedUsage != null) _usage = updatedUsage;
        });
        _scrollToBottom();
        // Kick off character-by-character typing animation
        unawaited(_animateResponse(fullText));
        return; // skip finally's redundant setState
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(DrugAIMessage(id: -2, role: 'assistant', content: '**Error:** ${e.toString()}', createdAt: DateTime.now()));
      });
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  /// Plays a character-by-character reveal animation for the last AI message.
  Future<void> _animateResponse(String fullText) async {
    if (!mounted) return;
    setState(() {
      _isTyping = true;
      _currentTyped = '';
    });
    for (int i = 1; i <= fullText.length; i++) {
      await Future.delayed(const Duration(milliseconds: 6));
      if (!mounted) return;
      setState(() => _currentTyped = fullText.substring(0, i));
      if (i % 15 == 0) _scrollToBottom();
    }
    if (mounted) {
      setState(() {
        _isTyping = false;
        _currentTyped = '';
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: theme.textTertiary.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          _buildHeader(theme),

          // Usage bar — hide for unlimited plans (admin-set unlimited quota)
          if (_usage != null && !_usage!.isUnlimited) _buildUsageBar(theme),

          const Divider(height: 1),

          // Messages
          Expanded(
            child: _loading
                ? _buildLoadingState(theme)
                : _error != null
                    ? _buildErrorState(theme)
                    : _buildChat(theme),
          ),

          // Input bar
          _buildInputBar(theme, bottomInset),
        ],
      ),
    );
  }

  Widget _buildHeader(OneUITheme theme) {
    final drugTitle = widget.drug.tradeName?.isNotEmpty == true
        ? widget.drug.tradeName!
        : widget.drug.genericName ?? '';
    final genericSub = widget.drug.genericName?.isNotEmpty == true &&
            widget.drug.tradeName?.isNotEmpty == true
        ? widget.drug.genericName!
        : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Circular AI avatar with online indicator
          Stack(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.primary, theme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.primary.withValues(alpha: 0.30),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 24),
              ),
              // Online / active dot
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    color: theme.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.cardBackground, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Title + drug name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Doctak AI — Drug Assistant',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: drugTitle,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.primary,
                        ),
                      ),
                      if (genericSub != null)
                        TextSpan(
                          text: '  •  $genericSub',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Close button
          IconButton(
            icon: Icon(Icons.close_rounded, color: theme.textSecondary, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageBar(OneUITheme theme) {
    final usage = _usage!;
    final pct = usage.usagePercent.clamp(0.0, 1.0);
    final usageColor = pct >= 0.9 ? theme.error : pct >= 0.6 ? theme.warning : theme.success;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded, size: 14, color: usageColor),
              const SizedBox(width: 6),
              Text(
                '${usage.planName} Plan',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.textPrimary),
              ),
              const Spacer(),
              Text(
                '${usage.dailyUsed}/${usage.dailyLimit} queries today',
                style: TextStyle(fontSize: 11, color: theme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: theme.cardBackground,
              valueColor: AlwaysStoppedAnimation<Color>(usageColor),
              minHeight: 6,
            ),
          ),
          if (usage.isLimitReached) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.lock_outline_rounded, size: 14, color: theme.error),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Daily limit reached. Upgrade for unlimited AI queries.',
                    style: TextStyle(fontSize: 11, color: theme.error),
                  ),
                ),
                GestureDetector(
                  onTap: () => const SubscriptionScreen().launch(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [theme.primary, theme.secondary]),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Upgrade',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (!usage.isPremium) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => const SubscriptionScreen().launch(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.diamond_outlined, size: 13, color: theme.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Upgrade for unlimited AI queries →',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.primary),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState(OneUITheme theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: theme.primary),
          const SizedBox(height: 16),
          Text(
            'Connecting to AI...',
            style: TextStyle(color: theme.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(OneUITheme theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: theme.textTertiary),
            const SizedBox(height: 12),
            Text(_error ?? 'Something went wrong', style: TextStyle(color: theme.textSecondary)),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _error = null;
                  _loading = true;
                });
                _init();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChat(OneUITheme theme) {
    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty ? _buildWelcomeState(theme) : _buildMessageList(theme),
        ),

        // Quick questions
        if (_messages.isEmpty && !(_usage?.isLimitReached ?? false))
          _buildQuickQuestions(theme),
      ],
    );
  }

  Widget _buildWelcomeState(OneUITheme theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.primary.withValues(alpha: 0.15), theme.secondary.withValues(alpha: 0.15)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(Icons.auto_awesome_rounded, size: 36, color: theme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Ask about ${widget.drug.genericName ?? 'this drug'}',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: theme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Get evidence-based pharmaceutical information from Dr. AI.',
              style: TextStyle(fontSize: 13, color: theme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(OneUITheme theme) {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: _messages.length + (_sending ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == _messages.length && _sending) {
          return _typingIndicator(theme);
        }
        return _messageBubble(theme, _messages[i]);
      },
    );
  }

  Widget _messageBubble(OneUITheme theme, DrugAIMessage msg) {
    final isUser = msg.isUser;
    final isLastAI = !isUser && msg == _messages.last;
    // Use animated text when this message is currently being typed
    final displayText = (isLastAI && _isTyping) ? _currentTyped : msg.content;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // ── AI avatar ──────────────────────────────────────────────────────
          if (!isUser) ...[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.primary, theme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: theme.primary.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
          ],

          // ── Bubble ─────────────────────────────────────────────────────────
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.fromLTRB(14, 12, 14, isUser ? 12 : 8),
                  decoration: BoxDecoration(
                    color: isUser ? theme.primary : theme.cardBackground,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    border: isUser
                        ? null
                        : Border.all(color: theme.primary.withValues(alpha: 0.12)),
                    boxShadow: isUser
                        ? []
                        : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: isUser
                      // User bubble: plain styled text
                      ? Text(
                          displayText,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            height: 1.5,
                          ),
                        )
                      // AI bubble: rendered markdown
                      : displayText.isEmpty
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: theme.primary),
                            )
                          : MarkdownBlock(
                              data: displayText,
                              config: MarkdownConfig(
                                configs: [
                                  PConfig(
                                    textStyle: TextStyle(
                                      fontSize: 14,
                                      height: 1.6,
                                      color: theme.textPrimary,
                                    ),
                                  ),
                                  H1Config(
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: theme.textPrimary,
                                    ),
                                  ),
                                  H2Config(
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: theme.textPrimary,
                                    ),
                                  ),
                                  H3Config(
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: theme.primary,
                                    ),
                                  ),
                                  CodeConfig(
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontFamily: 'monospace',
                                      color: theme.textPrimary,
                                      backgroundColor: theme.surfaceVariant,
                                    ),
                                  ),
                                  PreConfig(
                                    decoration: BoxDecoration(
                                      color: theme.surfaceVariant,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    textStyle: TextStyle(fontSize: 13, fontFamily: 'monospace', color: theme.textPrimary),
                                  ),
                                ],
                              ),
                            ),
                ),

                // Citation sources for AI responses (Apple Guideline 1.4.1)
                if (!isUser && !_isTyping && (msg.sources?.isNotEmpty ?? false)) ...[
                  const SizedBox(height: 6),
                  _buildDrugCitations(theme, msg.sources!),
                ],

                // Copy button for AI responses
                if (!isUser && !_isTyping) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: msg.content));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 1), behavior: SnackBarBehavior.floating),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.copy_rounded, size: 12, color: theme.textTertiary),
                        const SizedBox(width: 4),
                        Text('Copy', style: TextStyle(fontSize: 11, color: theme.textTertiary)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildDrugCitations(OneUITheme theme, List<Map<String, dynamic>> sources) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.verified_outlined, size: 13, color: Colors.blue[700]),
            const SizedBox(width: 4),
            Text(
              'Sources',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blue[700]),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: sources.asMap().entries.map((entry) {
            final i = entry.key + 1;
            final s = entry.value;
            final url = s['url']?.toString() ?? '';
            final title = s['title']?.toString() ?? _domain(url);
            return GestureDetector(
              onTap: url.isEmpty ? null : () async {
                try {
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                } catch (_) {}
              },
              child: Container(
                constraints: const BoxConstraints(maxWidth: 180),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.15)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16, height: 16,
                      decoration: BoxDecoration(color: Colors.blue[700], borderRadius: BorderRadius.circular(4)),
                      alignment: Alignment.center,
                      child: Text('$i', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: theme.textPrimary)),
                          Text(_domain(url), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 8, color: Colors.blue[600])),
                        ],
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(Icons.open_in_new_rounded, size: 10, color: Colors.blue[600]),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _domain(String url) {
    try { return Uri.parse(url).host.replaceFirst('www.', ''); } catch (_) { return url; }
  }

  Widget _typingIndicator(OneUITheme theme) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [theme.primary, theme.secondary]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.surfaceVariant,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) => _dot(theme, i)),
          ),
        ),
      ],
    );
  }

  Widget _dot(OneUITheme theme, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + index * 200),
      curve: Curves.easeInOut,
      builder: (_, v, __) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: theme.textSecondary.withValues(alpha: 0.4 + 0.6 * v),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildQuickQuestions(OneUITheme theme) {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _quickQuestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          return GestureDetector(
            onTap: () => _ask(_quickQuestions[i]),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.primary.withValues(alpha: 0.3)),
              ),
              child: Text(
                _quickQuestions[i],
                style: TextStyle(fontSize: 12, color: theme.primary, fontWeight: FontWeight.w500),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputBar(OneUITheme theme, double bottomInset) {
    final isLimited = _usage?.isLimitReached ?? false;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset > 0 ? bottomInset + 8 : MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.surfaceVariant,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _controller,
                enabled: !isLimited && !_sending,
                maxLines: 3,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: _ask,
                style: TextStyle(fontSize: 14, color: theme.textPrimary),
                decoration: InputDecoration(
                  hintText: isLimited ? 'Upgrade to send more queries' : 'Ask about ${widget.drug.genericName ?? 'this drug'}…',
                  hintStyle: TextStyle(fontSize: 13, color: theme.textTertiary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: isLimited || _sending ? null : () => _ask(_controller.text),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isLimited ? theme.textTertiary.withValues(alpha: 0.3) : theme.primary,
                shape: BoxShape.circle,
              ),
              child: _sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      ),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
