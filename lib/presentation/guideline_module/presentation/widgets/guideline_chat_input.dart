import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

/// Chat input bar for the guideline agent — matches the reference design.
class GuidelineChatInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final Function(String) onSend;
  final VoidCallback? onAttachSource;

  const GuidelineChatInput({
    super.key,
    required this.controller,
    required this.isSending,
    required this.onSend,
    this.onAttachSource,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        border: Border(
          top: BorderSide(color: theme.border, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackground,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: theme.border,
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          enabled: !isSending,
                          maxLines: 4,
                          minLines: 1,
                          textInputAction: TextInputAction.newline,
                          style: TextStyle(
                            color: theme.textPrimary,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Ask about medical guidelines...',
                            hintStyle: TextStyle(
                              color: theme.textSecondary.withOpacity(0.6),
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                            ),
                          ),
                          onSubmitted: isSending
                              ? null
                              : (value) => onSend(value),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Send button
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isSending
                      ? const Color(0xFF0A84FF).withOpacity(0.5)
                      : const Color(0xFF0A84FF),
                  borderRadius: BorderRadius.circular(21),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0A84FF).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isSending
                        ? null
                        : () {
                            if (controller.text.trim().isNotEmpty) {
                              onSend(controller.text);
                            }
                          },
                    borderRadius: BorderRadius.circular(21),
                    child: const Center(
                      child: Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Keyboard hints removed — matches chat_gpt_with_image_screen style
        ],
      ),
    );
  }
}
