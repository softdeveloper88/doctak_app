import 'package:flutter/material.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;

class ChatInputField extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSubmitted;
  final VoidCallback onAttachmentPressed;
  final Function(bool) onRecordStateChanged;
  final Function(String) onVoiceRecorded;
  final bool isRecording;
  final bool isLoading;
  final Function(String)? onTyping;

  const ChatInputField({
    super.key,
    required this.controller,
    required this.onSubmitted,
    required this.onAttachmentPressed,
    required this.onRecordStateChanged,
    required this.onVoiceRecorded,
    required this.isRecording,
    required this.isLoading,
    this.onTyping,
  });

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField>
    with SingleTickerProviderStateMixin {
  bool _showEmoji = false;
  late AnimationController _animationController;
  late Animation<double> _animation;
  final FocusNode _focusNode = FocusNode();
  bool _isPressed = false; // Track if mic button is being pressed

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _toggleEmoji() {
    setState(() {
      _showEmoji = !_showEmoji;
      if (_showEmoji) {
        _focusNode.unfocus();
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    // Get proper padding for edge-to-edge support
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.cardBackground,
            boxShadow: [
              BoxShadow(
                color: theme.isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            // Use viewPadding when keyboard is hidden, don't add extra padding when keyboard is shown
            bottom: (keyboardPadding > 0 ? 0 : bottomPadding) + 8,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Input field
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(
                    minHeight: 48,
                    maxHeight: 120,
                  ),
                  decoration: BoxDecoration(
                    color: theme.inputBackground,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: theme.divider, width: 1),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Emoji button
                      IconButton(
                        icon: Icon(
                          _showEmoji
                              ? Icons.keyboard
                              : Icons.emoji_emotions_outlined,
                          color: theme.textSecondary,
                          size: 24,
                        ),
                        onPressed: _toggleEmoji,
                      ),
                      // Text field
                      Expanded(
                        child: TextField(
                          controller: widget.controller,
                          focusNode: _focusNode,
                          textCapitalization: TextCapitalization.sentences,
                          keyboardType: TextInputType.multiline,
                          maxLines: null,
                          minLines: 1,
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.textPrimary,
                            fontFamily: 'Poppins',
                          ),
                          decoration: InputDecoration(
                            hintText: translation(
                              context,
                            ).lbl_type_message_here,
                            hintStyle: TextStyle(
                              color: theme.textTertiary,
                              fontSize: 16,
                              fontFamily: 'Poppins',
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 0,
                              vertical: 12,
                            ),
                          ),
                          onChanged: widget.onTyping,
                          onTap: () {
                            if (_showEmoji) {
                              setState(() {
                                _showEmoji = false;
                                _animationController.reverse();
                              });
                            }
                          },
                        ),
                      ),
                      // Attachment button
                      IconButton(
                        icon: Icon(
                          Icons.attach_file_rounded,
                          color: theme.textSecondary,
                          size: 24,
                        ),
                        onPressed: widget.onAttachmentPressed,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Send/Record button with scale animation
              AnimatedScale(
                scale: _isPressed ? 1.2 : 1.0, // Scale up when pressed
                duration: const Duration(milliseconds: 150),
                child: GestureDetector(
                  onTap: widget.isLoading
                      ? null
                      : () {
                          // Only send message if there's text
                          if (widget.controller.text.trim().isNotEmpty) {
                            widget.onSubmitted(widget.controller.text);
                          }
                        },
                  onLongPressStart:
                      widget.isLoading ||
                          widget.controller.text.trim().isNotEmpty
                      ? null
                      : (details) {
                          // Start recording on long press (hold) - not on tap
                          print('👇 Long press started - recording');
                          setState(() {
                            _isPressed = true; // Button grows
                          });
                          widget.onRecordStateChanged(true);
                        },
                  onLongPressEnd: (details) {
                    // Stop recording when user releases finger
                    setState(() {
                      _isPressed = false; // Button returns to normal size
                    });
                    if (widget.isRecording) {
                      print('👆 Long press ended - stopping recording');
                      widget.onRecordStateChanged(false);
                    }
                  },
                  onLongPressCancel: () {
                    // Handle if long press is cancelled
                    setState(() {
                      _isPressed = false;
                    });
                  },
                  child: Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [theme.primary, theme.primary.withOpacity(0.8)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: widget.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Icon(
                                widget.controller.text.trim().isEmpty
                                    ? Icons.mic
                                    : Icons.send_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Emoji picker
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: SizeTransition(
            sizeFactor: _animation,
            child: _showEmoji
                ? SizedBox(
                    height: 250,
                    child: EmojiPicker(
                      onEmojiSelected: (category, emoji) {
                        widget.controller.text += emoji.emoji;
                        widget
                            .controller
                            .selection = TextSelection.fromPosition(
                          TextPosition(offset: widget.controller.text.length),
                        );
                        if (widget.onTyping != null) {
                          widget.onTyping!(widget.controller.text);
                        }
                      },
                      textEditingController: widget.controller,
                      config: Config(
                        height: 256,
                        checkPlatformCompatibility: true,
                        viewOrderConfig: const ViewOrderConfig(),
                        emojiViewConfig: EmojiViewConfig(
                          emojiSizeMax:
                              28 *
                              (foundation.defaultTargetPlatform ==
                                      TargetPlatform.iOS
                                  ? 1.2
                                  : 1.0),
                        ),
                        skinToneConfig: const SkinToneConfig(),
                        categoryViewConfig: const CategoryViewConfig(),
                        bottomActionBarConfig: const BottomActionBarConfig(),
                        searchViewConfig: const SearchViewConfig(),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}
