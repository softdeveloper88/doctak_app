import 'dart:io';

import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/apiClient/groups/groups_node_api_service.dart';
import 'package:doctak_app/data/models/group_model/group_enhanced_models.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/app_button.dart';
import 'package:doctak_app/widgets/app_cached_network_image.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:doctak_app/widgets/one_ui_form_dropdown.dart';
import 'package:doctak_app/widgets/one_ui_form_field.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Edit group settings for owners/admins.
class GroupEditScreen extends StatefulWidget {
  final GroupDetailModel group;

  const GroupEditScreen({super.key, required this.group});

  @override
  State<GroupEditScreen> createState() => _GroupEditScreenState();
}

class _GroupEditScreenState extends State<GroupEditScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _purposeController = TextEditingController();
  final _guidelinesController = TextEditingController();
  final _picker = ImagePicker();

  late String _privacy;
  late String _groupType;
  late bool _allowMemberPosts;
  late bool _requirePostApproval;
  late bool _enablePolls;
  late bool _enableDiscussions;
  late bool _enableDocumentLibrary;

  String? _logoImage;
  String? _bannerImage;
  bool _saving = false;
  String? _uploadingKind;

  @override
  void initState() {
    super.initState();
    final g = widget.group;
    _nameController.text = g.name;
    _descriptionController.text = g.description ?? '';
    _purposeController.text = g.purposeDefinition ?? '';
    _guidelinesController.text = g.communityGuidelines ?? '';
    _privacy = g.privacy;
    _groupType = g.groupType;
    _allowMemberPosts = g.settings.allowMemberPosts;
    _requirePostApproval = g.settings.requirePostApproval;
    _enablePolls = g.settings.enablePolls;
    _enableDiscussions = g.settings.enableDiscussions;
    _enableDocumentLibrary = g.settings.enableDocumentLibrary;
    _logoImage = g.logoImage;
    _bannerImage = g.bannerImage;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _purposeController.dispose();
    _guidelinesController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpload(String kind) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: kind == 'cover' ? 1600 : 800,
    );
    if (picked == null) return;

    setState(() => _uploadingKind = kind);
    try {
      final url = await GroupsNodeApiService.uploadGroupMedia(
        kind == 'cover' ? 'cover' : 'logo',
        File(picked.path),
        groupId: widget.group.routeId,
      );
      if (!mounted) return;
      setState(() {
        if (kind == 'cover') {
          _bannerImage = url;
        } else {
          _logoImage = url;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _uploadingKind = null);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group name is required.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await GroupsNodeApiService.updateGroup(widget.group.routeId, {
        'name': name,
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'purposeDefinition': _purposeController.text.trim().isEmpty
            ? null
            : _purposeController.text.trim(),
        'communityGuidelines': _guidelinesController.text.trim().isEmpty
            ? null
            : _guidelinesController.text.trim(),
        'privacy': _privacy,
        'groupType': _groupType,
        'logoImage': _logoImage,
        'bannerImage': _bannerImage,
        'allowMemberPosts': _allowMemberPosts,
        'requirePostApproval': _requirePostApproval,
        'enablePolls': _enablePolls,
        'enableDiscussions': _enableDiscussions,
        'enableDocumentLibrary': _enableDocumentLibrary,
      });
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final logoUrl = AppData.fullImageUrl(_logoImage);
    final bannerUrl = AppData.fullImageUrl(_bannerImage);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: const DoctakAppBar(title: 'Group settings', toolbarHeight: 56),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _MediaTile(
            label: 'Cover photo',
            height: 120,
            imageUrl: bannerUrl,
            uploading: _uploadingKind == 'cover',
            onTap: () => _pickAndUpload('cover'),
          ),
          const SizedBox(height: 12),
          _MediaTile(
            label: 'Group logo',
            height: 88,
            imageUrl: logoUrl,
            uploading: _uploadingKind == 'logo',
            onTap: () => _pickAndUpload('logo'),
            square: true,
          ),
          const SizedBox(height: 16),
          OneUIFormField(
            controller: _nameController,
            label: 'Group name',
            hintText: 'Enter group name',
          ),
          const SizedBox(height: 12),
          OneUIFormField(
            controller: _descriptionController,
            label: 'Description',
            hintText: 'What is this group about?',
            maxLines: 4,
          ),
          const SizedBox(height: 12),
          OneUIFormField(
            controller: _purposeController,
            label: 'Purpose',
            hintText: 'Optional purpose statement',
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          OneUIFormDropdown<String>(
            label: 'Privacy',
            value: _privacy,
            items: const ['public', 'private', 'invitation_only'],
            itemLabel: (v) {
              switch (v) {
                case 'private':
                  return 'Private';
                case 'invitation_only':
                  return 'Invite only';
                default:
                  return 'Public';
              }
            },
            onChanged: (v) => setState(() => _privacy = v ?? 'public'),
          ),
          const SizedBox(height: 12),
          OneUIFormDropdown<String>(
            label: 'Group type',
            value: _groupType,
            items: const [
              'general',
              'medical_specialty',
              'research',
              'educational',
              'clinical',
            ],
            itemLabel: (v) {
              switch (v) {
                case 'medical_specialty':
                  return 'Medical specialty';
                case 'research':
                  return 'Research';
                case 'educational':
                  return 'Educational';
                case 'clinical':
                  return 'Clinical';
                default:
                  return 'General';
              }
            },
            onChanged: (v) => setState(() => _groupType = v ?? 'general'),
          ),
          const SizedBox(height: 16),
          Text(
            'Member permissions',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: theme.textPrimary,
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Allow member posts'),
            value: _allowMemberPosts,
            onChanged: (v) => setState(() => _allowMemberPosts = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Require post approval'),
            value: _requirePostApproval,
            onChanged: (v) => setState(() => _requirePostApproval = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Enable polls'),
            value: _enablePolls,
            onChanged: (v) => setState(() => _enablePolls = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Enable discussions'),
            value: _enableDiscussions,
            onChanged: (v) => setState(() => _enableDiscussions = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Document library'),
            value: _enableDocumentLibrary,
            onChanged: (v) => setState(() => _enableDocumentLibrary = v),
          ),
          const SizedBox(height: 12),
          OneUIFormField(
            controller: _guidelinesController,
            label: 'Community guidelines',
            hintText: 'Optional rules for members',
            maxLines: 4,
          ),
          const SizedBox(height: 20),
          AppButton(
            text: _saving ? 'Saving…' : 'Save changes',
            enabled: !_saving,
            onTap: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}

class _MediaTile extends StatelessWidget {
  final String label;
  final double height;
  final String imageUrl;
  final bool uploading;
  final VoidCallback onTap;
  final bool square;

  const _MediaTile({
    required this.label,
    required this.height,
    required this.imageUrl,
    required this.uploading,
    required this.onTap,
    this.square = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: theme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: uploading ? null : onTap,
          child: Container(
            height: height,
            width: square ? height : double.infinity,
            decoration: BoxDecoration(
              color: theme.surfaceVariant,
              borderRadius: BorderRadius.circular(square ? 16 : 12),
              border: Border.all(color: theme.divider),
            ),
            clipBehavior: Clip.antiAlias,
            child: uploading
                ? Center(child: CircularProgressIndicator(color: theme.primary))
                : imageUrl.isNotEmpty
                    ? AppCachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover)
                    : Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, color: theme.textTertiary),
                            const SizedBox(height: 4),
                            Text('Tap to upload', style: TextStyle(color: theme.textTertiary, fontSize: 12)),
                          ],
                        ),
                      ),
          ),
        ),
      ],
    );
  }
}
