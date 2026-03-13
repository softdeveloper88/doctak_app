import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/one_ui_theme.dart';

/// A reusable DocTak app bar widget that provides consistent One UI 8.5 styling
class DoctakAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final bool showOnlineIndicator;
  final IconData? titleIcon;
  final List<Widget>? actions;
  final bool centerTitle;
  final double toolbarHeight;
  final VoidCallback? onBackPressed;
  final bool showBackButton;
  final Widget? customLeading;
  final PreferredSizeWidget? bottom;
  final double? elevation;
  final Color? backgroundColor;
  final Color? titleColor;
  final double? titleFontSize;
  final FontWeight? titleFontWeight;
  final bool automaticallyImplyLeading;

  /// Optional search field widget that renders below the title row
  /// inside the same app bar container (sharing the same background).
  final Widget? searchField;

  const DoctakAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.showOnlineIndicator = false,
    this.titleIcon,
    this.actions,
    this.centerTitle = true,
    this.toolbarHeight = 70,
    this.onBackPressed,
    this.showBackButton = true,
    this.customLeading,
    this.bottom,
    this.elevation = 0,
    this.backgroundColor,
    this.titleColor,
    this.titleFontSize = 17,
    this.titleFontWeight = FontWeight.w500,
    this.automaticallyImplyLeading = true,
    this.searchField,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(toolbarHeight + (bottom?.preferredSize.height ?? 0.0));

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    // If an explicit transparent background is requested (e.g. nested inside
    // a parent header container), don't apply the AppBar's own shadow/border so
    // the parent container fully controls decoration.
    final resolvedBg = backgroundColor ?? theme.cardBackground;
    final isTransparent = resolvedBg == Colors.transparent;

    return Container(
      decoration: isTransparent
          ? const BoxDecoration(color: Colors.transparent)
          : theme.appBarDecoration.copyWith(color: resolvedBg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final appBar = AppBar(
                toolbarHeight: toolbarHeight,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                iconTheme: IconThemeData(color: theme.iconColor),
                elevation: 0,
                centerTitle: false,
                automaticallyImplyLeading: automaticallyImplyLeading,
                leading: automaticallyImplyLeading
                    ? customLeading ??
                          (showBackButton
                              ? _buildBackButton(context, theme)
                              : null)
                    : null,
                title: _buildTitle(context, theme),
                actions: actions,
                bottom: bottom,
              );

              // When placed in an unbounded-height parent (e.g. body Column),
              // AppBar's internal Flexible crashes. Wrap in SizedBox to fix.
              if (constraints.maxHeight == double.infinity) {
                return SizedBox(
                  height:
                      MediaQuery.of(context).padding.top +
                      toolbarHeight +
                      (bottom?.preferredSize.height ?? 0.0),
                  child: appBar,
                );
              }

              // When used as Scaffold.appBar, constraints are already bounded.
              return appBar;
            },
          ),
          if (searchField != null) searchField!,
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context, OneUITheme theme) {
    return IconButton(
      onPressed: onBackPressed ?? () => Navigator.pop(context),
      icon: Icon(CupertinoIcons.back, color: theme.iconColor, size: 22),
      tooltip: 'Back',
    );
  }

  Widget _buildTitle(BuildContext context, OneUITheme theme) {
    final effectiveTitleColor = titleColor ?? theme.textPrimary;
    final effectiveFontSize = (subtitle != null
        ? (titleFontSize ?? 17) - 1
        : (titleFontSize ?? 17));

    final titleWidget = Text(
      title,
      style: TextStyle(
        fontSize: effectiveFontSize,
        fontWeight: titleFontWeight,
        color: effectiveTitleColor,
        letterSpacing: -0.2,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );

    if (subtitle != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          titleWidget,
          const SizedBox(height: 1),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showOnlineIndicator) ...[
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF34C759),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: theme.textSecondary,
                    letterSpacing: 0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return titleWidget;
  }
}

/// A custom sliver app bar for screens that need scrollable content with One UI 8.5 styling
class DoctakSliverAppBar extends StatelessWidget {
  final String title;
  final IconData? titleIcon;
  final List<Widget>? actions;
  final bool centerTitle;
  final double expandedHeight;
  final bool floating;
  final bool pinned;
  final bool snap;
  final Widget? flexibleSpace;
  final VoidCallback? onBackPressed;
  final bool showBackButton;
  final Widget? customLeading;
  final PreferredSizeWidget? bottom;
  final double? elevation;
  final Color? backgroundColor;
  final Color? titleColor;
  final double? titleFontSize;
  final FontWeight? titleFontWeight;
  final double? collapsedHeight;

  const DoctakSliverAppBar({
    super.key,
    required this.title,
    this.titleIcon,
    this.actions,
    this.centerTitle = true,
    this.expandedHeight = 120.0,
    this.floating = false,
    this.pinned = true,
    this.snap = false,
    this.flexibleSpace,
    this.onBackPressed,
    this.showBackButton = true,
    this.customLeading,
    this.bottom,
    this.elevation = 0,
    this.backgroundColor,
    this.titleColor,
    this.titleFontSize = 17,
    this.titleFontWeight = FontWeight.w500,
    this.collapsedHeight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return SliverAppBar(
      expandedHeight: expandedHeight,
      floating: floating,
      pinned: pinned,
      snap: snap,
      collapsedHeight: collapsedHeight,
      backgroundColor: backgroundColor ?? theme.appBarBackground,
      surfaceTintColor: backgroundColor ?? theme.appBarBackground,
      iconTheme: IconThemeData(color: theme.iconColor),
      elevation: elevation,
      centerTitle: centerTitle,
      leading:
          customLeading ??
          (showBackButton ? _buildBackButton(context, theme) : null),
      title: _buildTitle(context, theme),
      actions: actions,
      bottom: bottom,
      flexibleSpace: flexibleSpace,
    );
  }

  Widget _buildBackButton(BuildContext context, OneUITheme theme) {
    return IconButton(
      onPressed: onBackPressed ?? () => Navigator.pop(context),
      icon: Icon(CupertinoIcons.back, color: theme.iconColor, size: 22),
      tooltip: 'Back',
    );
  }

  Widget _buildTitle(BuildContext context, OneUITheme theme) {
    return Text(
      title,
      style: TextStyle(
        fontSize: titleFontSize,
        fontWeight: titleFontWeight,
        color: titleColor ?? theme.textPrimary,
        letterSpacing: -0.2,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }
}
