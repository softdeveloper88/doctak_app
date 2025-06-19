import 'dart:io';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/presentation/doctak_ai_module/presentation/user_message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../theme/theme_helper.dart';
import '../blocs/ai_chat/ai_chat_bloc.dart';
import '../data/api/streaming_message_service.dart'; 
import '../data/models/ai_chat_model/ai_chat_message_model.dart';
import '../data/models/ai_chat_model/ai_chat_session_model.dart';
import 'ai_chat/widgets/ai_message_bubble.dart';
import 'ai_chat/widgets/session_settings_bottom_sheet.dart';
import 'ai_chat/widgets/streaming_message_bubble.dart';
import 'ai_chat/widgets/virtualized_message_list.dart';
import 'ai_typing_indicator.dart';
import 'message_input.dart';

class AiChatScreen extends StatefulWidget {
  final String? initialSessionId;

  const AiChatScreen({
    super.key,
    this.initialSessionId,
  });

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
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for the AI to respond before sending another message'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
      context.read<AiChatBloc>().add(SendMessage(
        message: message,
        model: _selectedModel,
        temperature: _temperature,
        maxTokens: _maxTokens,
        webSearch: _webSearchEnabled,
        searchContextSize: _webSearchEnabled ? _searchContextSize : null,
        file: imageToSend, // Use local copy
        suggestTitle: false, // Don't suggest title for normal messages
      ));
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot access session settings right now'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
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
      barrierColor: Colors.black.withOpacity(0.5),
      elevation: 16,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
            
            context.read<AiChatBloc>().add(RenameSession(
              sessionId: state.selectedSession.id.toString(),
              name: name,
            ));
            
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

  // Modern welcome screen with medical-specific feature cards
  Widget _buildWelcomeScreen() {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final isMediumScreen = screenSize.width >= 360 && screenSize.width < 600;
    final isLargeScreen = screenSize.width >= 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        
        // Animated header section with icon - more compact design
        Container(
          margin: EdgeInsets.only(top: isSmallScreen ? 6 : 10),
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: isSmallScreen ? 10 : 12,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primaryContainer.withOpacity(0.3),
                colorScheme.primaryContainer.withOpacity(0.1),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Icon
              Icon(
                Icons.psychology_rounded,
                size: isSmallScreen ? 40 : 48,
                color: colorScheme.primary,
              ),
              
              SizedBox(height: isSmallScreen ? 10 : 12),
              
              // Main title with better typography
              Text(
                'DocTak AI Assistant',
                style: textTheme.titleLarge?.copyWith(
                  fontSize: isSmallScreen ? 20 : 24,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: isSmallScreen ? 6 : 8),
              
              // Subtitle with better readability
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'How can I help you today?',
                  style: textTheme.titleMedium?.copyWith(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w400,
                    color: colorScheme.onSurface.withOpacity(0.8),
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        
        // Gap before feature cards with visual divider - more compact
        Padding(
          padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 8 : 10),
          child: Row(
            children: [
              Expanded(
                child: Divider(
                  color: colorScheme.outlineVariant.withOpacity(0.5),
                  thickness: 1,
                  indent: 24,
                  endIndent: 12,
                ),
              ),
              Text(
                'Suggestions',
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              Expanded(
                child: Divider(
                  color: colorScheme.outlineVariant.withOpacity(0.5),
                  thickness: 1,
                  indent: 12,
                  endIndent: 24,
                ),
              ),
            ],
          ),
        ),
        // Medical features in a responsive grid layout - takes most of the screen
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 10 : (isMediumScreen ? 12 : 16), 
              vertical: 4 // Small vertical padding for better aesthetics
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate optimal card width based on screen width with better spacing
                // Use integer division to ensure even spacing
                final int cardsPerRow = isLargeScreen ? 3 : 2;
                final double totalSpacing = (cardsPerRow - 1) * (isSmallScreen ? 8 : (isMediumScreen ? 10 : 14));
                final double cardWidth = (constraints.maxWidth - totalSpacing) / cardsPerRow;

                return Wrap(
                  alignment: WrapAlignment.center,
                  spacing: isSmallScreen ? 8 : (isMediumScreen ? 10 : 14),
                  runSpacing: isSmallScreen ? 8 : (isMediumScreen ? 10 : 14),
                  children: [
                    _buildFeatureCard(
                      'Code Detection',
                      'Identify CPT or ICD codes',
                      Icons.qr_code,
                      'What CPT code should I use for a routine physical exam?',
                      cardWidth: cardWidth,
                    ),
                    _buildFeatureCard(
                      'Diagnosis Help',
                      'Clinical decision support',
                      Icons.health_and_safety,
                      'What conditions should I consider for a patient with fever, headache and fatigue?',
                      cardWidth: cardWidth,
                    ),
                    _buildFeatureCard(
                      'Drug Interactions',
                      'Check medication safety',
                      Icons.medication,
                      'Are there any interactions between metformin and lisinopril?',
                      cardWidth: cardWidth,
                    ),
                    _buildFeatureCard(
                      'Templates',
                      'Common medical documents',
                      Icons.description,
                      'Create a template for a discharge summary',
                      cardWidth: cardWidth,
                    ),
                    _buildFeatureCard(
                      'Patient Info',
                      'Simple explanations',
                      Icons.people,
                      'How do I explain type 2 diabetes treatment to a patient?',
                      cardWidth: cardWidth,
                    ),
                    _buildFeatureCard(
                      'Guidelines',
                      'Evidence-based practice',
                      Icons.menu_book,
                      'What are the current treatment guidelines for hypertension?',
                      cardWidth: cardWidth,
                    ),
                    _buildFeatureCard(
                      'Research',
                      'Latest medical findings',
                      Icons.science_outlined,
                      'Summarize recent studies on ACE inhibitors for heart failure',
                      cardWidth: cardWidth,
                    ),
                    _buildFeatureCard(
                      'Treatment',
                      'Compare options',
                      Icons.medical_services_outlined,
                      'What are the best hypertension treatments for elderly patients?',
                      cardWidth: cardWidth,
                    ),
                  ],
                );
              }
            ),
          ),
        ),

