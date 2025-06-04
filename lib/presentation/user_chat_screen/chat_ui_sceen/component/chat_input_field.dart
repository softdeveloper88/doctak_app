import 'package:flutter/material.dart';
import 'package:doctak_app/main.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVColors.dart';
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

class _ChatInputFieldState extends State<ChatInputField> with SingleTickerProviderStateMixin {
  bool _showEmoji = false;
  late AnimationController _animationController;
  late Animation<double> _animation;
  final FocusNode _focusNode = FocusNode();

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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: appStore.isDarkMode 
                ? const Color(0xFF1A1A1A) 
                : Colors.white,
            boxShadow: [
              BoxShadow(
                color: appStore.isDarkMode
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
            bottom: MediaQuery.of(context).padding.bottom + 8,
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
                    color: appStore.isDarkMode
                        ? const Color(0xFF262626)
                        : const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: appStore.isDarkMode
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Emoji button
                      IconButton(
                        icon: Icon(
                          _showEmoji ? Icons.keyboard : Icons.emoji_emotions_outlined,
                          color: appStore.isDarkMode
                              ? Colors.white70
                              : Colors.grey[600],
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
                            color: appStore.isDarkMode
                                ? Colors.white
                                : Colors.black87,
                            fontFamily: 'Poppins',
                          ),
                          decoration: InputDecoration(
                            hintText: translation(context).lbl_type_message_here,
                            hintStyle: TextStyle(
                              color: appStore.isDarkMode
                                  ? Colors.white38
                                  : Colors.grey[500],
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
                          color: appStore.isDarkMode
                              ? Colors.white70
                              : Colors.grey[600],
                          size: 24,
                        ),
                        onPressed: widget.onAttachmentPressed,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Send/Record button
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      SVAppColorPrimary,
                      SVAppColorPrimary.withOpacity(0.8),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: SVAppColorPrimary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.isLoading
                        ? null
                        : () {
                            if (widget.controller.text.trim().isNotEmpty) {
                              widget.onSubmitted(widget.controller.text);
                            } else {
                              // For tap, just trigger record state change
                              widget.onRecordStateChanged(true);
                            }
                          },
                    borderRadius: BorderRadius.circular(24),
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
                        widget.controller.selection = TextSelection.fromPosition(
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
                          emojiSizeMax: 28 *
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