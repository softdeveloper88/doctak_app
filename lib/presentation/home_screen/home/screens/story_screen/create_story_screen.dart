import 'dart:io';

import 'package:doctak_app/core/utils/unified_gallery_picker.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/story_screen/bloc/story_bloc.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:flutter/material.dart';

/// Screen to create a new story: Photo, Video, or Text
class CreateStoryScreen extends StatefulWidget {
  final StoryBloc storyBloc;

  const CreateStoryScreen({super.key, required this.storyBloc});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Text story fields
  final TextEditingController _textController = TextEditingController();
  int _selectedColorIndex = 0;
  final List<Color> _backgroundColors = [
    const Color(0xFF0d6efd), // Blue
    const Color(0xFF6f42c1), // Purple
    const Color(0xFFe83e8c), // Pink
    const Color(0xFFdc3545), // Red
    const Color(0xFFfd7e14), // Orange
    const Color(0xFF28a745), // Green
    const Color(0xFF20c997), // Teal
    const Color(0xFF17a2b8), // Cyan
    const Color(0xFF343a40), // Dark
    const Color(0xFF6c757d), // Gray
  ];

  // Media
  File? _selectedMedia;
  String? _mediaType; // 'image' or 'video'

  // Settings
  int _duration = 24; // hours
  String _privacy = 'public';
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final l10n = translation(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: DoctakAppBar(
        title: l10n.lbl_create_story,
        showBackButton: true,
        onBackPressed: () => Navigator.pop(context),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.primary,
          indicatorWeight: 2.5,
          labelColor: theme.primary,
          unselectedLabelColor: theme.textSecondary,
          labelStyle: theme.bodySecondary.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          unselectedLabelStyle: theme.bodySecondary.copyWith(
            fontSize: 14,
          ),
          tabs: [
            Tab(icon: const Icon(Icons.text_fields), text: l10n.lbl_text),
            Tab(icon: const Icon(Icons.photo), text: l10n.lbl_photo),
            Tab(icon: const Icon(Icons.videocam), text: l10n.lbl_video),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTextTab(theme),
          _buildPhotoTab(theme),
          _buildVideoTab(theme),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // TEXT STORY TAB
  // ═══════════════════════════════════════════════
  Widget _buildTextTab(OneUITheme theme) {
    final bgColor = _backgroundColors[_selectedColorIndex];

    return Column(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: theme.radiusL,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [bgColor, bgColor.withValues(alpha: 0.7)],
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: TextField(
                  controller: _textController,
                  maxLength: 500,
                  maxLines: null,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                  decoration: InputDecoration(
                    hintText: translation(context).lbl_type_your_story,
                    hintStyle: const TextStyle(
                      color: Colors.white54,
                      fontSize: 22,
                    ),
                    border: InputBorder.none,
                    counterStyle: const TextStyle(color: Colors.white54),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Color picker
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _backgroundColors.length,
            itemBuilder: (context, index) {
              final isSelected = index == _selectedColorIndex;
              return GestureDetector(
                onTap: () => setState(() => _selectedColorIndex = index),
                child: Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: _backgroundColors[index],
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: theme.cardBackground, width: 3)
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: _backgroundColors[index]
                                  .withValues(alpha: 0.4),
                              blurRadius: 8,
                            )
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // Settings row + Post button
        _buildSettingsAndPost(theme, 'text'),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  // PHOTO STORY TAB
  // ═══════════════════════════════════════════════
  Widget _buildPhotoTab(OneUITheme theme) {
    return Column(
      children: [
        Expanded(
          child: _selectedMedia != null && _mediaType == 'image'
              ? Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: theme.radiusL,
                    image: DecorationImage(
                      image: FileImage(_selectedMedia!),
                      fit: BoxFit.contain,
                    ),
                  ),
                )
              : _buildMediaPicker(theme, 'photo'),
        ),
        _buildSettingsAndPost(theme, 'image'),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  // VIDEO STORY TAB
  // ═══════════════════════════════════════════════
  Widget _buildVideoTab(OneUITheme theme) {
    return Column(
      children: [
        Expanded(
          child: _selectedMedia != null && _mediaType == 'video'
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: theme.radiusL,
                        color: theme.isDark
                            ? Colors.black
                            : const Color(0xFF1C1C1E),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.play_circle_outline,
                          color: theme.isDark
                              ? Colors.white54
                              : Colors.white70,
                          size: 64,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 24,
                      child: Text(
                        _selectedMedia!.path.split('/').last,
                        style: theme.bodySecondary.copyWith(fontSize: 12),
                      ),
                    ),
                  ],
                )
              : _buildMediaPicker(theme, 'video'),
        ),
        _buildSettingsAndPost(theme, 'video'),
      ],
    );
  }

  Widget _buildMediaPicker(OneUITheme theme, String type) {
    final isPhoto = type == 'photo';
    final l10n = translation(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPhoto
                ? Icons.add_photo_alternate_outlined
                : Icons.videocam_outlined,
            size: 64,
            color: theme.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            isPhoto ? l10n.lbl_select_photo : l10n.lbl_select_video,
            style: theme.bodyMedium.copyWith(
              color: theme.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMediaButton(
                theme: theme,
                icon: Icons.camera_alt,
                label: l10n.lbl_camera,
                isPrimary: true,
                onTap: () => _captureFromCamera(isPhoto ? 'image' : 'video'),
              ),
              const SizedBox(width: 16),
              _buildMediaButton(
                theme: theme,
                icon: Icons.photo_library,
                label: l10n.lbl_gallery,
                isPrimary: false,
                onTap: () => _pickFromGallery(isPhoto ? 'image' : 'video'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMediaButton({
    required OneUITheme theme,
    required IconData icon,
    required String label,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? theme.primary : theme.surfaceVariant,
        foregroundColor: isPrimary ? Colors.white : theme.textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        elevation: 0,
      ),
    );
  }

  Widget _buildSettingsAndPost(OneUITheme theme, String storyType) {
    final l10n = translation(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            // Privacy & Duration row
            Row(
              children: [
                // Privacy dropdown
                Expanded(
                  child: _buildDropdownContainer(
                    theme: theme,
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _privacy,
                        isExpanded: true,
                        icon: Icon(Icons.arrow_drop_down,
                            color: theme.textSecondary),
                        dropdownColor: theme.cardBackground,
                        style: theme.bodySecondary.copyWith(fontSize: 13),
                        items: [
                          _buildPrivacyItem(
                            'public',
                            Icons.public,
                            l10n.lbl_public,
                            theme,
                          ),
                          _buildPrivacyItem(
                            'friends',
                            Icons.people,
                            l10n.lbl_friends,
                            theme,
                          ),
                          _buildPrivacyItem(
                            'private',
                            Icons.lock,
                            l10n.lbl_only_me,
                            theme,
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _privacy = value);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Duration dropdown
                Expanded(
                  child: _buildDropdownContainer(
                    theme: theme,
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _duration,
                        isExpanded: true,
                        icon: Icon(Icons.arrow_drop_down,
                            color: theme.textSecondary),
                        dropdownColor: theme.cardBackground,
                        style: theme.bodySecondary.copyWith(fontSize: 13),
                        items: [6, 12, 24, 48]
                            .map((h) => _buildDurationItem(h, theme))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => _duration = value);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Post button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isCreating ? null : () => _postStory(storyType),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: theme.primary.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                ),
                child: _isCreating
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: theme.cardBackground,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        l10n.lbl_share_story,
                        style: theme.titleSmall.copyWith(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared dropdown container decoration ──
  Widget _buildDropdownContainer({
    required OneUITheme theme,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: theme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  DropdownMenuItem<String> _buildPrivacyItem(
    String value,
    IconData icon,
    String label,
    OneUITheme theme,
  ) {
    return DropdownMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.iconColor),
          const SizedBox(width: 8),
          Text(label, style: theme.bodyMedium.copyWith(fontSize: 13)),
        ],
      ),
    );
  }

  DropdownMenuItem<int> _buildDurationItem(int hours, OneUITheme theme) {
    return DropdownMenuItem(
      value: hours,
      child: Row(
        children: [
          Icon(Icons.access_time, size: 16, color: theme.iconColor),
          const SizedBox(width: 8),
          Text(
            translation(context).lbl_hours_format(hours.toString()),
            style: theme.bodyMedium.copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }

  /// Pick media from gallery using UnifiedGalleryPicker bottom sheet
  Future<void> _pickFromGallery(String type) async {
    try {
      final l10n = translation(context);
      File? picked;

      if (type == 'image') {
        picked = await UnifiedGalleryPicker.pickSingleImage(
          context,
          title: l10n.lbl_select_photo,
        );
      } else {
        picked = await UnifiedGalleryPicker.pickSingleVideo(
          context,
          title: l10n.lbl_select_video,
        );
      }

      if (picked != null) {
        setState(() {
          _selectedMedia = picked;
          _mediaType = type;
        });
      }
    } catch (e) {
      debugPrint('Media picker error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(translation(context).msg_pick_media_failed),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Capture media using camera via UnifiedGalleryPicker
  Future<void> _captureFromCamera(String type) async {
    try {
      File? captured;

      if (type == 'image') {
        captured = await UnifiedGalleryPicker.captureFromCamera(context);
      } else {
        captured = await UnifiedGalleryPicker.captureVideoFromCamera(
          context,
          maxDuration: const Duration(seconds: 60),
        );
      }

      if (captured != null) {
        setState(() {
          _selectedMedia = captured;
          _mediaType = type;
        });
      }
    } catch (e) {
      debugPrint('Camera capture error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(translation(context).msg_pick_media_failed),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _postStory(String type) {
    final theme = OneUITheme.of(context);
    final l10n = translation(context);

    // Validate
    if (type == 'text' && _textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.msg_enter_story_text),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if ((type == 'image' || type == 'video') && _selectedMedia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.msg_select_media(
            type == 'image' ? l10n.lbl_photo.toLowerCase() : l10n.lbl_video.toLowerCase(),
          )),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    final bgHex =
        '#${_backgroundColors[_selectedColorIndex].toARGB32().toRadixString(16).substring(2)}';

    widget.storyBloc.add(CreateStoryEvent(
      type: type,
      mediaPath: _selectedMedia?.path,
      content: type == 'text' ? _textController.text.trim() : null,
      backgroundColor: type == 'text' ? bgHex : null,
      duration: _duration,
      privacy: _privacy,
    ));

    // Listen for result then pop
    late final subscription = widget.storyBloc.stream.listen((state) {});
    subscription.onData((state) {
      if (!mounted) {
        subscription.cancel();
        return;
      }
      if (state is StoryCreatedState) {
        subscription.cancel();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.message),
            behavior: SnackBarBehavior.floating,
            backgroundColor: theme.success,
          ),
        );
        Navigator.pop(context);
      } else if (state is StoryErrorState) {
        subscription.cancel();
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.message),
            behavior: SnackBarBehavior.floating,
            backgroundColor: theme.error,
          ),
        );
      }
    });
  }
}
