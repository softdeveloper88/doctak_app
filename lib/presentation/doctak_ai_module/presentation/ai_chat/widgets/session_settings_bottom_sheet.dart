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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, -2),
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
              color: colorScheme.onSurface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Chat Settings',
          style: textTheme.titleLarge,
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
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _renameController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              hintText: 'Enter session name',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            final newName = _renameController.text.trim();
                            if (newName.isNotEmpty) {
                              // Validate name length and content
                              if (newName.length > 50) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Session name must be 50 characters or less'),
                                    behavior: SnackBarBehavior.floating,
                                    duration: Duration(seconds: 2),
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
                                            const CircularProgressIndicator(),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Text('Renaming session to "$newName"...'),
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
                                      content: Text('Session renamed to "$newName"'),
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 2),
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
                                      content: Text('Failed to rename session: ${e.toString()}'),
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
                            backgroundColor: colorScheme.primary,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Rename'),
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
                          style: textTheme.titleMedium,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _temperature.toStringAsFixed(1),
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Slider(
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Precise',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        Text(
                          'Creative',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.7),
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
                          style: textTheme.titleMedium,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$_maxTokens tokens',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Slider(
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Brief',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        Text(
                          'Detailed',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.7),
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