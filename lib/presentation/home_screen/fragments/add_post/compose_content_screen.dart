import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/core/acting/acting_context_service.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/apiClient/groups/groups_node_api_service.dart';
import 'package:doctak_app/data/apiClient/shared_api_service.dart';
import 'package:doctak_app/data/models/group_model/group_enhanced_models.dart';
import 'package:doctak_app/presentation/home_screen/fragments/add_post/bloc/add_post_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/add_post/bloc/add_post_event.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/feed_card_shell.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/hashtag_rich_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nb_utils/nb_utils.dart';

enum ComposeTab { update, poll, blog }

/// When set, composer posts/polls/articles are created in this group.
class ComposeGroupTarget {
  final String groupId;
  final String groupName;
  final String? groupLogo;
  final bool enablePolls;
  final bool requiresApproval;

  const ComposeGroupTarget({
    required this.groupId,
    required this.groupName,
    this.groupLogo,
    this.enablePolls = true,
    this.requiresApproval = false,
  });

  factory ComposeGroupTarget.fromDetail(GroupDetailModel group) {
    return ComposeGroupTarget(
      groupId: group.routeId,
      groupName: group.name,
      groupLogo: group.logoImage,
      enablePolls: group.settings.enablePolls,
      requiresApproval: group.capabilities.requiresApproval,
    );
  }
}

/// Existing media attached to a post (for edit mode).
class ComposeExistingMedia {
  final String id;
  final String mediaType;
  final String mediaPath;
  final String previewUrl;

  const ComposeExistingMedia({
    required this.id,
    required this.mediaType,
    required this.mediaPath,
    required this.previewUrl,
  });

  bool get canRemove => id.isNotEmpty && id != 'legacy-image';
}

/// Data for editing an existing post, poll, or blog (mirrors web composer).
class ComposeEditData {
  final String id;
  final ComposeTab tab;
  final String? title;
  final String? body;
  final String? description;
  final List<String>? pollOptions;
  final String? excerpt;
  final String? content;
  final String? slug;
  final String? coverImage;
  final List<ComposeExistingMedia>? existingMedia;

  const ComposeEditData({
    required this.id,
    required this.tab,
    this.title,
    this.body,
    this.description,
    this.pollOptions,
    this.excerpt,
    this.content,
    this.slug,
    this.coverImage,
    this.existingMedia,
  });
}

/// Unified create screen matching the doctak-node composer.
/// Tabs: Update (post + media), Poll, Blog. Update reuses [AddPostBloc]'s
/// proven multipart upload path; Poll/Blog call the doctak-node create APIs.
class ComposeContentScreen extends StatefulWidget {
  final ComposeTab initialTab;
  final ComposeEditData? editData;
  final ComposeGroupTarget? groupTarget;

  /// Prefill Update-tab body (e.g. shared URL / text from another app).
  final String? initialBody;

  /// Local image paths to attach on create (e.g. shared gallery images).
  final List<String> initialImagePaths;

  /// Called after a successful create so the caller can refresh the feed.
  final VoidCallback onPosted;

  const ComposeContentScreen({
    super.key,
    this.initialTab = ComposeTab.update,
    this.editData,
    this.groupTarget,
    this.initialBody,
    this.initialImagePaths = const [],
    required this.onPosted,
  });

  @override
  State<ComposeContentScreen> createState() => _ComposeContentScreenState();
}

class _ComposeContentScreenState extends State<ComposeContentScreen> {
  final AddPostBloc _addPostBloc = AddPostBloc();
  final SharedApiService _api = SharedApiService();
  final ImagePicker _picker = ImagePicker();

  late ComposeTab _tab = widget.editData?.tab ?? widget.initialTab;
  String _privacy = 'public';
  bool _submitting = false;
  bool _loadingBlog = false;

  bool get _isEdit => widget.editData != null;

  bool get _isGroupMode => widget.groupTarget != null && !_isEdit;

  // Update tab
  final TextEditingController _bodyCtrl = TextEditingController();
  final TextEditingController _tagCtrl = TextEditingController();
  final List<String> _hashtags = [];

  // Poll tab
  final TextEditingController _pollQuestionCtrl = TextEditingController();
  final TextEditingController _pollDescriptionCtrl = TextEditingController();
  final List<TextEditingController> _pollOptionCtrls = [
    TextEditingController(),
    TextEditingController(),
  ];
  int _pollDurationValue = 1;
  String _pollDurationUnit = 'days';
  bool _pollMultiple = false;
  bool _pollShowVoters = true;
  bool _pollAnonymous = false;
  bool _pollAllowAddOptions = false;
  bool _pollAllowChangeVote = false;

  // Blog tab
  final TextEditingController _blogTitleCtrl = TextEditingController();
  final TextEditingController _blogSlugCtrl = TextEditingController();
  final TextEditingController _blogExcerptCtrl = TextEditingController();
  final TextEditingController _blogContentCtrl = TextEditingController();
  final TextEditingController _blogMetaTitleCtrl = TextEditingController();
  final TextEditingController _blogMetaDescCtrl = TextEditingController();
  bool _blogSlugEdited = false;
  bool _blogCoverUploading = false;
  bool _showBlogSeo = false;
  String? _blogCoverPath;
  String? _blogCoverPreviewUrl;
  String? _blogCategoryId;
  List<Map<String, dynamic>> _blogCategories = [];
  GroupPostMediaUpload? _groupCoverUpload;

  // Post edit — existing media from server + removals
  List<ComposeExistingMedia> _existingMedia = [];
  final Set<String> _removedMediaIds = {};

