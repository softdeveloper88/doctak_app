import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/unified_gallery_picker.dart';
import 'package:doctak_app/presentation/home_screen/fragments/add_post/bloc/add_post_event.dart';
import 'package:doctak_app/presentation/home_screen/fragments/add_post/components/check_place_bottom_sheet.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/display_video.dart';
import 'package:doctak_app/widgets/toast_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:nb_utils/nb_utils.dart';

import '../../../../core/utils/app/AppData.dart';
import '../../../../main.dart';
import '../../utils/SVColors.dart';
import '../../utils/SVCommon.dart';
import 'bloc/add_post_bloc.dart';

class SVAddPostFragment extends StatefulWidget {
  const SVAddPostFragment({required this.refresh, this.addPostBloc, super.key});
  final Function refresh;
  final AddPostBloc? addPostBloc;

  @override
  State<SVAddPostFragment> createState() => _SVAddPostFragmentState();
}

class _SVAddPostFragmentState extends State<SVAddPostFragment> with WidgetsBindingObserver {
  String image = '';

  // Professional background colors matching the design
  final List<String> backgroundColors = [
    '', // None (no background)
    '#F2F2F7', // Light gray
    '#E8F0FE', // Light blue
    '#E6F4EA', // Light teal/green
    '#E8EAF6', // Light indigo
    '#FCE4EC', // Light rose/pink
    '#FFF8E1', // Light amber
    '#1C1C1E', // Dark/black
    '#007AFF', // Primary blue (gradient start)
  ];
  int _selectedColorIndex = 0;
  Random random = Random();
  String currentSetColor = '';
  Color currentColor = Colors.red;
  bool _isPickingMedia = false;

  Color _hexToColor(String hexColorCode) {
    String colorCode = hexColorCode.replaceAll("#", "");
    int intValue = int.parse(colorCode, radix: 16);
    return Color(intValue).withAlpha(0xFF);
  }

  void changeColor() {
    // No longer random — color selection is handled by tapping individual swatches
  }

  void _selectBackgroundColor(int index) {
    setState(() {
      _selectedColorIndex = index;
      if (index == 0 || backgroundColors[index].isEmpty) {
        currentSetColor = '';
        currentColor = SVDividerColor;
      } else {
        currentSetColor = backgroundColors[index];
        currentColor = _hexToColor(backgroundColors[index]);
      }
      searchPeopleBloc.backgroundColor = currentSetColor;
    });
  }

  late final AddPostBloc searchPeopleBloc;
  late final bool _createdBloc;
  final TextEditingController _postTextController = TextEditingController();

