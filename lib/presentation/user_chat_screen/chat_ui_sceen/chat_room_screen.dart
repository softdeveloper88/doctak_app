import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:chewie/chewie.dart';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/notification_service.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/chat_model/conversation_message_model.dart';
import 'package:doctak_app/core/utils/profile_navigation.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/user_chat_screen/bloc/chat_bloc.dart';
import 'package:doctak_app/widgets/shimmer_widget/chat_shimmer_loader.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_bubble/bubble_type.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart' as chatItem;
import 'package:flutter_chat_bubble/clippers/chat_bubble_clipper_5.dart';
import 'package:record/record.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../../calling_module_v2/calling_module_v2.dart';
import 'package:doctak_app/widgets/communication/communication_gate.dart';
import 'package:doctak_app/data/apiClient/services/communication_service.dart';
import 'package:doctak_app/widgets/communication/communication_restriction_sheet.dart';
import 'component/optimized_message_list.dart';
import 'component/enhanced_chat_input_field.dart';
import 'component/animated_voice_recorder.dart';
import 'component/audio_cache_manager.dart';
import 'component/attachment_bottom_sheet.dart';
import 'component/attachment_preview_screen.dart';

class ChatRoomScreen extends StatefulWidget {
  final String username;
  final String profilePic;
  final String id;
  final int conversationId;
  final String roomId;

  const ChatRoomScreen({
    super.key,
    required this.username,
    required this.profilePic,
    required this.id,
    this.conversationId = 0,
    this.roomId = '',
  });

