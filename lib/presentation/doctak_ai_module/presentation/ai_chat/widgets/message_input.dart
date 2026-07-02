import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../localization/app_localization.dart';
import '../../../../../theme/one_ui_theme.dart';

class MessageInput extends StatefulWidget {
  final Function(String message)? onSendMessage; // Make nullable
  final Function()? onAttachImage; // Make nullable
  final String selectedModel;
  final Function(String model) onModelChanged;
  final bool webSearchEnabled;
  final Function(bool enabled) onWebSearchToggled;
  final String searchContextSize;
  final Function(String size) onSearchContextSizeChanged;
  final TextEditingController? controller;
  final bool isWaitingForResponse; // Add waiting indicator
  final VoidCallback? onVoiceTap; // Voice input callback
  final bool isListening; // Whether currently listening

  const MessageInput({
    super.key,
    this.controller,
    required this.onSendMessage,
    required this.onAttachImage,
    required this.selectedModel,
    required this.onModelChanged,
    required this.webSearchEnabled,
    required this.onWebSearchToggled,
    required this.searchContextSize,
    required this.onSearchContextSizeChanged,
    this.isWaitingForResponse = false,
    this.onVoiceTap,
    this.isListening = false,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _isComposing = false;
  late AnimationController _listeningAnimController;
  late Animation<double> _listeningScaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(() {
      final composing = _controller.text.trim().isNotEmpty;
      if (composing != _isComposing) {
        setState(() => _isComposing = composing);
      }
    });
    _listeningAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _listeningScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _listeningAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    _focusNode.dispose();
    _listeningAnimController.dispose();
    super.dispose();
  }

  void _handleSend() {
    if (widget.isWaitingForResponse) return;
    final message = _controller.text.trim();
    if (message.isNotEmpty && widget.onSendMessage != null) {
      widget.onSendMessage!(message);
      _controller.clear();
      setState(() => _isComposing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final bool canSend = _isComposing && !widget.isWaitingForResponse;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), offset: const Offset(0, -2), blurRadius: 10)],
      ),
      padding: EdgeInsets.only(
        left: 12.0,
        right: 12.0,
        top: 10.0,
        bottom: bottomPadding > 0 ? bottomPadding + 6.0 : 10.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main input row
          Container(
            decoration: BoxDecoration(
              color: theme.isDark ? theme.inputBackground : const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: widget.isListening
                    ? theme.primary.withValues(alpha: 0.6)
                    : theme.divider.withValues(alpha: 0.5),
                width: widget.isListening ? 1.5 : 1,
              ),
            ),
            child: Column(
              children: [
                // Text field
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Text input
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        minLines: 1,
                        maxLines: 4,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          color: theme.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintStyle: TextStyle(
                            color: widget.isListening
                                ? Colors.red.withValues(alpha: 0.7)
                                : theme.textSecondary.withValues(alpha: 0.7),
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: widget.isListening ? FontWeight.w500 : FontWeight.normal,
                          ),
                          hintText: widget.isListening
                              ? 'Speak now...'
                              : widget.isWaitingForResponse
                                  ? 'Waiting for response...'
                                  : 'Ask anything about medicine...',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        cursorColor: theme.primary,
                        textInputAction: TextInputAction.newline,
                      ),
                    ),

                    // Voice / Send button (right side)
                    Padding(
                      padding: const EdgeInsets.only(right: 6, bottom: 6),
                      child: canSend
                          ? _buildSendButton(theme)
                          : _buildVoiceButton(theme),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Disclaimer
          Text(
            translation(context).msg_ai_disclaimer,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: theme.textSecondary.withValues(alpha: 0.6),
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton(OneUITheme theme) {
    return GestureDetector(
      onTap: _handleSend,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: theme.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: theme.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildVoiceButton(OneUITheme theme) {
    if (widget.isListening) {
      return ScaleTransition(
        scale: _listeningScaleAnimation,
        child: GestureDetector(
          onTap: widget.onVoiceTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.5),
                  blurRadius: 14,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.mic, color: Colors.white, size: 20),
          ),
        ),
      );
    }

    return _buildCircleButton(
      icon: Icons.mic_none_rounded,
      size: 36,
      iconSize: 20,
      color: theme.textSecondary,
      onTap: widget.isWaitingForResponse ? null : widget.onVoiceTap,
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required double size,
    required double iconSize,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Icon(icon, size: iconSize, color: onTap != null ? color : color.withValues(alpha: 0.4)),
        ),
      ),
    );
  }
}
