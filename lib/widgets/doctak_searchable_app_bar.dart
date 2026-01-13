import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/one_ui_theme.dart';

/// A searchable app bar that provides a search field with One UI 8.5 styling
/// When search is active, the title hides and search field expands - similar to high-quality apps
class DoctakSearchableAppBar extends StatefulWidget
    implements PreferredSizeWidget {
  final String title;
  final String searchHint;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSearchSubmitted;
  final VoidCallback? onBackPressed;
  final VoidCallback? onSearchClosed;
  final bool showBackButton;
  final List<Widget>? actions;
  final bool autoFocus;
  final Duration searchDebounce;
  final Widget? customLeading;
  final bool startWithSearch;

  const DoctakSearchableAppBar({
    Key? key,
    required this.title,
    this.searchHint = 'Search...',
    this.searchController,
    this.onSearchChanged,
    this.onSearchSubmitted,
    this.onBackPressed,
    this.onSearchClosed,
    this.showBackButton = true,
    this.actions,
    this.autoFocus = true,
    this.searchDebounce = const Duration(milliseconds: 400),
    this.customLeading,
    this.startWithSearch = false,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  State<DoctakSearchableAppBar> createState() => DoctakSearchableAppBarState();
}

class DoctakSearchableAppBarState extends State<DoctakSearchableAppBar>
    with SingleTickerProviderStateMixin {
  bool _isSearching = false;
  late TextEditingController _searchController;
  late AnimationController _animationController;
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  bool get isSearching => _isSearching;

  @override
  void initState() {
    super.initState();
    _searchController = widget.searchController ?? TextEditingController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    if (widget.startWithSearch) {
      _isSearching = true;
      _animationController.value = 1.0;
    }

    _searchController.addListener(_onSearchTextChanged);
  }

  void _onSearchTextChanged() {
    setState(() {}); // Rebuild to show/hide clear button
  }

  @override
  void dispose() {
    if (widget.searchController == null) {
      _searchController.dispose();
    } else {
      _searchController.removeListener(_onSearchTextChanged);
    }
    _animationController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (_isSearching) {
        _animationController.forward();
        if (widget.autoFocus) {
          Future.delayed(const Duration(milliseconds: 100), () {
            _focusNode.requestFocus();
          });
        }
      } else {
        _animationController.reverse();
        _searchController.clear();
        widget.onSearchChanged?.call('');
        widget.onSearchClosed?.call();
        _focusNode.unfocus();
      }
    });
  }

  void openSearch() {
    if (!_isSearching) {
      toggleSearch();
    }
  }

  void closeSearch() {
    if (_isSearching) {
      toggleSearch();
    }
  }

  void clearSearch() {
    _searchController.clear();
    widget.onSearchChanged?.call('');
    _focusNode.requestFocus();
  }

  void _handleSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(widget.searchDebounce, () {
      widget.onSearchChanged?.call(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Container(
      decoration: theme.appBarDecoration,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 70,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                // Back button - only show when searching OR when showBackButton is true and not searching
                if (_isSearching)
                  _buildSearchBackButton(context, theme)
                else if (widget.showBackButton)
                  _buildBackButton(context, theme)
                else if (widget.customLeading != null)
                  widget.customLeading!,

                if (_isSearching || widget.showBackButton || widget.customLeading != null)
                  const SizedBox(width: 8),

                // Title or Search Field
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.1),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: _isSearching
                        ? _buildSearchField(theme)
                        : _buildTitle(theme),
                  ),
                ),

                // Search toggle button (only show when not searching)
                if (!_isSearching) _buildSearchButton(theme),

                // Additional actions (only show when not searching)
                if (!_isSearching && widget.actions != null) ...widget.actions!,

                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Back button that appears when searching - closes search when tapped
  Widget _buildSearchBackButton(BuildContext context, OneUITheme theme) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: toggleSearch,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          decoration: theme.iconButtonDecoration(),
          child: Icon(
            Icons.arrow_back_rounded,
            color: theme.primary,
            size: 20,
          ),
        ),
      ),
    );
  }

  /// Regular back button for navigation - only shown when not searching
  Widget _buildBackButton(BuildContext context, OneUITheme theme) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: () {
          if (widget.onBackPressed != null) {
            widget.onBackPressed!();
          } else {
            Navigator.pop(context);
          }
        },
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          decoration: theme.iconButtonDecoration(),
          child: Icon(
            CupertinoIcons.back,
            color: theme.primary,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(OneUITheme theme) {
    return Row(
      key: const ValueKey('title'),
      children: [
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            widget.title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
              color: theme.primary,
              letterSpacing: -0.2,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField(OneUITheme theme) {
    return Container(
      key: const ValueKey('search'),
      height: 48,
      decoration: BoxDecoration(
        color: theme.inputBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.primary.withOpacity(0.15), width: 1),
        boxShadow: [
          BoxShadow(
            color: theme.primary.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Icon(CupertinoIcons.search, color: theme.textTertiary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              style: TextStyle(
                fontSize: 15,
                fontFamily: 'Poppins',
                color: theme.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: widget.searchHint,
                hintStyle: TextStyle(
                  fontSize: 15,
                  fontFamily: 'Poppins',
                  color: theme.textTertiary,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              onChanged: _handleSearchChanged,
              onSubmitted: (_) => widget.onSearchSubmitted?.call(),
              textInputAction: TextInputAction.search,
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _searchController.text.isNotEmpty
                ? GestureDetector(
                    key: const ValueKey('clear'),
                    onTap: clearSearch,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(
                        CupertinoIcons.xmark_circle_fill,
                        color: theme.textTertiary,
                        size: 20,
                      ),
                    ),
                  )
                : const SizedBox(key: ValueKey('empty'), width: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchButton(OneUITheme theme) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: toggleSearch,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          decoration: theme.iconButtonDecoration(),
          child: Icon(CupertinoIcons.search, color: theme.primary, size: 20),
        ),
      ),
    );
  }
}

/// A widget that wraps content with a searchable app bar
/// Provides easy integration with existing screens
class SearchableScaffold extends StatefulWidget {
  final String title;
  final String searchHint;
  final Widget body;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final bool showBackButton;
  final Color? backgroundColor;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const SearchableScaffold({
    Key? key,
    required this.title,
    required this.body,
    this.searchHint = 'Search...',
    this.onSearchChanged,
    this.onBackPressed,
    this.actions,
    this.showBackButton = true,
    this.backgroundColor,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  }) : super(key: key);

  @override
  State<SearchableScaffold> createState() => _SearchableScaffoldState();
}

class _SearchableScaffoldState extends State<SearchableScaffold> {
  final GlobalKey<DoctakSearchableAppBarState> _appBarKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Scaffold(
      backgroundColor: widget.backgroundColor ?? theme.scaffoldBackground,
      appBar: DoctakSearchableAppBar(
        key: _appBarKey,
        title: widget.title,
        searchHint: widget.searchHint,
        onSearchChanged: widget.onSearchChanged,
        onBackPressed: widget.onBackPressed,
        actions: widget.actions,
        showBackButton: widget.showBackButton,
      ),
      body: widget.body,
      floatingActionButton: widget.floatingActionButton,
      floatingActionButtonLocation: widget.floatingActionButtonLocation,
    );
  }
}

/// A collapsible search field widget that can be placed below an app bar
/// Animates in/out when isVisible changes - perfect for screens with
/// custom app bars that need a search toggle button
class DoctakCollapsibleSearchField extends StatefulWidget {
  final bool isVisible;
  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final Duration animationDuration;
  final Duration searchDebounce;
  final double height;
  final EdgeInsets margin;
  final bool autofocus;

  const DoctakCollapsibleSearchField({
    Key? key,
    required this.isVisible,
    this.hintText = 'Search...',
    this.controller,
    this.onChanged,
    this.onClear,
    this.animationDuration = const Duration(milliseconds: 300),
    this.searchDebounce = const Duration(milliseconds: 400),
    this.height = 72,
    this.margin = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
    this.autofocus = true,
  }) : super(key: key);

  @override
  State<DoctakCollapsibleSearchField> createState() =>
      _DoctakCollapsibleSearchFieldState();
}

class _DoctakCollapsibleSearchFieldState
    extends State<DoctakCollapsibleSearchField> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(DoctakCollapsibleSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-focus when becoming visible
    if (widget.isVisible && !oldWidget.isVisible && widget.autofocus) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _focusNode.requestFocus();
      });
    }
    // Unfocus when hiding
    if (!widget.isVisible && oldWidget.isVisible) {
      _focusNode.unfocus();
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_onTextChanged);
    }
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {}); // Rebuild to show/hide clear button
  }

  void _handleSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(widget.searchDebounce, () {
      widget.onChanged?.call(value);
    });
  }

  void _clearSearch() {
    _controller.clear();
    widget.onClear?.call();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return AnimatedContainer(
      duration: widget.animationDuration,
      curve: Curves.easeInOut,
      height: widget.isVisible ? widget.height : 0,
      child: AnimatedOpacity(
        duration: widget.animationDuration,
        opacity: widget.isVisible ? 1.0 : 0.0,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Container(
            margin: widget.margin,
            height: widget.height - widget.margin.vertical,
            decoration: BoxDecoration(
              color: theme.inputBackground,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.primary.withOpacity(0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.isDark
                      ? Colors.black.withOpacity(0.2)
                      : theme.primary.withOpacity(0.05),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Icon(
                    CupertinoIcons.search,
                    color: theme.primary.withOpacity(0.6),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        color: theme.textPrimary,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: widget.hintText,
                        hintStyle: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          color: theme.textTertiary,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14.0,
                        ),
                        isDense: true,
                      ),
                      onChanged: _handleSearchChanged,
                      textInputAction: TextInputAction.search,
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _controller.text.isNotEmpty
                        ? Material(
                            key: const ValueKey('clear'),
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _clearSearch,
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(24),
                                bottomRight: Radius.circular(24),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: theme.primary.withOpacity(0.1),
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(24),
                                    bottomRight: Radius.circular(24),
                                  ),
                                ),
                                child: Icon(
                                  CupertinoIcons.xmark,
                                  color: theme.primary.withOpacity(0.6),
                                  size: 20,
                                ),
                              ),
                            ),
                          )
                        : const SizedBox(key: ValueKey('empty'), width: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A helper widget that provides a search toggle button for app bars
/// Use this in your DoctakAppBar actions to maintain consistent styling
class DoctakSearchToggleButton extends StatelessWidget {
  final bool isSearching;
  final VoidCallback onTap;
  final double size;

  const DoctakSearchToggleButton({
    Key? key,
    required this.isSearching,
    required this.onTap,
    this.size = 44,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          decoration: theme.iconButtonDecoration(),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) {
              return RotationTransition(
                turns: Tween(begin: 0.0, end: 0.25).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: Icon(
              isSearching ? CupertinoIcons.xmark : CupertinoIcons.search,
              key: ValueKey(isSearching),
              color: theme.primary,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
