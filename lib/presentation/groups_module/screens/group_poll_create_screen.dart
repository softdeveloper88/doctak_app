import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/apiClient/groups/groups_node_api_service.dart';
import 'package:doctak_app/data/models/group_model/group_enhanced_models.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/app_button.dart';
import 'package:doctak_app/widgets/app_cached_network_image.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:doctak_app/widgets/one_ui_form_field.dart';
import 'package:flutter/material.dart';

/// Group poll composer — mirrors web `GroupPollComposerModal`.
class GroupPollCreateScreen extends StatefulWidget {
  final GroupDetailModel group;

  const GroupPollCreateScreen({super.key, required this.group});

  @override
  State<GroupPollCreateScreen> createState() => _GroupPollCreateScreenState();
}

class _GroupPollCreateScreenState extends State<GroupPollCreateScreen> {
  static const _maxOptions = 10;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  int _durationValue = 1;
  String _durationUnit = 'days';
  String _resultsVisibility = 'immediate';
  bool _allowMultiple = false;
  bool _anonymous = false;
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  int get _validOptionCount =>
      _optionControllers.where((c) => c.text.trim().isNotEmpty).length;

  bool get _canSubmit =>
      _titleController.text.trim().isNotEmpty && _validOptionCount >= 2 && !_submitting;

  void _addOption() {
    if (_optionControllers.length >= _maxOptions) return;
    setState(() => _optionControllers.add(TextEditingController()));
  }

  void _removeOption(int index) {
    if (_optionControllers.length <= 2) return;
    setState(() {
      _optionControllers.removeAt(index).dispose();
    });
  }

  String _roleLabel() {
    if (widget.group.capabilities.canManage) return 'Owner';
    final role = widget.group.membership?.role;
    if (role == null) return 'Member';
    return role[0].toUpperCase() + role.substring(1);
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _submitting = true);
    try {
      await GroupsNodeApiService.createPoll(
        widget.group.routeId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        options: _optionControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList(),
        allowMultipleSelections: _allowMultiple,
        anonymousVoting: _anonymous,
        durationValue: _durationValue,
        durationUnit: _durationUnit,
        showVoters: _resultsVisibility == 'immediate',
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final logoUrl = AppData.fullImageUrl(widget.group.logoImage);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: const DoctakAppBar(
        title: 'Create poll',
        toolbarHeight: 56,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _PollingAsCard(
            theme: theme,
            name: widget.group.name,
            detail: '${widget.group.specialty ?? 'Professional community'} · ${_roleLabel()}',
            logoUrl: logoUrl,
          ),
          const SizedBox(height: 18),
          OneUIFormField(
            controller: _titleController,
            label: 'Question',
            hintText: 'Ask something clinical…',
            required: true,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          OneUIFormField(
            controller: _descriptionController,
            label: 'Description (optional)',
            hintText: 'Add background or context…',
            maxLines: 4,
          ),
          const SizedBox(height: 18),
          Text(
            'Options ($_validOptionCount/${_optionControllers.length})',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(_optionControllers.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: OneUIFormField(
                      controller: _optionControllers[index],
                      label: 'Option ${index + 1}',
                      hintText: 'Option ${index + 1}',
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  if (_optionControllers.length > 2)
                    IconButton(
                      icon: Icon(Icons.remove_circle_outline, color: theme.textSecondary),
                      onPressed: () => _removeOption(index),
                    ),
                ],
              ),
            );
          }),
          if (_optionControllers.length < _maxOptions)
            OutlinedButton.icon(
              onPressed: _addOption,
              icon: Icon(Icons.add_rounded, size: 18, color: theme.primary),
              label: Text('Add option', style: TextStyle(color: theme.primary)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                side: BorderSide(color: theme.divider),
              ),
            ),
          const SizedBox(height: 18),
          Text(
            'Duration',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OneUICompactDropdown<int>(
                  value: _durationValue,
                  items: List.generate(52, (i) => i + 1)
                      .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                      .toList(),
                  onChanged: (v) => setState(() => _durationValue = v ?? 1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OneUICompactDropdown<String>(
                  value: _durationUnit,
                  items: const [
                    DropdownMenuItem(value: 'hours', child: Text('Hours')),
                    DropdownMenuItem(value: 'days', child: Text('Days')),
                    DropdownMenuItem(value: 'weeks', child: Text('Weeks')),
                  ],
                  onChanged: (v) => setState(() => _durationUnit = v ?? 'days'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Results visibility',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          OneUICompactDropdown<String>(
            value: _resultsVisibility,
            items: const [
              DropdownMenuItem(value: 'immediate', child: Text('Visible immediately')),
              DropdownMenuItem(value: 'after_voting', child: Text('Visible after voting')),
            ],
            onChanged: (v) => setState(() => _resultsVisibility = v ?? 'immediate'),
          ),
          const SizedBox(height: 8),
          _ToggleRow(
            theme: theme,
            label: 'Allow multiple choices',
            value: _allowMultiple,
            onChanged: (v) => setState(() => _allowMultiple = v),
          ),
          _ToggleRow(
            theme: theme,
            label: 'Show voters',
            value: _resultsVisibility == 'immediate',
            onChanged: (v) => setState(() => _resultsVisibility = v ? 'immediate' : 'after_voting'),
          ),
          _ToggleRow(
            theme: theme,
            label: 'Anonymous poll',
            value: _anonymous,
            onChanged: (v) => setState(() => _anonymous = v),
          ),
          const SizedBox(height: 24),
          AppButton(
            text: _submitting ? 'Publishing…' : 'Publish poll',
            height: 48,
            enabled: _canSubmit,
            onTap: _submit,
          ),
        ],
      ),
    );
  }
}

class _PollingAsCard extends StatelessWidget {
  final OneUITheme theme;
  final String name;
  final String detail;
  final String logoUrl;

  const _PollingAsCard({
    required this.theme,
    required this.name,
    required this.detail,
    required this.logoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          if (logoUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: AppCachedNetworkImage(imageUrl: logoUrl, width: 48, height: 48, fit: BoxFit.cover),
            )
          else
            CircleAvatar(
              radius: 24,
              backgroundColor: theme.surfaceVariant,
              child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'G'),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'POLLING AS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: theme.textSecondary,
                  ),
                ),
                Text(name, style: TextStyle(fontWeight: FontWeight.w700, color: theme.textPrimary)),
                Text(detail, style: TextStyle(fontSize: 12, color: theme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final OneUITheme theme;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.theme,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: TextStyle(fontSize: 14, color: theme.textPrimary)),
      value: value,
      onChanged: onChanged,
      activeThumbColor: theme.primary,
    );
  }
}

void openGroupPollCreate(BuildContext context, GroupDetailModel group) {
  Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => GroupPollCreateScreen(group: group)),
  );
}

bool groupCanCreatePoll(GroupDetailModel group) {
  return group.capabilities.canPost && group.settings.enablePolls;
}
