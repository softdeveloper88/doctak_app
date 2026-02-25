import 'package:dio/dio.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/subscription/premium_page_model.dart';
import 'package:doctak_app/data/models/subscription/subscription_plan_model.dart';
import 'package:doctak_app/presentation/subscription_screen/bloc/subscription_bloc.dart';
import 'package:doctak_app/presentation/subscription_screen/bloc/subscription_event.dart';
import 'package:doctak_app/presentation/subscription_screen/bloc/subscription_state.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

// ── Semantic badge colours (branding – consistent across themes) ─────────────
const _popular = Color(0xFF0A84FF); // OneUI Blue  – "Most Popular"
const _elite   = Color(0xFF5AC8FA); // OneUI Cyan  – "Best Value"
const _purple  = Color(0xFF8B5CF6); // Premium gradient accent

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with SingleTickerProviderStateMixin {
  late final SubscriptionBloc _bloc;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _bloc = SubscriptionBloc()..add(const LoadSubscriptionData());
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _bloc.close();
    _tabController.dispose();
    super.dispose();
  }

  /// Opens the try-premium page in the device's external browser.
  Future<void> _openTryPremium() async {
    final url = Uri.parse('http://127.0.0.1:8000/try-premium');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
    if (mounted) _bloc.add(const RefreshSubscriptionStatus());
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackground,
        appBar: DoctakAppBar(
          title: 'Subscription',
          titleIcon: Icons.workspace_premium_rounded,
        ),
        body: BlocBuilder<SubscriptionBloc, SubscriptionState>(
          bloc: _bloc,
          builder: (context, state) {
            if (state is SubscriptionLoading) {
              return Center(child: CircularProgressIndicator(color: theme.primary));
            }
            if (state is SubscriptionError) {
              return _buildError(theme, state.message);
            }
            if (state is SubscriptionLoaded) {
              return _buildContent(theme, state);
            }
            return Center(child: CircularProgressIndicator(color: theme.primary));
          },
        ),
      ),
    );
  }

  Widget _buildError(OneUITheme theme, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 56, color: theme.error),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: theme.textSecondary, fontSize: 15)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _bloc.add(const LoadSubscriptionData()),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(OneUITheme theme, SubscriptionLoaded state) {
    return Column(
      children: [
        // Tab bar
        Container(
          color: theme.cardBackground,
          child: TabBar(
            controller: _tabController,
            labelColor: theme.primary,
            unselectedLabelColor: theme.textSecondary,
            indicatorColor: theme.primary,
            indicatorWeight: 2.5,
            labelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'My Plan'),
              Tab(text: 'History'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _MyPlanTab(state: state, onUpgrade: _openTryPremium),
              const _HistoryTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════════
// MY PLAN TAB  – uses data from /api/v6/subscription/premium-page (synced with web)
// ════════════════════════════════════════════════════════════════════════════════

class _MyPlanTab extends StatelessWidget {
  final SubscriptionLoaded state;
  final VoidCallback onUpgrade;

  const _MyPlanTab({required this.state, required this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final page = state.premiumPage;
    final hero = page?.hero ?? PremiumHero();
    final plans = page?.plans ?? <PremiumPlan>[];
    final guarantee = page?.guarantee;

    return RefreshIndicator(
      color: theme.primary,
      backgroundColor: theme.cardBackground,
      onRefresh: () async {
        context.read<SubscriptionBloc>().add(const LoadSubscriptionData());
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // ── PREMIUM PLANS badge (from server) ──
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_purple, _elite]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    hero.badge.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Title (from server) ──
          Center(
            child: Column(
              children: [
                _buildHeroTitle(theme, hero.title),
                const SizedBox(height: 8),
                if (hero.subtitle.isNotEmpty)
                  Text(
                    hero.subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.textSecondary, fontSize: 13, height: 1.5),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Billing toggle ──
          BlocBuilder<SubscriptionBloc, SubscriptionState>(
            builder: (context, st) {
              final showYearly = (st is SubscriptionLoaded) ? st.showYearly : false;
              return _BillingToggle(showYearly: showYearly);
            },
          ),
          const SizedBox(height: 24),

          // ── Plan cards (from server) ──
          if (plans.isNotEmpty)
            BlocBuilder<SubscriptionBloc, SubscriptionState>(
              builder: (context, st) {
                final showYearly = (st is SubscriptionLoaded) ? st.showYearly : false;
                return Column(
                  children: plans.map((plan) {
                    return _PremiumPlanCard(
                      plan: plan,
                      showYearly: showYearly,
                      onUpgrade: onUpgrade,
                    );
                  }).toList(),
                );
              },
            )
          else
            _buildAllFreeNotice(theme),

          // ── Guarantee banner (from server) ──
          if (guarantee != null && guarantee.title.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildGuarantee(theme, guarantee),
          ],

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeroTitle(OneUITheme theme, String title) {
    final yourIdx = title.indexOf('Your ');
    if (yourIdx >= 0) {
      final before = title.substring(0, yourIdx + 5);
      final after  = title.substring(yourIdx + 5);
      return Text.rich(
        TextSpan(children: [
          TextSpan(text: before, style: TextStyle(color: theme.textPrimary, fontSize: 22, fontWeight: FontWeight.w800, fontFamily: 'Poppins')),
          TextSpan(text: after,  style: TextStyle(color: theme.secondary,  fontSize: 22, fontWeight: FontWeight.w800, fontFamily: 'Poppins')),
        ]),
        textAlign: TextAlign.center,
      );
    }
    return Text(title, textAlign: TextAlign.center,
        style: TextStyle(color: theme.textPrimary, fontSize: 22, fontWeight: FontWeight.w800, fontFamily: 'Poppins'));
  }

  Widget _buildAllFreeNotice(OneUITheme theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.celebration_rounded, color: theme.success, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('All Features Free!', style: TextStyle(color: theme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('All features are currently available to everyone for free.', style: TextStyle(color: theme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuarantee(OneUITheme theme, PremiumGuarantee guarantee) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.primary.withValues(alpha: theme.isDark ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.verified_user_rounded, color: theme.primary, size: 32),
          const SizedBox(height: 8),
          Text(guarantee.title, textAlign: TextAlign.center, style: TextStyle(color: theme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(guarantee.description, textAlign: TextAlign.center, style: TextStyle(color: theme.textSecondary, fontSize: 12, height: 1.4)),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════════
// BILLING TOGGLE
// ════════════════════════════════════════════════════════════════════════════════

class _BillingToggle extends StatelessWidget {
  final bool showYearly;
  const _BillingToggle({required this.showYearly});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Center(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: theme.surfaceVariant,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: theme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _toggleBtn(context, theme, 'Monthly', !showYearly, false),
            _toggleBtn(context, theme, 'Yearly',  showYearly,  true),
          ],
        ),
      ),
    );
  }

  Widget _toggleBtn(BuildContext context, OneUITheme theme, String label, bool active, bool isYearly) {
    return GestureDetector(
      onTap: () => context.read<SubscriptionBloc>().add(TogglePricingPeriod(isYearly)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: active ? theme.cardBackground : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          boxShadow: active && !theme.isDark
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6, offset: const Offset(0, 2))]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                    color: active ? theme.textPrimary : theme.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
            if (isYearly) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: theme.success, borderRadius: BorderRadius.circular(10)),
                child: const Text('Save 17%', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════════
// PLAN CARD – uses PremiumPlan from /premium-page API
// ════════════════════════════════════════════════════════════════════════════════

class _PremiumPlanCard extends StatelessWidget {
  final PremiumPlan plan;
  final bool showYearly;
  final VoidCallback onUpgrade;

  const _PremiumPlanCard({
    required this.plan,
    required this.showYearly,
    required this.onUpgrade,
  });

  String? get _badgeLabel {
    if (plan.badge == 'most_popular') return 'MOST POPULAR';
    if (plan.badge == 'best_value') return 'BEST VALUE';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    // Semantic colours derived from theme
    final Color badgeColor  = plan.badge == 'best_value' ? _elite : _popular;
    final Color borderColor = plan.isCurrent
        ? theme.success
        : (plan.badge == 'most_popular'
            ? _popular
            : (plan.badge == 'best_value' ? _elite : theme.border));
    final Color ctaColor    = plan.badge == 'best_value' ? _elite : theme.primary;
    final bool  hasBadge    = _badgeLabel != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: theme.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: hasBadge || plan.isCurrent ? 1.5 : 1),
              boxShadow: theme.isDark ? [] : theme.cardShadow,
            ),
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Plan name ──
                Text(
                  plan.name,
                  style: TextStyle(color: theme.textPrimary, fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
                ),
                const SizedBox(height: 12),

                // ── Price ──
                _buildPrice(theme),
                const SizedBox(height: 12),

                // ── Description ──
                if (plan.description != null && plan.description!.isNotEmpty)
                  Text(
                    plan.description!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.textSecondary, fontSize: 12, height: 1.4),
                  ),
                const SizedBox(height: 20),

                // ── Divider ──
                Divider(height: 1, color: theme.divider),
                const SizedBox(height: 18),

                // ── "WHAT'S INCLUDED" header ──
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "WHAT'S INCLUDED",
                    style: TextStyle(color: theme.textTertiary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2),
                  ),
                ),
                const SizedBox(height: 14),

                // ── Highlight rows (from server) ──
                ...plan.highlights.map((h) => _HighlightRow(highlight: h)),

                const SizedBox(height: 20),

                // ── CTA Button ──
                _buildCta(theme, ctaColor),
              ],
            ),
          ),

          // ── Floating badge ──
          if (_badgeLabel != null)
            Positioned(
              top: -12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        plan.badge == 'best_value' ? Icons.diamond_rounded : Icons.star_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _badgeLabel!,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPrice(OneUITheme theme) {
    if (plan.isFree) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text('Free', style: TextStyle(color: theme.textPrimary, fontSize: 36, fontWeight: FontWeight.w800, fontFamily: 'Poppins')),
          const SizedBox(width: 4),
          Text('forever', style: TextStyle(color: theme.textSecondary, fontSize: 14)),
        ],
      );
    }

    final price  = showYearly ? plan.priceYearly : plan.priceMonthly;
    final period = showYearly ? '/ year' : '/ month';
    final priceStr = price == price.roundToDouble()
        ? '\$${price.toInt()}'
        : '\$${price.toStringAsFixed(2)}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(priceStr, style: TextStyle(color: theme.textPrimary, fontSize: 36, fontWeight: FontWeight.w800, fontFamily: 'Poppins')),
        const SizedBox(width: 4),
        Text(period, style: TextStyle(color: theme.textSecondary, fontSize: 14)),
      ],
    );
  }

  Widget _buildCta(OneUITheme theme, Color ctaColor) {
    if (plan.isCurrent) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: null,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: theme.success.withValues(alpha: 0.5)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Text('Your Current Plan', style: TextStyle(color: theme.success, fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      );
    }

    if (plan.isFree) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: null,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: theme.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Text('Available', style: TextStyle(color: theme.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onUpgrade,
        style: ElevatedButton.styleFrom(
          backgroundColor: ctaColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(plan.badge == 'best_value' ? Icons.diamond_rounded : Icons.upgrade_rounded, size: 16),
            const SizedBox(width: 8),
            Text('Upgrade to ${plan.name}  →', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════════
// HIGHLIGHT ROW  – renders a single PlanHighlight from the API
// ════════════════════════════════════════════════════════════════════════════════

class _HighlightRow extends StatelessWidget {
  final PlanHighlight highlight;

  const _HighlightRow({required this.highlight});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    final Color iconColor;
    final IconData iconData;

    switch (highlight.type) {
      case 'unlimited':
        iconColor = theme.success;
        iconData  = Icons.verified_rounded;
        break;
      case 'included':
        iconColor = theme.success;
        iconData  = Icons.check_circle_rounded;
        break;
      case 'limited':
        iconColor = theme.warning;
        iconData  = Icons.remove_circle_outline_rounded;
        break;
      default:
        iconColor = theme.textSecondary;
        iconData  = Icons.check_circle_rounded;
    }

    final bool isPositive = highlight.type != 'limited';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(iconData, color: iconColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              highlight.text,
              style: TextStyle(
                color: isPositive ? theme.textPrimary : theme.warning,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════════
// HISTORY TAB
// ════════════════════════════════════════════════════════════════════════════════

class _HistoryTab extends StatefulWidget {
  const _HistoryTab();

  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> with AutomaticKeepAliveClientMixin {
  List<SubscriptionHistoryItem>? _history;
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final dio = Dio();
      final resp = await dio.get(
        '${AppData.remoteUrlV6}/subscription/history',
        options: Options(headers: {'Authorization': 'Bearer ${AppData.userToken}'}),
      );
      final data = resp.data is Map ? Map<String, dynamic>.from(resp.data as Map) : <String, dynamic>{};
      final list = (data['history'] as List<dynamic>? ?? [])
          .map((e) => SubscriptionHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) setState(() { _history = list; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Could not load history.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = OneUITheme.of(context);

    if (_loading) {
      return Center(child: CircularProgressIndicator(color: theme.primary));
    }
    if (_error != null || _history == null) {
      return Center(child: Text(_error ?? 'No data', style: TextStyle(color: theme.textSecondary)));
    }
    if (_history!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_rounded, size: 56, color: theme.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text('No subscription history yet.', style: TextStyle(color: theme.textSecondary, fontSize: 15)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _history!.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _buildHistoryItem(theme, _history![i]),
    );
  }

  Widget _buildHistoryItem(OneUITheme theme, SubscriptionHistoryItem item) {
    final isActive = item.status == 'active';
    final statusColor = isActive ? theme.success : (item.status == 'expired' ? theme.error : theme.textSecondary);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.divider),
        boxShadow: theme.isDark ? [] : theme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(isActive ? Icons.check_circle_rounded : Icons.history_rounded, color: statusColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.planName, style: TextStyle(color: theme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  _formatDate(item.startedAt),
                  style: TextStyle(color: theme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.amount > 0 ? '\$${item.amount.toStringAsFixed(2)}' : 'Free',
                style: TextStyle(color: theme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                child: Text(
                  item.status.toUpperCase(),
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final dt = DateTime.parse(isoDate);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return isoDate;
    }
  }
}
