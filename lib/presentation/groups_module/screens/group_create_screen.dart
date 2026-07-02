import 'package:doctak_app/data/apiClient/groups/groups_node_api_service.dart';
import 'package:doctak_app/presentation/groups_module/screens/group_detail_screen.dart';
import 'package:doctak_app/routes/app_navigator.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/app_button.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:doctak_app/widgets/one_ui_form_dropdown.dart';
import 'package:doctak_app/widgets/one_ui_form_field.dart';
import 'package:flutter/material.dart';

class GroupCreateScreen extends StatefulWidget {
  const GroupCreateScreen({super.key});

  @override
  State<GroupCreateScreen> createState() => _GroupCreateScreenState();
}

class _GroupCreateScreenState extends State<GroupCreateScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _privacy = 'public';
  String _groupType = 'general';
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final result = await GroupsNodeApiService.createGroup(
        name: name,
        description: _descriptionController.text.trim(),
        privacy: _privacy,
        groupType: _groupType,
      );
      if (!mounted) return;
      final groupId = (result['uuid'] ?? result['id'])?.toString();
      if (groupId != null && groupId.isNotEmpty) {
        AppNavigator.pushReplacement(
          context,
          GroupDetailScreen(groupId: groupId),
        );
      } else {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: const DoctakAppBar(
        title: 'Create group',
        toolbarHeight: 56,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(
            'Start a community for your specialty, research, or clinical team.',
            style: TextStyle(fontSize: 14, color: theme.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 20),
          OneUIFormField(
            controller: _nameController,
            label: 'Group name',
            hintText: 'e.g. Cardiology Updates',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          OneUIFormField(
            controller: _descriptionController,
            label: 'Description',
            hintText: 'What is this group about?',
            maxLines: 4,
          ),
          const SizedBox(height: 14),
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
          const SizedBox(height: 14),
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
          const SizedBox(height: 24),
          AppButton(
            text: _submitting ? 'Creating…' : 'Create group',
            enabled: !_submitting,
            onTap: _submit,
            height: 48,
          ),
        ],
      ),
    );
  }
}
