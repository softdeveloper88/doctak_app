import 'package:doctak_app/data/apiClient/groups/groups_node_api_service.dart';
import 'package:doctak_app/data/models/group_model/group_enhanced_models.dart';
import 'package:doctak_app/presentation/groups_module/widgets/group_circle_avatar.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/app_button.dart';
import 'package:flutter/material.dart';

class GroupPollCard extends StatefulWidget {
  final GroupPollModel poll;
  final String groupId;
  final bool canModerate;
  final VoidCallback? onVoted;
  final VoidCallback? onClosed;

  const GroupPollCard({
    super.key,
    required this.poll,
    required this.groupId,
    this.canModerate = false,
    this.onVoted,
    this.onClosed,
  });

  @override
  State<GroupPollCard> createState() => _GroupPollCardState();
}

class _GroupPollCardState extends State<GroupPollCard> {
  final Set<String> _selected = {};
  bool _submitting = false;
  bool _closing = false;
  late GroupPollModel _poll;

  @override
  void initState() {
    super.initState();
    _poll = widget.poll;
    if (_poll.myVote != null) {
      _selected.addAll(_poll.myVote!);
    }
  }

  @override
  void didUpdateWidget(covariant GroupPollCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.poll.id != widget.poll.id) {
      _poll = widget.poll;
      _selected
        ..clear()
        ..addAll(_poll.myVote ?? const []);
    }
  }

  void _toggleOption(String optionId) {
    if (_poll.hasVoted || _poll.isClosed) return;
    setState(() {
      if (_poll.allowMultipleSelections) {
        if (_selected.contains(optionId)) {
          _selected.remove(optionId);
        } else {
          _selected.add(optionId);
        }
      } else {
        _selected
          ..clear()
          ..add(optionId);
      }
    });
  }

  Future<void> _submitVote() async {
    if (_selected.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    try {
      await GroupsNodeApiService.votePoll(
        widget.groupId,
        _poll.id,
        _selected.toList(),
      );
      if (!mounted) return;
      setState(() {
        _poll = GroupPollModel(
          id: _poll.id,
          title: _poll.title,
          description: _poll.description,
          status: _poll.status,
          totalVotes: _poll.totalVotes + 1,
          createdAt: _poll.createdAt,
          options: _poll.options,
          author: _poll.author,
          myVote: _selected.toList(),
          allowMultipleSelections: _poll.allowMultipleSelections,
        );
      });
      widget.onVoted?.call();
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

  Future<void> _closePoll() async {
    if (_closing || _poll.isClosed) return;
    setState(() => _closing = true);
    try {
      await GroupsNodeApiService.closePoll(widget.groupId, _poll.id);
      widget.onClosed?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _closing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final showResults = _poll.hasVoted || _poll.isClosed;
    final maxVotes = _poll.options.fold<int>(
      0,
      (max, opt) => opt.votes > max ? opt.votes : max,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: theme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.poll_rounded, size: 18, color: theme.primary),
              const SizedBox(width: 6),
              Text('Poll', style: TextStyle(fontWeight: FontWeight.w700, color: theme.primary)),
              const Spacer(),
              if (_poll.isClosed)
                Text('Closed', style: TextStyle(fontSize: 12, color: theme.textTertiary)),
            ],
          ),
          if (_poll.author != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                GroupCircleAvatar(
                  imageUrl: _poll.author!.avatar,
                  name: _poll.author!.name,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(_poll.author!.name, style: TextStyle(fontSize: 13, color: theme.textSecondary)),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Text(
            _poll.title,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: theme.textPrimary),
          ),
          if (_poll.description?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Text(_poll.description!, style: TextStyle(color: theme.textSecondary)),
          ],
          const SizedBox(height: 12),
          ..._poll.options.map((opt) {
            final selected = _selected.contains(opt.id);
            final ratio = maxVotes == 0 ? 0.0 : opt.votes / maxVotes;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: showResults ? null : () => _toggleOption(opt.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  decoration: BoxDecoration(
                    color: theme.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? theme.primary : theme.divider,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(opt.label)),
                          if (showResults)
                            Text('${opt.votes}', style: TextStyle(color: theme.textSecondary)),
                          if (!showResults && selected)
                            Icon(Icons.check_circle_rounded, size: 18, color: theme.primary),
                        ],
                      ),
                      if (showResults) ...[
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 5,
                            backgroundColor: theme.divider,
                            color: theme.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 4),
          Text(
            '${_poll.totalVotes} votes',
            style: TextStyle(fontSize: 12, color: theme.textTertiary),
          ),
          if (!_poll.hasVoted && !_poll.isClosed) ...[
            const SizedBox(height: 10),
            AppButton(
              text: _submitting ? 'Submitting…' : 'Submit vote',
              height: 38,
              enabled: !_submitting && _selected.isNotEmpty,
              onTap: _submitVote,
            ),
          ],
          if (widget.canModerate && !_poll.isClosed) ...[
            const SizedBox(height: 8),
            AppButton(
              text: _closing ? 'Closing…' : 'Close poll',
              height: 36,
              enabled: !_closing,
              color: theme.surfaceVariant,
              textColor: theme.textPrimary,
              onTap: _closePoll,
            ),
          ],
        ],
      ),
    );
  }
}