  @override
  void initState() {
    super.initState();
    _applyEditData();
    _applyInitialSharePrefill();
    _loadBlogCategories();
    _blogTitleCtrl.addListener(_syncBlogSlugFromTitle);
    if (_isEdit && widget.editData!.tab == ComposeTab.update) {
      _loadPostMediaForEdit(widget.editData!.id);
    }
  }

  void _applyInitialSharePrefill() {
    if (_isEdit) return;
    final initial = widget.initialBody?.trim();
    if (initial != null && initial.isNotEmpty && _bodyCtrl.text.isEmpty) {
      _bodyCtrl.text = initial;
    }
    for (final path in widget.initialImagePaths) {
      if (path.trim().isEmpty) continue;
      _addPostBloc.add(
        SelectedFiles(pickedfiles: XFile(path), isRemove: false),
      );
    }
  }

  void _syncBlogSlugFromTitle() {
    if (!_blogSlugEdited && !_isEdit) {
      _blogSlugCtrl.text = _slugify(_blogTitleCtrl.text);
    }
    setState(() {});
  }

  Future<void> _loadBlogCategories() async {
    final res = await _api.getBlogCategories();
    if (!mounted) return;
    if (res.success) {
      setState(() => _blogCategories = res.data ?? []);
    }
  }

  static String _slugify(String value) {
    var s = value
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    if (s.length > 190) s = s.substring(0, 190);
    return s;
  }

  void _applyEditData() {
    final edit = widget.editData;
    if (edit == null) return;

    switch (edit.tab) {
      case ComposeTab.update:
        _bodyCtrl.text = edit.body ?? '';
        if (edit.existingMedia != null && edit.existingMedia!.isNotEmpty) {
          _existingMedia = List.from(edit.existingMedia!);
        }
        break;
      case ComposeTab.poll:
        _pollQuestionCtrl.text = edit.title ?? '';
        _pollDescriptionCtrl.text = edit.description ?? '';
        final opts = edit.pollOptions;
        if (opts != null && opts.isNotEmpty) {
          for (final c in _pollOptionCtrls) {
            c.dispose();
          }
          _pollOptionCtrls
            ..clear()
            ..addAll(opts.map((opt) => TextEditingController(text: opt)));
        }
        break;
      case ComposeTab.blog:
        _blogTitleCtrl.text = edit.title ?? '';
        _blogExcerptCtrl.text = edit.excerpt ?? '';
        if (edit.slug != null && edit.slug!.isNotEmpty) {
          _blogSlugCtrl.text = edit.slug!;
          _blogSlugEdited = true;
        }
        if (edit.coverImage != null && edit.coverImage!.isNotEmpty) {
          _blogCoverPreviewUrl = AppData.fullImageUrl(edit.coverImage);
          _blogCoverPath = edit.coverImage;
        }
        if (edit.content != null && edit.content!.isNotEmpty) {
          _blogContentCtrl.text = edit.content!;
        } else {
          _loadBlogContent(edit.id);
        }
        break;
    }
  }

  Future<void> _loadBlogContent(String blogId) async {
    setState(() => _loadingBlog = true);
    final res = await _api.getBlogDetail(blogId: blogId);
    if (!mounted) return;
    setState(() {
      _loadingBlog = false;
      if (res.success && res.data != null) {
        final data = res.data!;
        final content = data['content']?.toString();
        if (content != null && content.isNotEmpty) {
          _blogContentCtrl.text = content;
        }
        final slug = data['slug']?.toString();
        if (slug != null && slug.isNotEmpty && _blogSlugCtrl.text.isEmpty) {
          _blogSlugCtrl.text = slug;
          _blogSlugEdited = true;
        }
        final cover = data['coverImage']?.toString();
        if (cover != null && cover.isNotEmpty && _blogCoverPreviewUrl == null) {
          _blogCoverPath = cover;
          _blogCoverPreviewUrl = AppData.fullImageUrl(cover);
        }
        final categoryId = data['categoryId']?.toString();
        if (categoryId != null && categoryId.isNotEmpty) {
          _blogCategoryId = categoryId;
        }
      }
    });
  }

  Future<void> _loadPostMediaForEdit(String postId) async {
    final res = await _api.getPostV1(postId: postId);
    if (!mounted) return;
    if (!res.success || res.data == null) return;

    final root = res.data!;
    final post = root['post'] is Map
        ? Map<String, dynamic>.from(root['post'] as Map)
        : root;
    final mediaList = <ComposeExistingMedia>[];

    final media = post['media'];
    if (media is List) {
      for (final raw in media) {
        if (raw is! Map) continue;
        final m = Map<String, dynamic>.from(raw);
        final id = '${m['id'] ?? ''}';
        final path =
            (m['media_path'] ?? m['mediaPath'] ?? '').toString().trim();
        if (path.isEmpty) continue;
        final type =
            (m['media_type'] ?? m['mediaType'] ?? 'image').toString();
        mediaList.add(
          ComposeExistingMedia(
            id: id,
            mediaType: type,
            mediaPath: path,
            previewUrl: AppData.fullImageUrl(path),
          ),
        );
      }
    }

    final image = post['image']?.toString().trim();
    if (mediaList.isEmpty && image != null && image.isNotEmpty) {
      mediaList.add(
        ComposeExistingMedia(
          id: 'legacy-image',
          mediaType: 'image',
          mediaPath: image,
          previewUrl: AppData.fullImageUrl(image),
        ),
      );
    }

    setState(() => _existingMedia = mediaList);
  }

  bool get _hasVisibleExistingMedia =>
      _existingMedia.any((m) => !_removedMediaIds.contains(m.id));

