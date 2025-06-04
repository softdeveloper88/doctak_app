import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CommentInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmit;
  final bool isLoading;

  const CommentInput({
    Key? key,
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<CommentInput> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            offset: const Offset(0, -2),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Comment composition area
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.focusNode.hasFocus
                      ? Colors.blue.withOpacity(0.3)
                      : Colors.blue.withOpacity(0.1),
                  width: widget.focusNode.hasFocus ? 2 : 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Avatar
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        child: Icon(
                          Icons.person_rounded,
                          size: 18,
                          color: Colors.blue[600],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Text input
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: widget.focusNode,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Poppins',
                        color: Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Share your medical insights...',
                        hintStyle: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          fontFamily: 'Poppins',
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 0,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _hasText ? widget.onSubmit() : null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  
                  // Send button
                  Padding(
                    padding: const EdgeInsets.only(right: 8, bottom: 4),
                    child: GestureDetector(
                      onTap: widget.isLoading || !_hasText ? null : widget.onSubmit,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: widget.isLoading || !_hasText
                              ? Colors.grey.withOpacity(0.3)
                              : Colors.blue[600],
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _hasText && !widget.isLoading
                              ? [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.3),
                                    offset: const Offset(0, 2),
                                    blurRadius: 6,
                                    spreadRadius: 0,
                                  ),
                                ]
                              : null,
                        ),
                        child: widget.isLoading
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.blue[800]!,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.send_rounded,
                                size: 16,
                                color: _hasText ? Colors.white : Colors.grey[600],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Helper text
            if (widget.focusNode.hasFocus) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 12,
                      color: Colors.blue[600],
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Share professional insights and maintain medical ethics',
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'Poppins',
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}