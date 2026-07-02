import 'dart:io';

import 'package:doctak_app/data/apiClient/groups/groups_node_api_service.dart';
import 'package:doctak_app/data/models/group_model/group_enhanced_models.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/app_button.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:doctak_app/widgets/one_ui_form_field.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Create a long-form group article (blog post_type).
class GroupArticleCreateScreen extends StatefulWidget {
  final GroupDetailModel group;

  const GroupArticleCreateScreen({super.key, required this.group});

  @override
  State<GroupArticleCreateScreen> createState() => _GroupArticleCreateScreenState();
}

class _GroupArticleCreateScreenState extends State<GroupArticleCreateScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _picker = ImagePicker();
  File? _coverImage;
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pickCover() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() => _coverImage = File(picked.path));
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty || body.isEmpty || _submitting) return;

    setState(() => _submitting = true);
    try {
      final uploads = <GroupPostMediaUpload>[];
      if (_coverImage != null) {
        uploads.add(
          await GroupsNodeApiService.uploadPostMedia(
            widget.group.routeId,
            _coverImage!,
          ),
        );
      }

      await GroupsNodeApiService.createGroupPost(
        widget.group.routeId,
        body: body,
        title: title,
        postType: 'blog',
        caption: body.length > 160 ? '${body.substring(0, 157)}…' : body,
        media: uploads.isEmpty ? null : uploads,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final canSubmit = _titleController.text.trim().isNotEmpty &&
        _bodyController.text.trim().isNotEmpty &&
        !_submitting;

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: DoctakAppBar(
        title: 'Write article',
        toolbarHeight: 56,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OneUIFormField(
            controller: _titleController,
            label: 'Title',
            hintText: 'Article headline',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          OneUIFormField(
            controller: _bodyController,
            label: 'Content',
            hintText: 'Write your article…',
            maxLines: 12,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          if (_coverImage != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                _coverImage!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => setState(() => _coverImage = null),
              icon: const Icon(Icons.close_rounded, size: 18),
              label: const Text('Remove cover image'),
            ),
          ] else
            OutlinedButton.icon(
              onPressed: _pickCover,
              icon: Icon(Icons.image_outlined, color: theme.primary),
              label: Text('Add cover image', style: TextStyle(color: theme.primary)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                side: BorderSide(color: theme.divider),
              ),
            ),
          if (widget.group.capabilities.requiresApproval) ...[
            const SizedBox(height: 12),
            Text(
              'Articles may require moderator approval before appearing in the feed.',
              style: TextStyle(fontSize: 12, color: theme.warning, height: 1.35),
            ),
          ],
          const SizedBox(height: 20),
          AppButton(
            text: _submitting ? 'Publishing…' : 'Publish article',
            height: 44,
            enabled: canSubmit,
            onTap: _submit,
          ),
        ],
      ),
    );
  }
}

void openGroupArticleCreate(BuildContext context, GroupDetailModel group) {
  Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => GroupArticleCreateScreen(group: group)),
  );
}
