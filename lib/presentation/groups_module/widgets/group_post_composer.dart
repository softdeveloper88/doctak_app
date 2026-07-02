import 'dart:io';

import 'package:doctak_app/data/apiClient/groups/groups_node_api_service.dart';
import 'package:doctak_app/data/models/group_model/group_enhanced_models.dart';
import 'package:doctak_app/presentation/groups_module/widgets/group_circle_avatar.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class GroupPostComposer extends StatefulWidget {
  final GroupDetailModel group;
  final VoidCallback onPosted;

  const GroupPostComposer({
    super.key,
    required this.group,
    required this.onPosted,
  });

  @override
  State<GroupPostComposer> createState() => _GroupPostComposerState();
}

class _GroupPostComposerState extends State<GroupPostComposer> {
  final _controller = TextEditingController();
  final _picker = ImagePicker();
  final List<File> _images = [];
  bool _submitting = false;
  bool _pendingNotice = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() => _images.add(File(picked.path)));
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _images.isEmpty) return;
    if (_submitting) return;

    setState(() => _submitting = true);
    try {
      final uploads = <GroupPostMediaUpload>[];
      for (final file in _images) {
        uploads.add(
          await GroupsNodeApiService.uploadPostMedia(widget.group.routeId, file),
        );
      }

      final result = await GroupsNodeApiService.createGroupPost(
        widget.group.routeId,
        body: text,
        media: uploads.isEmpty ? null : uploads,
      );

      if (!mounted) return;
      final approvalStatus = result['approvalStatus']?.toString();
      setState(() {
        _controller.clear();
        _images.clear();
        _pendingNotice = approvalStatus == 'pending' ||
            widget.group.capabilities.requiresApproval;
      });
      widget.onPosted();
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
    if (!widget.group.capabilities.canPost) return const SizedBox.shrink();

    final theme = OneUITheme.of(context);
    final logoUrl = widget.group.logoImage;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GroupCircleAvatar(
                imageUrl: logoUrl,
                name: widget.group.name,
                size: 36,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLines: 4,
                  minLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Share something with ${widget.group.name}…',
                    hintStyle: TextStyle(color: theme.textTertiary, fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: TextStyle(color: theme.textPrimary, fontSize: 15, height: 1.4),
                ),
              ),
            ],
          ),
          if (_images.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 84,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(_images[index], width: 84, height: 84, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => setState(() => _images.removeAt(index)),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(2),
                            child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
          if (_pendingNotice || widget.group.capabilities.requiresApproval) ...[
            const SizedBox(height: 8),
            Text(
              _pendingNotice
                  ? 'Your post was submitted and is pending moderator approval.'
                  : 'Posts in this group are reviewed before they appear in the feed.',
              style: TextStyle(fontSize: 12, color: theme.warning, height: 1.35),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              IconButton(
                onPressed: _submitting ? null : _pickImage,
                icon: Icon(Icons.image_outlined, color: theme.primary),
                tooltip: 'Add photo',
              ),
              const Spacer(),
              AppButton(
                text: _submitting ? 'Posting…' : 'Post',
                height: 38,
                width: 96,
                enabled: !_submitting &&
                    (_controller.text.trim().isNotEmpty || _images.isNotEmpty),
                onTap: _submit,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
