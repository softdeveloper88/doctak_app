import 'package:doctak_app/data/apiClient/services/v5_profile_api_service.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:flutter/material.dart';

class InterestedInfoScreen extends StatefulWidget {
  final ProfileBloc profileBloc;

  const InterestedInfoScreen({required this.profileBloc, super.key});

  @override
  State<InterestedInfoScreen> createState() => _InterestedInfoScreenState();
}

class _InterestedInfoScreenState extends State<InterestedInfoScreen> {
  final V5ProfileApiService _api = V5ProfileApiService();
  List<Map<String, dynamic>> _hobbies = [];
  List<Map<String, dynamic>> _interests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final hobbiesResult = await _api.getHobbies();
      final interestsResult = await _api.getUserInterests();
      if (mounted) {
        setState(() {
          _hobbies = hobbiesResult.data ?? [];
          _interests = interestsResult.data ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading hobbies/interests: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final isMe = widget.profileBloc.isMe;

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: DoctakAppBar(
        title: translation(context).lbl_interest_information,
        titleIcon: Icons.interests_rounded,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _hobbies.isEmpty && _interests.isEmpty
                  ? _buildEmptyState(theme, isMe)
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // ── Hobbies Section ──
                        _buildSectionHeader(
                          title: 'Hobbies',
                          icon: Icons.sports_esports_outlined,
                          color: Colors.purple,
                          theme: theme,
                          onAdd: isMe ? () => _showAddEditDialog(type: 'hobby') : null,
                        ),
                        const SizedBox(height: 8),
                        if (_hobbies.isEmpty)
                          _buildEmptySectionHint('No hobbies added yet', theme)
                        else
                          ..._hobbies.map((h) => _buildItemCard(
                                item: h,
                                type: 'hobby',
                                color: Colors.purple,
                                theme: theme,
                                isMe: isMe,
                              )),
                        const SizedBox(height: 24),

                        // ── Interests Section ──
                        _buildSectionHeader(
                          title: 'Interests',
                          icon: Icons.lightbulb_outline,
                          color: Colors.blue,
                          theme: theme,
                          onAdd: isMe ? () => _showAddEditDialog(type: 'interest') : null,
                        ),
                        const SizedBox(height: 8),
                        if (_interests.isEmpty)
                          _buildEmptySectionHint('No interests added yet', theme)
                        else
                          ..._interests.map((i) => _buildItemCard(
                                item: i,
                                type: 'interest',
                                color: Colors.blue,
                                theme: theme,
                                isMe: isMe,
                              )),
                        SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                      ],
                    ),
            ),
      floatingActionButton: isMe && !_isLoading
          ? FloatingActionButton(
              onPressed: () => _showAddTypeChooser(),
              backgroundColor: theme.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  // ── Empty state (no hobbies AND no interests) ──
  Widget _buildEmptyState(OneUITheme theme, bool isMe) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.interests_rounded, size: 80, color: theme.textSecondary.withValues(alpha: 0.3)),
              const SizedBox(height: 24),
              Text(translation(context).lbl_no_interest_added, style: theme.titleMedium),
              const SizedBox(height: 12),
              Text(
                'Share your hobbies and professional interests to connect with like-minded colleagues.',
                textAlign: TextAlign.center,
                style: theme.bodySecondary,
              ),
              if (isMe) ...[
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildAddButton('Add Hobby', Colors.purple, () => _showAddEditDialog(type: 'hobby')),
                    const SizedBox(width: 12),
                    _buildAddButton('Add Interest', Colors.blue, () => _showAddEditDialog(type: 'interest')),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(String label, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.add, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  // ── Section header with title + Add button ──
  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required Color color,
    required OneUITheme theme,
    VoidCallback? onAdd,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color, fontFamily: 'Poppins')),
        ),
        if (onAdd != null)
          TextButton.icon(
            onPressed: onAdd,
            icon: Icon(Icons.add_circle_outline, size: 18, color: color),
            label: Text('Add', style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }

  Widget _buildEmptySectionHint(String text, OneUITheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Text(text, style: theme.caption.copyWith(fontStyle: FontStyle.italic)),
    );
  }

