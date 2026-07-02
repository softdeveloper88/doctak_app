import 'package:flutter/material.dart';
import '../theme/one_ui_theme.dart';

/// A reusable One UI–style underline tab bar that matches the Drugs List
/// screen design language.
///
/// Place immediately below [DoctakAppBar] (or inside a shared header container)
/// and pair with a standard [TabBarView]:
///
/// ```dart
/// Column(
///   children: [
///     _buildHeader(theme),           // Contains DoctakAppBar + OneUITabBar
///     Expanded(
///       child: TabBarView(
///         controller: _tabController,
///         children: [...],
///       ),
///     ),
///   ],
/// )
/// ```
class OneUITabBar extends StatefulWidget {
  /// The [TabController] that drives this tab bar.
  final TabController controller;

  /// Labels for each tab. Length must match [controller.length].
  final List<String> tabs;

  /// Optional icons shown left of each label. If provided, length must equal [tabs].
  final List<IconData>? icons;

  /// Whether to draw a top divider line above the row (connect to header above).
  final bool showTopDivider;

  const OneUITabBar({
    super.key,
    required this.controller,
    required this.tabs,
    this.icons,
    this.showTopDivider = true,
  }) : assert(
         icons == null || icons.length == tabs.length,
         'icons.length must equal tabs.length',
       );

  @override
  State<OneUITabBar> createState() => _OneUITabBarState();
}

class _OneUITabBarState extends State<OneUITabBar> {
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.controller.index;
    widget.controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (mounted && !widget.controller.indexIsChanging) {
      setState(() => _selected = widget.controller.index);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return ColoredBox(
      color: theme.cardBackground,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: widget.showTopDivider
                ? BorderSide(color: theme.border, width: 0.8)
                : BorderSide.none,
          ),
        ),
        child: Row(
          children: List.generate(widget.tabs.length, (i) => _buildTab(theme, i)),
        ),
      ),
    );
  }

  Widget _buildTab(OneUITheme theme, int index) {
    final selected = _selected == index;
    final icon = widget.icons != null ? widget.icons![index] : null;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          widget.controller.animateTo(index);
          setState(() => _selected = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: theme.cardBackground,
            border: Border(
              bottom: BorderSide(
                color: selected ? theme.primary : theme.cardBackground.withValues(alpha: 0),
                width: 2.5,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    icon,
                    key: ValueKey('icon_${index}_$selected'),
                    size: 14,
                    color: selected ? theme.primary : theme.textTertiary,
                  ),
                ),
                const SizedBox(width: 5),
              ],
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: selected ? theme.primary : theme.textTertiary,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                  fontSize: 13,
                ),
                child: Text(widget.tabs[index], textAlign: TextAlign.center),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Scrollable underline tab bar matching [SVProfilePostsComponent] / profile screen.
class OneUIProfileTabBar extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<int?>? badgeCounts;
  final EdgeInsetsGeometry padding;
  final double tabSpacing;
  final bool showBottomBorder;
  final Color? backgroundColor;
  final bool matchAppBar;
  final bool? expandTabs;

  const OneUIProfileTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
    this.badgeCounts,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
    this.tabSpacing = 28,
    this.showBottomBorder = true,
    this.backgroundColor,
    this.matchAppBar = true,
    this.expandTabs,
  }) : assert(
         badgeCounts == null || badgeCounts.length == tabs.length,
         'badgeCounts.length must equal tabs.length',
       );

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final barBackground = backgroundColor ??
        (matchAppBar ? theme.appBarBackground : theme.cardBackground);
    final inactiveUnderline = barBackground.withValues(alpha: 0);
    final useExpanded = expandTabs ?? tabs.length <= 3;
    final resolvedPadding = padding.resolve(Directionality.of(context));
    final horizontalInset = EdgeInsets.only(
      left: resolvedPadding.left,
      right: resolvedPadding.right,
    );

    final tabRow = useExpanded
        ? Row(
            children: List.generate(
              tabs.length,
              (index) => Expanded(
                child: _ProfileTabItem(
                  label: tabs[index],
                  badge: badgeCounts?[index],
                  isSelected: selectedIndex == index,
                  inactiveUnderline: inactiveUnderline,
                  expanded: true,
                  onTap: () => onSelected(index),
                ),
              ),
            ),
          )
        : Padding(
            padding: const EdgeInsets.only(top: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(tabs.length, (index) {
                  return Padding(
                    padding: EdgeInsetsDirectional.only(
                      end: index == tabs.length - 1 ? 0 : tabSpacing,
                    ),
                    child: _ProfileTabItem(
                      label: tabs[index],
                      badge: badgeCounts?[index],
                      isSelected: selectedIndex == index,
                      inactiveUnderline: inactiveUnderline,
                      expanded: false,
                      onTap: () => onSelected(index),
                    ),
                  );
                }),
              ),
            ),
          );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: barBackground,
        border: showBottomBorder
            ? Border(bottom: BorderSide(color: theme.border, width: 1))
            : null,
      ),
      child: Padding(
        padding: horizontalInset,
        child: tabRow,
      ),
    );
  }
}

class _ProfileTabItem extends StatelessWidget {
  const _ProfileTabItem({
    required this.label,
    required this.isSelected,
    required this.inactiveUnderline,
    required this.expanded,
    required this.onTap,
    this.badge,
  });

