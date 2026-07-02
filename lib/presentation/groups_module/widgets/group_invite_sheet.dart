import 'dart:async';

import 'package:doctak_app/core/utils/specialty_display.dart';
import 'package:doctak_app/data/models/group_model/group_enhanced_models.dart';
import 'package:doctak_app/presentation/groups_module/services/group_invite_service.dart';
import 'package:doctak_app/presentation/groups_module/widgets/group_circle_avatar.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

const _kInviteButtonHeight = 30.0;

/// Bottom sheet to invite connections to a group (web modal parity).
Future<void> showGroupInviteSheet(
  BuildContext context, {
  required GroupDetailModel group,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: true,
    enableDrag: true,
    barrierColor: Colors.black54,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _GroupInviteSheet(group: group),
  );
}

class _GroupInviteSheet extends StatefulWidget {
  final GroupDetailModel group;

  const _GroupInviteSheet({required this.group});

  @override
  State<_GroupInviteSheet> createState() => _GroupInviteSheetState();
}

class _GroupInviteSheetState extends State<_GroupInviteSheet> {
  final _searchController = TextEditingController();
  final _inviteService = GroupInviteService.instance;
  Timer? _debounce;
  List<GroupUserStubModel> _results = [];
  final Set<String> _sentIds = {};
  final Set<String> _invitingIds = {};
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    preloadSpecialties().then((_) {
      if (mounted) setState(() {});
    });
    _load('');
    _searchController.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      _load(_searchController.text);
    });
  }

  Future<void> _load(String query) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _inviteService.loadCandidates(
        widget.group.routeId,
        query: query,
      );
      if (!mounted) return;
      setState(() {
        _results = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load connections. Pull to retry.';
        _results = [];
      });
    }
  }

  Future<void> _invite(GroupUserStubModel user) async {
    if (!widget.group.capabilities.canInvite) return;
    if (_invitingIds.contains(user.id) || _sentIds.contains(user.id)) return;
    setState(() => _invitingIds.add(user.id));
    try {
      await _inviteService.sendInvite(
        widget.group.routeId,
        inviteeId: user.id,
        message: 'Join ${widget.group.name} on Doctak',
      );
      if (!mounted) return;
      setState(() {
        _sentIds.add(user.id);
        _error = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invite sent to ${user.name}')),
      );
    } catch (e) {
      final msg = '$e';
      if (msg.contains('already_invited')) {
        setState(() => _sentIds.add(user.id));
      } else if (mounted) {
        setState(() => _error = msg);
      }
    } finally {
      if (mounted) setState(() => _invitingIds.remove(user.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final canInvite = widget.group.capabilities.canInvite;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Material(
          color: theme.cardBackground,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.88,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    Icon(Icons.hub_outlined, color: theme.primary, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Invite friends',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: theme.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  canInvite
                      ? 'Search your connections and send an in-app group invite.'
                      : 'Browse your connections below. Join this group to send invites.',
                  style: TextStyle(fontSize: 13, color: theme.textSecondary),
                ),
              ),
              if (!canInvite)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: theme.primary.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      'Join this group first to invite friends.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.primary,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search friends by name..',
                    prefixIcon: const Icon(Icons.search_rounded, size: 22),
                    filled: true,
                    fillColor: theme.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.primary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Text(
                    _error!,
                    style: TextStyle(color: theme.error, fontSize: 13),
                  ),
                ),
              Flexible(
                child: _loading
                    ? Center(child: CircularProgressIndicator(color: theme.primary))
                    : _results.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                _searchController.text.trim().isEmpty
                                    ? 'No connections available to invite.'
                                    : 'No connections match your search.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: theme.textSecondary),
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                            itemCount: _results.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 4),
                            itemBuilder: (context, index) {
                              final user = _results[index];
                              final sent = _sentIds.contains(user.id);
                              final inviting = _invitingIds.contains(user.id);

                              return _InviteUserRow(
                                user: user,
                                sent: sent,
                                inviting: inviting,
                                canInvite: canInvite,
                                onInvite: () => _invite(user),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

class _InviteUserRow extends StatelessWidget {
  final GroupUserStubModel user;
  final bool sent;
  final bool inviting;
  final bool canInvite;
  final VoidCallback onInvite;

  const _InviteUserRow({
    required this.user,
    required this.sent,
    required this.inviting,
    required this.canInvite,
    required this.onInvite,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final specialty = user.specialtyLabel;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GroupCircleAvatar(
            imageUrl: user.avatar,
            name: user.name,
            size: 44,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.textPrimary,
                  ),
                ),
                if (specialty != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    specialty,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          _InviteActionButton(
            label: sent ? 'Sent' : 'Invite',
            loading: inviting,
            enabled: canInvite && !sent && !inviting,
            sent: sent,
            onTap: canInvite && !sent && !inviting ? onInvite : null,
          ),
        ],
      ),
    );
  }
}

class _InviteActionButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool sent;
  final bool loading;
  final VoidCallback? onTap;

  const _InviteActionButton({
    required this.label,
    required this.enabled,
    required this.sent,
    this.loading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final canTap = enabled && onTap != null && !loading;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canTap ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: 64,
          height: _kInviteButtonHeight,
          decoration: BoxDecoration(
            color: sent ? theme.surfaceVariant : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: sent
                  ? theme.divider
                  : (canTap ? theme.primary : theme.divider),
            ),
          ),
          child: Center(
            child: loading
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.primary,
                    ),
                  )
                : Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                      color: sent
                          ? theme.textTertiary
                          : (canTap ? theme.primary : theme.textTertiary),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
