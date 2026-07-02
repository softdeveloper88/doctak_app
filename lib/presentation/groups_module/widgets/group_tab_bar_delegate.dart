import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

/// Shared group profile [TabBar] used inside a pinned [SliverPersistentHeader].
class GroupTabBar {
  GroupTabBar._();

  /// Visual tab row height (excluding top divider).
  static const double height = 48;

  static const double borderWidth = 0.8;

  /// Tab bar paints at ~48.5px; must match [preferredHeight] exactly.
  static const double tabBarHeight = 48.5;

  /// Total pinned tab strip height: divider + tab bar.
  static const double preferredHeight = borderWidth + tabBarHeight;

  /// @deprecated Use [preferredHeight] for sliver extent calculations.
  static const double tabExtent = height;

  static TabBar build({
    required TabController tabController,
    required List<String> tabs,
    required OneUITheme theme,
  }) {
    return TabBar(
      controller: tabController,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      labelColor: theme.primary,
      unselectedLabelColor: theme.textTertiary,
      indicatorColor: theme.primary,
      indicatorWeight: 2.5,
      dividerColor: Colors.transparent,
      labelStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      tabs: tabs.map((label) => Tab(text: label)).toList(),
    );
  }

  static Widget tabStrip({
    required TabController tabController,
    required List<String> tabs,
    required OneUITheme theme,
    bool showTopDivider = true,
  }) {
    return ColoredBox(
      color: theme.cardBackground,
      child: SizedBox(
        height: preferredHeight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showTopDivider)
              Divider(
                height: borderWidth,
                thickness: borderWidth,
                color: theme.border,
              ),
            SizedBox(
              height: tabBarHeight,
              child: build(
                tabController: tabController,
                tabs: tabs,
                theme: theme,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static PreferredSize preferredSize({
    required TabController tabController,
    required List<String> tabs,
    required OneUITheme theme,
    bool showBackground = false,
  }) {
    return PreferredSize(
      preferredSize: Size.fromHeight(showBackground ? preferredHeight : height),
      child: tabStrip(
        tabController: tabController,
        tabs: tabs,
        theme: theme,
        showTopDivider: showBackground,
      ),
    );
  }
}

/// Pinned tab row — fixed extent; never changes height while scrolling.
class GroupTabBarHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final List<String> tabs;
  final OneUITheme theme;

  GroupTabBarHeaderDelegate({
    required this.tabController,
    required this.tabs,
    required this.theme,
  });

  @override
  double get minExtent => GroupTabBar.preferredHeight;

  @override
  double get maxExtent => GroupTabBar.preferredHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return GroupTabBar.tabStrip(
      tabController: tabController,
      tabs: tabs,
      theme: theme,
    );
  }

  @override
  bool shouldRebuild(covariant GroupTabBarHeaderDelegate oldDelegate) {
    return oldDelegate.tabController != tabController ||
        oldDelegate.tabs != tabs ||
        oldDelegate.theme != theme;
  }
}
