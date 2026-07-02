import 'package:doctak_app/data/apiClient/cme/cme_node_api_service.dart';
import 'package:doctak_app/data/apiClient/services/group_api_service.dart';
import 'package:doctak_app/data/models/feed_model/feed_models.dart';
import 'package:doctak_app/widgets/app_cached_network_image.dart';
import 'package:doctak_app/presentation/cme_module/cme_main_screen.dart';
import 'package:doctak_app/presentation/cme_module/screens/cme_event_detail_screen.dart';
import 'package:doctak_app/presentation/groups_module/screens/group_detail_screen.dart';
import 'package:doctak_app/presentation/group_screen/my_groups_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/feed_card_shell.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/conferences_screen/conferences_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/jobs_details_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/jobs_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/survey_screen/survey_fill_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/survey_screen/surveys_browse_screen.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

/// Horizontal rail of compact tiles — mirrors doctak-web `FeedStrip` and the
/// home mockups (Surveys, Groups, Jobs, CME sections).
class FeedStrip extends StatelessWidget {
  final String? stripType;
  final List<FeedItem> items;

  const FeedStrip({super.key, required this.stripType, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    if (items.isEmpty) return const SizedBox.shrink();

    final meta = _meta(stripType);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(0, 15, 0, 16),
      decoration: theme.feedStripModuleDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FeedStripHeader(
            icon: meta.icon,
            title: meta.title,
            subtitle: meta.subtitle,
            seeAllLabel: meta.seeAll,
            onSeeAll: meta.onSeeAll != null ? () => meta.onSeeAll!(context) : null,
          ),
          SizedBox(
            height: meta.tileHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              primary: false,
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
              cacheExtent: 280,
              addRepaintBoundaries: true,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) => _StripTile(
                items[index],
                stripType: stripType,
                height: meta.tileHeight - 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _StripMeta _meta(String? type) {
    switch (type) {
      case 'jobs':
        return _StripMeta(
          icon: Icons.work_outline_rounded,
          title: 'Jobs for you',
          subtitle: 'Based on your specialty & license',
          seeAll: 'See all',
          tileHeight: 210,
          onSeeAll: (ctx) => const JobsScreen().launch(ctx),
        );
      case 'cme':
        return _StripMeta(
          icon: Icons.school_outlined,
          title: 'CME & live events',
          subtitle: 'Earn Category 1 credits this month',
          seeAll: 'See all',
          tileHeight: 220,
          onSeeAll: (ctx) => const CmeMainScreen().launch(ctx),
        );
      case 'surveys':
        return _StripMeta(
          icon: Icons.poll_outlined,
          title: 'Surveys',
          subtitle: 'Quick questionnaires from your peers',
          seeAll: 'See all',
          tileHeight: 210,
          onSeeAll: (ctx) => const SurveysBrowseScreen().launch(ctx),
        );
      case 'groups':
        return _StripMeta(
          icon: Icons.groups_outlined,
          title: 'Groups you may like',
          subtitle: 'Specialty communities to join',
          seeAll: 'See all',
          tileHeight: 220,
          onSeeAll: (ctx) => const MyGroupsScreen().launch(ctx),
        );
      case 'conferences':
        return _StripMeta(
          icon: Icons.event_outlined,
          title: 'Upcoming conferences',
          subtitle: 'Events in your region',
          seeAll: 'See all',
          tileHeight: 200,
          onSeeAll: (ctx) => const ConferencesScreen().launch(ctx),
        );
      default:
        return _StripMeta(
          icon: Icons.star_outline,
          title: 'Recommended',
          tileHeight: 180,
        );
    }
  }
}

class _StripMeta {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String seeAll;
  final double tileHeight;
  final void Function(BuildContext)? onSeeAll;

  const _StripMeta({
    required this.icon,
    required this.title,
    this.subtitle,
    this.seeAll = 'See all',
    this.tileHeight = 200,
    this.onSeeAll,
  });
}

class _StripTile extends StatelessWidget {
  final FeedItem item;
  final String? stripType;
  final double height;

  const _StripTile(
    this.item, {
    this.stripType,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    switch (item.type) {
      case 'survey':
        return _SurveyTile(item, height: height);
      case 'group_suggestion':
        return _GroupTile(item, height: height);
      case 'job':
        return _JobTile(item, height: height);
      case 'cme':
        return _CmeTile(item, height: height);
      default:
        return _GenericTile(item, height: height);
    }
  }
}

class _SurveyTile extends StatelessWidget {
  final FeedItem item;
  final double height;
  const _SurveyTile(this.item, {required this.height});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final title = item.str('title') ?? 'Survey';
    final org = item.str('organizationName') ?? 'Research';
    final logo = item.str('orgLogo');
    final questions = item.intVal('questionCount');
    final responses = item.intVal('responseCount');
    final daysLeft = item.intVal('daysLeft');

    void open() => SurveyFillScreen(surveyId: item.id).launch(context);

    return _tileShell(
      context,
      width: 280,
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          FeedBadge(label: 'Survey', color: theme.primary),
          const SizedBox(height: 10),
          Row(
            children: [
              _logo(logo, org, theme),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(org,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.titleSmall.copyWith(fontSize: 13)),
                    Text('Global study', style: theme.caption),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.titleSmall.copyWith(fontSize: 14, height: 1.3)),
          const SizedBox(height: 6),
          Text(
            [
              if (questions > 0) '$questions items',
              if (responses > 0) '${feedCompactNumber(responses)} responses',
              if (daysLeft > 0) '${daysLeft}d left',
            ].join(' · '),
            style: theme.caption,
          ),
          const Spacer(),
          Row(
            children: [
              Text('Anonymous', style: theme.caption),
              const Spacer(),
              FeedAccentButton(label: 'Respond', onTap: open, fontSize: 12),
            ],
          ),
        ],
      ),
    );
  }
}

class _GroupTile extends StatefulWidget {
  final FeedItem item;
  final double height;
  const _GroupTile(this.item, {required this.height});

  @override
  State<_GroupTile> createState() => _GroupTileState();
}

class _GroupTileState extends State<_GroupTile> {
  bool _joining = false;
  String? _joinStatus;

  Color _headerColor(OneUITheme theme) {
    final options = [theme.primary, theme.secondary];
    return options[widget.item.id.hashCode.abs() % options.length];
  }

  Future<void> _handleJoin() async {
    if (_joining || _joinStatus != null) return;
    setState(() => _joining = true);
    try {
      final res = await GroupApiService().joinGroup(groupId: widget.item.id);
      if (!mounted) return;
      if (res.success) {
        final data = res.data ?? {};
        final status = (data['status'] ?? 'approved').toString();
        setState(() {
          _joining = false;
          _joinStatus = status == 'pending' ? 'pending' : 'approved';
        });
        if (status == 'approved') {
          GroupDetailScreen(groupId: widget.item.id).launch(context);
        } else {
          toast('Join request sent');
        }
      } else {
        setState(() => _joining = false);
        toast(res.message ?? 'Could not join group');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _joining = false);
      toast('Could not join group');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final item = widget.item;
    final name = item.str('name') ?? 'Group';
    final members = item.intVal('membersCount');
    final logo = item.str('logoImage');
    final headerColor = _headerColor(theme);

    void openGroup() => GroupDetailScreen(groupId: item.id).launch(context);

    return _tileShell(
      context,
      width: 200,
      height: widget.height,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 56,
                decoration: BoxDecoration(
                  color: headerColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                ),
              ),
              Positioned(
                left: 12,
                top: 28,
                child: _logo(logo, name, theme, size: 44),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 28, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: openGroup,
                    child: Text(name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.titleSmall.copyWith(fontSize: 14)),
                  ),
                  const SizedBox(height: 4),
                  Text('${feedCompactNumber(members)} members',
                      style: theme.caption),
                  Text('Public group', style: theme.caption),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _joinStatus == 'approved'
                              ? 'You joined'
                              : _joinStatus == 'pending'
                                  ? 'Request sent'
                                  : 'Open group',
                          style: theme.caption.copyWith(fontSize: 11),
                        ),
                      ),
                      if (_joinStatus == 'approved')
                        FeedAccentButton(
                          label: 'View',
                          fontSize: 12,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          onTap: openGroup,
                        )
                      else if (_joinStatus == 'pending')
                        const FeedStatusChip(label: 'Pending', fontSize: 11)
                      else
                        FeedAccentButton(
                          label: _joining ? 'Joining…' : 'Join',
                          fontSize: 12,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          onTap: _joining ? null : _handleJoin,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JobTile extends StatelessWidget {
  final FeedItem item;
  final double height;
  const _JobTile(this.item, {required this.height});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final title = item.str('jobTitle') ?? 'Job opening';
    final company = item.str('companyName') ?? '';
    final location = item.str('location') ?? '';
    final salary = item.str('salaryRange');
    final image = item.str('image');

    void open() => JobsDetailsScreen(jobId: item.id).launch(context);

    return _tileShell(
      context,
      width: 260,
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          Row(
            children: [
              _logo(image, company, theme),
              const Spacer(),
              Icon(Icons.bookmark_border, size: 20, color: theme.textSecondary),
            ],
          ),
          const SizedBox(height: 8),
          Text(title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.titleSmall.copyWith(fontSize: 14, height: 1.25)),
          const SizedBox(height: 4),
          Text('$company · $location',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.caption),
          if (salary != null && salary.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(salary,
                  style: theme.caption.copyWith(
                    color: theme.primary,
                    fontWeight: FontWeight.w600,
                  )),
            ),
          ],
          const Spacer(),
          Row(
            children: [
              Text('Recently posted', style: theme.caption),
              const Spacer(),
              FeedAccentButton(
                label: 'Apply',
                onTap: open,
                fontSize: 12,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CmeTile extends StatefulWidget {
  final FeedItem item;
  final double height;
  const _CmeTile(this.item, {required this.height});

  @override
  State<_CmeTile> createState() => _CmeTileState();
}

class _CmeTileState extends State<_CmeTile> {
  bool _registering = false;
  late bool _registered;
  String? _registrationStatus;

  @override
  void initState() {
    super.initState();
    _registered = feedCmeIsRegistered(widget.item);
    _registrationStatus = widget.item.str('registrationStatus');
  }

  Future<void> _handleRegister() async {
    if (_registering || _registered) return;
    setState(() => _registering = true);
    try {
      await CmeNodeApiService.registerEvent(widget.item.id);
      if (!mounted) return;
      setState(() {
        _registering = false;
        _registered = true;
        _registrationStatus = 'registered';
      });
      toast('Registered for event');
    } catch (e) {
      if (!mounted) return;
      setState(() => _registering = false);
      toast('Could not register');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final item = widget.item;
    final title = item.str('title') ?? 'CME event';
    final credits = item.numOrNull('credits');
    final going = item.intVal('goingCount');
    final startDate = DateTime.tryParse(item.str('startDate') ?? '');
    final headerColor = _headerColor(theme);

    void open() => CmeEventDetailScreen(eventId: item.id).launch(context);

    return _tileShell(
      context,
      width: 220,
      height: widget.height,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          InkWell(
            onTap: open,
            child: Container(
              height: 72,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: headerColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (startDate != null)
                    Container(
                      width: 42,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text('${startDate.day}',
                              style: theme.titleSmall.copyWith(fontSize: 16)),
                          Text(_month(startDate.month),
                              style: theme.caption.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              )),
                        ],
                      ),
                    ),
                  const Spacer(),
                  FeedBadge(label: 'CME', color: theme.secondary),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: open,
                    child: Text(title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.titleSmall.copyWith(fontSize: 13, height: 1.25)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (credits != null)
                        '${credits % 1 == 0 ? credits.toInt() : credits} credit hrs',
                      if (going > 0) '${feedCompactNumber(going)} registered',
                    ].join(' · '),
                    style: theme.caption,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _registered
                              ? feedCmeRegistrationLabel(item, overrideStatus: _registrationStatus)
                              : (going > 0 ? '${feedCompactNumber(going)} registered' : 'Earn credits'),
                          style: theme.caption,
                        ),
                      ),
                      if (_registered)
                        FeedStatusChip(
                          label: feedCmeRegistrationLabel(item, overrideStatus: _registrationStatus),
                          fontSize: 11,
                        )
                      else
                        FeedAccentButton(
                          label: _registering ? 'Registering…' : 'Register',
                          fontSize: 12,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          onTap: _registering ? null : _handleRegister,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _headerColor(OneUITheme theme) {
    final options = [theme.primary, theme.secondary];
    return options[widget.item.id.hashCode.abs() % options.length];
  }

  String _month(int m) {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    return (m >= 1 && m <= 12) ? months[m - 1] : '';
  }
}

class _GenericTile extends StatelessWidget {
  final FeedItem item;
  final double height;
  const _GenericTile(this.item, {required this.height});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return _tileShell(
      context,
      width: 220,
      height: height,
      child: Text(item.str('title') ?? 'Recommended', style: theme.titleSmall),
    );
  }
}

Widget _tileShell(
  BuildContext context, {
  required double width,
  required double height,
  required Widget child,
  EdgeInsetsGeometry padding = const EdgeInsets.all(12),
}) {
  final theme = OneUITheme.of(context);
  return SizedBox(
    width: width,
    height: height,
    child: DecoratedBox(
      decoration: theme.feedStripTileDecoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    ),
  );
}

Widget _logo(String? url, String name, OneUITheme theme, {double size = 36}) {
  final fallback = Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: theme.avatarBackground,
      borderRadius: BorderRadius.circular(size > 40 ? 22 : 8),
    ),
    child: Text(
      feedAvatarInitial(name),
      style: TextStyle(
        color: theme.avatarText,
        fontWeight: FontWeight.w700,
        fontFamily: 'Poppins',
        fontSize: size * 0.35,
      ),
    ),
  );
  if (url == null || url.isEmpty) return fallback;
  return ClipRRect(
    borderRadius: BorderRadius.circular(size > 40 ? size / 2 : 8),
    child: AppCachedNetworkImage(
      imageUrl: url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      memCacheWidth: (size * 2).round(),
      memCacheHeight: (size * 2).round(),
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      filterQuality: FilterQuality.low,
      placeholder: (_, __) => fallback,
      errorWidget: (_, __, ___) => fallback,
    ),
  );
}
