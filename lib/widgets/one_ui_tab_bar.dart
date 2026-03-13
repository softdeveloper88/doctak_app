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
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          top: widget.showTopDivider
              ? BorderSide(
                  color: theme.isDark ? theme.border : Colors.grey.shade100,
                  width: 0.8,
                )
              : BorderSide.none,
        ),
      ),
      child: Row(
        children: List.generate(
          widget.tabs.length,
          (i) => _buildTab(theme, i),
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
            color: Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: selected ? theme.primary : Colors.transparent,
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
