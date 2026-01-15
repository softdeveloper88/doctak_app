import 'dart:io';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../blocs/ai_chat/ai_chat_bloc.dart';
import '../data/models/ai_chat_model/ai_chat_message_model.dart';
import '../data/models/ai_chat_model/ai_chat_session_model.dart';
import 'ai_chat/widgets/session_settings_bottom_sheet.dart';
import 'ai_chat/widgets/virtualized_message_list.dart';
import 'ai_chat/widgets/message_input.dart';

class AiChatScreen extends StatefulWidget {
  final String? initialSessionId;

  const AiChatScreen({super.key, this.initialSessionId});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  TextEditingController? _inputController;
  File? _selectedImage;
  bool _showWelcomeScreen = true;
  String _selectedModel = 'gpt-4o';
  bool _webSearchEnabled = false;
  String _searchContextSize = 'medium';
  double _temperature = 0.7;
  int _maxTokens = 1024;
  bool _isWaitingForResponse = false; // Track if we're waiting for a response

  @override
  void initState() {
    super.initState();

    // Always load sessions first for consistent state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load all sessions first to ensure the drawer has data
      context.read<AiChatBloc>().add(LoadSessions());

      // If we have an initial session ID, select it immediately after sessions load
      if (widget.initialSessionId != null) {
        setState(() {
          _showWelcomeScreen = false;
        });
        context.read<AiChatBloc>().add(SelectSession(sessionId: widget.initialSessionId!));
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _showWelcomeScreen = false;
      });
    }
  }

  void _clearImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  /// Stores a message to be sent after session creation
  String? _pendingMessage;
  File? _pendingImageFile;

  // Handle prompt card tap with immediate UI update and session creation
  void _preCreateSession(String promptText) {
    // Immediately hide welcome screen when a prompt is clicked and show loading
    setState(() {
      _showWelcomeScreen = false; // Hide welcome screen immediately when prompt is clicked
      _isWaitingForResponse = true;
    });

    // Generate session name from the prompt
    final sessionName = _generateSessionNameFromPrompt(promptText);

    // Store message to be sent after session creation
    _pendingMessage = promptText;
    _pendingImageFile = _selectedImage;

    // Create the session immediately without delay
    if (mounted) {
      // The BLoC will handle the actual sending after session creation
      context.read<AiChatBloc>().add(CreateSession(name: sessionName));
    }
  }

  void _sendMessage(String message, {bool isFeatureCardPrompt = false}) {
    // For feature cards, use the pre-create session flow instead
    if (isFeatureCardPrompt) {
      _preCreateSession(message);
      return;
    }

    // Prevent sending if already waiting for a response
    if (_isWaitingForResponse) {
      debugPrint("Blocked message send - already waiting for response");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(translation(context).msg_wait_for_ai_response), duration: Duration(seconds: 2), behavior: SnackBarBehavior.floating));
      return;
    }

    // Validate that we have at least a message or an image
    if (message.trim().isEmpty && _selectedImage == null) {
      debugPrint("Empty message attempted");
      return;
    }

    // Set UI state to show we're waiting for response and now hide welcome screen
    // as user has explicitly sent a message
    setState(() {
      _showWelcomeScreen = false; // Now hide the welcome screen as user is sending a message
      _isWaitingForResponse = true;

      // If using input controller, clear it after sending
      if (_inputController != null && _inputController!.text == message) {
        _inputController!.clear();
      }
    });

    debugPrint("Sending message: $message");
    // Debug log
    if (_selectedImage != null) {
      debugPrint("Sending message with image: ${_selectedImage!.path}");
    } else {
      debugPrint("Sending text-only message");
    }

    final state = context.read<AiChatBloc>().state;

    // Make a local copy of the selected image before clearing it
    final imageToSend = _selectedImage;

    if (state is SessionSelected || state is MessageSent) {
      // Session already exists, send message to the current session
      debugPrint("Using existing session for message (state: ${state.runtimeType})");

      // Get session ID from either state type
      String sessionId;
      if (state is SessionSelected) {
        sessionId = state.selectedSession.id.toString();
      } else if (state is MessageSent) {
        sessionId = state.selectedSession.id.toString();
      } else {
        debugPrint("Unexpected state type when trying to get session ID");
        return;
      }

      debugPrint("Continuing conversation in session: $sessionId");

      // Send message to existing session
      context.read<AiChatBloc>().add(
        SendMessage(
          message: message,
          model: _selectedModel,
          temperature: _temperature,
          maxTokens: _maxTokens,
          webSearch: _webSearchEnabled,
          searchContextSize: _webSearchEnabled ? _searchContextSize : null,
          file: imageToSend, // Use local copy
          suggestTitle: false, // Don't suggest title for normal messages
        ),
      );
    } else {
      // No session selected, create one first
      debugPrint("No session selected, creating one first - state type: ${state.runtimeType}");

      // Store message to be sent after session creation
      _pendingMessage = message;
      _pendingImageFile = imageToSend;

      // Create session with default name (will be updated later)
      context.read<AiChatBloc>().add(const CreateSession());
    }

    // Clear image after sending
    _clearImage();
    _scrollToBottom();
  }

  /// Generates a session name from a prompt message
  String _generateSessionNameFromPrompt(String prompt) {
    // Extract first 4-5 words for a brief title
    final words = prompt.split(' ');
    if (words.length <= 5) {
      return prompt;
    }

    // Take first 5 words and add ellipsis
    return '${words.take(5).join(' ')}...';
  }

  void _showSessionSettingsSheet(BuildContext context) {
    final state = context.read<AiChatBloc>().state;
    if (state is! SessionSelected) {
      // Show error toast if we can't get session
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(translation(context).msg_cannot_access_session_settings), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 2)));
      return;
    }

    // Add haptic feedback when opening the sheet
    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      useRootNavigator: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      elevation: 16,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SessionSettingsBottomSheet(
        session: state.selectedSession,
        temperature: _temperature,
        maxTokens: _maxTokens,
        onTemperatureChanged: (value) {
          setState(() {
            _temperature = value;
          });
        },
        onMaxTokensChanged: (value) {
          setState(() {
            _maxTokens = value;
          });
        },
        onRenameSession: (name) {
          // Directly trigger the rename event without delay
          if (mounted) {
            // Show loading indicator while renaming
            setState(() {
              _isWaitingForResponse = true;
            });

            context.read<AiChatBloc>().add(RenameSession(sessionId: state.selectedSession.id.toString(), name: name));

            // Reset loading indicator after a reasonable timeout
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted && _isWaitingForResponse) {
                setState(() {
                  _isWaitingForResponse = false;
                });
              }
            });
          }
        },
      ),
    );
  }

  // Enhanced welcome screen with 4 essential medical prompt cards
  Widget _buildWelcomeScreen() {
    final theme = OneUITheme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;
    final isVerySmallScreen = screenSize.height < 700;

    return Container(
      color: theme.scaffoldBackground,
      child: SafeArea(
        child: Column(
          children: [
            // Compact Hero Header Section
            Container(
              margin: EdgeInsets.fromLTRB(24, isVerySmallScreen ? 12 : (isSmallScreen ? 16 : 24), 24, isVerySmallScreen ? 12 : 20),
              child: Column(
                children: [
                  // AI Icon - OneUI 8.5 style
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: theme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: theme.primary.withValues(alpha: 0.3), spreadRadius: 2, blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: const Center(child: Icon(Icons.psychology_alt_rounded, color: Colors.white, size: 40)),
                  ),

                  SizedBox(height: isVerySmallScreen ? 12 : (isSmallScreen ? 16 : 20)),

                  // Title text - OneUI 8.5 style
                  Text(
                    translation(context).lbl_doctak_ai_assistant,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Poppins', letterSpacing: 0.5, color: theme.textPrimary),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: isVerySmallScreen ? 8 : (isSmallScreen ? 10 : 12)),

                  // Description - OneUI 8.5 style
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      translation(context).lbl_intelligent_medical_companion,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, fontFamily: 'Poppins', height: 1.5, color: theme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),

            // Compact Quick Start Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Section header - OneUI 8.5 style
                  Text(
                    translation(context).lbl_quick_start,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: theme.primary),
                  ),

                  SizedBox(height: isVerySmallScreen ? 16 : (isSmallScreen ? 18 : 22)),
                ],
              ),
            ),

            // Enhanced 4-card grid layout - no scrolling
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: isSmallScreen ? 10 : 14,
                  mainAxisSpacing: isSmallScreen ? 10 : 14,
                  childAspectRatio: isVerySmallScreen ? 1.1 : (isSmallScreen ? 1.0 : 0.95),
                  physics: const NeverScrollableScrollPhysics(), // Disable scrolling
                  shrinkWrap: true,
                  children: [
                    _buildEnhancedFeatureCard(
                      title: translation(context).lbl_diagnosis_support,
                      description: translation(context).lbl_clinical_decision_assistance,
                      icon: Icons.medical_services_rounded,
                      gradientColors: [theme.primary.withValues(alpha: 0.6), theme.primary],
                      prompt: translation(context).msg_diagnosis_support_prompt,
                      isSmallScreen: isSmallScreen,
                      isVerySmallScreen: isVerySmallScreen,
                    ),
                    _buildEnhancedFeatureCard(
                      title: translation(context).lbl_drug_information,
                      description: translation(context).lbl_medication_safety_interactions,
                      icon: Icons.medication_liquid_rounded,
                      gradientColors: [theme.primary.withValues(alpha: 0.4), theme.primary.withValues(alpha: 0.8)],
                      prompt: translation(context).msg_drug_information_prompt,
                      isSmallScreen: isSmallScreen,
                      isVerySmallScreen: isVerySmallScreen,
                    ),
                    _buildEnhancedFeatureCard(
                      title: translation(context).lbl_treatment_plans,
                      description: translation(context).lbl_evidence_based_protocols,
                      icon: Icons.assignment_turned_in_rounded,
                      gradientColors: [theme.primary.withValues(alpha: 0.7), theme.primary],
                      prompt: translation(context).msg_treatment_plans_prompt,
                      isSmallScreen: isSmallScreen,
                      isVerySmallScreen: isVerySmallScreen,
                    ),
                    _buildEnhancedFeatureCard(
                      title: translation(context).lbl_medical_codes,
                      description: translation(context).lbl_icd_cpt_code_lookup,
                      icon: Icons.qr_code_scanner_rounded,
                      gradientColors: [theme.primary.withValues(alpha: 0.6), theme.primary],
                      prompt: translation(context).msg_medical_codes_prompt,
                      isSmallScreen: isSmallScreen,
                      isVerySmallScreen: isVerySmallScreen,
                    ),
                  ],
                ),
              ),
            ),

            // Minimal bottom spacing
            SizedBox(height: isVerySmallScreen ? 12 : (isSmallScreen ? 16 : 20)),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList() {
    return BlocConsumer<AiChatBloc, AiChatState>(
      listener: (context, state) {
        // Log current state type for debugging
        debugPrint("Current AI chat state: ${state.runtimeType}");

        // More stable state management with fewer setState calls
        // Group states by their effect on UI to reduce flickering

        // CASE 1: States that indicate we're actively sending a message
        if (state is MessageSending) {
          setState(() {
            // Always hide welcome screen when sending messages
            _showWelcomeScreen = false;
            _isWaitingForResponse = true;
          });
        }
        // CASE 2: States that indicate message activity is complete
        else if (state is MessageSent || state is MessageSendError) {
          setState(() {
            _showWelcomeScreen = false; // Always hide welcome screen after message activity
            _isWaitingForResponse = false;
          });

          // Only scroll if message was sent successfully
          if (state is MessageSent) {
            _scrollToBottom();
          }
        }
        // CASE 3: Session update states
        else if (state is SessionUpdating) {
          // Just show loading without changing welcome screen visibility
          setState(() {
            _isWaitingForResponse = true;
          });
        } else if (state is SessionUpdateError) {
          setState(() {
            _isWaitingForResponse = false;
          });
          // Show error message for session updates
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 3), backgroundColor: Colors.red));
        }
        // When a new session is created
        else if (state is SessionCreated) {
          debugPrint("SessionCreated received - selecting session: ${state.newSession.id}");

          // Use a microtask to avoid race conditions with state transitions
          Future.microtask(() {
            if (mounted) {
              context.read<AiChatBloc>().add(SelectSession(sessionId: state.newSession.id.toString()));
            }
          });
        }
        // CASE 4: Session selection - handle this only once
        else if (state is SessionSelected) {
          bool hasMessages = state.messages.isNotEmpty;

          // Handle pending messages for empty sessions first
          if (state.messages.isEmpty && _pendingMessage != null) {
            final String messageToSend = _pendingMessage!;
            final File? fileToSend = _pendingImageFile;

            debugPrint("Sending pending message to session: ${state.selectedSession.id}");

            // Send message immediately
            context.read<AiChatBloc>().add(
              SendMessage(
                message: messageToSend,
                model: _selectedModel,
                temperature: _temperature,
                maxTokens: _maxTokens,
                webSearch: _webSearchEnabled,
                searchContextSize: _webSearchEnabled ? _searchContextSize : null,
                file: fileToSend,
                suggestTitle: true, // Always suggest title for first message
              ),
            );

            // Clear pending message and file
            _pendingMessage = null;
            _pendingImageFile = null;

            // Clear selected image if it was used and not already cleared
            if (_selectedImage != null) {
              _clearImage();
            }

            return; // Return early to avoid the setState below
          }

          setState(() {
            // Only show welcome screen if session is empty - once we have messages, never show welcome again
            _showWelcomeScreen = !hasMessages;
            _isWaitingForResponse = false;
          });

          // Scroll to bottom only when session has messages
          if (hasMessages) {
            _scrollToBottom();
          }
        }

        // Handle session load errors
        if (state is SessionLoadError) {
          debugPrint("Session load error: ${state.message}");
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 3), backgroundColor: Colors.red));

          setState(() {
            _isWaitingForResponse = false;
          });
        }
      },
      builder: (context, state) {
        final theme = OneUITheme.of(context);
        // Use a more stable approach to determine what to render
        // This prevents flickering between different UI states

        // First case: If the welcome screen should be shown (for new sessions)
        // Simple logic: only show welcome screen if flag is true and no activity is happening
        if (_showWelcomeScreen && !_isWaitingForResponse) {
          return _buildWelcomeScreen();
        }

        // Second case: Show chat messages for all other situations
        List<AiChatMessageModel> messages = [];
        if (state is SessionSelected) {
          messages = state.messages;
        } else if (state is MessageSending) {
          messages = state.messages;
        } else if (state is MessageSent) {
          messages = state.messages;
        }

        // Use improved virtualized message list with streaming support
        final isStreaming = state is MessageStreaming;
        final streamingContent = isStreaming ? state.partialResponse : '';

        if (state is SessionLoading) {
          // When session is loading and we have a pending message, show it immediately
          // This makes the transition feel much smoother
          if (_pendingMessage != null) {
            // Create temporary user message to show immediately
            final userMessage = AiChatMessageModel(
              id: DateTime.now().millisecondsSinceEpoch,
              sessionId: 0, // Temporary ID
              role: MessageRole.user,
              content: _pendingMessage!,
              createdAt: DateTime.now(),
            );

            return Stack(
              children: [
                // Show the user message
                VirtualizedMessageList(
                  messages: [userMessage],
                  isLoading: true, // Show loading indicator
                  isStreaming: false,
                  streamingContent: '',
                  webSearch: _webSearchEnabled,
                  scrollController: _scrollController,
                  onFeedbackSubmitted: (_, __) {}, // No feedback during loading
                ),
              ],
            );
          } else {
            // Regular loading state with spinner if no pending message
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: 40, height: 40, child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(theme.primary))),
                  const SizedBox(height: 16),
                  Text(
                    translation(context).msg_loading_conversation,
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 16, color: theme.textSecondary),
                  ),
                ],
              ),
            );
          }
        } else if (state is MessageSendError) {
          // Enhanced error UI with animation
          return AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 300),
            child: Center(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: theme.error),
                      const SizedBox(height: 16),
                      Text(translation(context).msg_failed_to_send_message, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(state.message, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              // Retry sending the last message
                              final pendingMessage = _inputController?.text ?? "";

                              if (pendingMessage.isNotEmpty || _selectedImage != null) {
                                // Re-send the message with the same parameters
                                context.read<AiChatBloc>().add(
                                  SendMessage(
                                    message: pendingMessage,
                                    model: _selectedModel,
                                    temperature: _temperature,
                                    maxTokens: _maxTokens,
                                    webSearch: _webSearchEnabled,
                                    searchContextSize: _webSearchEnabled ? _searchContextSize : null,
                                    file: _selectedImage,
                                  ),
                                );
                              } else {
                                // Just clear the error state if no message to retry
                                context.read<AiChatBloc>().add(ClearCurrentSession());
                              }
                            },
                            icon: const Icon(Icons.refresh),
                            label: Text(translation(context).lbl_try_again),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          TextButton.icon(
                            icon: const Icon(Icons.close),
                            label: Text(translation(context).lbl_dismiss),
                            onPressed: () {
                              // Clear the error state
                              context.read<AiChatBloc>().add(ClearCurrentSession());
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        } else if (state is SessionsLoaded || state is SessionDeleted) {
          // Get the sessions list
          List<AiChatSessionModel> sessions = [];
          if (state is SessionsLoaded) {
            sessions = state.sessions;
          } else if (state is SessionDeleted) {
            sessions = state.sessions;
          }

          // If we have sessions but no selection, show empty state with sessions list
          if (sessions.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: theme.primary.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'Select a chat from the menu',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w500, color: theme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  // Info icon with hint
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: theme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: Icon(Icons.menu, size: 24, color: theme.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Open the menu to start a new chat',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: theme.textSecondary.withValues(alpha: 0.7), fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Default case: show the welcome screen layout
          return _buildWelcomeScreen();
        }

        // Return the virtualized message list for normal chat display
        return VirtualizedMessageList(
          messages: messages,
          isLoading: state is MessageSending && state is! MessageStreaming,
          isStreaming: isStreaming,
          streamingContent: streamingContent,
          webSearch: _webSearchEnabled,
          scrollController: _scrollController,
          onFeedbackSubmitted: (messageId, feedback) {
            context.read<AiChatBloc>().add(SubmitFeedback(messageId: messageId, feedback: feedback));
          },
        );
      },
    );
  }

  // Helper function to format session dates
  String _formatSessionDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      // Format as date
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  // Helper function to get current session title
  String _getCurrentSessionTitle() {
    final state = context.read<AiChatBloc>().state;
    if (state is SessionSelected || state is SessionUpdating || state is MessageSending || state is MessageSendError || state is MessageSent) {
      String title = '';
      if (state is SessionSelected) {
        title = state.selectedSession.name;
      } else if (state is SessionUpdating) {
        title = state.selectedSession?.name ?? 'Loading...';
      } else if (state is MessageSending) {
        title = state.selectedSession.name;
      } else if (state is MessageSent) {
        title = state.selectedSession.name;
      } else if (state is MessageSendError) {
        title = state.selectedSession.name;
      }

      // Return truncated session name for cleaner UI
      return title.isEmpty
          ? 'New Chat'
          : title.length > 25
          ? '${title.substring(0, 25)}...'
          : title;
    }

    // Show brand name when on welcome screen
    return 'DocTak AI';
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: DoctakAppBar(
        title: _getCurrentSessionTitle(),
        titleIcon: Icons.psychology_alt_rounded,
        showBackButton: true,
        onBackPressed: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
        },
        actions: [
          // History button - OneUI 8.5 style
          Builder(
            builder: (context) => IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: theme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(Icons.history, color: theme.primary, size: 14),
              ),
              tooltip: 'Chat History',
              onPressed: () {
                HapticFeedback.lightImpact();
                Scaffold.of(context).openDrawer();
              },
            ),
          ),

          // New Chat button
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: theme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.add_circle, color: theme.primary, size: 14),
            ),
            tooltip: 'New Chat',
            onPressed: () {
              HapticFeedback.mediumImpact();
              setState(() {
                _showWelcomeScreen = true;
                _isWaitingForResponse = true;
              });
              context.read<AiChatBloc>().add(const CreateSession());
              Future.delayed(const Duration(seconds: 3), () {
                if (mounted && _isWaitingForResponse) {
                  setState(() {
                    _isWaitingForResponse = false;
                  });
                }
              });
            },
          ),

          // Settings button (only visible when in a chat)
          BlocBuilder<AiChatBloc, AiChatState>(
            builder: (context, state) {
              final theme = OneUITheme.of(context);
              if (state is SessionSelected || state is SessionUpdating || state is MessageSending || state is MessageSendError || state is MessageSent) {
                return IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: theme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: Icon(Icons.settings_outlined, color: theme.primary, size: 14),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _showSessionSettingsSheet(context);
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      drawer: _buildChatDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            // Main chat area
            Expanded(child: _buildChatList()),
            // Image preview (if any)
            if (_selectedImage != null)
              Container(
                padding: const EdgeInsets.all(8),
                width: double.infinity,
                color: theme.cardBackground,
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(_selectedImage!, height: 60, width: 60, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(translation(context).lbl_image_attached, style: TextStyle(fontSize: 14, color: theme.textPrimary)),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: 20, color: theme.textSecondary),
                      onPressed: _clearImage,
                    ),
                  ],
                ),
              ),

            // Input area
            MessageInput(
              controller: _inputController = TextEditingController(),
              onSendMessage: _isWaitingForResponse ? null : _sendMessage, // Disable when waiting
              onAttachImage: _isWaitingForResponse ? null : _pickImage, // Disable when waiting
              selectedModel: _selectedModel,
              isWaitingForResponse: _isWaitingForResponse, // Pass waiting state to input
              onModelChanged: (model) {
                setState(() {
                  _selectedModel = model;
                });
              },
              webSearchEnabled: _webSearchEnabled,
              onWebSearchToggled: (enabled) {
                setState(() {
                  _webSearchEnabled = enabled;
                });
              },
              searchContextSize: _searchContextSize,
              onSearchContextSizeChanged: (size) {
                setState(() {
                  _searchContextSize = size;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatDrawer() {
    final theme = OneUITheme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top + 8;

    return Drawer(
      width: mediaQuery.size.width * 0.85,
      backgroundColor: theme.scaffoldBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // User profile header with safe area padding
          Container(
            padding: EdgeInsets.only(top: topPadding + 8, left: 16, right: 16, bottom: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [theme.primary.withValues(alpha: 0.1), theme.scaffoldBackground]),
            ),
            child: Row(
              children: [
                // Profile image - OneUI 8.5 style
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.primary.withValues(alpha: 0.1),
                    border: Border.all(color: theme.primary.withValues(alpha: 0.2), width: 2),
                    boxShadow: [BoxShadow(color: theme.primary.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: Center(
                    child: CustomImageView(imagePath: '${AppData.imageUrl}${AppData.profile_pic}', color: theme.isDark ? Colors.white : theme.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dr. ${AppData.name}',
                        style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins', fontSize: 16, color: theme.isDark ? Colors.white : theme.primary),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppData.specialty,
                        style: TextStyle(fontFamily: 'Poppins', color: theme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Close button
                IconButton(
                  icon: Icon(Icons.close, size: 20, color: theme.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Divider(color: theme.primary.withValues(alpha: 0.2), height: 1),
          ),

          // New Chat Button - OneUI 8.5 style
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: ElevatedButton(
              onPressed: () {
                // Add haptic feedback
                HapticFeedback.mediumImpact();

                // Close drawer first
                Navigator.pop(context);

                // Keep welcome screen visible, just show loading indicator
                setState(() {
                  _showWelcomeScreen = true; // Keep or restore welcome screen
                  _isWaitingForResponse = true;
                });

                // Create session immediately
                context.read<AiChatBloc>().add(const CreateSession());

                // Safety timeout in case creation takes too long
                Future.delayed(const Duration(seconds: 4), () {
                  if (mounted && _isWaitingForResponse) {
                    setState(() {
                      _isWaitingForResponse = false;
                    });

                    // Show error toast if we timed out
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Session creation timed out. Please try again.'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 2)));
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: theme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                elevation: 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    translation(context).lbl_new_chat,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: Colors.white, fontSize: 14, letterSpacing: 0.2),
                  ),
                ],
              ),
            ),
          ),

          // Recent chats header - OneUI 8.5 style
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
            child: Row(
              children: [
                Icon(Icons.history, size: 16, color: theme.primary.withValues(alpha: 0.7)),
                const SizedBox(width: 8),
                Text(
                  translation(context).lbl_recent_chats,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, letterSpacing: 0.2, fontFamily: 'Poppins', color: theme.primary.withValues(alpha: 0.9)),
                ),
                const Spacer(),
                // Number of sessions counter
                BlocBuilder<AiChatBloc, AiChatState>(
                  builder: (context, state) {
                    // Get sessions count
                    int count = 0;
                    if (state is SessionsLoaded) count = state.sessions.length;
                    if (state is SessionSelected) count = state.sessions.length;
                    if (state is MessageSending) count = state.sessions.length;
                    if (state is MessageSent) count = state.sessions.length;

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: theme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: Text(
                        '$count',
                        style: TextStyle(color: theme.primary, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Chat list
          Expanded(
            child: BlocBuilder<AiChatBloc, AiChatState>(
              builder: (context, state) {
                List<AiChatSessionModel> sessions = [];

                if (state is SessionsLoaded) {
                  sessions = state.sessions;
                } else if (state is SessionSelected) {
                  sessions = state.sessions;
                } else if (state is MessageSending) {
                  sessions = state.sessions;
                } else if (state is MessageSendError) {
                  sessions = state.sessions;
                } else if (state is MessageSent) {
                  sessions = state.sessions;
                } else if (state is SessionCreated) {
                  sessions = state.sessions;
                } else if (state is SessionDeleted) {
                  sessions = state.sessions;
                } else if (state is SessionUpdateError) {
                  sessions = state.sessions;
                } else if (state is FeedbackError) {
                  sessions = state.sessions;
                }

                // Make sure sessions are loaded at init or when empty
                if (sessions.isEmpty) {
                  // Always try to load or refresh sessions when drawer is opened
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    debugPrint("Triggering LoadSessions from drawer - state: ${state.runtimeType}");
                    context.read<AiChatBloc>().add(LoadSessions());
                  });

                  // Show loading indicator for better UX
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading your conversations...', textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  );
                }

                if (sessions.isEmpty) {
                  return Center(
                    child: Text(translation(context).msg_no_chat_history, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: theme.textSecondary)),
                  );
                }

                return ListView.builder(
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessions[index];

                    // Determine if this session is selected
                    bool isSelected = false;
                    if (state is SessionSelected) {
                      isSelected = state.selectedSession.id.toString() == session.id.toString();
                    } else if (state is MessageSending) {
                      isSelected = state.selectedSession.id.toString() == session.id.toString();
                    } else if (state is MessageSendError) {
                      isSelected = state.selectedSession.id.toString() == session.id.toString();
                    }
                    return Dismissible(
                      key: Key('session_${session.id}'),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16.0),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Delete Conversation'),
                              content: Text('Are you sure you want to delete "${session.name}"?'),
                              actions: <Widget>[
                                TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('CANCEL')),
                                TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('DELETE')),
                              ],
                            );
                          },
                        );
                      },
                      onDismissed: (direction) {
                        context.read<AiChatBloc>().add(DeleteSession(sessionId: session.id.toString()));
                      },
                      child: ListTile(
                        title: Text(
                          session.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Poppins',
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? theme.primary : theme.textPrimary,
                            letterSpacing: isSelected ? 0.1 : 0,
                          ),
                        ),
                        subtitle: Text(
                          // Format date for better readability
                          _formatSessionDate(session.updatedAt),
                          style: TextStyle(fontSize: 11, fontFamily: 'Poppins', color: isSelected ? theme.primary.withValues(alpha: 0.7) : theme.textSecondary),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: isSelected ? theme.primary.withValues(alpha: 0.1) : theme.textSecondary.withValues(alpha: 0.1)),
                          child: Icon(Icons.chat_bubble_outline, size: 16, color: isSelected ? theme.primary : theme.textSecondary),
                        ),
                        trailing: IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(shape: BoxShape.circle, color: theme.textSecondary.withValues(alpha: 0.1)),
                            child: Icon(Icons.delete_outline, size: 16, color: isSelected ? theme.primary : theme.textSecondary),
                          ),
                          onPressed: () async {
                            // Add haptic feedback
                            HapticFeedback.lightImpact();

                            final shouldDelete = await showDialog<bool>(
                              context: context,
                              builder: (BuildContext dialogContext) {
                                final dialogTheme = OneUITheme.of(dialogContext);
                                return AlertDialog(
                                  backgroundColor: dialogTheme.cardBackground,
                                  title: Text('Delete Conversation', style: TextStyle(color: dialogTheme.textPrimary)),
                                  content: Text('Are you sure you want to delete "${session.name}"?', style: TextStyle(color: dialogTheme.textSecondary)),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () => Navigator.of(dialogContext).pop(false),
                                      child: Text(
                                        'CANCEL',
                                        style: TextStyle(color: dialogTheme.primary, fontFamily: 'Poppins'),
                                      ),
                                    ),
                                    FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: dialogTheme.error,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onPressed: () => Navigator.of(dialogContext).pop(true),
                                      child: const Text('DELETE'),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (shouldDelete == true) {
                              context.read<AiChatBloc>().add(DeleteSession(sessionId: session.id.toString()));

                              // Show success message
                              if (mounted) {
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(SnackBar(content: Text('Conversation "${session.name}" deleted'), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)));
                              }
                            }
                          },
                        ),
                        selected: isSelected,
                        selectedTileColor: theme.primary.withValues(alpha: 0.1),
                        onTap: () {
                          // First close the drawer
                          Navigator.pop(context);

                          // Check if this is already the selected session
                          if (state is SessionSelected && state.selectedSession.id.toString() == session.id.toString()) {
                            // Already selected, just clear welcome screen
                            setState(() {
                              _showWelcomeScreen = false;
                            });
                            return;
                          }

                          // Show loading indicator immediately - but don't hide welcome screen yet
                          // It will be properly handled in BlocConsumer based on session content
                          setState(() {
                            _isWaitingForResponse = true; // Only show loading state
                          });

                          // Load the session immediately without delay
                          context.read<AiChatBloc>().add(SelectSession(sessionId: session.id.toString()));

                          // Safety timeout in case the session loading gets stuck
                          Future.delayed(const Duration(seconds: 5), () {
                            if (mounted && _isWaitingForResponse) {
                              setState(() {
                                _isWaitingForResponse = false;
                              });
                              // Show error toast if we timed out
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(const SnackBar(content: Text('Session loading timed out. Please try again.'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 2)));
                            }
                          });
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Professional feature card - OneUI 8.5 styled
  Widget _buildEnhancedFeatureCard({
    required String title,
    required String description,
    required IconData icon,
    required List<Color> gradientColors,
    required String prompt,
    required bool isSmallScreen,
    bool isVerySmallScreen = false,
  }) {
    final theme = OneUITheme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          _preCreateSession(prompt);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.primary.withValues(alpha: 0.15), width: 1),
            boxShadow: [
              BoxShadow(
                color: theme.primary.withValues(alpha: theme.isDark ? 0.15 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon - OneUI 8.5 style
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: theme.primary.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 8),

              // Title
              Text(
                title,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: theme.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),

              // Description
              Text(
                description,
                style: TextStyle(fontSize: 11, fontFamily: 'Poppins', color: theme.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
