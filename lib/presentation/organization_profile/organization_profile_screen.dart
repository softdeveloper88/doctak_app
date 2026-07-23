import 'dart:ui';

import 'package:doctak_app/core/acting/acting_context_service.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/apiClient/services/organization_profile_api_service.dart';
import 'package:doctak_app/data/apiClient/shared_api_service.dart';
import 'package:doctak_app/data/models/organization_profile/organization_public_profile_model.dart';
import 'package:doctak_app/data/models/post_model/post_data_model.dart';
import 'package:doctak_app/presentation/home_screen/fragments/add_post/compose_content_screen.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/bloc/home_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/network_fragment/network_widgets.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/adapters/post_feed_adapter.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/post_feed_list_view.dart';
import 'package:doctak_app/data/models/jobs/job_dto.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/jobs_details_screen.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/job_card.dart';
import 'package:doctak_app/presentation/organization_profile/organization_people_list_screen.dart';
import 'package:doctak_app/presentation/organization_profile/organization_profile_edit_screen.dart';
import 'package:doctak_app/presentation/organization_profile/bloc/organization_profile_bloc.dart';
import 'package:doctak_app/presentation/organization_profile/bloc/organization_profile_event.dart';
import 'package:doctak_app/presentation/organization_profile/bloc/organization_profile_state.dart';
import 'package:doctak_app/presentation/user_chat_screen/chat_ui_sceen/chat_room_screen.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/app_cached_network_image.dart';
import 'package:doctak_app/widgets/app_surface_card.dart';
import 'package:doctak_app/widgets/one_ui_confirm_dialog.dart';
import 'package:doctak_app/widgets/retry_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:url_launcher/url_launcher.dart';

enum OrganizationProfileTab {
  profile,
  jobs,
  posts,
  cme,
  promotions,
  surveys,
}

class OrganizationProfileScreen extends StatefulWidget {
  const OrganizationProfileScreen({
    required this.identifier,
    this.showBackButton = true,
    super.key,
  });

  final String identifier;

  /// When false (bottom-nav profile tab), hide the back control — same as
  /// personal [SVProfileFragment] on the dashboard tab.
  final bool showBackButton;

  @override
  State<OrganizationProfileScreen> createState() =>
      _OrganizationProfileScreenState();
}