  @override
  _ChatRoomScreenState createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen>
    with TickerProviderStateMixin {
  // late UserMessagesModel userMessagesList;
  // late List<Message> messagesList = []; // Initialize it here with an empty list
  final ScrollController _scrollController = ScrollController();

  // late Message message;
  TextEditingController textController = TextEditingController();
  bool isLoading = false;
  Timer? typingTimer;
  ChatBloc chatBloc = ChatBloc();
  bool isSomeoneTyping = false;
  int _lastMessageCount = 0;
  bool isDataLoaded = true;
  bool isTextTyping = false;
  Timer? _typingTimer;
  final FocusNode focusNode = FocusNode();

  // WhatsApp-style inline edit
  ConversationMessage? _editingMessage;

  // Online presence
  bool _isOtherUserOnline = false;

  // Peer display info. Notification deep-links often pass a generic title
  // ("Chat") and an empty profilePic/id, so these start from the widget values
  // and are back-filled from the loaded conversation messages.
  String _peerName = '';
  String _peerAvatar = '';
  String _peerId = '';

  // List<SelectedByte> selectedFiles = [];
  bool isMessageLoaded = false; // Initialize it as per your logic
  bool _isFileUploading = false;
  Timer? _timer;
  Timer? _timerChat;
  Timer? _ampTimer;
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecorderInitialized = false;
  bool? isBottom = true;

  // Communication permission check
  CommunicationPermission? _communicationPermission;
  bool _isCommunicationAllowed = true;
  // Prevents multiple call taps while permission API is in-flight
  // null = idle, false = audio loading, true = video loading
  bool? _callingType;

  @override
  void dispose() {
    GestureBinding.instance.pointerRouter.removeGlobalRoute(
      _handleGlobalPointerEvent,
    );
    _timer?.cancel();
    _ampTimer?.cancel();
    _timerChat?.cancel();
    _typingTimer?.cancel();
    typingTimer?.cancel();
    _audioRecorder.dispose();
    _scrollController.removeListener(_checkScrollPosition);
    _scrollController.dispose();
    textController.dispose();
    focusNode.dispose();
    // Disconnect native WebSocket
    chatBloc.add(DisconnectWebSocketEvent());
    if (NotificationService.activeChatConversationId ==
        (chatBloc.currentConversationId ?? widget.conversationId)) {
      NotificationService.activeChatConversationId = null;
    }
    super.dispose();
  }

  Future<void> _initRecorder() async {
    if (!_isRecorderInitialized) {
      _isRecorderInitialized = true;
    }
  }

  @override
  void initState() {
    super.initState();
    // Capture finger release globally while recording.
    // This fixes cases where the mic button widget is replaced before it receives onLongPressEnd.
    GestureBinding.instance.pointerRouter.addGlobalRoute(
      _handleGlobalPointerEvent,
    );
    setStatusBarColor(svGetScaffoldColor());
    _scrollController.addListener(_checkScrollPosition);
    _initRecorder();

    _peerName = widget.username;
    _peerAvatar = widget.profilePic;
    _peerId = widget.id;

    if (widget.conversationId > 0) {
      NotificationService.activeChatConversationId = widget.conversationId;
      // New conversation-based flow
      chatBloc.currentConversationId = widget.conversationId;
      chatBloc.add(LoadConversationMessagesEvent(
        conversationId: widget.conversationId,
        isFirstLoading: true,
      ));
      chatBloc.add(MarkConversationReadEvent(conversationId: widget.conversationId));
      // Connect native WebSocket for real-time receipt events (read/delivered)
      chatBloc.add(ConnectWebSocketEvent(conversationId: widget.conversationId));
    } else {
      // Legacy fallback — create/find conversation first
      _initConversationFromUserId();
    }

    _startTimerForChat();

    // Clean old cache files on startup
    _cleanOldAudioCache();

    // Check communication permission (connection + block status)
    _checkCommunicationPermission();

    // fetchMessages();
    // _createClient();
  }

  /// For backward compat: resolve a conversationId from user ID
  Future<void> _initConversationFromUserId() async {
    final convId = await chatBloc.getOrCreateConversation(widget.id);
    if (convId != null && mounted) {
      NotificationService.activeChatConversationId = convId;
      chatBloc.currentConversationId = convId;
      chatBloc.add(LoadConversationMessagesEvent(
        conversationId: convId,
        isFirstLoading: true,
      ));
      chatBloc.add(MarkConversationReadEvent(conversationId: convId));
      chatBloc.add(ConnectWebSocketEvent(conversationId: convId));
    }
  }

  void _handleGlobalPointerEvent(PointerEvent event) {
    // Only act for the WhatsApp-style recorder flow.
    if (!isRecording) return;
    if (_shouldStopRecording) return;

    if (event is PointerUpEvent || event is PointerCancelEvent) {
      // User released finger: request recorder to stop+send.
      debugPrint('👆 Global pointer up/cancel detected - requesting stop+send');
      if (mounted) {
        setState(() {
          _shouldStopRecording = true;
        });
      }
    }
  }

  Future<void> _cleanOldAudioCache() async {
    try {
      final cacheManager = AudioCacheManager();
      await cacheManager.cleanOldCache();
    } catch (e) {
      debugPrint('Error cleaning audio cache: $e');
    }
  }

  /// Fill in missing peer info (name / avatar / user id) from the loaded
  /// conversation. Needed when the screen is opened from a push notification,
  /// which only carries the push title (often just "Chat") and no avatar.
  void _resolvePeerDetails() {
    final needName =
        _peerName.trim().isEmpty || _peerName.trim().toLowerCase() == 'chat';
    final needAvatar = _peerAvatar.trim().isEmpty;
    final needId = _peerId.trim().isEmpty;
    if (!needName && !needAvatar && !needId) return;

    final myId = AppData.logInUserId?.toString() ?? '';

    // 1. The chat list (if loaded) knows the conversation's peer.
    String? foundId, foundName, foundAvatar;
    final convId = chatBloc.currentConversationId ?? widget.conversationId;
    for (final conv in chatBloc.conversationsList) {
      if (conv.id != convId) continue;
      final peer = conv.peer;
      final peerId = peer?.id ?? '';
      if (peerId.isNotEmpty) foundId = peerId;
      final peerName = peer?.name ?? '';
      if (peerName.trim().isNotEmpty) foundName = peerName;
      final peerAvatar = peer?.avatarUrl ?? '';
      if (peerAvatar.trim().isNotEmpty) foundAvatar = peerAvatar;
      break;
    }

    // 2. Otherwise derive the peer from any incoming message's sender.
    for (final msg in chatBloc.conversationMessages) {
      if (foundId != null && foundName != null && foundAvatar != null) break;
      final senderId = msg.senderId?.toString() ?? '';
      if (senderId.isEmpty || senderId == myId) continue;
      foundId ??= senderId;
      final sender = msg.sender;
      if (sender == null) continue;
      if (foundName == null && sender.fullName.trim().isNotEmpty) {
        foundName = sender.fullName;
      }
      final avatar = sender.displayAvatar ?? '';
      if (foundAvatar == null && avatar.trim().isNotEmpty) {
        foundAvatar = avatar;
      }
    }

    var changed = false;
    if (needId && foundId != null) {
      _peerId = foundId;
      changed = true;
    }
    if (needName && foundName != null) {
      _peerName = foundName;
      changed = true;
    }
    if (needAvatar && foundAvatar != null) {
      _peerAvatar = foundAvatar;
      changed = true;
    }
    if (changed && mounted) {
      setState(() {});
      // The initial permission check is skipped when the peer id was unknown.
      if (_communicationPermission == null) {
        _checkCommunicationPermission();
      }
    }
  }

  /// Check whether the current user can communicate with the target user.
  Future<void> _checkCommunicationPermission() async {
    final peerId = _peerId.trim().isNotEmpty ? _peerId : widget.id;
    if (peerId.trim().isEmpty) return;
    try {
      final permission = await CommunicationService().checkPermission(peerId);
      if (mounted) {
        setState(() {
          _communicationPermission = permission;
          _isCommunicationAllowed = permission.canMessage;
        });
      }
    } catch (e) {
      debugPrint('Communication permission check failed: $e');
    }
  }

  /// Build a banner shown when communication is restricted.
  Widget _buildRestrictionBanner(OneUITheme theme) {
    final permission = _communicationPermission;
    if (permission == null) return const SizedBox.shrink();

    final isBlocked = permission.reasonCode == 'blocked';
    final icon = isBlocked ? Icons.block_rounded : Icons.lock_outline_rounded;
    final color = isBlocked ? Colors.red : Colors.orange;
    final text = permission.reason ?? 'Communication is restricted.';

    return GestureDetector(
      onTap: () {
        CommunicationRestrictionSheet.show(
          context: context,
          permission: permission,
          targetUserName: _peerName,
          targetUserId: _resolvePeerId(),
          onActionDone: () {
            // Re-check after user action
            _checkCommunicationPermission();
          },
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          border: Border(top: BorderSide(color: color.withValues(alpha: 0.2))),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: theme.bodySecondary.copyWith(height: 1.4),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: theme.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  void _checkScrollPosition() {
    if (_scrollController.position.pixels == 0) {
      setState(() {
        isBottom = true;
        print('top');
      });
    } else if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      setState(() {
        isBottom = false;
        print('bottom');
      });
    } else {
      setState(() {
        print('middle');

        isBottom = false;
      });
    }
  }

  void onTextFieldFocused(bool typingStatus) async {
    final convId = chatBloc.currentConversationId;
    if (convId == null || convId == 0) return;
    if (typingStatus) {
      chatBloc.sendTypingIndicator(convId);
    }
  }

  final bool _emojiShowing = false;

  void seenSenderMessage(int seenStatus) async {
    final convId = chatBloc.currentConversationId;
    if (convId != null && convId > 0) {
      chatBloc.add(MarkConversationReadEvent(conversationId: convId));
    }
  }

  /// A call action button that shows a spinner and is disabled while the
  /// CommunicationGate permission API is in-flight, preventing multiple taps.
  /// Peer id for calls. `widget.id` is normally the other user's id, but some
  /// entry points (legacy notification deep-links, conversations without a
  /// resolved peer) pass it empty, which surfaced as "Could not identify this
  /// user". Fall back to the loaded conversation's other participant.
  String _resolvePeerId() {
    if (_peerId.trim().isNotEmpty) return _peerId;
    if (widget.id.trim().isNotEmpty) return widget.id;
    final convId = chatBloc.currentConversationId ?? widget.conversationId;

    // 1. The chat LIST (if loaded) has the conversation with its peer.
    for (final conv in chatBloc.conversationsList) {
      if (conv.id != convId) continue;
      final peerId = conv.peer?.id ?? '';
      if (peerId.isNotEmpty) return peerId;
      final other = conv.getOtherParticipant(AppData.logInUserId);
      final partId = other?.userId?.toString() ?? '';
      if (partId.isNotEmpty) return partId;
      break;
    }

    // 2. In the chat ROOM the list is usually empty, so derive the peer from
    //    the loaded messages: the sender of any incoming message. `isMine`
    //    (senderId == logInUserId) is the SAME check the UI uses to place
    //    bubbles left/right, so an incoming message's senderId is the peer's
    //    user id in the exact form calls expect.
    for (final msg in chatBloc.conversationMessages) {
      if (msg.isMine) continue;
      final senderId = msg.senderId?.toString() ?? '';
      if (senderId.isNotEmpty) return senderId;
    }
    return '';
  }

  Widget _callActionButton({
    required IconData icon,
    required String tooltip,
    required bool isVideo,
    required OneUITheme theme,
  }) {
    final bool isThisLoading = _callingType == isVideo;
    final bool isOtherLoading = _callingType != null && _callingType != isVideo;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _callingType != null
              ? null
              : () async {
                  if (_callingType != null) return;
                  setState(() => _callingType = isVideo);
                  try {
                    final peerId = _resolvePeerId();
                    if (peerId.isEmpty) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not identify this user')),
                        );
                      }
                      return;
                    }
                    await CommunicationGate.guardCall(
                      context: context,
                      targetUserId: peerId,
                      targetUserName: _peerName,
                      onAllowed: () {
                        startOutgoingCallV2(
                          peerId,
                          _peerName,
                          _peerAvatar,
                          isVideo,
                        );
                      },
                    );
                  } finally {
                    if (mounted) setState(() => _callingType = null);
                  }
                },
          child: SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: isThisLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
                      ),
                    )
                  : Opacity(
                      opacity: isOtherLoading ? 0.3 : 1.0,
                      child: Icon(icon, color: theme.iconColor, size: 22),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // Complete implementation of the startOutgoingCall function
  //   Future<void> startOutgoingCall(String userId, String username, String profilePic, bool isVideoCall) async {
  //     // Show calling screen immediately
  //     NavigatorService.navigatorKey.currentState?.push(
  //       MaterialPageRoute(
  //         builder: (context) => CallLoadingScreen(
  //           contactName: username,
  //           contactAvatar: "${AppData.imageUrl}$profilePic",
  //           isVideoCall: isVideoCall,
  //           onCancel: () {
  //             // Pop the loading screen
  //             Navigator.of(context).pop();
  //             // Cancel any pending call setup
  //             CallKitService().endAllCalls();
  //           },
  //         ),
  //       ),
  //     );
  //
  //     try {
  //       // Initialize call in the background with proper error handling
  //       Map<String, dynamic> callData;
  //
  //       try {
  //         final response = await CallKitService().startOutgoingCall(
  //             userId: userId,
  //             calleeName: username,
  //             avatar: "${AppData.imageUrl}$profilePic",
  //             hasVideo: isVideoCall
  //         );
  //
  //         // Ensure we have proper Map<String, dynamic>
  //         if (response is Map<String, dynamic>) {
  //           callData = response;
  //         } else {
  //           // Convert to Map<String, dynamic> if needed
  //           callData = {};
  //           if (response is Map) {
  //             response.forEach((key, value) {
  //               if (key is String) {
  //                 callData[key] = value;
  //               }
  //             });
  //           } else {
  //             throw Exception('Invalid response format from CallKitService');
  //           }
  //         }
  //       } catch (e) {
  //         print('Error calling CallKitService.startOutgoingCall: $e');
  //         throw e;
  //       }
  //
  //       // Handle success - replace loading screen with call screen
  //       if (callData['success'] == true &&
  //           callData['callId'] != null &&
  //           NavigatorService.navigatorKey.currentState != null) {
  //
  //         final callId = callData['callId'].toString();
  //
  //         // Verify call was created successfully by checking with the API
  //         bool isCallActive = true;
  //         try {
  //           isCallActive = await CallKitService().checkCallIsActive(callId);
  //         } catch (e) {
  //           print('Error verifying call is active: $e');
  //           // Continue anyway since we just created it
  //         }
  //
  //         if (!isCallActive) {
  //           // This is unusual - the call we just created isn't active
  //           print('Call API reports call not active immediately after creation');
  //           NavigatorService.navigatorKey.currentState?.pop(); // Remove loading screen
  //           _showCallError("Could not establish call. Please try again.");
  //           return;
  //         }
  //
  //         NavigatorService.navigatorKey.currentState!.pushReplacement(
  //           MaterialPageRoute(
  //             settings: const RouteSettings(name: '/call'),
  //             builder: (context) => CallScreen(
  //               callId: callId,
  //               contactId: userId,
  //               contactName: username,
  //               contactAvatar: "${AppData.imageUrl}$profilePic",
  //               isIncoming: false,
  //               isVideoCall: isVideoCall,
  //               token: callData['token']?.toString() ?? '',
  //             ),
  //           ),
  //         );
  //       } else {
  //         // Handle API error
  //         NavigatorService.navigatorKey.currentState?.pop(); // Remove loading screen
  //         _showCallError("Failed to establish call. Please try again.");
  //       }
  //     } catch (error) {
  //       print('Error starting outgoing call: $error');
  //
  //       NavigatorService.navigatorKey.currentState?.pop(); // Remove loading screen
  //       _showCallError("Error starting call. Please try again.");
  //
  //       // Make sure any partial call state is cleaned up
  //       try {
  //         await CallKitService().endAllCalls();
  //       } catch (e) {
  //         print('Error cleaning up after failed call: $e');
  //       }
  //     }
  //   }

  // Simple loading screen for calls
  void scrollToBottom() {
    // Future.delayed(const Duration(milliseconds: 100), () {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0, // Scroll to the start of the list
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    }
    // });
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: _buildAppBar(context, theme),
      body: BlocConsumer<ChatBloc, ChatState>(
        bloc: chatBloc,
        listener: (BuildContext context, ChatState state) {
          if (state is DataError) {
            showDialog(
              context: context,
              builder: (context) =>
                  AlertDialog(content: Text(state.errorMessage)),
            );
          } else if (state is PaginationLoadedState) {
            setState(() {
              _isFileUploading = false;
            });
            _resolvePeerDetails();
            final count = chatBloc.conversationMessages.length;
            if (count > _lastMessageCount && (isBottom ?? true)) {
              WidgetsBinding.instance.addPostFrameCallback((_) => scrollToBottom());
            }
            _lastMessageCount = count;
          } else if (state is FileUploadingState) {
            setState(() {
              _isFileUploading = true;
            });
            // Optional: Show a brief toast for file uploads
            // showToast('Uploading file...');
          } else if (state is FileUploadedState) {
            setState(() {
              _isFileUploading = false;
            });
          } else if (state is PresenceUpdatedState) {
            if (state.userId != AppData.logInUserId?.toString()) {
              setState(() {
                _isOtherUserOnline = state.isOnline;
              });
            }
          } else if (state is TypingState) {
            if (state.isTyping) {
              _onTypingStarted();
            } else {
              _onTypingStopped();
            }
          }
        },
        builder: (context, state) {
          if (state is DataError) {
            return Center(child: Text(state.errorMessage));
          }

          final showMessageArea = state is PaginationLoadedState ||
              state is FileUploadingState ||
              state is FileUploadedState ||
              state is TypingState ||
              state is PresenceUpdatedState ||
              state is PaginationLoadingState ||
              state is DataInitial ||
              state is PaginationInitialState;

          if (!showMessageArea) {
            return const Center(child: Text('Something went wrong'));
          }

          final showShimmer = chatBloc.isLoadingInitialMessages ||
              state is PaginationLoadingState ||
              state is DataInitial ||
              state is PaginationInitialState;

          isDataLoaded = false;
          final bloc = chatBloc;
          return Column(
            children: [
              Expanded(
                child: showShimmer
                    ? const ChatShimmerLoader()
                    : OptimizedMessageList(
                        chatBloc: bloc,
                        userId: AppData.logInUserId?.toString() ?? '',
                        conversationId:
                            chatBloc.currentConversationId ?? widget.conversationId,
                        profilePic: _peerAvatar,
                        scrollController: _scrollController,
                        isSomeoneTyping: isSomeoneTyping,
                        onEditRequested: (msg) {
                          setState(() {
                            _editingMessage = msg;
                            textController.text = msg.body ?? msg.displayText;
                            textController.selection = TextSelection.fromPosition(
                              TextPosition(offset: textController.text.length),
                            );
                          });
                        },
                      ),
              ),
                // Show restriction banner when communication is not allowed
                if (!_isCommunicationAllowed && _communicationPermission != null)
                  _buildRestrictionBanner(theme)
                else if (isRecording)
                  AnimatedVoiceRecorder(
                        shouldStopAndSend: _shouldStopRecording,
                        initialPointerPosition: _recordingPointerPosition,
                        onStop: (path) {
                          debugPrint('Recording stopped with path: $path');
                          final convId = chatBloc.currentConversationId;
                          if (convId != null && convId > 0) {
                            chatBloc.add(SendConversationMessageEvent(
                              conversationId: convId,
                              filePath: path,
                              attachmentType: 'voice',
                              receiverId: _resolvePeerId(),
                            ));
                          }
                          setState(() {
                            isRecording = false;
                            _shouldStopRecording = false;
                            _recordingPointerPosition = null;
                          });
                          scrollToBottom();
                        },
                        onCancel: () {
                          print('❌ Recording cancelled');
                          setState(() {
                            isRecording = false;
                            _shouldStopRecording = false;
                            _recordingPointerPosition = null;
                          });
                        },
                      )
                else
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── WhatsApp-style edit banner ──────────────────────
                      if (_editingMessage != null)
                        _buildEditBanner(theme),
                      EnhancedChatInputField(
                        controller: textController,
                        onSubmitted: (message) {
                          setState(() {
                            isTextTyping = false;
                          });
                          final convId = chatBloc.currentConversationId;
                          if (convId != null && convId > 0) {
                            if (_editingMessage != null) {
                              // Edit mode: dispatch EditMessageEvent
                              final newBody = message.trim();
                              if (newBody.isNotEmpty && _editingMessage!.id != null) {
                                chatBloc.add(EditMessageEvent(
                                  messageId: _editingMessage!.id!,
                                  body: newBody,
                                ));
                              }
                              setState(() => _editingMessage = null);
                            } else {
                              chatBloc.add(SendConversationMessageEvent(
                                conversationId: convId,
                                message: message,
                                receiverId: _resolvePeerId(),
                              ));
                            }
                          }
                          textController.clear();
                          scrollToBottom();
                        },
                        onAttachmentPressed: () async {
                          const permission = Permission.storage;
                          const permission1 = Permission.photos;
                          var status = await permission.status;
                          print(status);
                          if (await permission1.isGranted) {
                            _showFileOptions();
                          } else if (await permission1.isDenied) {
                            final result = await permission1.request();
                            if (status.isGranted) {
                              _showFileOptions();
                              print("isGranted");
                            } else if (result.isGranted) {
                              _showFileOptions();
                              print("isGranted");
                            } else if (result.isDenied) {
                              await permission.request();
                              print("isDenied");
                            } else if (result.isPermanentlyDenied) {
                              print("isPermanentlyDenied");
                            }
                          } else if (await permission.isPermanentlyDenied) {
                            print("isPermanentlyDenied");
                          }
                        },
                        onRecordStateChanged: (recording, {Offset? pointerPosition}) {
                          setState(() {
                            if (recording) {
                              isRecording = true;
                              _shouldStopRecording = false;
                              _recordingPointerPosition = pointerPosition;
                            } else {
                              _shouldStopRecording = true;
                            }
                          });
                        },
                        onVoiceRecorded: (path) {
                          // This is handled by AnimatedVoiceRecorder
                        },
                        isRecording: isRecording,
                        isLoading: _isFileUploading || isLoading,
                        onTyping: (text) {
                          final hasText = text.isNotEmpty;
                          isTextTyping = hasText;
                          if (hasText) {
                            onTextFieldFocused(true);
                          } else {
                            chatBloc.add(SendTypingEvent(isTyping: false));
                          }

                          _typingTimer?.cancel();
                          if (hasText) {
                            _typingTimer = Timer(const Duration(seconds: 4), () {
                              if (mounted) {
                                setState(() {
                                  isTextTyping = false;
                                });
                              }
                            });
                          } else {
                            isTextTyping = false;
                          }
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                Offstage(
                  offstage: !_emojiShowing,
                  child: EmojiPicker(
                    textEditingController: textController,
                    // scrollController: _scrollController,
                    config: Config(
                      height: 256,
                      checkPlatformCompatibility: true,
                      viewOrderConfig: const ViewOrderConfig(),
                      emojiViewConfig: EmojiViewConfig(
                        // Issue: https://github.com/flutter/flutter/issues/28894
                        emojiSizeMax:
                            28 *
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
                ),
              ],
            );
        },
      ),
    );
  }

  bool isPlayingMsg = false, isRecording = false, isSending = false;
  bool _shouldStopRecording = false; // Flag to trigger stop and send
  Offset?
  _recordingPointerPosition; // Track where user pressed to start recording

  Future<bool> checkPermission() async {
    var status = await Permission.microphone.status;
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) return false;
    status = await Permission.microphone.request();
    return status.isGranted;
  }

  // final record = AudioRecorder();
  void startRecord() async {
    try {
      // Check microphone permission
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        debugPrint("Microphone permission not granted");
        return;
      }

      if (!_isRecorderInitialized) {
        await _initRecorder();
      }

      recordFilePath = await getFilePath();

      // Start recording
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: recordFilePath ?? '',
      );
    } catch (e) {
      debugPrint("Error starting recording: $e");
    }
  }

  void stopRecord() async {
    try {
      await _audioRecorder.stop();
      final convId = chatBloc.currentConversationId;
      if (convId != null && convId > 0 && recordFilePath != null) {
        chatBloc.add(SendConversationMessageEvent(
          conversationId: convId,
          filePath: recordFilePath,
          attachmentType: 'voice',
          receiverId: _resolvePeerId(),
        ));
      }
      scrollToBottom();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  String? recordFilePath;

  // Future<void> play() async {
  //   if (recordFilePath != null && File(recordFilePath).existsSync()) {
  //     AudioPlayer audioPlayer = AudioPlayer();
  //     await audioPlayer.play(
  //       recordFilePath,
  //       isLocal: false,
  //     );
  //   }
  // }
  int i = 0;

  Future<String> getFilePath() async {
    Directory storageDirectory = await getApplicationDocumentsDirectory();
    String sdPath = "${storageDirectory.path}/record";
    var d = Directory(sdPath);
    if (!d.existsSync()) {
      d.createSync(recursive: true);
    }
    return "$sdPath/test_${i++}.mp3";
  }

  void _showFileOptions() {
    final BuildContext currentContext = context; // Store context reference
    NavigatorState? bottomSheetNavigator;

    showModalBottomSheet(
      context: currentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bottomSheetContext) {
        // Store the navigator reference
        bottomSheetNavigator = Navigator.of(bottomSheetContext);

        return AttachmentBottomSheet(
          onFileSelected: (File file, String type) {
            // Safely close bottom sheet
            try {
              if (bottomSheetNavigator != null &&
                  bottomSheetNavigator!.mounted) {
                bottomSheetNavigator!.pop();
              } else if (bottomSheetContext.mounted) {
                Navigator.of(bottomSheetContext).pop();
              }
            } catch (e) {
              print('Error closing bottom sheet: $e');
            }

            // Schedule the navigation to happen after the bottom sheet is completely closed
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted && currentContext.mounted) {
                  Navigator.push(
                    currentContext,
                    MaterialPageRoute(
                      builder: (context) => AttachmentPreviewScreen(
                        file: file,
                        type: type,
                        onSend: (File sendFile, String caption) {
                          // Only pop if we can (close preview screen only)
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop(); // Close preview screen
                          }
                          print("sendFile $sendFile");
                          if (mounted) {
                            final convId = chatBloc.currentConversationId;
                            if (convId != null && convId > 0) {
                              chatBloc.add(SendConversationMessageEvent(
                                conversationId: convId,
                                filePath: sendFile.path,
                                message: caption.isNotEmpty ? caption : null,
                                attachmentType: 'file',
                                receiverId: _resolvePeerId(),
                              ));
                            }

                            scrollToBottom();
                          }
                        },
                      ),
                    ),
                  );
                }
              });
            });
          },
        );
      },
    );
  }

  void onSubscriptionCount(String channelName, int subscriptionCount) {}


  // Handle typing events
  void handleTypingEvent(Map<String, dynamic> eventData) {
    // Handle typing event here
  }

  // Handle message events
  void handleMessageEvent(Map<String, dynamic> eventData) {
    // Handle message event here
  }

  void _onTypingStarted() {
    if (!mounted) return;
    setState(() {
      isSomeoneTyping = true;
    });
    typingTimer?.cancel();
    typingTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) _onTypingStopped();
    });
  }

  void _onTypingStopped() {
    if (!mounted) return;
    setState(() {
      isSomeoneTyping = false;
    });
  }

  void _startTimerForChat() {
    // Light fallback sync when WebSocket polling is active (every 60s).
    _timerChat = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (!isDataLoaded) {
        if (isBottom ?? true) {
          final convId = chatBloc.currentConversationId;
          if (convId != null && convId > 0) {
            chatBloc.add(LoadConversationMessagesEvent(
              conversationId: convId,
              isFirstLoading: false,
            ));
          }
        }
      }
    });
  }

  /// WhatsApp-style banner shown above the input field while editing a message.
  Widget _buildEditBanner(OneUITheme theme) {
    final isDark = theme.isDark;
    final preview = _editingMessage?.body ?? _editingMessage?.displayText ?? '';
    return Container(
      color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Green accent bar (WhatsApp style)
          Container(
            width: 3,
            height: 38,
            decoration: BoxDecoration(
              color: theme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Editing message',
                  style: theme.bodySecondary.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.primary,
                  ),
                ),
                Text(
                  preview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodyMedium.copyWith(
                    fontSize: 13,
                    color: theme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Cancel button
          IconButton(
            icon: Icon(Icons.close, size: 20, color: theme.textSecondary),
            onPressed: () {
              setState(() {
                _editingMessage = null;
                textController.clear();
              });
            },
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, OneUITheme theme) {
    return AppBar(
      backgroundColor: theme.appBarBackground,
      iconTheme: IconThemeData(color: theme.iconColor),
      elevation: 0,
      toolbarHeight: 70,
      surfaceTintColor: theme.appBarBackground,
      centerTitle: false,
      leading: IconButton(
        icon: Icon(CupertinoIcons.back, color: theme.iconColor, size: 22),
        onPressed: () => Navigator.pop(context),
      ),
      title: InkWell(
        onTap: () {
          final peerId = _resolvePeerId();
          if (peerId.isNotEmpty) {
            ProfileNavigation.openUser(context, peerId);
          }
        },
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.primary.withValues(alpha: 0.1),
                border: Border.all(
                  color: theme.primary.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: _peerAvatar.trim().isEmpty
                    ? Center(
                        child: Icon(
                          Icons.person_rounded,
                          color: theme.primary,
                          size: 22,
                        ),
                      )
                    : CustomImageView(
                        imagePath:
                            AppData.fullImageUrl(_peerAvatar.validate()),
                        height: 40,
                        width: 40,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _peerName.trim().isEmpty ? 'Chat' : _peerName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                      color: theme.textPrimary,
                    ),
                  ),
                  if (isSomeoneTyping)
                    Text(
                      translation(context).lbl_typing,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else if (_isOtherUserOnline)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.only(right: 4),
                          decoration: const BoxDecoration(
                            color: Color(0xFF4CAF50),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Text(
                          'Online',
                          style: TextStyle(
                            fontSize: 12,
                            color: const Color(0xFF4CAF50),
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Voice Call Button
        _callActionButton(
          icon: Icons.phone_outlined,
          tooltip: 'Voice Call',
          isVideo: false,
          theme: theme,
        ),
        // Video Call Button
        _callActionButton(
          icon: Icons.videocam_outlined,
          tooltip: 'Video Call',
          isVideo: true,
          theme: theme,
        ),
        // More Options Menu
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: theme.iconColor, size: 22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: theme.cardBackground,
          elevation: 8,
          offset: const Offset(0, 50),
          onSelected: (value) {
            // Handle menu selection
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'media',
              child: Row(
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 20,
                    color: theme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    translation(context).lbl_media,
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 20, color: theme.error),
                  const SizedBox(width: 12),
                  Text(
                    translation(context).lbl_delete_chat,
                    style: TextStyle(color: theme.error, fontFamily: 'Poppins'),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // List<RtmAttribute> convertToRtmAttributes(Map<String, dynamic> attributes) {
  //   List<RtmAttribute> rtmAttributes = [];
  //
  //   attributes.forEach((key, value) {
  //     if (value is String) {
  //       rtmAttributes.add(RtmAttribute(key, value));
  //     }
  //   });
  //
  //   return rtmAttributes;
  // }
}

class TypingIndicator extends StatelessWidget {
  final String profilePic;

  const TypingIndicator({super.key, required this.profilePic});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: chatItem.ChatBubble(
        alignment: Alignment.centerLeft,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        clipper: ChatBubbleClipper5(type: BubbleType.receiverBubble),
        backGroundColor: theme.surfaceVariant,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                translation(context).lbl_typing,
                style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 14.0,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Include your _DisplayVideo class here...

class FullScreenVideoPage extends StatefulWidget {
  final VideoPlayerController videoPlayerController;

  const FullScreenVideoPage({super.key, required this.videoPlayerController});

  @override
  _FullScreenVideoPageState createState() => _FullScreenVideoPageState();
}

class _FullScreenVideoPageState extends State<FullScreenVideoPage> {
  late ChewieController _chewieController;

  @override
  void initState() {
    super.initState();
    // Get safe aspect ratio (default to 16:9 if invalid)
    final ratio = widget.videoPlayerController.value.aspectRatio;
    final safeRatio =
        (ratio <= 0 ||
            ratio.isNaN ||
            ratio.isInfinite ||
            ratio < 0.1 ||
            ratio > 10)
        ? 16 / 9
        : ratio;
    _chewieController = ChewieController(
      videoPlayerController: widget.videoPlayerController,
      aspectRatio: safeRatio,
      autoPlay: true,
      looping: true,
      // Configure additional settings as needed
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackground,
        leading: IconButton(
          icon: Icon(Icons.close, color: theme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(child: Chewie(controller: _chewieController)),
    );
  }

  @override
  void dispose() {
    _chewieController.dispose();

    super.dispose();
  }
}

class VoiceRecordingPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  VoiceRecordingPainter({required this.animation, required this.color})
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final radius = size.width / 2;
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    canvas.drawCircle(Offset(centerX, centerY), radius, paint);

    final double angle = animation.value * 2.0 * math.pi;

    final double lineLength = size.width / 3;
    final double startX = centerX + math.cos(angle) * (radius - lineLength / 2);
    final double startY = centerY + math.sin(angle) * (radius - lineLength / 2);
    final double endX = centerX + math.cos(angle) * (radius + lineLength / 2);
    final double endY = centerY + math.sin(angle) * (radius + lineLength / 2);

    canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