  final String label;
  final int? badge;
  final bool isSelected;
  final Color inactiveUnderline;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: expanded ? 12 : 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? theme.primary : inactiveUnderline,
              width: expanded ? 2.5 : 2,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: expanded ? MainAxisAlignment.center : MainAxisAlignment.start,
          mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: expanded
                    ? theme.bodyMedium.copyWith(
                        fontFamily: 'Poppins',
                        color: isSelected ? theme.primary : theme.textTertiary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      )
                    : theme.bodyMedium.copyWith(
                        fontFamily: 'Poppins',
                        color: isSelected ? theme.primary : theme.textSecondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 14,
                      ),
              ),
            ),
            if (badge != null && badge! > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: theme.accentSoft,
                  borderRadius: theme.radiusS,
                ),
                child: Text(
                  badge! > 99 ? '99+' : '$badge',
                  style: theme.caption.copyWith(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    color: theme.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class OneUISegmentedTabBar extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<IconData>? icons;
  final List<int?>? badgeCounts;
  final EdgeInsetsGeometry padding;
  final bool isScrollable;
  final double minItemWidth;
  final double height;
  final double spacing;
  final Color? backgroundColor;
  final bool matchAppBar;
  final bool compact;

  const OneUISegmentedTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
    this.icons,
    this.badgeCounts,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.isScrollable = true,
    this.minItemWidth = 92,
    this.height = 38,
    this.spacing = 10,
    this.backgroundColor,
    this.matchAppBar = true,
    this.compact = false,
  }) : assert(
         icons == null || icons.length == tabs.length,
         'icons.length must equal tabs.length',
       ),
       assert(
         badgeCounts == null || badgeCounts.length == tabs.length,
         'badgeCounts.length must equal tabs.length',
       );

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final barBackground = backgroundColor ??
        (matchAppBar ? theme.appBarBackground : theme.cardBackground);
    final itemHeight = compact ? 32.0 : height;
    final outerPadding = compact
        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 6)
        : padding;
    final itemSpacing = compact ? 8.0 : spacing;
    final items = List.generate(tabs.length, (index) {
      return _SegmentedTabItem(
        label: tabs[index],
        icon: icons?[index],
        badgeCount: badgeCounts?[index],
        selected: index == selectedIndex,
        minWidth: minItemWidth,
        height: itemHeight,
        compact: compact,
        onTap: () => onSelected(index),
        barColor: barBackground,
      );
    });

    final row = isScrollable
        ? SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: outerPadding,
            child: Row(children: _withSpacing(items, itemSpacing)),
          )
        : Padding(
            padding: outerPadding,
            child: Row(
              children: [
                for (var index = 0; index < items.length; index++) ...[
                  if (index > 0) SizedBox(width: itemSpacing),
                  Expanded(child: items[index]),
                ],
              ],
            ),
          );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: barBackground,
        border: matchAppBar
            ? Border(bottom: BorderSide(color: theme.border, width: 1))
            : null,
      ),
      child: SizedBox(height: itemHeight + (compact ? 10 : 14), child: row),
    );
  }

  List<Widget> _withSpacing(List<Widget> children, double gap) {
    return List.generate(children.length * 2 - 1, (index) {
      if (index.isOdd) return SizedBox(width: gap);
      return children[index ~/ 2];
    });
  }
}

class _SegmentedTabItem extends StatelessWidget {
  final String label;
  final IconData? icon;
  final int? badgeCount;
  final bool selected;
  final double minWidth;
  final double height;
  final bool compact;
  final VoidCallback onTap;
  final Color barColor;

  const _SegmentedTabItem({
    required this.label,
    required this.selected,
    required this.minWidth,
    required this.height,
    required this.onTap,
    required this.barColor,
    this.compact = false,
    this.icon,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final unselectedBorder = theme.border.withValues(alpha: theme.isDark ? 0.55 : 1);
    final unselectedBackground = compact ? theme.cardBackground : theme.inputBackground;

    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: minWidth),
      child: Material(
        color: barColor,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.center,
            constraints: BoxConstraints(minHeight: height),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 16,
              vertical: compact ? 5 : 7,
            ),
            decoration: BoxDecoration(
              color: selected ? theme.primary : unselectedBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? theme.primary : unselectedBorder,
                width: selected ? 1.1 : 1,
              ),
              boxShadow: selected && !compact
                  ? [
                      BoxShadow(
                        color: theme.primary.withValues(alpha: 0.16),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: compact ? 13 : 15,
                      color: selected ? theme.buttonPrimaryText : theme.textSecondary,
                    ),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: theme.caption.copyWith(
                      fontFamily: 'Poppins',
                      fontSize: compact ? 11.5 : 12,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? theme.buttonPrimaryText : theme.textSecondary,
                    ),
                  ),
                  if (badgeCount != null && badgeCount! > 0) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: selected
                            ? theme.buttonPrimaryText.withValues(alpha: 0.22)
                            : theme.accentSoft,
                        borderRadius: theme.radiusS,
                      ),
                      child: Text(
                        badgeCount! > 99 ? '99+' : '$badgeCount',
                        style: theme.caption.copyWith(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          color: selected ? theme.buttonPrimaryText : theme.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
