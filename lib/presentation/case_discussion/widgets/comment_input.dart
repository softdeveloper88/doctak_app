import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'comment_card.dart'; // For ClinicalTag enum

/// A rich comment input widget with clinical tag selector support.
/// Matches the website's tag options: Diagnosis, Treatment, Prognosis,
/// Workup, Complication, Differential.
class CommentInput extends StatefulWidget {
  final Function(String text, List<String> clinicalTags) onSubmit;
  final bool isLoading;
  final String hintText;
  final bool showClinicalTags;

  const CommentInput({
    super.key,
    required this.onSubmit,
    this.isLoading = false,
    this.hintText = 'Add a comment...',
    this.showClinicalTags = true,
  });

  @override
  State<CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<CommentInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final Set<ClinicalTag> _selectedTags = {};
  bool _showTagSelector = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    widget.onSubmit(
      text,
      _selectedTags.map((t) => t.name).toList(),
    );
    _controller.clear();
    setState(() {
      _selectedTags.clear();
      _showTagSelector = false;
    });
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final hasContent = _controller.text.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        border: Border(
          top: BorderSide(color: theme.divider, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Selected Tags ──
            if (_selectedTags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: SizedBox(
                  height: 28,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _selectedTags.map((tag) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _SelectedTagChip(
                          tag: tag,
                          onRemove: () {
                            setState(() => _selectedTags.remove(tag));
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

            // ── Tag Selector Panel ──
            if (_showTagSelector)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: _TagSelectorPanel(
                  selectedTags: _selectedTags,
                  onToggle: (tag) {
                    setState(() {
                      if (_selectedTags.contains(tag)) {
                        _selectedTags.remove(tag);
                      } else {
                        _selectedTags.add(tag);
                      }
                    });
                  },
                  theme: theme,
                ),
              ),

            // ── Input Row ──
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Clinical tag toggle button
                  if (widget.showClinicalTags)
                    InkWell(
                      onTap: () {
                        setState(
                            () => _showTagSelector = !_showTagSelector);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _showTagSelector
                              ? theme.primary.withValues(alpha: 0.1)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.medical_information_outlined,
                          size: 22,
                          color: _showTagSelector
                              ? theme.primary
                              : theme.textTertiary,
                        ),
                      ),
                    ),

                  const SizedBox(width: 4),

                  // Text field
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      decoration: BoxDecoration(
                        color: theme.inputBackground,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: theme.border),
                      ),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Poppins',
                          color: theme.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: widget.hintText,
                          hintStyle: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Poppins',
                            color: theme.textTertiary,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          isDense: true,
                        ),
                        maxLines: 5,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.newline,
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  // Send button
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: hasContent && !widget.isLoading ? 1.0 : 0.5,
                    child: InkWell(
                      onTap:
                          hasContent && !widget.isLoading ? _submit : null,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: widget.isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send,
                                size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tag Selector Panel ──

class _TagSelectorPanel extends StatelessWidget {
  final Set<ClinicalTag> selectedTags;
  final Function(ClinicalTag) onToggle;
  final OneUITheme theme;

  const _TagSelectorPanel({
    required this.selectedTags,
    required this.onToggle,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: ClinicalTag.values.map((tag) {
        final isSelected = selectedTags.contains(tag);
        return GestureDetector(
          onTap: () => onToggle(tag),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? tag.color.withValues(alpha: 0.15)
                  : theme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? tag.color.withValues(alpha: 0.5)
                    : theme.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(tag.icon, size: 14, color: isSelected ? tag.color : theme.textTertiary),
                const SizedBox(width: 5),
                Text(
                  tag.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? tag.color : theme.textSecondary,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.check, size: 14, color: tag.color),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Selected Tag Chip ──

class _SelectedTagChip extends StatelessWidget {
  final ClinicalTag tag;
  final VoidCallback onRemove;

  const _SelectedTagChip({
    required this.tag,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tag.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tag.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(tag.icon, size: 12, color: tag.color),
          const SizedBox(width: 4),
          Text(
            tag.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: tag.color,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 12, color: tag.color),
          ),
        ],
      ),
    );
  }
}
