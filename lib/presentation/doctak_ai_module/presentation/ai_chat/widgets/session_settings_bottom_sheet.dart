import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/models/ai_chat_model/ai_chat_session_model.dart';

class SessionSettingsBottomSheet extends StatefulWidget {
  final AiChatSessionModel session;
  final double temperature;
  final int maxTokens;
  final Function(double) onTemperatureChanged;
  final Function(int) onMaxTokensChanged;
  final Function(String) onRenameSession;

  const SessionSettingsBottomSheet({
    Key? key,
    required this.session,
    required this.temperature,
    required this.maxTokens,
    required this.onTemperatureChanged,
    required this.onMaxTokensChanged,
    required this.onRenameSession,
  }) : super(key: key);

  @override
  State<SessionSettingsBottomSheet> createState() => _SessionSettingsBottomSheetState();
}

class _SessionSettingsBottomSheetState extends State<SessionSettingsBottomSheet> {
  late TextEditingController _renameController;
  double _temperature = 0.7;
  int _maxTokens = 1024;

  @override
  void initState() {
    super.initState();
    _renameController = TextEditingController(text: widget.session.name);
    _temperature = widget.temperature;
    _maxTokens = widget.maxTokens;
  }

  @override
  void dispose() {
    _renameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      // Handle bar at top - outside of scroll area
      child: Column(children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[600],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.settings_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Chat Settings',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // The rest in scrollable area
        Expanded(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 1.0,
            maxChildSize: 1.0,
            minChildSize: 1.0,
            builder: (_, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
           SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                    // Session name
                    Text(
                      'Session name',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.2),
                                width: 1.5,
                              ),
                            ),
                            child: TextField(
                              controller: _renameController,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Enter session name',
                                hintStyle: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Colors.grey[600],
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.blue[600],
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                offset: const Offset(0, 2),
                                blurRadius: 8,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () async {
                              final newName = _renameController.text.trim();
                              if (newName.isNotEmpty) {
                                // Validate name length and content
                                if (newName.length > 50) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        'Session name must be 50 characters or less',
                                        style: TextStyle(fontFamily: 'Poppins'),
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 2),
                                      backgroundColor: Colors.blue[600],
                                    ),
                                  );
                                  return;
                                }
                                
                                // Add haptic feedback
                                HapticFeedback.mediumImpact();
                                
                                // Use a variable to track completion
                                bool isRenameComplete = false;
                                
                                // Show indicator dialog
                                if (mounted) {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (dialogContext) {
                                      return PopScope(
                                        canPop: isRenameComplete,
                                        child: AlertDialog(
                                          content: Row(
                                            children: [
                                              CircularProgressIndicator(
                                                color: Colors.blue[600],
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Text(
                                                  'Renaming session to "$newName"...',
                                                  style: const TextStyle(fontFamily: 'Poppins'),
                                                ),
                                              ),
                                            ],
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                        ),
                                      );
                                    },
                                  );
                                }
                                
                                try {
                                  // Call the rename function directly without delay
                                  widget.onRenameSession(newName);
                                  
                                  // Mark complete and allow time for network request
                                  await Future.delayed(const Duration(milliseconds: 500));
                                  isRenameComplete = true;
                                  
                                  // Safely close dialogs if mounted
                                  if (mounted) {
                                    // Close the loading dialog
                                    Navigator.of(context).pop();
                                    
                                    // Close the bottom sheet
                                    Navigator.of(context).pop();
                                    
                                    // Show success message
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Session renamed to "$newName"',
                                          style: const TextStyle(fontFamily: 'Poppins'),
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                        duration: const Duration(seconds: 2),
                                        backgroundColor: Colors.blue[600],
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  isRenameComplete = true;
                                  
                                  // Close dialog if still open
                                  if (mounted) {
                                    Navigator.of(context).pop();
                                    
                                    // Show error message
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to rename session: ${e.toString()}',
                                          style: const TextStyle(fontFamily: 'Poppins'),
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                        backgroundColor: Colors.red,
                                        duration: const Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Rename',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),

                    // Temperature
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Temperature',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                            color: Colors.black87,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _temperature.toStringAsFixed(1),
                            style: TextStyle(
                              color: Colors.blue[600],
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.blue[600],
                        inactiveTrackColor: Colors.blue.withOpacity(0.2),
                        thumbColor: Colors.blue[600],
                        overlayColor: Colors.blue.withOpacity(0.1),
                        valueIndicatorColor: Colors.blue[600],
                        valueIndicatorTextStyle: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      child: Slider(
                        value: _temperature,
                        min: 0,
                        max: 2,
                        divisions: 20,
                        label: _temperature.toStringAsFixed(1),
                        onChanged: (value) {
                          setState(() {
                            _temperature = value;
                          });
                          widget.onTemperatureChanged(value);
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Precise',
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'Poppins',
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          'Creative',
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'Poppins',
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Max tokens
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Response Length',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                            color: Colors.black87,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$_maxTokens tokens',
                            style: TextStyle(
                              color: Colors.blue[600],
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.blue[600],
                        inactiveTrackColor: Colors.blue.withOpacity(0.2),
                        thumbColor: Colors.blue[600],
                        overlayColor: Colors.blue.withOpacity(0.1),
                        valueIndicatorColor: Colors.blue[600],
                        valueIndicatorTextStyle: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      child: Slider(
                        value: _maxTokens.toDouble(),
                        min: 16,
                        max: 4096,
                        divisions: 40,
                        label: '$_maxTokens tokens',
                        onChanged: (value) {
                          setState(() {
                            _maxTokens = value.toInt();
                          });
                          widget.onMaxTokensChanged(value.toInt());
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Brief',
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'Poppins',
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          'Detailed',
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'Poppins',
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    )),
      ]),
    );
  }
}