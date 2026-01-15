import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;

/// Enhanced chat input field with advanced animations
/// Features:
/// - Animated mic button with scale and pulse effects
/// - Smooth transitions between send/mic modes
/// - Ripple effect on button press
/// - Elastic animations
class EnhancedChatInputField extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSubmitted;
  final VoidCallback onAttachmentPressed;
  final Function(bool, {Offset? pointerPosition}) onRecordStateChanged;
  final Function(String) onVoiceRecorded;
  final bool isRecording;
  final bool isLoading;
  final Function(String)? onTyping;

  const EnhancedChatInputField({
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
  State<EnhancedChatInputField> createState() => _EnhancedChatInputFieldState();
}

class _EnhancedChatInputFieldState extends State<EnhancedChatInputField> with TickerProviderStateMixin {
  bool _showEmoji = false;
  final FocusNode _focusNode = FocusNode();
  bool _isPressed = false;

  // Animation controllers
  late AnimationController _emojiController;
  late AnimationController _micPulseController;
  late AnimationController _micScaleController;
  late AnimationController _buttonTransitionController;

  // Animations
  late Animation<double> _emojiAnimation;
  late Animation<double> _micPulseAnimation;
  late Animation<double> _micScaleAnimation;
  late Animation<double> _buttonTransitionAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    widget.controller.addListener(_onTextChanged);
  }

  void _initAnimations() {
    // Emoji picker animation
    _emojiController = AnimationController(duration: const Duration(milliseconds: 250), vsync: this);
    _emojiAnimation = CurvedAnimation(parent: _emojiController, curve: Curves.easeOutCubic);

    // Mic pulse animation (breathing effect)
    _micPulseController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this)..repeat(reverse: true);
    _micPulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(CurvedAnimation(parent: _micPulseController, curve: Curves.easeInOut));

    // Mic scale animation (on press)
    _micScaleController = AnimationController(duration: const Duration(milliseconds: 150), vsync: this);
    _micScaleAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(CurvedAnimation(parent: _micScaleController, curve: Curves.elasticOut));

    // Button transition (mic <-> send)
    _buttonTransitionController = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
    _buttonTransitionAnimation = CurvedAnimation(parent: _buttonTransitionController, curve: Curves.easeInOut);
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText && _buttonTransitionController.value == 0) {
      _buttonTransitionController.forward();
    } else if (!hasText && _buttonTransitionController.value == 1) {
      _buttonTransitionController.reverse();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _emojiController.dispose();
    _micPulseController.dispose();
    _micScaleController.dispose();
    _buttonTransitionController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _toggleEmoji() {
    setState(() {
      _showEmoji = !_showEmoji;
      if (_showEmoji) {
        _focusNode.unfocus();
        _emojiController.forward();
      } else {
        _emojiController.reverse();
      }
    });
  }

  void _onMicPress(LongPressStartDetails details) {
    if (widget.isLoading || widget.controller.text.trim().isNotEmpty) return;

    setState(() => _isPressed = true);
    _micScaleController.forward();
    HapticFeedback.mediumImpact();
    widget.onRecordStateChanged(true, pointerPosition: details.globalPosition);
  }

  void _onMicRelease(LongPressEndDetails details) {
    setState(() => _isPressed = false);
    _micScaleController.reverse();

    if (widget.isRecording) {
      widget.onRecordStateChanged(false);
    }
  }

  void _onMicCancel() {
    setState(() => _isPressed = false);
    _micScaleController.reverse();
  }

  void _onSendTap() {
    if (widget.controller.text.trim().isNotEmpty) {
      HapticFeedback.lightImpact();
      widget.onSubmitted(widget.controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;
    final theme = OneUITheme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.cardBackground,
            boxShadow: [BoxShadow(color: theme.isDark ? Colors.black.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -3))],
          ),
          padding: EdgeInsets.only(left: 12, right: 12, top: 8, bottom: (keyboardPadding > 0 ? 0 : bottomPadding) + 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Input field container
              Expanded(child: _buildInputContainer(theme)),
              const SizedBox(width: 10),
              // Animated action button
              _buildActionButton(theme),
            ],
          ),
        ),
        // Emoji picker
        _buildEmojiPicker(theme),
      ],
    );
  }

  Widget _buildInputContainer(OneUITheme theme) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48, maxHeight: 120),
      decoration: BoxDecoration(
        color: theme.inputBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.divider, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Emoji button with animation
          _buildEmojiButton(theme),
          // Text field
          Expanded(child: _buildTextField(theme)),
          // Attachment button
          _buildAttachmentButton(theme),
        ],
      ),
    );
  }

  Widget _buildEmojiButton(OneUITheme theme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: _toggleEmoji,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) {
              return RotationTransition(
                turns: Tween(begin: 0.5, end: 1.0).animate(animation),
                child: ScaleTransition(scale: animation, child: child),
              );
            },
            child: Icon(_showEmoji ? Icons.keyboard : Icons.emoji_emotions_outlined, key: ValueKey(_showEmoji), color: theme.textSecondary, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(OneUITheme theme) {
    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      textCapitalization: TextCapitalization.sentences,
      keyboardType: TextInputType.multiline,
      maxLines: null,
      minLines: 1,
      style: TextStyle(fontSize: 16, color: theme.textPrimary, fontFamily: 'Poppins'),
      decoration: InputDecoration(
        hintText: translation(context).lbl_type_message_here,
        hintStyle: TextStyle(color: theme.textTertiary, fontSize: 16, fontFamily: 'Poppins'),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
      ),
      onChanged: widget.onTyping,
      onTap: () {
        if (_showEmoji) {
          setState(() {
            _showEmoji = false;
            _emojiController.reverse();
          });
        }
      },
    );
  }

  Widget _buildAttachmentButton(OneUITheme theme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: widget.onAttachmentPressed,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(Icons.attach_file_rounded, color: theme.textSecondary, size: 24),
        ),
      ),
    );
  }

  Widget _buildActionButton(OneUITheme theme) {
    return AnimatedBuilder(
      animation: Listenable.merge([_micPulseAnimation, _micScaleAnimation, _buttonTransitionAnimation]),
      builder: (context, child) {
        final hasText = widget.controller.text.trim().isNotEmpty;
        final isMicMode = !hasText && !widget.isLoading;

        // Calculate combined scale
        double scale = 1.0;
        if (isMicMode) {
          scale = _micPulseAnimation.value;
          if (_isPressed) {
            scale *= _micScaleAnimation.value;
          }
        }

        return GestureDetector(
          onTap: hasText ? _onSendTap : null,
          onLongPressStart: isMicMode ? _onMicPress : null,
          onLongPressEnd: isMicMode ? _onMicRelease : null,
          onLongPressCancel: _onMicCancel,
          child: Transform.scale(
            scale: scale,
            child: Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [theme.primary, theme.primary.withValues(alpha: 0.75)]),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.primary.withValues(alpha: _isPressed ? 0.5 : 0.3),
                    blurRadius: _isPressed ? 16 : 10,
                    offset: const Offset(0, 3),
                    spreadRadius: _isPressed ? 2 : 0,
                  ),
                ],
              ),
              child: Center(child: _buildButtonIcon()),
            ),
          ),
        );
      },
    );
  }

  Widget _buildButtonIcon() {
    if (widget.isLoading) {
      return const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)));
    }

    final hasText = widget.controller.text.trim().isNotEmpty;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: animation,
          child: RotationTransition(turns: Tween(begin: 0.0, end: 1.0).animate(animation), child: child),
        );
      },
      child: Icon(hasText ? Icons.send_rounded : Icons.mic_rounded, key: ValueKey(hasText ? 'send' : 'mic'), color: Colors.white, size: 26),
    );
  }

  Widget _buildEmojiPicker(OneUITheme theme) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      child: SizeTransition(
        sizeFactor: _emojiAnimation,
        child: _showEmoji
            ? SizedBox(
                height: 260,
                child: EmojiPicker(
                  onEmojiSelected: (category, emoji) {
                    widget.controller.text += emoji.emoji;
                    widget.controller.selection = TextSelection.fromPosition(TextPosition(offset: widget.controller.text.length));
                    if (widget.onTyping != null) {
                      widget.onTyping!(widget.controller.text);
                    }
                  },
                  textEditingController: widget.controller,
                  config: Config(
                    height: 260,
                    checkPlatformCompatibility: true,
                    viewOrderConfig: const ViewOrderConfig(),
                    emojiViewConfig: EmojiViewConfig(emojiSizeMax: 28 * (foundation.defaultTargetPlatform == TargetPlatform.iOS ? 1.2 : 1.0)),
                    skinToneConfig: const SkinToneConfig(),
                    categoryViewConfig: const CategoryViewConfig(),
                    bottomActionBarConfig: const BottomActionBarConfig(),
                    searchViewConfig: const SearchViewConfig(),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
