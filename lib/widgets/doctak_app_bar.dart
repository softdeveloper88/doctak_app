import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import '../presentation/home_screen/utils/SVCommon.dart';

/// A reusable DocTak app bar widget that provides consistent styling across the app
class DoctakAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
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
  final String? titleFontFamily;
  final bool automaticallyImplyLeading;

  const DoctakAppBar({
    Key? key,
    required this.title,
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
    this.titleFontSize = 18,
    this.titleFontWeight = FontWeight.w600,
    this.titleFontFamily = 'Poppins',
    this.automaticallyImplyLeading = true,
  }) : super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(
      toolbarHeight + (bottom?.preferredSize.height ?? 0.0)
  );

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: toolbarHeight,
      backgroundColor: backgroundColor ?? svGetScaffoldColor(),
      surfaceTintColor: backgroundColor ?? svGetScaffoldColor(),
      iconTheme: IconThemeData(color: context.iconColor),
      elevation: elevation,
      centerTitle: false,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: automaticallyImplyLeading
          ? customLeading ?? (showBackButton ? _buildBackButton(context) : null)
          : null,
      title: _buildTitle(context),
      actions: actions,
      bottom: bottom,
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return IconButton(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.blue[600],
          size: 16,
        ),
      ),
      onPressed: onBackPressed ?? () => Navigator.pop(context),
    );
  }

  Widget _buildTitle(BuildContext context) {
    if (titleIcon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon(
          //   titleIcon,
          //   color: titleColor ?? Colors.blue[600],
          //   size: 24,
          // ),
          // const SizedBox(width: 10),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: titleFontWeight,
                fontFamily: titleFontFamily,
                color: titleColor ?? Colors.blue[800],
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      );
    }
    
    return Text(
      title,
      style: TextStyle(
        fontSize: titleFontSize,
        fontWeight: titleFontWeight,
        fontFamily: titleFontFamily,
        color: titleColor ?? Colors.blue[800],
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }
}

/// A custom sliver app bar for screens that need scrollable content
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
  final String? titleFontFamily;
  final double? collapsedHeight;

  const DoctakSliverAppBar({
    Key? key,
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
    this.titleFontSize = 18,
    this.titleFontWeight = FontWeight.w600,
    this.titleFontFamily = 'Poppins',
    this.collapsedHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: expandedHeight,
      floating: floating,
      pinned: pinned,
      snap: snap,
      collapsedHeight: collapsedHeight,
      backgroundColor: backgroundColor ?? svGetScaffoldColor(),
      surfaceTintColor: backgroundColor ?? svGetScaffoldColor(),
      iconTheme: IconThemeData(color: context.iconColor),
      elevation: elevation,
      centerTitle: centerTitle,
      leading: customLeading ?? (showBackButton ? _buildBackButton(context) : null),
      title: _buildTitle(context),
      actions: actions,
      bottom: bottom,
      flexibleSpace: flexibleSpace,
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return IconButton(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.blue[600],
          size: 16,
        ),
      ),
      onPressed: onBackPressed ?? () => Navigator.pop(context),
    );
  }

  Widget _buildTitle(BuildContext context) {
    if (titleIcon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon(
          //   titleIcon,
          //   color: titleColor ?? Colors.blue[600],
          //   size: 24,
          // ),
          // const SizedBox(width: 10),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: titleFontWeight,
                fontFamily: titleFontFamily,
                color: titleColor ?? Colors.blue[800],
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      );
    }
    
    return Text(
      title,
      style: TextStyle(
        fontSize: titleFontSize,
        fontWeight: titleFontWeight,
        fontFamily: titleFontFamily,
        color: titleColor ?? Colors.blue[800],
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }
}