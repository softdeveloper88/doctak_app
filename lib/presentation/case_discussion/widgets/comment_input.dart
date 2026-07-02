import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

/// Bottom comment composer for case discussion detail.
class CommentInput extends StatefulWidget {
  final void Function(String text) onSubmit;
  final bool isLoading;
  final String hintText;

  const CommentInput({
    super.key,
    required this.onSubmit,
    this.isLoading = false,
    this.hintText = 'Share your thoughts on this case...',
  });

  @override
  State<CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<CommentInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isLoading) return;

    widget.onSubmit(text);
    _controller.clear();
    setState(() {});
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final hasContent = _controller.text.trim().isNotEmpty;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        border: Border(
          top: BorderSide(color: theme.divider.withValues(alpha: 0.8)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(12, 10, 12, bottomInset > 0 ? bottomInset + 8 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
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
                    horizontal: 16,
                    vertical: 11,
                  ),
                  isDense: true,
                ),
                maxLines: 5,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.newline,
                onSubmitted: (_) => _submit(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: hasContent && !widget.isLoading ? 1.0 : 0.45,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: hasContent && !widget.isLoading ? _submit : null,
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: theme.primary,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: widget.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
