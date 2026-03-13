import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/capitalize_words.dart';
import 'package:doctak_app/data/apiClient/services/network_api_service.dart';
import 'package:doctak_app/presentation/home_screen/fragments/network_fragment/people_you_may_know_screen.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/SVProfileFragment.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../localization/app_localization.dart';

/// ═══════════════════════════════════════════════════════
///  NETWORK SEARCH SCREEN — LinkedIn-style typeahead search
///  Shows quick suggestions as user types.
///  Tap suggestion → opens profile.
///  Submit search → opens PeopleYouMayKnowScreen with query.
/// ═══════════════════════════════════════════════════════
class NetworkSearchScreen extends StatefulWidget {
  const NetworkSearchScreen({super.key});

  @override
  State<NetworkSearchScreen> createState() => _NetworkSearchScreenState();
}

class _NetworkSearchScreenState extends State<NetworkSearchScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final NetworkApiService _api = NetworkApiService();

  Timer? _debounce;
  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoading = false;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    // Auto-focus the search field when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();
    if (trimmed == _lastQuery) return;
    _lastQuery = trimmed;

    if (trimmed.isEmpty) {
      setState(() {
        _suggestions = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    _debounce = Timer(const Duration(milliseconds: 300), () => _fetchSuggestions(trimmed));
  }

  Future<void> _fetchSuggestions(String query) async {
    try {
      final result = await _api.searchSuggestions(query: query);
      if (!mounted) return;
      if (_lastQuery != query) return; // Stale response
      final list = (result['suggestions'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      setState(() {
        _suggestions = list;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSubmitSearch() {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) return;
    FocusManager.instance.primaryFocus?.unfocus();
    // Navigate to full search results using existing PeopleYouMayKnowScreen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PeopleYouMayKnowScreen(initialSearch: query),
      ),
    );
  }

  void _onSuggestionTap(Map<String, dynamic> user) {
    FocusManager.instance.primaryFocus?.unfocus();
    final userId = user['id']?.toString() ?? '';
    if (userId.isNotEmpty) {
      SVProfileFragment(userId: userId)
          .launch(context, pageRouteAnimation: PageRouteAnimation.Slide);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            // ── Search Bar Row ──
            _buildSearchBar(theme),
            // ── Suggestions List ──
            Expanded(child: _buildSuggestionsList(theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(OneUITheme theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 6, 12, 6),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        boxShadow: [
          BoxShadow(
            color: theme.isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(CupertinoIcons.back, color: theme.iconColor, size: 22),
            splashRadius: 20,
          ),
          // Search text field
          Expanded(
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: theme.inputBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _focusNode.hasFocus
                      ? theme.primary.withValues(alpha: 0.3)
                      : theme.border,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _searchCtrl,
                focusNode: _focusNode,
                onChanged: _onSearchChanged,
                onSubmitted: (_) => _onSubmitSearch(),
                textInputAction: TextInputAction.search,
                style: theme.bodyMedium.copyWith(fontSize: 15),
                decoration: InputDecoration(
                  hintText: translation(context).lbl_search,
                  hintStyle: theme.bodySecondary.copyWith(fontSize: 14),
                  border: InputBorder.none,
                  prefixIcon: Icon(CupertinoIcons.search, size: 18, color: theme.textTertiary),
                  prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 0),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchCtrl.clear();
                            _onSearchChanged('');
                            _focusNode.requestFocus();
                          },
                          child: Icon(Icons.close_rounded, size: 18, color: theme.textTertiary),
                        )
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList(OneUITheme theme) {
    if (_searchCtrl.text.trim().isEmpty) {
      // Show empty state hint
      return Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Column(
          children: [
            Icon(CupertinoIcons.search, size: 48, color: theme.textTertiary.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              translation(context).lbl_search,
              style: theme.bodySecondary.copyWith(fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_isLoading && _suggestions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
            ),
          ),
        ),
      );
    }

    if (!_isLoading && _suggestions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Center(
          child: Text(
            'No results found',
            style: theme.bodySecondary.copyWith(fontSize: 14),
          ),
        ),
      );
    }

    // Build list: suggestions + "Show all results" at the bottom
    return ListView.separated(
      padding: const EdgeInsets.only(top: 4),
      itemCount: _suggestions.length + 1,
      separatorBuilder: (_, i) {
        if (i >= _suggestions.length) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsetsDirectional.only(start: 72),
          child: Divider(height: 1, color: theme.divider),
        );
      },
      itemBuilder: (ctx, i) {
        if (i < _suggestions.length) {
          return _buildSuggestionTile(theme, _suggestions[i]);
        }
        return _buildShowAllResultsTile(theme);
      },
    );
  }

  Widget _buildSuggestionTile(OneUITheme theme, Map<String, dynamic> user) {
    final name = user['fullName'] as String? ?? '';
    final specialty = user['specialty'] as String? ?? '';
    final profilePic = AppData.fullImageUrl(user['profile_pic'] as String? ?? '');
    final degree = user['degree'] as String?;
    final country = user['country'] as String? ?? '';

    // Build subtitle: "specialty · country" or just one
    String subtitle = '';
    if (specialty.isNotEmpty && country.isNotEmpty) {
      subtitle = '${capitalizeWords(specialty)} · $country';
    } else if (specialty.isNotEmpty) {
      subtitle = capitalizeWords(specialty);
    } else if (country.isNotEmpty) {
      subtitle = country;
    }

    return InkWell(
      onTap: () => _onSuggestionTap(user),
      splashColor: theme.primary.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: theme.avatarBorder, width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(21),
                child: profilePic.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: profilePic,
                        width: 42,
                        height: 42,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _buildAvatarPlaceholder(theme, name),
                        errorWidget: (_, __, ___) => _buildAvatarPlaceholder(theme, name),
                      )
                    : _buildAvatarPlaceholder(theme, name),
              ),
            ),
            const SizedBox(width: 12),
            // Name + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.titleSmall.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (degree != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: theme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            degree,
                            style: theme.caption.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: theme.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.bodySecondary.copyWith(fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            // Arrow to fill search with this name
            GestureDetector(
              onTap: () {
                _searchCtrl.text = name;
                _searchCtrl.selection = TextSelection.fromPosition(
                  TextPosition(offset: name.length),
                );
                _onSearchChanged(name);
              },
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.north_west_rounded,
                  size: 16,
                  color: theme.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShowAllResultsTile(OneUITheme theme) {
    if (_searchCtrl.text.trim().isEmpty) return const SizedBox.shrink();
    return InkWell(
      onTap: _onSubmitSearch,
      splashColor: theme.primary.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.primary.withValues(alpha: 0.08),
              ),
              child: Center(
                child: Icon(CupertinoIcons.search, size: 18, color: theme.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${translation(context).lbl_see_all} "${_searchCtrl.text.trim()}"',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.bodyMedium.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.primary,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: theme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder(OneUITheme theme, String name) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.avatarBackground,
      ),
      child: Center(
        child: name.isNotEmpty
            ? Text(
                name[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: theme.avatarText,
                  fontFamily: 'Poppins',
                ),
              )
            : Icon(Icons.person, size: 20, color: theme.primary),
      ),
    );
  }
}