  @override
  void initState() {
    currentColor = SVDividerColor;
    super.initState();
    // Use provided bloc if available to preserve state across navigation
    _createdBloc = widget.addPostBloc == null;
    searchPeopleBloc = widget.addPostBloc ?? AddPostBloc();
    WidgetsBinding.instance.addObserver(this);
    afterBuildCreated(() {
      setStatusBarColor(context.cardColor);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    setStatusBarColor(appStore.isDarkMode ? appBackgroundColorDark : SVAppLayoutBackground);
    _postTextController.dispose();
    // Close the bloc if this widget created it
    if (_createdBloc) {
      searchPeopleBloc.close();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('SVAddPost: App lifecycle changed to: $state');
    if (state == AppLifecycleState.resumed) {
      print('SVAddPost: App resumed from background');
      // Force a UI refresh when returning from gallery
      // Try restoring persisted files explicitly (in case they were cleared from memory)
      try {
        searchPeopleBloc.restorePersistedFiles();
      } catch (e) {
        print('SVAddPost: restorePersistedFiles failed: $e');
      }
      if (mounted) {
        setState(() {
          // This will trigger a rebuild with updated images
          print('SVAddPost: Force refresh - BLoC has ${searchPeopleBloc.imagefiles.length} files');
        });
      }
    }
  }

  bool _validatePost() {
    // Check if there's either text content or media files
    bool hasText = searchPeopleBloc.title.trim().isNotEmpty;
    bool hasMedia = searchPeopleBloc.imagefiles.isNotEmpty;

    return hasText || hasMedia;
  }

  void _showValidationError() {
    final theme = OneUITheme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Please add some content or select media to create a post',
          style: TextStyle(fontFamily: 'Poppins', color: Colors.white),
        ),
        backgroundColor: theme.warning,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final isDark = theme.isDark;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 100,
        leading: GestureDetector(
          onTap: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.close, color: isDark ? Colors.grey[400] : const Color(0xFF64748B), size: 20),
                const SizedBox(width: 4),
                Text(
                  translation(context).lbl_cancel,
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ),
        title: Text(
          translation(context).lbl_new_post,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1E293B),
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
        actions: [
          BlocListener<AddPostBloc, AddPostState>(
            bloc: searchPeopleBloc,
            listener: (BuildContext context, AddPostState state) {
              if (state is ResponseLoadedState) {
                try {
                  Map<String, dynamic> jsonMap = json.decode(state.message);
                  String extractMessage(dynamic messageData, String defaultMsg) {
                    if (messageData == null) return defaultMsg;
                    if (messageData is String) return messageData;
                    if (messageData is List && messageData.isNotEmpty) {
                      return messageData.first.toString();
                    }
                    return defaultMsg;
                  }

                  if (jsonMap['success'] == true) {
                    final message = extractMessage(jsonMap['message'], 'Post created successfully!');
                    showToast(message);
                    searchPeopleBloc.selectedSearchPeopleData.clear();
                    searchPeopleBloc.imagefiles.clear();
                    searchPeopleBloc.title = '';
                    searchPeopleBloc.feeling = '';
                    searchPeopleBloc.backgroundColor = '';
                    _postTextController.clear();
                    if (mounted) {
                      setState(() {
                        currentColor = SVDividerColor;
                        currentSetColor = '';
                        _selectedColorIndex = 0;
                      });
                    }
                    Future.delayed(const Duration(milliseconds: 200), () {
                      if (mounted) widget.refresh();
                    });
                  } else {
                    final errorMsg = extractMessage(jsonMap['message'], 'Failed to create post');
                    showToast(errorMsg);
                  }
                } catch (e) {
                  showToast('Post created successfully!');
                  _postTextController.clear();
                  if (mounted) {
                    setState(() {
                      currentColor = SVDividerColor;
                      currentSetColor = '';
                      _selectedColorIndex = 0;
                    });
                  }
                  Future.delayed(const Duration(milliseconds: 200), () {
                    if (mounted) widget.refresh();
                  });
                }
              } else if (state is DataError) {
                showToast(state.errorMessage);
              }
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              child: TextButton(
                onPressed: () {
                  if (_validatePost()) {
                    searchPeopleBloc.add(AddPostDataEvent());
                  } else {
                    _showValidationError();
                  }
                },
                style: TextButton.styleFrom(
                  backgroundColor: _validatePost() ? const Color(0xFF007AFF) : const Color(0xFF007AFF).withValues(alpha: 0.4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: Text(
                  translation(context).lbl_post,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(
            height: 0.5,
            color: isDark ? Colors.grey[800] : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── User Profile Section ──
                  _buildUserProfileSection(theme, isDark),
                  // ── Text Input Area ──
                  _buildInputArea(theme, isDark),
                  // ── Media Preview (if any) ──
                  BlocBuilder<AddPostBloc, AddPostState>(
                    bloc: searchPeopleBloc,
                    builder: (context, state) {
                      if (searchPeopleBloc.imagefiles.isNotEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildMediaPreview(theme),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  // ── Tagged Friends Preview ──
                  BlocBuilder<AddPostBloc, AddPostState>(
                    bloc: searchPeopleBloc,
                    builder: (context, state) {
                      if (searchPeopleBloc.selectedSearchPeopleData.isNotEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildTaggedFriendsPreview(theme),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  // ── Post Background Picker ──
                  _buildBackgroundPicker(theme, isDark),
                ],
              ),
            ),
          ),
          // ── Bottom Action Area ──
          _buildBottomActions(theme, isDark),
        ],
      ),
    );
  }

  // ── User Profile Section ──
  Widget _buildUserProfileSection(OneUITheme theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          // Avatar with online indicator
          Stack(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                    width: 2,
                  ),
                ),
                padding: const EdgeInsets.all(1),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: ValueListenableBuilder<String>(
                    valueListenable: AppData.profilePicNotifier,
                    builder: (_, picUrl, __) {
                      final url = picUrl.isNotEmpty ? picUrl : AppData.profilePicUrl;
                      return CachedNetworkImage(
                        imageUrl: url,
                        height: 56,
                        width: 56,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: isDark ? Colors.grey[800] : const Color(0xFFF2F2F7),
                          child: const Center(child: CupertinoActivityIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: isDark ? Colors.grey[800] : const Color(0xFFF2F2F7),
                          child: Icon(CupertinoIcons.person_fill, color: isDark ? Colors.grey[500] : Colors.grey[400], size: 28),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Green online dot
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Name + Specialty + Public
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppData.name,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (AppData.specialty.isNotEmpty) ...[
                      Flexible(
                        child: Text(
                          AppData.specialty,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                            color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      'Public',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'Poppins',
                        color: isDark ? Colors.grey[500] : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Input Area (large rounded card) ──
  Widget _buildInputArea(OneUITheme theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900]!.withValues(alpha: 0.5) : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.grey[700]!.withValues(alpha: 0.6) : const Color(0xFFE2E8F0).withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: TextFormField(
          controller: _postTextController,
          minLines: 8,
          maxLines: 20,
          style: TextStyle(
            fontSize: 17,
            fontFamily: 'Poppins',
            color: isDark ? Colors.grey[300] : const Color(0xFF475569),
            height: 1.5,
            fontWeight: FontWeight.w400,
          ),
          onChanged: (value) {
            searchPeopleBloc.add(TextFieldEvent(value));
            setState(() {});
          },
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'Share a clinical insight or update...',
            hintStyle: TextStyle(
              fontSize: 17,
              fontFamily: 'Poppins',
              color: isDark ? Colors.grey[600] : const Color(0xFF94A3B8),
              fontWeight: FontWeight.w400,
            ),
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  // ── Background Color Picker ──
  Widget _buildBackgroundPicker(OneUITheme theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'POST BACKGROUND',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
                letterSpacing: 1.2,
                color: isDark ? Colors.grey[500] : const Color(0xFF94A3B8),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(backgroundColors.length, (index) {
                final isSelected = _selectedColorIndex == index;
                final isNone = index == 0;
                final colorHex = backgroundColors[index];

                return GestureDetector(
                  onTap: () => _selectBackgroundColor(index),
                  child: Container(
                    margin: EdgeInsets.only(right: index < backgroundColors.length - 1 ? 12 : 0),
                    width: isSelected ? 36 : 32,
                    height: isSelected ? 36 : 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isNone
                          ? (isDark ? Colors.grey[800] : Colors.white)
                          : _hexToColor(colorHex),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF007AFF)
                            : (isDark ? Colors.grey[700]! : const Color(0xFFE2E8F0)),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF007AFF).withValues(alpha: 0.2),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: isNone
                        ? Icon(
                            Icons.block,
                            size: isSelected ? 18 : 16,
                            color: isSelected ? const Color(0xFF007AFF) : (isDark ? Colors.grey[500] : Colors.grey[400]),
                          )
                        : null,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Action Area ──
  Widget _buildBottomActions(OneUITheme theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        border: Border(
          top: BorderSide(color: isDark ? Colors.grey[800]! : const Color(0xFFE2E8F0), width: 0.5),
        ),
      ),
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Gallery & Tag Action Cards ──
          Row(
            children: [
              // Gallery Card
              Expanded(
                child: _buildActionCard(
                  isDark: isDark,
                  icon: Icons.collections_outlined,
                  iconColor: const Color(0xFF2563EB),
                  iconBgColor: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEFF6FF),
                  title: translation(context).lbl_gallery,
                  subtitle: 'Photos/Video',
                  onTap: _isPickingMedia ? null : _openGallery,
                ),
              ),
              const SizedBox(width: 16),
              // Tag Card
              Expanded(
                child: _buildActionCard(
                  isDark: isDark,
                  icon: Icons.group_add_outlined,
                  iconColor: const Color(0xFF9333EA),
                  iconBgColor: isDark ? const Color(0xFF3B1F5B) : const Color(0xFFFAF5FF),
                  title: 'Tag',
                  subtitle: 'Colleagues',
                  onTap: () => svShowShareBottomSheet(context, searchPeopleBloc),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // ── Bottom Row: Location, Activity, Quick Add ──
          Row(
            children: [
              // Location
              _buildSmallAction(
                isDark: isDark,
                icon: Icons.location_on_outlined,
                label: 'Location',
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (context) => SizedBox(
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: CheckPlaceBottomSheet(searchPeopleBloc),
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              // Activity
              _buildSmallAction(
                isDark: isDark,
                icon: Icons.mood_outlined,
                label: 'Activity',
                onTap: () {
                  // Feeling/activity - currently maps to feeling field
                },
              ),
              const Spacer(),
              // Quick Add label
              Text(
                'QUICK ADD',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                  letterSpacing: -0.3,
                  color: isDark ? Colors.grey[500] : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(width: 8),
              // Video quick add
              _buildQuickAddButton(
                isDark: isDark,
                icon: Icons.videocam_outlined,
                onTap: _isPickingMedia ? null : _openVideo,
              ),
              const SizedBox(width: 4),
              // Camera quick add
              _buildQuickAddButton(
                isDark: isDark,
                icon: Icons.photo_camera_outlined,
                onTap: _isPickingMedia ? null : _openCamera,
              ),
            ],
          ),
          // Loading indicator for media picking
          if (_isPickingMedia)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(
                backgroundColor: isDark ? Colors.grey[800] : const Color(0xFFE2E8F0),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
                minHeight: 2,
              ),
            ),
        ],
      ),
    );
  }

  // ── Action Card (Gallery / Tag) ──
  Widget _buildActionCard({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Material(
      color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.grey[700]! : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Poppins',
                      color: isDark ? Colors.grey[500] : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Small Action Button (Location / Activity) ──
  Widget _buildSmallAction({
    required bool isDark,
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: isDark ? Colors.grey[400] : const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
              color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick Add Circle Button ──
  Widget _buildQuickAddButton({
    required bool isDark,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
        ),
        child: Icon(
          icon,
          size: 20,
          color: onTap == null
              ? (isDark ? Colors.grey[700] : const Color(0xFFCBD5E1))
              : (isDark ? Colors.grey[400] : const Color(0xFF64748B)),
        ),
      ),
    );
  }

  Widget _buildMediaPreview(OneUITheme theme) {
    final files = searchPeopleBloc.imagefiles;
    final isDark = theme.isDark;
    if (files.length == 1) {
      return Container(
        margin: const EdgeInsets.only(top: 12, bottom: 8),
        constraints: const BoxConstraints(maxHeight: 260),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.grey[700]! : const Color(0xFFE2E8F0), width: 0.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              SizedBox(
                width: double.infinity,
                child: _buildMediaItem(File(files[0].path), theme, fit: BoxFit.cover),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: _buildRemoveButton(files[0], theme),
              ),
            ],
          ),
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: files.length,
        itemBuilder: (context, index) {
          final file = files[index];
          return Container(
            width: 130,
            margin: EdgeInsets.only(right: index < files.length - 1 ? 8 : 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.grey[700]! : const Color(0xFFE2E8F0), width: 0.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildMediaItem(File(file.path), theme, fit: BoxFit.cover),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: _buildRemoveButton(file, theme),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRemoveButton(XFile file, OneUITheme theme) {
    return GestureDetector(
      onTap: () {
        searchPeopleBloc.add(SelectedFiles(pickedfiles: file, isRemove: true));
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.close, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _buildMediaItem(File file, OneUITheme theme, {BoxFit fit = BoxFit.cover}) {
    final path = file.path;
    final lower = path.toLowerCase();
    if (lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.avi') || lower.endsWith('.mkv') || lower.endsWith('.webm')) {
      return Stack(
        fit: StackFit.expand,
        children: [
          DisplayVideo(selectedByte: file),
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), shape: BoxShape.circle),
                child: Icon(CupertinoIcons.play_fill, color: theme.primary, size: 18),
              ),
            ),
          ),
        ],
      );
    }
    return FutureBuilder<List<int>>(
      future: XFile(path).readAsBytes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: theme.surfaceVariant,
            child: Center(child: CupertinoActivityIndicator(color: theme.primary)),
          );
        }
        if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
          return Container(
            color: theme.surfaceVariant,
            child: Icon(CupertinoIcons.doc, color: theme.textTertiary, size: 28),
          );
        }
        return Image.memory(
          Uint8List.fromList(snapshot.data!),
          fit: fit,
          errorBuilder: (_, __, ___) => Container(
            color: theme.surfaceVariant,
            child: Icon(CupertinoIcons.doc, color: theme.textTertiary, size: 28),
          ),
        );
      },
    );
  }

  Widget _buildTaggedFriendsPreview(OneUITheme theme) {
    final isDark = theme.isDark;
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: searchPeopleBloc.selectedSearchPeopleData.map((element) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF007AFF).withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF007AFF).withValues(alpha: 0.2), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.person_fill, size: 12, color: const Color(0xFF007AFF)),
                const SizedBox(width: 4),
                Text(
                  '${element.firstName ?? ''} ${element.lastName ?? ''}'.trim(),
                  style: const TextStyle(
                    color: Color(0xFF007AFF),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    searchPeopleBloc.add(SelectFriendEvent(userData: element, isAdd: false));
                  },
                  child: const Icon(Icons.close, size: 14, color: Color(0xFF007AFF)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---- Media picker methods ----

  Future<void> _openGallery() async {
    if (_isPickingMedia) return;
    setState(() => _isPickingMedia = true);
    try {
      final List<File>? pickedFiles = await UnifiedGalleryPicker.pickMultipleImages(
        context,
        title: translation(context).lbl_choose_from_gallery,
      );
      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        for (var element in pickedFiles) {
          if (_isValidMediaFile(element.path)) {
            final xfile = XFile(element.path);
            searchPeopleBloc.add(SelectedFiles(pickedfiles: xfile, isRemove: false));
          }
        }
        setState(() {});
      }
    } catch (e) {
      debugPrint("Error picking images: $e");
    } finally {
      setState(() => _isPickingMedia = false);
    }
  }

  Future<void> _openCamera() async {
    if (_isPickingMedia) return;
    setState(() => _isPickingMedia = true);
    try {
      final File? photo = await UnifiedGalleryPicker.captureFromCamera(context);
      if (photo != null) {
        final xfile = XFile(photo.path);
        searchPeopleBloc.add(SelectedFiles(pickedfiles: xfile, isRemove: false));
        setState(() {});
      }
    } catch (e) {
      debugPrint("Error taking photo: $e");
    } finally {
      setState(() => _isPickingMedia = false);
    }
  }

  Future<void> _openVideo() async {
    if (_isPickingMedia) return;
    setState(() => _isPickingMedia = true);
    try {
      var video = await UnifiedGalleryPicker.captureVideoFromCamera(
        context,
        maxDuration: const Duration(minutes: 10),
      );
      if (video != null) {
        final xfile = XFile(video.path);
        searchPeopleBloc.add(SelectedFiles(pickedfiles: xfile, isRemove: false));
        setState(() {});
      }
    } catch (e) {
      debugPrint("Error recording video: $e");
    } finally {
      setState(() => _isPickingMedia = false);
    }
  }

  bool _isValidMediaFile(String path) {
    if (path.isEmpty) return false;
    final lower = path.toLowerCase();
    if (lower.startsWith('content://')) return true;
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.heic');
  }
}