  static const _privacyLabels = {
    'public': 'Public',
    'connections': 'Connections',
    'only_me': 'Only me',
  };

  @override
  void dispose() {
    _addPostBloc.close();
    _bodyCtrl.dispose();
    _tagCtrl.dispose();
    _pollQuestionCtrl.dispose();
    _pollDescriptionCtrl.dispose();
    for (final c in _pollOptionCtrls) {
      c.dispose();
    }
    _blogTitleCtrl.dispose();
    _blogSlugCtrl.dispose();
    _blogExcerptCtrl.dispose();
    _blogContentCtrl.dispose();
    _blogMetaTitleCtrl.dispose();
    _blogMetaDescCtrl.dispose();
    super.dispose();
  }

  bool get _canPost {
    if (_loadingBlog) return false;
    switch (_tab) {
      case ComposeTab.update:
        if (_isEdit) {
          return _bodyCtrl.text.trim().isNotEmpty ||
              _addPostBloc.imagefiles.isNotEmpty ||
              _hasVisibleExistingMedia;
        }
        return _bodyCtrl.text.trim().isNotEmpty ||
            _addPostBloc.imagefiles.isNotEmpty;
      case ComposeTab.poll:
        if (_isEdit) {
          return _pollQuestionCtrl.text.trim().isNotEmpty;
        }
        final opts =
            _pollOptionCtrls.where((c) => c.text.trim().isNotEmpty).length;
        return _pollQuestionCtrl.text.trim().isNotEmpty && opts >= 2;
      case ComposeTab.blog:
        if (_isGroupMode) {
          return !_blogCoverUploading &&
              _blogTitleCtrl.text.trim().isNotEmpty &&
              _blogContentCtrl.text.trim().isNotEmpty;
        }
        return !_blogCoverUploading &&
            _blogTitleCtrl.text.trim().isNotEmpty &&
            (_isEdit || _blogContentCtrl.text.trim().isNotEmpty);
    }
  }

  void _done(String message) {
    toast(message);
    widget.onPosted();
    if (mounted) Navigator.of(context).pop();
  }

  // ─── Submit handlers ────────────────────────────────────────────────

  void _submit() {
    if (_submitting || !_canPost) return;
    switch (_tab) {
      case ComposeTab.update:
        _submitUpdate();
        break;
      case ComposeTab.poll:
        _submitPoll();
        break;
      case ComposeTab.blog:
        _submitBlog();
        break;
    }
  }

  void _submitUpdate() {
    if (_isEdit) {
      _submitUpdateEdit();
      return;
    }
    if (_isGroupMode) {
      _submitGroupUpdate();
      return;
    }
    var body = _bodyCtrl.text.trim();
    if (_hashtags.isNotEmpty) {
      final tagLine = _hashtags.map((t) => '#$t').join(' ');
      body = body.isEmpty ? tagLine : '$body\n\n$tagLine';
    }
    _addPostBloc.title = body;
    _addPostBloc.privacy = _privacy;
    _addPostBloc.add(AddPostDataEvent());
  }

