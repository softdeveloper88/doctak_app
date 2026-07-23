import 'package:doctak_app/data/apiClient/settings_api_service.dart';
import 'package:doctak_app/presentation/subscription_screen/subscription_screen.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/app_surface_card.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class AiDataUsageScreen extends StatefulWidget {
  const AiDataUsageScreen({super.key});

  @override
  State<AiDataUsageScreen> createState() => _AiDataUsageScreenState();
}

class _AiDataUsageScreenState extends State<AiDataUsageScreen> {
  bool _loading = true;
  String? _error;
  String _planLabel = 'Free';
  bool _isPremium = false;
  bool _isUnlimited = false;
  List<_AiModule> _modules = [];

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
    try {
      final data = await SettingsApiService.getAiUsage();
      final plan = data['plan'];
      final modulesRaw = data['modules'];

      final modules = <_AiModule>[];
      if (modulesRaw is List) {
        for (final row in modulesRaw) {
          if (row is Map) {
            modules.add(_AiModule.fromJson(Map<String, dynamic>.from(row)));
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _planLabel = plan is Map ? (plan['label']?.toString() ?? 'Free') : 'Free';
        _isPremium = plan is Map && plan['isPremium'] == true;
        _isUnlimited = plan is Map && plan['isUnlimited'] == true;
        _modules = modules;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: const DoctakAppBar(
        title: 'AI & data usage',
        titleIcon: Icons.auto_awesome_rounded,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  if (_error != null)
                    AppSurfaceCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      borderColor: Colors.red.withValues(alpha: 0.3),
                      child: Text(_error!, style: const TextStyle(color: Colors.red)),
                    ),
                  AppSurfaceCard(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current plan',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: theme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _planLabel,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: theme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isUnlimited
                              ? 'Unlimited AI access on this plan.'
                              : 'Usage resets daily and monthly by feature.',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: theme.textSecondary,
                          ),
                        ),
                        if (!_isPremium) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => const SubscriptionScreen().launch(context),
                              child: const Text('Upgrade for higher limits'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (_modules.isEmpty)
                    AppSurfaceCard(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No AI usage data available yet.',
                        style: TextStyle(color: theme.textSecondary, fontFamily: 'Poppins'),
                      ),
                    )
                  else
                    ..._modules.map((module) {
                      return AppSurfaceCard(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              module.name,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: theme.textPrimary,
                              ),
                            ),
                            if (module.description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                module.description,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12.5,
                                  color: theme.textSecondary,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            if (module.isUnlimited ||
                                (module.dailyLimit == null && module.monthlyLimit == null))
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: theme.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Unlimited on your $_planLabel plan',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: theme.primary,
                                  ),
                                ),
                              )
                            else ...[
                              if (module.dailyLimit != null) ...[
                                _UsageBar(
                                  theme: theme,
                                  label: 'Today',
                                  used: module.dailyUsed,
                                  limit: module.dailyLimit,
                                  remaining: module.dailyRemaining,
                                ),
                                if (module.monthlyLimit != null) const SizedBox(height: 10),
                              ],
                              if (module.monthlyLimit != null)
                                _UsageBar(
                                  theme: theme,
                                  label: 'This month',
                                  used: module.monthlyUsed,
                                  limit: module.monthlyLimit,
                                  remaining: module.monthlyRemaining,
                                ),
                            ],
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}

class _UsageBar extends StatelessWidget {
  const _UsageBar({
    required this.theme,
    required this.label,
    required this.used,
    required this.limit,
    required this.remaining,
  });

  final OneUITheme theme;
  final String label;
  final int used;
  final int? limit;
  final int? remaining;

  @override
  Widget build(BuildContext context) {
    final cappedLimit = (limit != null && limit! > 0) ? limit! : null;
    // Determinate only — never null (indeterminate/loading animation).
    final progress = cappedLimit == null ? 0.0 : (used / cappedLimit).clamp(0.0, 1.0);
    final caption = cappedLimit == null
        ? 'No limit'
        : '$used / $cappedLimit used${remaining != null ? ' · $remaining left' : ''}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimary,
                ),
              ),
            ),
            Text(
              caption,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: theme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            backgroundColor: theme.divider.withValues(alpha: 0.35),
            color: progress >= 1 ? Colors.red.shade400 : theme.primary,
          ),
        ),
      ],
    );
  }
}

class _AiModule {
  _AiModule({
    required this.name,
    required this.description,
    required this.dailyUsed,
    required this.dailyLimit,
    required this.dailyRemaining,
    required this.monthlyUsed,
    required this.monthlyLimit,
    required this.monthlyRemaining,
    required this.isUnlimited,
  });

  factory _AiModule.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value) {
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    int? asNullableInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    return _AiModule(
      name: json['name']?.toString() ?? 'AI feature',
      description: json['description']?.toString() ?? '',
      dailyUsed: asInt(json['dailyUsed']),
      dailyLimit: asNullableInt(json['dailyLimit']),
      dailyRemaining: asNullableInt(json['dailyRemaining']),
      monthlyUsed: asInt(json['monthlyUsed']),
      monthlyLimit: asNullableInt(json['monthlyLimit']),
      monthlyRemaining: asNullableInt(json['monthlyRemaining']),
      isUnlimited: json['isUnlimited'] == true,
    );
  }

  final String name;
  final String description;
  final int dailyUsed;
  final int? dailyLimit;
  final int? dailyRemaining;
  final int monthlyUsed;
  final int? monthlyLimit;
  final int? monthlyRemaining;
  final bool isUnlimited;
}
