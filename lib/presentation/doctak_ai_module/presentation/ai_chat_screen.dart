 import 'dart:io';
import 'dart:async';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/unified_gallery_picker.dart';
import 'package:doctak_app/data/models/chat_gpt_model/chat_gpt_sesssion/chat_gpt_session.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/ai_quota_banner.dart';
import 'package:doctak_app/widgets/ai_data_consent_dialog.dart';
import 'package:doctak_app/widgets/app_cached_network_image.dart';
import 'package:doctak_app/presentation/subscription_screen/subscription_screen.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:doctak_app/core/utils/tts_service.dart';
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

class _AiChatScreenState extends State<AiChatScreen> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputController = TextEditingController();
  File? _selectedImage;
  bool _showWelcomeScreen = true;
  String _selectedModel = 'gpt-4o';
  bool _webSearchEnabled = false;
  String _searchContextSize = 'medium';
  double _temperature = 0.7;
  int _maxTokens = 1024;
  bool _isWaitingForResponse = false; // Track if we're waiting for a response
  AiUsageInfo? _quotaInfo; // Current quota state for AI chat
  int _lastStreamingLength = -1;
  int _lastRenderedMessageCount = -1;
  int _lastLiveAutoScrollAtMs = 0;

  // Typing animation state
  String _greetingText = '';
  String _subtitleText = '';
  bool _greetingDone = false;
  bool _subtitleDone = false;
  Timer? _typingTimer;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  // Voice input state
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;
  String _lastPartialWords = ''; // Track partial results for smooth updates
  bool _userStoppedListening = false; // Distinguish user stop vs auto-stop

  @override
  void initState() {
    super.initState();

    // Animation controllers
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    // Initialize speech
    _initSpeech();

    // Start typing animation after a short delay
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _startTypingAnimation();
    });

    // Show AI data-sharing consent on first use, then load sessions.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final agreed = await showAiConsentIfNeeded(context);
      if (!mounted) return;
      if (!agreed) {
        Navigator.of(context).maybePop();
        return;
      }

      // Consent granted — load sessions
      context.read<AiChatBloc>().add(LoadSessions());

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
    _inputController.dispose();
    _typingTimer?.cancel();
    _fadeController.dispose();
    _pulseController.dispose();
    if (_isListening) _speech.stop();
    TtsService.instance.stop();
    super.dispose();
  }

  void _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onError: (error) {
          debugPrint('Speech error: ${error.errorMsg} permanent: ${error.permanent}');
          if (mounted) {
            // Auto-restart on non-permanent errors (e.g. "error_speech_timeout")
            if (!error.permanent && _isListening && !_userStoppedListening) {
              _restartListening();
            } else {
              setState(() => _isListening = false);
            }
          }
        },
        onStatus: (status) {
          debugPrint('Speech status: $status');
          if (status == 'done' && mounted && _isListening && !_userStoppedListening) {
            // Auto-restart when speech engine stops but user hasn't tapped stop
            _restartListening();
          } else if (status == 'notListening' && mounted && _userStoppedListening) {
            setState(() => _isListening = false);
          }
        },
      );
    } catch (e) {
      debugPrint('Speech init error: $e');
      _speechAvailable = false;
    }
  }

  void _toggleListening() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    HapticFeedback.mediumImpact();

    if (_isListening) {
      _userStoppedListening = true;
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      _userStoppedListening = false;
      _lastPartialWords = '';
      _startListening();
    }
  }

  void _startListening() async {
    try {
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (result) {
          if (!mounted) return;
          final words = result.recognizedWords;
          // Update text field immediately with partial results for snappy feel
          if (words.isNotEmpty && words != _lastPartialWords) {
            _lastPartialWords = words;
            setState(() {
              _inputController.text = words;
              _inputController.selection = TextSelection.fromPosition(
                TextPosition(offset: words.length),
              );
            });
          }
          // Don't auto-stop on finalResult — let continuous mode handle it
        },
        listenFor: const Duration(minutes: 5),
        pauseFor: const Duration(seconds: 5),
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
          cancelOnError: false,
          autoPunctuation: true,
        ),
      );
    } catch (e) {
      debugPrint('Speech listen error: $e');
      if (mounted) setState(() => _isListening = false);
    }
  }

  void _restartListening() {
    // Brief delay before restarting to let the engine fully stop
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted && _isListening && !_userStoppedListening) {
        _startListening();
      }
    });
  }

  void _startTypingAnimation() {
    final doctorName = AppData.name.isNotEmpty ? AppData.name.split(' ').first : 'Doctor';
    final greeting = 'Hello, Dr. $doctorName';
    const subtitle = "I'm Doctak AI. How can I help you today?";

    int charIndex = 0;

    _typingTimer = Timer.periodic(const Duration(milliseconds: 45), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (!_greetingDone) {
        if (charIndex < greeting.length) {
          setState(() {
            _greetingText = greeting.substring(0, charIndex + 1);
          });
          charIndex++;
        } else {
          setState(() => _greetingDone = true);
          charIndex = 0;
        }
      } else if (!_subtitleDone) {
        if (charIndex < subtitle.length) {
          setState(() {
            _subtitleText = subtitle.substring(0, charIndex + 1);
          });
          charIndex++;
        } else {
          setState(() {
            _subtitleDone = true;
          });
          timer.cancel();
        }
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  List<AiChatMessageModel> _messagesForState(AiChatState state) {
    if (state is SessionSelected) return state.messages;
    if (state is MessageSending) return state.messages;
    if (state is MessageStreaming) return state.messages;
    if (state is MessageSent) return state.messages;
    if (state is MessageSendError) return state.messages;
    if (state is SessionUpdating) return state.messages;
    if (state is FeedbackError) return state.messages;
    if (state is SessionLoadError) return state.messages ?? [];
    return const [];
  }

  void _autoScrollForLiveResponse({
    required List<AiChatMessageModel> messages,
    required bool isLoading,
    required bool isStreaming,
    required String streamingContent,
  }) {
    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    final bool messageCountIncreased = messages.length > _lastRenderedMessageCount;
    final bool loadingStarted = isLoading && _lastRenderedMessageCount >= 0;
    final bool streamingGrew = isStreaming && streamingContent.length > _lastStreamingLength;
    final bool throttlePassed = (nowMs - _lastLiveAutoScrollAtMs) > 140;

    if (messageCountIncreased || (loadingStarted && throttlePassed) || (streamingGrew && throttlePassed)) {
      _lastLiveAutoScrollAtMs = nowMs;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      });
    }

    _lastRenderedMessageCount = messages.length;
    _lastStreamingLength = isStreaming ? streamingContent.length : -1;
  }

  Future<void> _pickImage() async {
    final File? image = await UnifiedGalleryPicker.pickSingleImage(
      context,
      title: translation(context).lbl_choose_from_gallery,
    );

    if (image != null) {
      setState(() {
        _selectedImage = image;
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
      if (_inputController.text == message) {
        _inputController.clear();
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

    return Container(
      color: theme.scaffoldBackground,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 40),

                // Animated AI Icon with pulse
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.primary.withValues(alpha: 0.8),
                          const Color(0xFF00C9A7),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.primary.withValues(alpha: 0.3),
                          spreadRadius: 4,
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.auto_awesome, color: Colors.white, size: 42),
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // Typing greeting: "Hello, Dr. Name"
                AnimatedSize(
                  duration: const Duration(milliseconds: 100),
                  child: Text(
                    _greetingText,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      color: theme.textPrimary,
                      letterSpacing: -0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 12),

                // Typing subtitle: "I'm Doctak AI..."
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Poppins',
                            height: 1.5,
                            color: theme.textSecondary,
                          ),
                          children: [
                            if (_subtitleText.startsWith("I'm ")) ...[
                              const TextSpan(text: "I'm "),
                              TextSpan(
                                text: _subtitleText.length > 4
                                    ? _subtitleText.substring(4, _subtitleText.indexOf('.') > 4 ? _subtitleText.indexOf('.') : _subtitleText.length)
                                    : '',
                                style: TextStyle(
                                  color: theme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (_subtitleText.contains('.'))
                                TextSpan(
                                  text: _subtitleText.substring(_subtitleText.indexOf('.')),
                                ),
                            ] else
                              TextSpan(text: _subtitleText),
                          ],
                        ),
                      ),
                    ),
                    // Blinking cursor
                    if (!_subtitleDone)
                      _TypingCursor(color: theme.primary),
                  ],
                ),

                const SizedBox(height: 48),

                const SizedBox(height: 40),
              ],
            ),
          ),
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
            if (state is MessageSent) _quotaInfo = state.quotaInfo;
            if (state is MessageSendError && state.isQuotaError) _quotaInfo = state.quotaInfo;
          });

          // Scroll after response arrives — use a second delayed scroll
          // to handle late layout changes (e.g. long markdown rendering)
          if (state is MessageSent) {
            _scrollToBottom();
            Future.delayed(const Duration(milliseconds: 350), () {
              if (mounted) _scrollToBottom();
            });
          }
        }
        else if (state is MessageStreaming) {
          setState(() {
            _showWelcomeScreen = false;
            _isWaitingForResponse = true;
          });
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
          // _onCreateSession in the BLoC already calls _onSelectSession
          // internally. Do NOT add a duplicate SelectSession here — that
          // would cause an extra SessionLoading→SessionSelected cycle that
          // resets _isWaitingForResponse and hides the typing indicator.
          debugPrint("SessionCreated received (handled by BLoC): ${state.newSession.id}");
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

            // Keep waiting-for-response state visible — SendMessage was just
            // dispatched and will be processed after the current event.
            setState(() {
              _isWaitingForResponse = true;
              _showWelcomeScreen = false;
            });
            return; // Return early to avoid the setState below
          }

          // If a message send is in progress (between dispatching SendMessage
          // and MessageSending/MessageSent arriving), don't reset the flag.
          // This prevents a duplicate SessionSelected emission from the BLoC's
          // network-refresh from hiding the typing indicator mid-send.
          if (_isWaitingForResponse) {
            if (hasMessages) _scrollToBottom();
            return;
          }

          setState(() {
            // Only show welcome screen if session is empty
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
        final List<AiChatMessageModel> messages = _messagesForState(state);

        // Use improved virtualized message list with streaming support
        final isStreaming = state is MessageStreaming;
        final streamingContent = isStreaming ? state.partialResponse : '';
        final bool isLoading = state is MessageSending && state is! MessageStreaming;

        _autoScrollForLiveResponse(
          messages: messages,
          isLoading: isLoading,
          isStreaming: isStreaming,
          streamingContent: streamingContent,
        );

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
                              final pendingMessage = _inputController.text;

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
          isLoading: isLoading,
          isStreaming: isStreaming,
          streamingContent: streamingContent,
          webSearch: _webSearchEnabled,
          scrollController: _scrollController,
          onSuggestionTap: (prompt) => _sendMessage(prompt),
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
              icon: Icon(Icons.history, color: theme.primary, size: 22),
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
            icon: Icon(Icons.add_circle, color: theme.primary, size: 22),
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
                  icon: Icon(Icons.settings_outlined, color: theme.primary, size: 22),
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

            // Quota banner — shown above input when quota is limited or exhausted
            AiQuotaBanner(usage: _quotaInfo),

            // Input area
            MessageInput(
              controller: _inputController,
              onSendMessage: (_isWaitingForResponse || _quotaInfo?.canUse == false) ? null : _sendMessage,
              onAttachImage: (_isWaitingForResponse || _quotaInfo?.canUse == false) ? null : _pickImage,
              selectedModel: _selectedModel,
              isWaitingForResponse: _isWaitingForResponse,
              onVoiceTap: _toggleListening,
              isListening: _isListening,
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
                  child: ClipOval(
                    child: AppData.profile_pic.isNotEmpty && AppData.profile_pic.toLowerCase() != 'null'
                        ? AppCachedNetworkImage(
                            imageUrl: AppData.profilePicUrl,
                            fit: BoxFit.cover,
                            width: 48,
                            height: 48,
                          )
                        : Center(
                            child: Text(
                              AppData.name.isNotEmpty ? AppData.name[0].toUpperCase() : 'U',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.primary),
                            ),
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

          // Quota / plan info bar (shown for free users)
          if (_quotaInfo != null && !(_quotaInfo!.isPaid))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.amber.shade50, Colors.amber.shade100]),
                border: Border(bottom: BorderSide(color: Colors.amber.shade300)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.amber.shade200, borderRadius: BorderRadius.circular(9999)),
                        child: Text(translation(context).lbl_free_plan, style: TextStyle(fontSize: 11, fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: Colors.orange.shade900)),
                      ),
                      Text(
                        '${_quotaInfo!.dailyRemaining}/${_quotaInfo!.dailyLimit} left (5h)',
                        style: TextStyle(fontSize: 12, fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: Colors.orange.shade800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context); // close drawer
                      const SubscriptionScreen().launch(context);
                    },
                    child: Text(
                      translation(context).lbl_upgrade_unlimited,
                      style: TextStyle(fontSize: 11, fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: Colors.blue.shade700),
                    ),
                  ),
                ],
              ),
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
}

/// Blinking cursor for the typing animation
class _TypingCursor extends StatefulWidget {
  final Color color;
  const _TypingCursor({required this.color});

  @override
  State<_TypingCursor> createState() => _TypingCursorState();
}

class _TypingCursorState extends State<_TypingCursor> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 530))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 2,
        height: 20,
        margin: const EdgeInsets.only(left: 2),
        color: widget.color,
      ),
    );
  }
}