        // Bottom space
        SizedBox(height: isSmallScreen ? 16 : 24),
      ],
    );
  }

  // Medical feature card with icon, title, description, and prompt text
  Widget _buildFeatureCard(
    String title, 
    String description, 
    IconData icon, 
    String promptText, 
    {double? cardWidth}
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final isMediumScreen = screenSize.width >= 360 && screenSize.width < 600;
    
    // Calculate default width if not provided - ensure proper sizing on all screens
    final width = cardWidth ?? (screenSize.width > 600 ? 220 : screenSize.width * 0.42);
    
    // Adjust height based on screen size - use more compact heights to fit more cards
    final double minHeight = isSmallScreen ? 100.0 : (isMediumScreen ? 110.0 : 120.0);
    final double maxHeight = isSmallScreen ? 120.0 : (isMediumScreen ? 130.0 : 140.0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Add haptic feedback for better user experience
          HapticFeedback.lightImpact();
          // Pre-create session then send the prompt
          _preCreateSession(promptText);
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: width,
          constraints: BoxConstraints(
            minHeight: minHeight,
            maxHeight: maxHeight,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 10 : 12,
            vertical: isSmallScreen ? 8 : 10,
          ),
          decoration: BoxDecoration(
            color: isDarkMode
                ? colorScheme.surfaceContainerHighest.withOpacity(0.4)
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDarkMode
                  ? colorScheme.primary.withOpacity(0.3)
                  : colorScheme.outlineVariant,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row with icon and title for better space usage
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon in a small circle with better padding
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 6 : 7),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: isSmallScreen ? 14 : 16,
                      color: colorScheme.primary,
                    ),
                  ),
                  
                  SizedBox(width: isSmallScreen ? 8 : 10),
                  
                  // Title in bold - make sure it doesn't overflow
                  Expanded(
                    child: Text(
                      title,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 11 : 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: isSmallScreen ? 8 : 10),
              
              // Description with better text styling
              Text(
                description,
                style: textTheme.bodySmall?.copyWith(
                  color: isDarkMode
                      ? Colors.white70
                      : Colors.black54,
                  fontSize: isSmallScreen ? 10 : 11,
                  height: 1.2, // More compact line height
                  letterSpacing: -0.1,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              // Example text (hidden - just for tooltip/semantic access)
              Semantics(
                label: promptText,
                child: const SizedBox.shrink(),
              ),
              
              // Use flexible spacing
              const Spacer(flex: 1),
              
              // Action row with try it button and hint about prompt
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Small hint about the prompt with tooltip for full text
                    Expanded(
                      child: Tooltip(
                        message: promptText,
                        child: Text(
                          _shortenPrompt(promptText),
                          style: TextStyle(
                            color: isDarkMode ? Colors.white60 : Colors.black45,
                            fontSize: isSmallScreen ? 9 : 10,
                            fontStyle: FontStyle.italic,
                            height: 1.2, // Better line height
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                    
                    // Spacing
                    const SizedBox(width: 8),
                    
                    // Try it button with improved styling
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 8 : 10,
                        vertical: isSmallScreen ? 4 : 5,
                      ),
                      decoration: BoxDecoration(
                        color: isDarkMode 
                            ? colorScheme.primary.withOpacity(0.2)
                            : colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Try it',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: isSmallScreen ? 10 : 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Helper to shorten prompt text for preview
  String _shortenPrompt(String prompt) {
    final words = prompt.split(' ');
    if (words.length <= 4) return prompt;
    
    return '${words.take(4).join(' ')}...';
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
          bool hasMessages = state.messages.isNotEmpty;
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
        }
        else if (state is SessionUpdateError) {
          setState(() {
            _isWaitingForResponse = false;
          });
          // Show error message for session updates
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.red,
            ),
          );
        }
        // When a new session is created
        else if (state is SessionCreated) {
          debugPrint("SessionCreated received - selecting session: ${state.newSession.id}");

          // Use a microtask to avoid race conditions with state transitions
          Future.microtask(() {
            if (mounted) {
              context.read<AiChatBloc>().add(SelectSession(
                sessionId: state.newSession.id.toString(),
              ));
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
            context.read<AiChatBloc>().add(SendMessage(
              message: messageToSend,
              model: _selectedModel,
              temperature: _temperature,
              maxTokens: _maxTokens,
              webSearch: _webSearchEnabled,
              searchContextSize: _webSearchEnabled ? _searchContextSize : null,
              file: fileToSend,
              suggestTitle: true, // Always suggest title for first message
            ));

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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.red,
            ),
          );

          setState(() {
            _isWaitingForResponse = false;
          });
        }
      },
      builder: (context, state) {
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
        final streamingContent = isStreaming ? (state as MessageStreaming).partialResponse : '';

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
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading conversation...',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to send message',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.message,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
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
                                context.read<AiChatBloc>().add(SendMessage(
                                  message: pendingMessage,
                                  model: _selectedModel,
                                  temperature: _temperature,
                                  maxTokens: _maxTokens,
                                  webSearch: _webSearchEnabled,
                                  searchContextSize: _webSearchEnabled ? _searchContextSize : null,
                                  file: _selectedImage,
                                ));
                              } else {
                                // Just clear the error state if no message to retry
                                context.read<AiChatBloc>().add(ClearCurrentSession());
                              }
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try Again'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          TextButton.icon(
                            icon: const Icon(Icons.close),
                            label: const Text('Dismiss'),
                            onPressed: () {
                              // Clear the error state
                              context.read<AiChatBloc>().add(ClearCurrentSession());
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
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
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Select a chat from the menu',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Info icon with hint
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.menu,
                      size: 24,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Open the menu to start a new chat',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      fontStyle: FontStyle.italic,
                    ),
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
          isLoading: state is MessageSending && !(state is MessageStreaming),
          isStreaming: isStreaming,
          streamingContent: streamingContent,
          webSearch: _webSearchEnabled,
          scrollController: _scrollController,
          onFeedbackSubmitted: (messageId, feedback) {
            context.read<AiChatBloc>().add(SubmitFeedback(
              messageId: messageId,
              feedback: feedback,
            ));
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
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        shadowColor: Colors.black26,
        shape: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.2),
            width: 1,
          ),
        ),
        title: BlocBuilder<AiChatBloc, AiChatState>(
          builder: (context, state) {
            if (state is SessionSelected ||
                state is SessionUpdating ||
                state is MessageSending ||
                state is MessageSendError ||
                state is MessageSent) {
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
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  title.isEmpty ? 'New Chat' : title.length > 25 ? '${title.substring(0, 25)}...' : title,
                  key: ValueKey(title), // For animation to detect changes
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              );
            }

            // Show brand name when on welcome screen
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.psychology_alt_rounded,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'DocTak AI',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            );
          },
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(
              Icons.menu,
              color: colorScheme.onSurface,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          // New Chat button in app bar - always visible (icon only)
          IconButton(
            icon: Icon(
              Icons.add_circle,
              color: colorScheme.onSurface,
              size: 26,
            ),
            tooltip: 'New Chat',
            onPressed: () {
              // Add haptic feedback
              HapticFeedback.mediumImpact();
              
              // Keep welcome screen visible, just show loading indicator
              setState(() {
                _showWelcomeScreen = true;
                _isWaitingForResponse = true;
              });
              
              // Create session immediately
              context.read<AiChatBloc>().add(const CreateSession());
              
              // Safety timeout in case creation takes too long
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
              if (state is SessionSelected ||
                  state is SessionUpdating ||
                  state is MessageSending ||
                  state is MessageSendError ||
                  state is MessageSent) {
                return IconButton(
                  icon: Icon(
                    Icons.settings_outlined,
                    color: colorScheme.onSurface,
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
                color: Theme.of(context).cardColor,
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _selectedImage!,
                        height: 60,
                        width: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Image attached',
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top + 8;

    return Drawer(
      width: mediaQuery.size.width * 0.85, // Better width for drawer
      backgroundColor: isDarkMode 
          ? colorScheme.surfaceContainerHighest 
          : colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // User profile header with safe area padding
          Container(
            padding: EdgeInsets.only(
              top: topPadding + 8, 
              left: 16, 
              right: 16, 
              bottom: 16
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colorScheme.primaryContainer.withOpacity(0.2),
                  colorScheme.surface,
                ],
              ),
            ),
            child: Row(
              children: [
                // Profile image with better styling
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primaryContainer,
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.2),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: CustomImageView(
                      imagePath: '${AppData.imageUrl}${AppData.profile_pic}',
                      color: isDarkMode ? Colors.white : colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dr. ${AppData.name}',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppData.specialty,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Add close button for better UX
                IconButton(
                  icon: Icon(
                    Icons.close, 
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Divider with better padding
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Divider(
              color: colorScheme.outlineVariant.withOpacity(0.5),
              height: 1,
            ),
          ),

          // New Chat Button - More prominent styling
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Session creation timed out. Please try again.'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 1,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'New Chat',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Recent chats header with better styling
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
            child: Row(
              children: [
                Icon(
                  Icons.history,
                  size: 16,
                  color: colorScheme.primary.withOpacity(0.7),
                ),
                const SizedBox(width: 8),
                Text(
                  'Recent Chats',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: 0.2,
                    color: colorScheme.primary.withOpacity(0.9),
                  ),
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
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
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
                          Text('Loading your conversations...', 
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (sessions.isEmpty) {
                  return Center(
                    child: Text(
                      'No chat history',
                      style: textTheme.bodyMedium?.copyWith(
                        color: isDarkMode
                            ? Colors.white54
                            : Colors.black38,
                      ),
                    ),
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
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
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
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('CANCEL'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text('DELETE'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      onDismissed: (direction) {
                        context.read<AiChatBloc>().add(DeleteSession(
                          sessionId: session.id.toString(),
                        ));
                      },
                      child: ListTile(
                        title: Text(
                          session.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected 
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                            letterSpacing: isSelected ? 0.1 : 0,
                          ),
                        ),
                        subtitle: Text(
                          // Format date for better readability
                          _formatSessionDate(session.updatedAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected
                                ? colorScheme.primary.withOpacity(0.7)
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? colorScheme.primaryContainer
                                : colorScheme.surfaceVariant,
                          ),
                          child: Icon(
                            Icons.chat_bubble_outline,
                            size: 16,
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colorScheme.surfaceVariant.withOpacity(0.5),
                            ),
                            child: Icon(
                              Icons.delete_outline,
                              size: 16,
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                          onPressed: () async {
                            // Add haptic feedback
                            HapticFeedback.lightImpact();
                            
                            final shouldDelete = await showDialog<bool>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Delete Conversation'),
                                  content: Text('Are you sure you want to delete "${session.name}"?'),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: Text(
                                        'CANCEL',
                                        style: TextStyle(color: colorScheme.primary),
                                      ),
                                    ),
                                    FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: () => Navigator.of(context).pop(true),
                                      child: const Text('DELETE'),
                                    ),
                                  ],
                                );
                              },
                            );
                            
                            if (shouldDelete == true) {
                              context.read<AiChatBloc>().add(DeleteSession(
                                sessionId: session.id.toString(),
                              ));
                              
                              // Show success message
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Conversation "${session.name}" deleted'),
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        selected: isSelected,
                        selectedTileColor: colorScheme.primaryContainer.withOpacity(0.2),
                        onTap: () {
                          // First close the drawer
                          Navigator.pop(context);
                          
                          // Check if this is already the selected session
                          if (state is SessionSelected && 
                              (state as SessionSelected).selectedSession.id.toString() == session.id.toString()) {
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
                          context.read<AiChatBloc>().add(SelectSession(
                            sessionId: session.id.toString(),
                          ));
                          
                          // Safety timeout in case the session loading gets stuck
                          Future.delayed(const Duration(seconds: 5), () {
                            if (mounted && _isWaitingForResponse) {
                              setState(() {
                                _isWaitingForResponse = false;
                              });
                              // Show error toast if we timed out
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Session loading timed out. Please try again.'),
                                  behavior: SnackBarBehavior.floating,
                                  duration: Duration(seconds: 2),
                                ),
                              );
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
}