import 'package:flutter/material.dart';

import '../../../theme/theme_helper.dart';

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

  const MessageInput({
    Key? key,
    this.controller,
    required this.onSendMessage,
    required this.onAttachImage,
    required this.selectedModel,
    required this.onModelChanged,
    required this.webSearchEnabled,
    required this.onWebSearchToggled,
    required this.searchContextSize,
    required this.onSearchContextSizeChanged,
    this.isWaitingForResponse = false, // Default to not waiting
  }) : super(key: key);

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _showAdvancedOptions = false;
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    // Use provided controller or create a new one
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(() {
      setState(() {
        _isComposing = _controller.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    // Only dispose the controller if we created it
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSend() {
    // Don't send if already waiting for a response
    if (widget.isWaitingForResponse) {
      return;
    }
    
    final message = _controller.text.trim();
    if (message.isNotEmpty && widget.onSendMessage != null) {
      widget.onSendMessage!(message);
      _controller.clear();
      setState(() {
        _isComposing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Advanced options
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: _showAdvancedOptions ? 56 : 0,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              top: BorderSide(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : appTheme.gray300.withOpacity(0.5),
                width: 1,
              ),
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Model dropdown
                  DropdownButton<String>(
                    value: widget.selectedModel,
                    underline: const SizedBox.shrink(),
                    isDense: true,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDarkMode ? Colors.white : colorScheme.onSurface,
                    ),
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: isDarkMode
                          ? Colors.white70
                          : colorScheme.onSurface.withOpacity(0.7),
                    ),
                    items: ['gpt-4o', 'gpt-3.5-turbo', 'gpt-4-turbo'].map((model) {
                      return DropdownMenuItem<String>(
                        value: model,
                        child: Text(
                          model,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDarkMode ? Colors.white : colorScheme.onSurface,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        widget.onModelChanged(value);
                      }
                    },
                  ),

                  const SizedBox(width: 16),

                  // Web search toggle - disabled when waiting
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search,
                        size: 16,
                        color: widget.webSearchEnabled
                            ? colorScheme.primary
                            : isDarkMode
                                ? Colors.white54
                                : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Web search',
                        style: TextStyle(
                          fontSize: 13,
                          color: widget.webSearchEnabled
                            ? colorScheme.primary
                            : isDarkMode
                                ? Colors.white70
                                : colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Switch.adaptive(
                        value: widget.webSearchEnabled,
                        // Disable toggle when waiting for response
                        onChanged: widget.isWaitingForResponse
                            ? null
                            : widget.onWebSearchToggled,
                        activeColor: colorScheme.primary,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),

                  // Web search context size (only if web search is enabled)
                  if (widget.webSearchEnabled) ...[
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: widget.searchContextSize,
                      underline: const SizedBox.shrink(),
                      isDense: true,
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: isDarkMode
                            ? Colors.white70
                            : colorScheme.onSurface.withOpacity(0.7),
                      ),
                      items: [
                        DropdownMenuItem<String>(
                          value: 'low',
                          child: Text(
                            'Low context',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDarkMode ? Colors.white : colorScheme.onSurface,
                            ),
                          ),
                        ),
                        DropdownMenuItem<String>(
                          value: 'medium',
                          child: Text(
                            'Medium context',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDarkMode ? Colors.white : colorScheme.onSurface,
                            ),
                          ),
                        ),
                        DropdownMenuItem<String>(
                          value: 'high',
                          child: Text(
                            'High context',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDarkMode ? Colors.white : colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          widget.onSearchContextSizeChanged(value);
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // Input field and buttons
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, -1),
              ),
            ],
            border: Border(
              top: BorderSide(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : appTheme.gray300.withOpacity(0.5),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Function buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Attach file button
                  IconButton(
                    icon: Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 22,
                      color: isDarkMode
                          ? Colors.white70
                          : appTheme.gray600,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    onPressed: widget.isWaitingForResponse ? null : widget.onAttachImage,
                    visualDensity: VisualDensity.compact,
                  ),

                  // Settings icon
                  // IconButton(
                  //   icon: Icon(
                  //     _showAdvancedOptions ? Icons.keyboard_arrow_down : Icons.settings_outlined,
                  //     size: 22,
                  //     color: _showAdvancedOptions
                  //         ? colorScheme.primary
                  //         : isDarkMode
                  //         ? Colors.white70
                  //         : appTheme.gray600,
                  //   ),
                  //   padding: EdgeInsets.zero,
                  //   constraints: const BoxConstraints(
                  //     minWidth: 32,
                  //     minHeight: 32,
                  //   ),
                  //   onPressed: () {
                  //     setState(() {
                  //       _showAdvancedOptions = !_showAdvancedOptions;
                  //     });
                  //   },
                  //   visualDensity: VisualDensity.compact,
                  // ),
                ],
              ),

              const SizedBox(width: 8),

              // Text input - Modern style input similar to ChatGPT
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(
                    minHeight: 40,
                    maxHeight: 120,
                  ),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.white.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          decoration: InputDecoration(
                            hintText: widget.isWaitingForResponse ? 'Waiting for AI response...' : 'Ask anything...',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            isDense: true,
                            hintStyle: TextStyle(
                              fontSize: 14,
                              color: isDarkMode
                                  ? Colors.white54
                                  : Colors.grey.shade600,
                            ),
                          ),
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.white : Colors.black87,
                            height: 1.2,
                          ),
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                          cursorColor: colorScheme.primary,
                          textInputAction: TextInputAction.newline,
                        ),
                      ),

                      // Send button
                      Padding(
                        padding: const EdgeInsets.only(right: 4, bottom: 4),
                        child: Material(
                          color: widget.isWaitingForResponse
                              ? Colors.grey.withOpacity(0.2) // Disabled color when waiting
                              : _isComposing
                                ? colorScheme.primary
                                : isDarkMode
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: (!widget.isWaitingForResponse && _isComposing) ? _handleSend : null,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.send,
                                size: 16,
                                color: _isComposing
                                    ? Colors.white
                                    : isDarkMode
                                    ? Colors.white30
                                    : Colors.grey.shade400,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}