  // ── Individual item card ──
  Widget _buildItemCard({
    required Map<String, dynamic> item,
    required String type,
    required Color color,
    required OneUITheme theme,
    required bool isMe,
  }) {
    final name = (item['name'] ?? item['hobby_name'] ?? '').toString();
    final description = (item['description'] ?? '').toString();
    final privacy = (item['privacy'] ?? 'public').toString();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: theme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.border),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Color dot
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: theme.textPrimary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      // Privacy badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _privacyColor(privacy).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _privacyLabel(privacy),
                          style: TextStyle(fontSize: 10, color: _privacyColor(privacy), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(fontSize: 13, color: theme.textSecondary, height: 1.4, fontFamily: 'Poppins'),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Actions
            if (isMe)
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 20, color: theme.textSecondary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onSelected: (val) {
                  if (val == 'edit') {
                    _showAddEditDialog(type: type, existingItem: item);
                  } else if (val == 'delete') {
                    _showDeleteConfirmation(item: item, type: type);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Edit')])),
                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Color _privacyColor(String privacy) {
    switch (privacy) {
      case 'friends':
        return Colors.orange;
      case 'only_me':
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  String _privacyLabel(String privacy) {
    switch (privacy) {
      case 'friends':
        return 'Friends';
      case 'only_me':
        return 'Only Me';
      default:
        return 'Public';
    }
  }

  // ── Choose type to add (hobby or interest) ──
  void _showAddTypeChooser() {
    final theme = OneUITheme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: theme.border, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text('What would you like to add?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textPrimary)),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.sports_esports_outlined, color: Colors.purple),
                ),
                title: const Text('Add Hobby', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Share your hobbies and interests'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddEditDialog(type: 'hobby');
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.lightbulb_outline, color: Colors.blue),
                ),
                title: const Text('Add Interest', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Share your professional interests'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddEditDialog(type: 'interest');
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── Add/Edit Dialog (matches web's modal) ──
  void _showAddEditDialog({required String type, Map<String, dynamic>? existingItem}) {
    final isEdit = existingItem != null;
    final nameCtrl = TextEditingController(text: isEdit ? (existingItem['name'] ?? existingItem['hobby_name'] ?? '').toString() : '');
    final descCtrl = TextEditingController(text: isEdit ? (existingItem['description'] ?? '').toString() : '');
    String privacy = isEdit ? (existingItem['privacy'] ?? 'public').toString() : 'public';
    final formKey = GlobalKey<FormState>();
    final theme = OneUITheme.of(context);
    final isHobby = type == 'hobby';
    final color = isHobby ? Colors.purple : Colors.blue;
    final label = isHobby ? 'Hobby' : 'Interest';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: theme.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(isHobby ? Icons.sports_esports_outlined : Icons.lightbulb_outline, color: color, size: 22),
              const SizedBox(width: 10),
              Text('${isEdit ? 'Edit' : 'Add'} $label', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textPrimary)),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isHobby ? 'Share your hobbies and interests' : 'Share your professional interests',
                    style: TextStyle(fontSize: 13, color: color),
                  ),
                  const SizedBox(height: 4),
                  // Privacy toggle
                  Row(
                    children: [
                      Icon(
                        privacy == 'public' ? Icons.public : privacy == 'friends' ? Icons.group : Icons.lock,
                        size: 16,
                        color: _privacyColor(privacy),
                      ),
                      const SizedBox(width: 4),
                      DropdownButton<String>(
                        value: privacy,
                        underline: const SizedBox(),
                        isDense: true,
                        style: TextStyle(fontSize: 12, color: _privacyColor(privacy), fontWeight: FontWeight.w600),
                        items: const [
                          DropdownMenuItem(value: 'public', child: Text('Public')),
                          DropdownMenuItem(value: 'friends', child: Text('Friends')),
                          DropdownMenuItem(value: 'only_me', child: Text('Only Me')),
                        ],
                        onChanged: (val) {
                          if (val != null) setDialogState(() => privacy = val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('$label Name *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.textPrimary)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: nameCtrl,
                    validator: (v) => (v == null || v.trim().isEmpty) ? '$label name is required' : null,
                    decoration: InputDecoration(
                      hintText: isHobby ? 'e.g. Photography, Chess, Hiking' : 'e.g. Artificial Intelligence, Cardiology Research',
                      hintStyle: TextStyle(color: theme.textSecondary.withValues(alpha: 0.5), fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: color, width: 1.5)),
                      filled: true,
                      fillColor: theme.scaffoldBackground,
                    ),
                    style: TextStyle(color: theme.textPrimary, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Text('Description', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.textPrimary)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: descCtrl,
                    maxLines: 3,
                    minLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Describe your ${type == 'hobby' ? 'interest in this area' : 'interest'} (optional)',
                      hintStyle: TextStyle(color: theme.textSecondary.withValues(alpha: 0.5), fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: color, width: 1.5)),
                      filled: true,
                      fillColor: theme.scaffoldBackground,
                    ),
                    style: TextStyle(color: theme.textPrimary, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: theme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                await _saveItem(
                  type: type,
                  name: nameCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  privacy: privacy,
                  existingId: existingItem?['id'],
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Save $label'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Delete confirmation dialog ──
  void _showDeleteConfirmation({required Map<String, dynamic> item, required String type}) {
    final theme = OneUITheme.of(context);
    final name = (item['name'] ?? item['hobby_name'] ?? '').toString();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
            const SizedBox(width: 10),
            Text('Delete ${type == 'hobby' ? 'Hobby' : 'Interest'}?', style: TextStyle(color: theme.textPrimary, fontSize: 17)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "$name"? This action cannot be undone.',
          style: TextStyle(color: theme.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: theme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteItem(item: item, type: type);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ── Save (create or update) ──
  Future<void> _saveItem({
    required String type,
    required String name,
    required String description,
    required String privacy,
    dynamic existingId,
  }) async {
    try {
      if (type == 'hobby') {
        if (existingId != null) {
          await _api.updateHobby(id: existingId, name: name, description: description, privacy: privacy);
        } else {
          await _api.storeHobby(name: name, description: description, privacy: privacy);
        }
      } else {
        if (existingId != null) {
          await _api.updateInterest(id: existingId, name: name, description: description, privacy: privacy);
        } else {
          await _api.storeInterest(name: name, description: description, privacy: privacy);
        }
      }
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${type == 'hobby' ? 'Hobby' : 'Interest'} ${existingId != null ? 'updated' : 'added'} successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      debugPrint('Error saving $type: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to save ${type == 'hobby' ? 'hobby' : 'interest'}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  // ── Delete ──
  Future<void> _deleteItem({required Map<String, dynamic> item, required String type}) async {
    try {
      if (type == 'hobby') {
        await _api.deleteHobby(id: item['id']);
      } else {
        await _api.deleteInterest(id: item['id']);
      }
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${type == 'hobby' ? 'Hobby' : 'Interest'} deleted'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      debugPrint('Error deleting $type: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to delete ${type == 'hobby' ? 'hobby' : 'interest'}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }
}
