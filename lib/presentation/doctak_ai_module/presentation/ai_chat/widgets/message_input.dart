import 'package:flutter/material.dart';

import '../../../../../localization/app_localization.dart';
import '../../../../../theme/theme_helper.dart';

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
                    style: const TextStyle(
                      fontSize: 13,
                      fontFamily: 'Poppins',
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: Colors.blue[600],
                    ),
                    items: ['gpt-4o', 'gpt-3.5-turbo', 'gpt-4-turbo'].map((model) {
                      return DropdownMenuItem<String>(
                        value: model,
                        child: Text(
                          model,
                          style: const TextStyle(
                            fontSize: 13,
                            fontFamily: 'Poppins',
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
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
                            ? Colors.blue[600]
                            : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Web search',
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                          color: widget.webSearchEnabled
                            ? Colors.blue[600]
                            : Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Switch.adaptive(
                        value: widget.webSearchEnabled,
                        // Disable toggle when waiting for response
                        onChanged: widget.isWaitingForResponse
                            ? null
                            : widget.onWebSearchToggled,
                        activeColor: Colors.blue[600],
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
                        color: Colors.blue[600],
                      ),
                      items: const [
                        DropdownMenuItem<String>(
                          value: 'low',
                          child: Text(
                            'Low context',
                            style: TextStyle(
                              fontSize: 13,
                              fontFamily: 'Poppins',
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        DropdownMenuItem<String>(
                          value: 'medium',
                          child: Text(
                            'Medium context',
                            style: TextStyle(
                              fontSize: 13,
                              fontFamily: 'Poppins',
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        DropdownMenuItem<String>(
                          value: 'high',
                          child: Text(
                            'High context',
                            style: TextStyle(
                              fontSize: 13,
                              fontFamily: 'Poppins',
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
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

        // Input field and buttons - matching ChatGPT design
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withAlpha(13),
                offset: const Offset(0, -3),
                blurRadius: 8,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Text input - ChatGPT style
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.blueGrey[800]
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(24.0),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.2),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.05),
                            offset: const Offset(0, 2),
                            blurRadius: 8,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              minLines: 1,
                              maxLines: 4,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                color: isDarkMode 
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                              decoration: InputDecoration(
                                hintStyle: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white60
                                      : Colors.black54,
                                  fontFamily: 'Poppins',
                                ),
                                hintText: widget.isWaitingForResponse ? 'Waiting for AI response...' : 'Ask anything...',
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8.0, 
                                  vertical: 16.0
                                ),
                              ),
                              textCapitalization: TextCapitalization.sentences,
                              cursorColor: Colors.blue[600],
                              textInputAction: TextInputAction.newline,
                            ),
                          ),
                          // Send button - ChatGPT style
                          Container(
                            margin: const EdgeInsets.only(right: 8.0),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isComposing && !widget.isWaitingForResponse
                                  ? Colors.blue[600]
                                  : Colors.grey.withOpacity(0.3),
                              boxShadow: _isComposing && !widget.isWaitingForResponse ? [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.3),
                                  offset: const Offset(0, 2),
                                  blurRadius: 8,
                                  spreadRadius: 0,
                                ),
                              ] : [],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(30),
                                onTap: (!widget.isWaitingForResponse && _isComposing) ? _handleSend : null,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Icon(
                                    Icons.send_rounded,
                                    color: _isComposing && !widget.isWaitingForResponse
                                        ? Colors.white
                                        : Colors.grey.shade400,
                                    size: 20,
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
              const SizedBox(height: 6),
              // Disclaimer note - ChatGPT style
              Text(
                translation(context).msg_ai_disclaimer,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}