class _OrganizationProfileScreenState extends State<OrganizationProfileScreen>
    with SingleTickerProviderStateMixin {
  late final OrganizationProfileBloc _bloc;
  TabController? _tabController;
  List<OrganizationProfileTab> _tabs = const [];

  List<OrganizationProfileTab> _tabsFor(OrganizationPublicProfileModel profile) {
    final tabs = <OrganizationProfileTab>[OrganizationProfileTab.profile];
    final type = profile.organization.type;
    if (type == 'hospital' || type == 'recruiter') {
      tabs.add(OrganizationProfileTab.jobs);
    }
    if (type == 'cme_provider') tabs.add(OrganizationProfileTab.cme);
    if (type == 'pharma') tabs.add(OrganizationProfileTab.promotions);
    tabs.addAll([
      OrganizationProfileTab.posts,
      OrganizationProfileTab.surveys,
    ]);
    return tabs;
  }

  void _ensureTabController(OrganizationPublicProfileModel profile) {
    final nextTabs = _tabsFor(profile);
    if (_tabController != null &&
        _tabs.length == nextTabs.length &&
        _tabs.every((tab) => nextTabs.contains(tab))) {
      return;
    }
    // Never dispose a TabController during build — TabBarView animations still
    // hold the old parent animation and crash with a null check.
    final old = _tabController;
    _tabs = nextTabs;
    _tabController = TabController(length: nextTabs.length, vsync: this);
    if (old != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        old.dispose();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _bloc = OrganizationProfileBloc()
      ..add(LoadOrganizationProfileEvent(identifier: widget.identifier));
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return BlocProvider.value(
      value: _bloc,
      child: BlocBuilder<OrganizationProfileBloc, OrganizationProfileState>(
        builder: (context, state) {
          if (state is OrganizationProfileLoading ||
              state is OrganizationProfileInitial) {
            return Scaffold(
              backgroundColor: theme.scaffoldBackground,
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          if (state is OrganizationProfileError) {
            return Scaffold(
              backgroundColor: theme.scaffoldBackground,
              appBar: AppBar(
                backgroundColor: theme.scaffoldBackground,
                elevation: 0,
                automaticallyImplyLeading: widget.showBackButton,
                leading: widget.showBackButton
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        onPressed: () => Navigator.pop(context),
                      )
                    : null,
              ),
              body: RetryWidget(
                errorMessage: state.message,
                onRetry: () => _bloc.add(
                  LoadOrganizationProfileEvent(identifier: widget.identifier),
                ),
              ),
            );
          }

          if (state is! OrganizationProfileLoaded) {
            return Scaffold(
              backgroundColor: theme.scaffoldBackground,
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          final profile = state.profile;
          final loadedState = state;
          _ensureTabController(profile);
          if (_tabController == null) {
            return Scaffold(
              backgroundColor: theme.scaffoldBackground,
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          return Scaffold(
            backgroundColor: theme.scaffoldBackground,
            body: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: _OrganizationProfileHeader(
                    profile: profile,
                    showBackButton: widget.showBackButton,
                    isFollowBusy: loadedState.isFollowBusy,
                    onFollowToggle: () =>
                        _bloc.add(const ToggleOrganizationFollowEvent()),
                    onMessageOwner: () => _openOwnerChat(profile),
                    onEditProfile: () => _openEditProfile(profile),
                    onCreatePost: () => _openBusinessComposer(profile),
                  ),
                ),
                SliverOverlapAbsorber(
                  handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                    context,
                  ),
                  sliver: SliverPersistentHeader(
                    pinned: true,
                    delegate: _OrgTabBarDelegate(
                      tabController: _tabController!,
                      tabs: _tabs,
                      theme: theme,
                    ),
                  ),
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                children: _tabs
                    .map(
                      (tab) => _OrganizationTabBody(
                        tab: tab,
                        profile: profile,
                        onContentChanged: _reload,
                        onDeletePage: _isOwner(profile)
                            ? () => _confirmDeleteBusiness(profile)
                            : null,
                      ),
                    )
                    .toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openOwnerChat(OrganizationPublicProfileModel profile) {
    final ownerId = profile.viewer?.ownerUserId;
    if (ownerId == null || ownerId.isEmpty) return;
    ChatRoomScreen(
      username: profile.viewer?.ownerName ?? profile.organization.name,
      profilePic: profile.organization.logoUrl ?? '',
      id: ownerId,
      conversationId: 0,
    ).launch(context);
  }

  void _reload() {
    _bloc.add(LoadOrganizationProfileEvent(identifier: widget.identifier));
  }

  Future<void> _openEditProfile(OrganizationPublicProfileModel profile) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => OrganizationProfileEditScreen(profile: profile),
      ),
    );
    if (changed == true && mounted) _reload();
  }

  bool _isOwner(OrganizationPublicProfileModel profile) {
    final viewer = profile.viewer;
    if (viewer == null) return false;
    final ownerId = viewer.ownerUserId?.toString() ?? '';
    if (ownerId.isEmpty) return false;
    return ownerId == viewer.userId.toString() ||
        ownerId == AppData.logInUserId.toString();
  }

  Future<void> _confirmDeleteBusiness(
    OrganizationPublicProfileModel profile,
  ) async {
    final ok = await showOneUIConfirmDialog(
      context,
      title: 'Delete business page?',
      subtitle:
          'You will lose all your data for “${profile.organization.name}”, including posts, jobs, members, and settings. This cannot be undone.',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await OrganizationProfileApiService().deleteBusiness(
        businessId: profile.organization.id,
      );
      final acting = ActingContextService.instance;
      if (acting.organization?.id == profile.organization.id) {
        await acting.switchToPersonal();
      }
      if (!mounted) return;
      toast('Business page deleted');
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      toast(e.toString());
    }
  }

  /// Opens the composer attributed to this business page. If the user is not
  /// currently acting as this organization, switch first (same as opening the
  /// workspace on the website).
  Future<void> _openBusinessComposer(
    OrganizationPublicProfileModel profile,
  ) async {
    final acting = ActingContextService.instance;
    if (acting.organization?.id != profile.organization.id) {
      try {
        await acting.switchToOrganization(profile.organization.id);
      } catch (_) {
        if (mounted) toast('Could not switch to this business page.');
        return;
      }
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ComposeContentScreen(onPosted: _reload),
      ),
    );
  }
}

class _OrganizationProfileHeader extends StatelessWidget {
  const _OrganizationProfileHeader({
    required this.profile,
    required this.showBackButton,
    required this.isFollowBusy,
    required this.onFollowToggle,
    required this.onMessageOwner,
    required this.onEditProfile,
    required this.onCreatePost,
  });

  final OrganizationPublicProfileModel profile;
  final bool showBackButton;
  final bool isFollowBusy;
  final VoidCallback onFollowToggle;
  final VoidCallback onMessageOwner;
  final VoidCallback onEditProfile;
  final VoidCallback onCreatePost;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final org = profile.organization;
    final viewer = profile.viewer;
    final canManage = viewer?.canManage ?? false;
    final isFollowing = viewer?.isFollowingOrganization ?? false;
    final canMessage = (viewer?.ownerUserId ?? '').isNotEmpty &&
        !(viewer?.isMember ?? false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            const SizedBox(height: 224, width: double.infinity),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 168,
                width: double.infinity,
                decoration: BoxDecoration(gradient: theme.coverGradient),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildCover(theme, org),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.05),
                            Colors.black.withValues(alpha: 0.28),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (showBackButton)
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                child: _OrgCoverButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => Navigator.pop(context),
                ),
              ),
            Positioned(
              top: 168 - 44,
              left: 20,
              child: _OrganizationLogoBadge(organization: org),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      org.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: theme.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  if (org.isVerified) ...[
                    const SizedBox(width: 6),
                    theme.buildVerifiedBadge(size: 20),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    networkOrganizationIcon(org.type),
                    size: 14,
                    color: networkOrganizationIconColor(org.type),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    org.typeLabel,
                    style: theme.bodySecondary.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (org.locationLine.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 15, color: theme.textTertiary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        org.locationLine,
                        style: theme.bodySecondary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if ((org.description ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  org.description!.trim(),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodySecondary.copyWith(height: 1.4),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: canManage
              // Own business page — manage instead of follow (mirrors the
              // website's "Manage workspace" hero action).
              ? Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEditProfile,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit page'),
                        style: OneUIButtons.outlined(theme),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onCreatePost,
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text('Create post'),
                        style: OneUIButtons.filled(theme),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    if (canMessage) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onMessageOwner,
                          icon: const Icon(Icons.message_outlined, size: 18),
                          label: const Text('Message'),
                          style: OneUIButtons.outlined(theme),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: FilledButton(
                        onPressed: isFollowBusy ? null : onFollowToggle,
                        style: OneUIButtons.filled(theme).copyWith(
                          backgroundColor: WidgetStatePropertyAll(
                            isFollowing ? theme.cardBackground : theme.primary,
                          ),
                          foregroundColor: WidgetStatePropertyAll(
                            isFollowing ? theme.textPrimary : Colors.white,
                          ),
                          side: WidgetStatePropertyAll(
                            isFollowing
                                ? BorderSide(color: theme.border)
                                : BorderSide.none,
                          ),
                        ),
                        child: Text(
                          isFollowBusy
                              ? '...'
                              : isFollowing
                                  ? 'Following'
                                  : 'Follow',
                        ),
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        _OrganizationStatsRow(organization: org),
      ],
    );
  }

  Widget _buildCover(OneUITheme theme, OrganizationSummary org) {
    final cover = org.coverUrl?.trim() ?? '';
    if (cover.isEmpty || cover.toLowerCase() == 'null') {
      return const SizedBox.shrink();
    }

    return AppCachedNetworkImage(
      imageUrl: cover,
      fit: BoxFit.cover,
      width: double.infinity,
      height: 168,
      errorWidget: (_, __, ___) => const SizedBox.shrink(),
    );
  }
}

class _OrganizationLogoBadge extends StatelessWidget {
  const _OrganizationLogoBadge({required this.organization});

  final OrganizationSummary organization;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: theme.cardBackground,
        shape: BoxShape.circle,
        border: Border.all(color: theme.cardBackground, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: networkOrganizationLogo(organization: {
        'type': organization.type,
        'logo_url': organization.logoUrl,
        'logoUrl': organization.logoUrl,
      }, size: 88),
    );
  }
}

class _OrganizationStatsRow extends StatelessWidget {
  const _OrganizationStatsRow({required this.organization});

  final OrganizationSummary organization;

  void _openPeopleList(
    BuildContext context,
    OrganizationPeopleListKind kind,
    int count,
  ) {
    OrganizationPeopleListScreen(
      organizationId: organization.id,
      kind: kind,
      initialCount: count,
    ).launch(context);
  }

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatData('Posts', organization.stats.posts, null),
      _StatData('Jobs', organization.stats.jobs, null),
      _StatData(
        'Followers',
        organization.followerCount,
        () => _openPeopleList(
          context,
          OrganizationPeopleListKind.followers,
          organization.followerCount,
        ),
      ),
      _StatData(
        'Members',
        organization.memberCount,
        () => _openPeopleList(
          context,
          OrganizationPeopleListKind.members,
          organization.memberCount,
        ),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppCardLayout.horizontalInset),
      child: AppSurfaceCard(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: stats
              .map(
                (item) => Expanded(
                  child: _OrganizationStatItem(
                    label: item.label,
                    value: item.value,
                    onTap: item.onTap,
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _OrganizationStatItem extends StatelessWidget {
  const _OrganizationStatItem({
    required this.label,
    required this.value,
    this.onTap,
  });

  final String label;
  final int value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final content = Column(
      children: [
        Text(
          _formatCount(value),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: theme.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.caption.copyWith(color: theme.textTertiary),
        ),
      ],
    );

    if (onTap == null) return content;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: content,
    );
  }
}

class _StatData {
  const _StatData(this.label, this.value, this.onTap);
  final String label;
  final int value;
  final VoidCallback? onTap;
}

class _OrgTabBarDelegate extends SliverPersistentHeaderDelegate {
  _OrgTabBarDelegate({
    required this.tabController,
    required this.tabs,
    required this.theme,
  });

  final TabController tabController;
  final List<OrganizationProfileTab> tabs;
  final OneUITheme theme;

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: theme.scaffoldBackground,
      elevation: overlapsContent ? 0.5 : 0,
      child: TabBar(
        controller: tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: theme.primary,
        unselectedLabelColor: theme.textSecondary,
        indicatorColor: theme.primary,
        dividerColor: theme.border.withValues(alpha: 0.4),
        tabs: tabs.map((tab) => Tab(text: _tabLabel(tab))).toList(),
      ),
    );
  }

  String _tabLabel(OrganizationProfileTab tab) {
    switch (tab) {
      case OrganizationProfileTab.profile:
        return 'Profile';
      case OrganizationProfileTab.jobs:
        return 'Jobs';
      case OrganizationProfileTab.posts:
        return 'Posts';
      case OrganizationProfileTab.cme:
        return 'CME';
      case OrganizationProfileTab.promotions:
        return 'Promotions';
      case OrganizationProfileTab.surveys:
        return 'Surveys';
    }
  }

  @override
  bool shouldRebuild(covariant _OrgTabBarDelegate oldDelegate) =>
      oldDelegate.tabs != tabs;
}

class _OrganizationTabBody extends StatelessWidget {
  const _OrganizationTabBody({
    required this.tab,
    required this.profile,
    required this.onContentChanged,
    this.onDeletePage,
  });

  final OrganizationProfileTab tab;
  final OrganizationPublicProfileModel profile;
  final VoidCallback onContentChanged;
  final VoidCallback? onDeletePage;

  @override
  Widget build(BuildContext context) {
    final content = switch (tab) {
      OrganizationProfileTab.profile => _ProfileTabContent(
          profile: profile,
          onDeletePage: onDeletePage,
        ),
      OrganizationProfileTab.jobs =>
        _JobsTabContent(jobs: profile.sections.jobs),
      OrganizationProfileTab.posts => _PostsTabContent(
          posts: profile.sections.posts,
          organization: profile.organization,
          canManage: profile.viewer?.canManage ?? false,
          onContentChanged: onContentChanged,
        ),
      OrganizationProfileTab.cme =>
        _CmeTabContent(events: profile.sections.cmeEvents),
      OrganizationProfileTab.promotions => _PromotionsTabContent(
          items: profile.sections.drugPromotions,
        ),
      OrganizationProfileTab.surveys =>
        _SurveysTabContent(surveys: profile.sections.surveys),
    };
    return _OrgNestedTabScrollView(child: content);
  }
}

/// Coordinates tab content with [NestedScrollView] so pinned tabs do not leave
/// a large empty gap above the first list item.
class _OrgNestedTabScrollView extends StatelessWidget {
  const _OrgNestedTabScrollView({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
            SliverToBoxAdapter(child: child),
          ],
        );
      },
    );
  }
}

class _ProfileTabContent extends StatelessWidget {
  const _ProfileTabContent({
    required this.profile,
    this.onDeletePage,
  });

  final OrganizationPublicProfileModel profile;
  final VoidCallback? onDeletePage;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final org = profile.organization;
    final departments = _departments(profile.typeProfile);

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        AppSectionCard(
          title: 'About',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (org.description ?? '').trim().isNotEmpty
                    ? org.description!.trim()
                    : 'No public description available yet.',
                style: theme.bodySecondary.copyWith(height: 1.45),
              ),
              if (departments.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: departments
                      .map(
                        (dep) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: theme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            dep,
                            style: theme.caption.copyWith(
                              color: theme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppSectionCard(
          title: 'Contact & details',
          child: Column(
            children: [
              _DetailRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: org.email,
                onTap: org.email != null ? () => _launchUri('mailto:${org.email}') : null,
              ),
              _DetailRow(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: org.phone,
                onTap: org.phone != null ? () => _launchUri('tel:${org.phone}') : null,
              ),
              _DetailRow(
                icon: Icons.language_outlined,
                label: 'Website',
                value: org.website,
                onTap: org.website != null ? () => _launchUri(org.website!) : null,
              ),
              _DetailRow(
                icon: Icons.location_on_outlined,
                label: 'Location',
                value: org.locationLine.isEmpty ? null : org.locationLine,
              ),
              _DetailRow(
                icon: Icons.calendar_today_outlined,
                label: 'Established',
                value: org.establishedAt,
              ),
              _DetailRow(
                icon: Icons.business_outlined,
                label: 'Type',
                value: org.typeLabel,
              ),
            ],
          ),
        ),
        if (profile.typeProfile.isNotEmpty) ...[
          const SizedBox(height: 12),
          AppSectionCard(
            title: '${org.typeLabel} specifics',
            child: Column(
              children: profile.typeProfile.entries
                  .where((entry) => _hasDisplayValue(entry.value))
                  .map(
                    (entry) => _DetailRow(
                      icon: Icons.info_outline_rounded,
                      label: organizationTypeProfileLabels[entry.key] ??
                          _sentenceCase(entry.key),
                      value: _formatTypeValue(entry.value),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
        if (onDeletePage != null) ...[
          const SizedBox(height: 12),
          AppSectionCard(
            title: 'Danger zone',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You will lose all your data for this business page, including posts, jobs, members, and settings. This cannot be undone.',
                  style: theme.bodySecondary.copyWith(height: 1.4),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: kOneUIButtonHeight,
                  child: OutlinedButton(
                    onPressed: onDeletePage,
                    style: OneUIButtons.outlined(theme, destructive: true),
                    child: const Text('Delete business page'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  List<String> _departments(Map<String, dynamic> typeProfile) {
    final raw = typeProfile['departments'];
    if (raw is List) {
      return raw.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
    }
    if (raw is String && raw.trim().isNotEmpty) {
      return raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return [];
  }
}

class _JobsTabContent extends StatelessWidget {
  const _JobsTabContent({required this.jobs});
  final List<OrganizationJobSummary> jobs;

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) return _EmptyTab(message: 'No open roles published yet.');
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        final job = jobs[index];
        return JobCard(
          job: JobCardDto(
            id: job.id,
            title: job.title,
            location: job.location,
            country: job.country,
            jobType: job.jobType,
            createdAt: job.createdAt,
            stats: JobStatsDto(applicants: job.applicants),
          ),
          showBookmark: false,
          onTap: () => JobsDetailsScreen(jobId: job.id).launch(context),
        );
      },
    );
  }
}

class _PostsTabContent extends StatefulWidget {
  const _PostsTabContent({
    required this.posts,
    required this.organization,
    this.canManage = false,
    this.onContentChanged,
  });

  final List<OrganizationPostSummary> posts;
  final OrganizationSummary organization;
  final bool canManage;
  final VoidCallback? onContentChanged;

  @override
  State<_PostsTabContent> createState() => _PostsTabContentState();
}

class _PostsTabContentState extends State<_PostsTabContent> {
  final HomeBloc _homeBloc = HomeBloc();

  @override
  void dispose() {
    _homeBloc.close();
    super.dispose();
  }

  Future<void> _confirmDelete(Post post) async {
    final theme = OneUITheme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardBackground,
        title: Text('Delete post?', style: theme.titleSmall),
        content: Text(
          'This post will be removed from the business page.',
          style: theme.bodySecondary,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: theme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: TextStyle(color: theme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final res = await SharedApiService().deletePostV1(postId: '${post.id}');
    if (!mounted) return;
    if (res.success) {
      toast('Post deleted');
      widget.onContentChanged?.call();
    } else {
      toast(res.message ?? 'Failed to delete post');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.posts.isEmpty) {
      return _EmptyTab(message: 'No posts published yet.');
    }

    final posts = widget.posts
        .map((post) {
          try {
            return PostFeedAdapter.organizationPostToPost(
              post,
              widget.organization,
            );
          } catch (e, stack) {
            debugPrint(
              'Organization post feed mapping failed for ${post.id}: $e\n$stack',
            );
            return null;
          }
        })
        .whereType<Post>()
        .toList();

    return PostFeedListView(
      posts: posts,
      homeBloc: _homeBloc,
      scrollMode: PostFeedScrollMode.nested,
      padding: EdgeInsets.zero,
      trimTopCardGap: true,
      canModerate: widget.canManage,
      hooks: widget.canManage
          ? PostFeedCardHooks(onDelete: _confirmDelete)
          : const PostFeedCardHooks(),
    );
  }
}

class _CmeTabContent extends StatelessWidget {
  const _CmeTabContent({required this.events});
  final List<OrganizationCmeSummary> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return _EmptyTab(message: 'No CME events published yet.');
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final event = events[index];
        return _ListCard(
          title: event.title,
          subtitle: [
            if ((event.eventType ?? '').isNotEmpty) _sentenceCase(event.eventType!),
            if ((event.startDate ?? '').isNotEmpty) event.startDate,
          ].whereType<String>().join(' · '),
          trailing: '${event.registrationsCount} registered',
        );
      },
    );
  }
}

class _PromotionsTabContent extends StatelessWidget {
  const _PromotionsTabContent({required this.items});
  final List<OrganizationDrugPromotionSummary> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptyTab(message: 'No drug promotions published yet.');
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        return _ListCard(
          title: item.drugName,
          subtitle: item.genericName ?? item.description ?? '',
          trailing: '${item.impressions} views',
        );
      },
    );
  }
}

class _SurveysTabContent extends StatelessWidget {
  const _SurveysTabContent({required this.surveys});
  final List<OrganizationSurveySummary> surveys;

  @override
  Widget build(BuildContext context) {
    if (surveys.isEmpty) return _EmptyTab(message: 'No surveys published yet.');
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: surveys.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final survey = surveys[index];
        return _ListCard(
          title: survey.title,
          subtitle: survey.description ?? survey.surveyType ?? '',
          trailing: '${survey.responseCount} responses',
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final display = (value ?? '').trim().isEmpty ? 'Not provided' : value!.trim();
    final isEmpty = (value ?? '').trim().isEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: isEmpty ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: theme.textTertiary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.caption.copyWith(color: theme.textTertiary)),
                  const SizedBox(height: 2),
                  Text(
                    display,
                    style: theme.bodySecondary.copyWith(
                      color: isEmpty
                          ? theme.textTertiary
                          : (onTap != null ? theme.primary : theme.textPrimary),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null && !isEmpty)
              Icon(Icons.open_in_new_rounded, size: 16, color: theme.primary),
          ],
        ),
      ),
    );
  }
}

class _ListCard extends StatelessWidget {
  const _ListCard({
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return AppSurfaceCard.listItem(
      margin: const EdgeInsets.only(bottom: AppCardLayout.listGap),
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.titleSmall.copyWith(fontWeight: FontWeight.w700),
                ),
                if (subtitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.bodySecondary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            Text(trailing!, style: theme.caption),
          ],
          if (onTap != null) ...[
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: theme.textTertiary),
          ],
        ],
      ),
    );
  }
}

class _EmptyTab extends StatelessWidget {
  const _EmptyTab({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: theme.bodySecondary,
        ),
      ),
    );
  }
}

class _OrgCoverButton extends StatelessWidget {
  const _OrgCoverButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.82),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 18,
              color: isDark ? Colors.white70 : Colors.grey[800],
            ),
          ),
        ),
      ),
    );
  }
}

String _formatCount(int value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
  return '$value';
}

String _sentenceCase(String value) {
  return value
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .split(RegExp(r'[_\s-]+'))
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1))
      .join(' ');
}

bool _hasDisplayValue(dynamic value) {
  if (value is List) return value.any((item) => '$item'.trim().isNotEmpty);
  if (value is bool) return true;
  return '$value'.trim().isNotEmpty;
}

String _formatTypeValue(dynamic value) {
  if (value is List) return value.map((e) => e.toString()).join(', ');
  if (value is bool) return value ? 'Yes' : 'No';
  return value?.toString() ?? '';
}

Future<void> _launchUri(String raw) async {
  final uri = Uri.tryParse(raw.startsWith('http') ? raw : raw);
  if (uri == null) return;
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