  Future<void> _submitGroupUpdate() async {
    final target = widget.groupTarget!;
    setState(() => _submitting = true);
    try {
      var body = _bodyCtrl.text.trim();
      if (_hashtags.isNotEmpty) {
        final tagLine = _hashtags.map((t) => '#$t').join(' ');
        body = body.isEmpty ? tagLine : '$body\n\n$tagLine';
      }
      final uploads = <GroupPostMediaUpload>[];
      for (final f in _addPostBloc.imagefiles) {
        uploads.add(
          await GroupsNodeApiService.uploadPostMedia(target.groupId, File(f.path)),
        );
      }
      await GroupsNodeApiService.createGroupPost(
        target.groupId,
        body: body,
        media: uploads.isEmpty ? null : uploads,
      );
      if (!mounted) return;
      setState(() => _submitting = false);
      _done(
        target.requiresApproval
            ? 'Post submitted for approval'
            : 'Post created successfully',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      toast('$e');
    }
  }

  Future<void> _submitUpdateEdit() async {
    setState(() => _submitting = true);

    final newMedia = <Map<String, dynamic>>[];
    for (final f in _addPostBloc.imagefiles) {
      final upload = await _api.uploadPostMedia(File(f.path));
      if (!upload.success || upload.data == null) {
        if (!mounted) return;
        setState(() => _submitting = false);
        toast(upload.message ?? 'Failed to upload media');
        return;
      }
      final media = upload.data!['media'];
      if (media is Map) {
        newMedia.add(Map<String, dynamic>.from(media));
      }
    }

    final removeIds = _removedMediaIds
        .where((id) => id.isNotEmpty && id != 'legacy-image')
        .toList();

    final res = await _api.updatePost(
      postId: widget.editData!.id,
      body: _bodyCtrl.text.trim(),
      title: widget.editData!.title,
      newMedia: newMedia.isEmpty ? null : newMedia,
      removeMediaIds: removeIds.isEmpty ? null : removeIds,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res.success) {
      _done('Post updated');
    } else {
      toast(res.message ?? 'Failed to update post');
    }
  }

  Future<void> _submitPoll() async {
    setState(() => _submitting = true);
    if (_isGroupMode) {
      await _submitGroupPoll();
      return;
    }
    if (_isEdit) {
      final res = await _api.updatePoll(
        pollId: widget.editData!.id,
        title: _pollQuestionCtrl.text.trim(),
        description: _pollDescriptionCtrl.text.trim().isEmpty
            ? null
            : _pollDescriptionCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() => _submitting = false);
      if (res.success) {
        _done('Poll updated');
      } else {
        toast(res.message ?? 'Failed to update poll');
      }
      return;
    }

    final options = _pollOptionCtrls
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    final res = await _api.createPoll(
      title: _pollQuestionCtrl.text.trim(),
      description: _pollDescriptionCtrl.text.trim().isEmpty
          ? null
          : _pollDescriptionCtrl.text.trim(),
      options: options,
      durationValue: _pollDurationValue,
      durationUnit: _pollDurationUnit,
      isMultipleChoice: _pollMultiple,
      showVoters: _pollShowVoters,
      isAnonymous: _pollAnonymous,
      allowAddOptions: _pollAllowAddOptions,
      allowChangeVote: _pollAllowChangeVote,
      privacy: _privacy,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res.success) {
      _done('Poll created');
    } else {
      toast(res.message ?? 'Failed to create poll');
    }
  }

  Future<void> _submitGroupPoll() async {
    final target = widget.groupTarget!;
    try {
      final options = _pollOptionCtrls
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      await GroupsNodeApiService.createPoll(
        target.groupId,
        title: _pollQuestionCtrl.text.trim(),
        description: _pollDescriptionCtrl.text.trim(),
        options: options,
        allowMultipleSelections: _pollMultiple,
        anonymousVoting: _pollAnonymous,
        durationValue: _pollDurationValue,
        durationUnit: _pollDurationUnit,
        showVoters: _pollShowVoters,
      );
      if (!mounted) return;
      setState(() => _submitting = false);
      _done(target.requiresApproval ? 'Poll submitted for approval' : 'Poll created');
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      toast('$e');
    }
  }

  Future<void> _submitBlog() async {
    setState(() => _submitting = true);
    if (_isGroupMode) {
      await _submitGroupBlog();
      return;
    }
    if (_isEdit) {
      final res = await _api.updateBlog(
        blogId: widget.editData!.id,
        title: _blogTitleCtrl.text.trim(),
        excerpt: _blogExcerptCtrl.text.trim().isEmpty
            ? null
            : _blogExcerptCtrl.text.trim(),
        content: _blogContentCtrl.text.trim().isEmpty
            ? null
            : _blogContentCtrl.text.trim(),
        slug: _blogSlugCtrl.text.trim().isEmpty
            ? null
            : _blogSlugCtrl.text.trim(),
        coverImage: _blogCoverPath,
      );
      if (!mounted) return;
      setState(() => _submitting = false);
      if (res.success) {
        _done('Blog updated');
      } else {
        toast(res.message ?? 'Failed to update blog');
      }
      return;
    }

    final res = await _api.createBlog(
      title: _blogTitleCtrl.text.trim(),
      content: _blogContentCtrl.text.trim(),
      excerpt: _blogExcerptCtrl.text.trim().isEmpty
          ? null
          : _blogExcerptCtrl.text.trim(),
      slug: _blogSlugCtrl.text.trim().isEmpty
          ? null
          : _blogSlugCtrl.text.trim(),
      coverImage: _blogCoverPath,
      categoryId: _blogCategoryId,
      metaTitle: _blogMetaTitleCtrl.text.trim().isEmpty
          ? null
          : _blogMetaTitleCtrl.text.trim(),
      metaDescription: _blogMetaDescCtrl.text.trim().isEmpty
          ? null
          : _blogMetaDescCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res.success) {
      _done('Blog published');
    } else {
      toast(res.message ?? 'Failed to publish blog');
    }
  }

  Future<void> _submitGroupBlog() async {
    final target = widget.groupTarget!;
    try {
      final title = _blogTitleCtrl.text.trim();
      final content = _blogContentCtrl.text.trim();
      final excerpt = _blogExcerptCtrl.text.trim();
      final uploads = _groupCoverUpload != null ? [_groupCoverUpload!] : null;
      await GroupsNodeApiService.createGroupPost(
        target.groupId,
        body: content,
        title: title,
        postType: 'blog',
        caption: excerpt.isNotEmpty
            ? excerpt
            : (content.length > 160 ? '${content.substring(0, 157)}…' : content),
        media: uploads,
      );
      if (!mounted) return;
      setState(() => _submitting = false);
      _done(
        target.requiresApproval
            ? 'Article submitted for approval'
            : 'Article published',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      toast('$e');
    }
  }

  // ─── Media (update tab) ─────────────────────────────────────────────

  Future<void> _pickImages() async {
    try {
      final files = await _picker.pickMultiImage();
      for (final f in files) {
        _addPostBloc.add(SelectedFiles(pickedfiles: f, isRemove: false));
      }
      setState(() {});
    } catch (_) {}
  }

  Future<void> _pickCamera() async {
    try {
      final f = await _picker.pickImage(source: ImageSource.camera);
      if (f != null) {
        _addPostBloc.add(SelectedFiles(pickedfiles: f, isRemove: false));
        setState(() {});
      }
    } catch (_) {}
  }

  Future<void> _pickVideo() async {
    try {
      final f = await _picker.pickVideo(source: ImageSource.gallery);
      if (f != null) {
        _addPostBloc.add(SelectedFiles(pickedfiles: f, isRemove: false));
        setState(() {});
      }
    } catch (_) {}
  }

  void _addHashtag() {
    final raw = _tagCtrl.text.trim().replaceAll('#', '');
    if (raw.isEmpty) return;
    if (!_hashtags.contains(raw)) {
      setState(() => _hashtags.add(raw));
    }
    _tagCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return BlocListener<AddPostBloc, AddPostState>(
      bloc: _addPostBloc,
      listener: (context, state) {
        if (_isGroupMode) return;
        if (state is ResponseLoadedState) {
          _done('Post created successfully');
        } else if (state is DataError) {
          toast(state.errorMessage.replaceAll('Error uploading post: ', ''));
        }
      },
      child: Scaffold(
        backgroundColor: theme.cardBackground,
        appBar: _buildAppBar(theme),
        body: Column(
          children: [
            _buildTabs(theme),
            Divider(height: 1, color: theme.divider),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: _buildTabBody(theme),
              ),
            ),
            if (_tab == ComposeTab.update) _buildBottomToolbar(theme),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(OneUITheme theme) {
    return AppBar(
      backgroundColor: theme.cardBackground,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: Icon(Icons.close, color: theme.textPrimary),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(_screenTitle, style: theme.titleMedium),
      centerTitle: false,
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: _PostButton(
            enabled: _canPost && !_submitting,
            loading: _submitting,
            label: _submitLabel,
            onTap: _submit,
            theme: theme,
          ),
        ),
      ],
    );
  }

  String get _screenTitle {
    if (_isEdit) {
      switch (_tab) {
        case ComposeTab.poll:
          return 'Edit poll';
        case ComposeTab.blog:
          return 'Edit article';
        case ComposeTab.update:
          return 'Edit post';
      }
    }
    switch (_tab) {
      case ComposeTab.poll:
        return 'Create a poll';
      case ComposeTab.blog:
        return 'New article';
      case ComposeTab.update:
        return 'New post';
    }
  }

  String get _submitLabel {
    if (_isEdit) return 'Save';
    switch (_tab) {
      case ComposeTab.poll:
        return 'Publish poll';
      case ComposeTab.blog:
        return 'Publish';
      case ComposeTab.update:
        return 'Post';
    }
  }

  Widget _buildTabs(OneUITheme theme) {
    if (_isEdit) return const SizedBox.shrink();

    Widget tab(String label, ComposeTab value, IconData icon) {
      final active = _tab == value;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: () => setState(() => _tab = value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: active ? theme.primary : theme.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(icon,
                    size: 16,
                    color: active ? Colors.white : theme.textSecondary),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : theme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          tab('Update', ComposeTab.update, Icons.edit_outlined),
          if (!_isGroupMode || widget.groupTarget!.enablePolls)
            tab('Poll', ComposeTab.poll, Icons.bar_chart_rounded),
          tab('Blog', ComposeTab.blog, Icons.article_outlined),
        ],
      ),
    );
  }

  Widget _buildTabBody(OneUITheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_tab != ComposeTab.poll) ...[
          _buildAuthorRow(theme),
          const SizedBox(height: 16),
        ] else if (!_isEdit) ...[
          _buildPollingAsRow(theme),
          const SizedBox(height: 16),
        ] else ...[
          _buildAuthorRow(theme),
          const SizedBox(height: 16),
        ],
        switch (_tab) {
          ComposeTab.update => _buildUpdateBody(theme),
          ComposeTab.poll => _buildPollBody(theme),
          ComposeTab.blog => _buildBlogBody(theme),
        },
      ],
    );
  }

  /// Business page currently being acted as (null → personal profile).
  ActingOrganization? get _actingOrg =>
      ActingContextService.instance.organization;

  Widget _orgAvatar(OneUITheme theme, ActingOrganization org, double size) {
    final logo = (org.logoUrl != null && org.logoUrl!.isNotEmpty)
        ? AppData.fullImageUrl(org.logoUrl!)
        : '';
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.avatarBackground,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(Icons.business_rounded,
          size: size * 0.5, color: theme.primary),
    );
    if (logo.isEmpty) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.28),
      child: CachedNetworkImage(
        imageUrl: logo,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => fallback,
        errorWidget: (_, __, ___) => fallback,
      ),
    );
  }

  Widget _buildPollingAsRow(OneUITheme theme) {
    final org = _actingOrg;
    final specialty = AppData.specialty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          if (org != null)
            _orgAvatar(theme, org, 36)
          else
            ValueListenableBuilder<String>(
              valueListenable: AppData.profilePicNotifier,
              builder: (_, pic, __) {
                final url = pic.isNotEmpty ? pic : AppData.profilePicUrl;
                if (url.isEmpty) {
                  return CircleAvatar(
                    radius: 18,
                    backgroundColor: theme.avatarBackground,
                    child:
                        Icon(Icons.person, size: 18, color: theme.avatarText),
                  );
                }
                return ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: url,
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'POLLING AS',
                  style: theme.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: theme.textSecondary,
                  ),
                ),
                Text(
                  org?.name ??
                      (AppData.name.isNotEmpty ? AppData.name : 'You'),
                  style: theme.titleSmall.copyWith(fontSize: 14),
                ),
                if (org != null)
                  Text(org.typeDisplay, style: theme.caption)
                else if (specialty.isNotEmpty)
                  Text(specialty, style: theme.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorRow(OneUITheme theme) {
    if (_isGroupMode) {
      final target = widget.groupTarget!;
      final actingOrg = _actingOrg;
      final logoUrl = AppData.fullImageUrl(target.groupLogo);
      final primaryName = actingOrg?.name ??
          (AppData.name.isNotEmpty ? AppData.name : 'You');
      final primaryAvatar = actingOrg != null
          ? ((actingOrg.logoUrl != null && actingOrg.logoUrl!.isNotEmpty)
              ? AppData.fullImageUrl(actingOrg.logoUrl!)
              : null)
          : (AppData.profilePicUrl.isEmpty ? null : AppData.profilePicUrl);
      return Row(
        children: [
          FeedOverlapAvatar(
            primaryName: primaryName,
            primaryAvatarUrl: primaryAvatar,
            secondaryName: target.groupName,
            secondaryAvatarUrl: logoUrl.isEmpty ? null : logoUrl,
            size: 44,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  primaryName,
                  style: theme.titleSmall,
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: theme.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.border, width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.groups_rounded,
                          size: 14, color: theme.textSecondary),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          target.groupName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.caption.copyWith(color: theme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final org = _actingOrg;
    if (org != null) {
      // Acting as a business page — the post is attributed to the page.
      return Row(
        children: [
          _orgAvatar(theme, org, 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(org.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.titleSmall),
                const SizedBox(height: 4),
                _buildPrivacyChip(theme),
              ],
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        ValueListenableBuilder<String>(
          valueListenable: AppData.profilePicNotifier,
          builder: (_, pic, __) {
            final url = pic.isNotEmpty ? pic : AppData.profilePicUrl;
            final fallback = CircleAvatar(
              radius: 22,
              backgroundColor: theme.avatarBackground,
              child: Icon(Icons.person, color: theme.avatarText),
            );
            if (url.isEmpty) return fallback;
            return ClipOval(
              child: CachedNetworkImage(
                imageUrl: url,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                placeholder: (_, __) => fallback,
                errorWidget: (_, __, ___) => fallback,
              ),
            );
          },
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppData.name.isNotEmpty ? AppData.name : 'You',
                  style: theme.titleSmall),
              const SizedBox(height: 4),
              _buildPrivacyChip(theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacyChip(OneUITheme theme) {
    final org = _actingOrg;
    final specialty = org?.typeDisplay ?? AppData.specialty;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _showPrivacySheet(theme),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: theme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.border, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_alt_outlined, size: 14, color: theme.textSecondary),
            const SizedBox(width: 6),
            Text(
              specialty.isNotEmpty
                  ? '${_privacyLabels[_privacy]} · $specialty'
                  : '${_privacyLabels[_privacy]}',
              style: theme.caption.copyWith(color: theme.textSecondary),
            ),
            const SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 16, color: theme.textSecondary),
          ],
        ),
      ),
    );
  }

  void _showPrivacySheet(OneUITheme theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _privacyLabels.entries.map((e) {
            final selected = _privacy == e.key;
            return ListTile(
              leading: Icon(
                e.key == 'public'
                    ? Icons.public
                    : e.key == 'connections'
                        ? Icons.people_alt_outlined
                        : Icons.lock_outline,
                color: selected ? theme.primary : theme.textSecondary,
              ),
              title: Text(e.value, style: theme.bodyMedium),
              trailing: selected
                  ? Icon(Icons.check, color: theme.primary)
                  : null,
              onTap: () {
                setState(() => _privacy = e.key);
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  // ─── Update body ────────────────────────────────────────────────────

  Widget _buildUpdateBody(OneUITheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _bodyCtrl,
          maxLines: null,
          minLines: 4,
          maxLength: 500,
          onChanged: (_) => setState(() {}),
          style: theme.bodyMedium.copyWith(fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Share a case, update, or question…',
            hintStyle: theme.bodySecondary.copyWith(fontSize: 16),
            border: InputBorder.none,
            counterText: '',
          ),
        ),
        HashtagComposePreview(
          text: _bodyCtrl.text,
          style: theme.bodyMedium.copyWith(fontSize: 15),
        ),
        _buildMediaGrid(theme),
        const SizedBox(height: 16),
        _buildTagsSection(theme),
      ],
    );
  }

  Widget _buildMediaGrid(OneUITheme theme) {
    final files = _addPostBloc.imagefiles;
    final visibleExisting = _existingMedia
        .where((m) => !_removedMediaIds.contains(m.id))
        .toList();
    if (files.isEmpty && visibleExisting.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final m in visibleExisting)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: m.mediaType == 'video'
                      ? Container(
                          width: 100,
                          height: 100,
                          color: theme.surfaceVariant,
                          child: Icon(Icons.videocam,
                              color: theme.textSecondary, size: 32),
                        )
                      : CachedNetworkImage(
                          imageUrl: m.previewUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                ),
                if (m.canRemove)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _removedMediaIds.add(m.id));
                      },
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          for (final f in files)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _isVideo(f.path)
                      ? Container(
                          width: 100,
                          height: 100,
                          color: theme.surfaceVariant,
                          child: Icon(Icons.videocam,
                              color: theme.textSecondary, size: 32),
                        )
                      : Image.file(File(f.path),
                          width: 100, height: 100, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: GestureDetector(
                    onTap: () {
                      _addPostBloc
                          .add(SelectedFiles(pickedfiles: f, isRemove: true));
                      setState(() {});
                    },
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  bool _isVideo(String path) {
    final p = path.toLowerCase();
    return p.endsWith('.mp4') ||
        p.endsWith('.mov') ||
        p.endsWith('.avi') ||
        p.endsWith('.mkv');
  }

  Widget _buildTagsSection(OneUITheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TAGS',
            style: theme.caption.copyWith(
                fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final t in _hashtags)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: theme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('#$t',
                        style: theme.caption.copyWith(
                            color: theme.primary, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => setState(() => _hashtags.remove(t)),
                      child: Icon(Icons.close, size: 14, color: theme.primary),
                    ),
                  ],
                ),
              ),
            IntrinsicWidth(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 90),
                child: TextField(
                  controller: _tagCtrl,
                  onSubmitted: (_) => _addHashtag(),
                  style: theme.caption,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: '+ add tag',
                    hintStyle: theme.caption,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomToolbar(OneUITheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        border: Border(top: BorderSide(color: theme.divider, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.image_outlined, color: theme.primary),
              onPressed: _pickImages,
            ),
            IconButton(
              icon: Icon(Icons.photo_camera_outlined, color: theme.textSecondary),
              onPressed: _pickCamera,
            ),
            IconButton(
              icon: Icon(Icons.videocam_outlined, color: theme.textSecondary),
              onPressed: _pickVideo,
            ),
            IconButton(
              icon: Icon(Icons.bar_chart_rounded, color: theme.textSecondary),
              onPressed: () => setState(() => _tab = ComposeTab.poll),
            ),
            const Spacer(),
            Text('${_bodyCtrl.text.characters.length} / 500',
                style: theme.caption),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  // ─── Poll body ──────────────────────────────────────────────────────

  Widget _buildPollBody(OneUITheme theme) {
    final validOptions =
        _pollOptionCtrls.where((c) => c.text.trim().isNotEmpty).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(theme, 'Question *'),
        TextField(
          controller: _pollQuestionCtrl,
          onChanged: (_) => setState(() {}),
          style: theme.bodyMedium,
          decoration: theme.inputDecoration(hint: 'Ask something clinical…'),
        ),
        HashtagComposePreview(text: _pollQuestionCtrl.text),
        const SizedBox(height: 18),
        _fieldLabel(theme, 'Description (optional)'),
        TextField(
          controller: _pollDescriptionCtrl,
          maxLines: 3,
          onChanged: (_) => setState(() {}),
          style: theme.bodyMedium,
          decoration: theme.inputDecoration(hint: 'Add background or context…'),
        ),
        HashtagComposePreview(text: _pollDescriptionCtrl.text),
        const SizedBox(height: 18),
        if (!_isEdit) ...[
          _fieldLabel(theme, 'Options ($validOptions/${_pollOptionCtrls.length})'),
          for (int i = 0; i < _pollOptionCtrls.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _pollOptionCtrls[i],
                      onChanged: (_) => setState(() {}),
                      style: theme.bodyMedium,
                      decoration:
                          theme.inputDecoration(hint: 'Option ${i + 1}'),
                    ),
                  ),
                  if (_pollOptionCtrls.length > 2)
                    IconButton(
                      icon: Icon(Icons.remove_circle_outline,
                          color: theme.textSecondary),
                      onPressed: () {
                        setState(() {
                          _pollOptionCtrls.removeAt(i).dispose();
                        });
                      },
                    ),
                ],
              ),
            ),
          if (_pollOptionCtrls.length < 10)
            OutlinedButton.icon(
              onPressed: () => setState(
                  () => _pollOptionCtrls.add(TextEditingController())),
              icon: Icon(Icons.add, size: 18, color: theme.primary),
              label: Text('Add option',
                  style: theme.bodySecondary.copyWith(color: theme.primary)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                side: BorderSide(color: theme.border),
              ),
            ),
          const SizedBox(height: 16),
          _fieldLabel(theme, 'Duration'),
          Row(
            children: [
              Expanded(
                child: OneUICompactDropdown<int>(
                  value: _pollDurationValue,
                  items: List.generate(14, (i) => i + 1)
                      .map((v) =>
                          DropdownMenuItem(value: v, child: Text('$v')))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _pollDurationValue = v ?? 1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OneUICompactDropdown<String>(
                  value: _pollDurationUnit,
                  items: const [
                    DropdownMenuItem(value: 'hours', child: Text('Hours')),
                    DropdownMenuItem(value: 'days', child: Text('Days')),
                    DropdownMenuItem(value: 'weeks', child: Text('Weeks')),
                  ],
                  onChanged: (v) =>
                      setState(() => _pollDurationUnit = v ?? 'days'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!_isGroupMode) ...[
            _fieldLabel(theme, 'Privacy'),
            OneUICompactDropdown<String>(
              value: _privacy,
              items: _privacyLabels.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _privacy = v ?? 'public'),
            ),
            const SizedBox(height: 8),
          ],
          _pollToggle(theme, 'Allow multiple choices', _pollMultiple,
              (v) => setState(() => _pollMultiple = v)),
          _pollToggle(theme, 'Show voters', _pollShowVoters,
              (v) => setState(() => _pollShowVoters = v)),
          _pollToggle(theme, 'Anonymous poll', _pollAnonymous,
              (v) => setState(() => _pollAnonymous = v)),
          _pollToggle(theme, 'Let voters add options', _pollAllowAddOptions,
              (v) => setState(() => _pollAllowAddOptions = v)),
          _pollToggle(theme, 'Allow voters to change vote', _pollAllowChangeVote,
              (v) => setState(() => _pollAllowChangeVote = v)),
        ] else ...[
          _fieldLabel(theme, 'Options (cannot be changed after publishing)'),
          for (int i = 0; i < _pollOptionCtrls.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextField(
                controller: _pollOptionCtrls[i],
                enabled: false,
                style: theme.bodyMedium,
                decoration: theme.inputDecoration(hint: 'Option ${i + 1}'),
              ),
            ),
        ],
      ],
    );
  }

  Widget _pollToggle(
    OneUITheme theme,
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      activeColor: theme.primary,
      title: Text(label, style: theme.bodyMedium),
      value: value,
      onChanged: (v) => onChanged(v ?? false),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  Future<void> _pickBlogCover() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      setState(() => _blogCoverUploading = true);
      if (_isGroupMode) {
        final upload = await GroupsNodeApiService.uploadPostMedia(
          widget.groupTarget!.groupId,
          File(picked.path),
        );
        if (!mounted) return;
        setState(() {
          _blogCoverUploading = false;
          _groupCoverUpload = upload;
          _blogCoverPath = upload.mediaPath;
          _blogCoverPreviewUrl =
              AppData.fullImageUrl(upload.mediaPath);
        });
        return;
      }
      final res = await _api.uploadPostMedia(File(picked.path));
      if (!mounted) return;
      setState(() => _blogCoverUploading = false);
      if (res.success && res.data != null) {
        final media = res.data!['media'];
        final path = media is Map ? media['mediaPath']?.toString() : null;
        if (path != null && path.isNotEmpty) {
          setState(() {
            _blogCoverPath = path;
            _blogCoverPreviewUrl = AppData.fullImageUrl(path);
          });
        }
      } else {
        toast(res.message ?? 'Failed to upload cover');
      }
    } catch (_) {
      if (mounted) setState(() => _blogCoverUploading = false);
    }
  }

  // ─── Blog body ──────────────────────────────────────────────────────

  Widget _buildBlogBody(OneUITheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(theme, 'Title *'),
        TextField(
          controller: _blogTitleCtrl,
          style: theme.titleSmall.copyWith(fontSize: 16),
          decoration: theme.inputDecoration(
            hint: 'A compelling title for your piece',
          ),
        ),
        const SizedBox(height: 16),
        _fieldLabel(theme, 'Slug'),
        TextField(
          controller: _blogSlugCtrl,
          onChanged: (_) {
            _blogSlugEdited = true;
            setState(() {});
          },
          style: theme.bodyMedium,
          decoration: theme.inputDecoration(hint: 'auto-generated-from-title'),
        ),
        const SizedBox(height: 16),
        _fieldLabel(theme, 'Excerpt (optional, max 500 chars)'),
        TextField(
          controller: _blogExcerptCtrl,
          maxLines: 2,
          maxLength: 500,
          style: theme.bodyMedium,
          decoration: theme.inputDecoration(hint: 'A short summary'),
        ),
        const SizedBox(height: 16),
        _fieldLabel(theme, 'Cover image'),
        _buildBlogCoverPicker(theme),
        const SizedBox(height: 16),
        _fieldLabel(theme, 'Category'),
        DropdownButtonFormField<String>(
          value: _blogCategoryId?.isNotEmpty == true ? _blogCategoryId : null,
          decoration: theme.inputDecoration(hint: 'Uncategorized'),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('Uncategorized'),
            ),
            ..._blogCategories.map((c) {
              final id = c['id']?.toString() ?? '';
              final name = c['name']?.toString() ?? 'Category';
              return DropdownMenuItem<String>(
                value: id,
                child: Text(name),
              );
            }),
          ],
          onChanged: (v) => setState(() => _blogCategoryId = v),
        ),
        const SizedBox(height: 16),
        _fieldLabel(theme, 'Content * (markdown supported)'),
        TextField(
          controller: _blogContentCtrl,
          maxLines: null,
          minLines: 12,
          onChanged: (_) => setState(() {}),
          style: theme.bodyMedium,
          decoration: theme.inputDecoration(
            hint: 'Write your blog post here…',
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => setState(() => _showBlogSeo = !_showBlogSeo),
          child: Text(
            _showBlogSeo ? 'Hide SEO settings' : 'Show SEO settings',
            style: TextStyle(color: theme.primary),
          ),
        ),
        if (_showBlogSeo) ...[
          const SizedBox(height: 8),
          _fieldLabel(theme, 'Meta title'),
          TextField(
            controller: _blogMetaTitleCtrl,
            maxLength: 255,
            style: theme.bodyMedium,
            decoration: theme.inputDecoration(hint: 'SEO title'),
          ),
          const SizedBox(height: 16),
          _fieldLabel(theme, 'Meta description'),
          TextField(
            controller: _blogMetaDescCtrl,
            maxLines: 2,
            maxLength: 255,
            style: theme.bodyMedium,
            decoration: theme.inputDecoration(hint: 'SEO description'),
          ),
        ],
      ],
    );
  }

  Widget _buildBlogCoverPicker(OneUITheme theme) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (_blogCoverPreviewUrl != null && _blogCoverPreviewUrl!.isNotEmpty)
            CachedNetworkImage(
              imageUrl: _blogCoverPreviewUrl!,
              width: double.infinity,
              height: 160,
              fit: BoxFit.cover,
            )
          else
            Container(
              width: double.infinity,
              height: 120,
              color: theme.surfaceVariant,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_outlined,
                      size: 28, color: theme.textTertiary),
                  const SizedBox(height: 6),
                  Text('No cover selected', style: theme.bodySecondary),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: OutlinedButton.icon(
              onPressed: _blogCoverUploading ? null : _pickBlogCover,
              icon: _blogCoverUploading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.primary,
                      ),
                    )
                  : Icon(Icons.upload_outlined, color: theme.primary),
              label: Text(
                _blogCoverUploading
                    ? 'Uploading…'
                    : (_blogCoverPath != null ? 'Replace cover' : 'Upload cover'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(OneUITheme theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: theme.bodySecondary
              .copyWith(fontWeight: FontWeight.w600, color: theme.textPrimary)),
    );
  }
}

class _PostButton extends StatelessWidget {
  final bool enabled;
  final bool loading;
  final String label;
  final VoidCallback onTap;
  final OneUITheme theme;

  const _PostButton({
    required this.enabled,
    required this.loading,
    required this.label,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
        decoration: BoxDecoration(
          color: enabled ? theme.primary : theme.primary.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
        ),
        child: loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
      ),
    );
  }
}
