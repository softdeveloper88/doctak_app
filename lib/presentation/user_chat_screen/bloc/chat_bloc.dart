import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/apiClient/api_service_manager.dart';
import 'package:doctak_app/data/apiClient/services/conversation_api_service.dart';
import 'package:doctak_app/data/models/chat_model/conversation_model.dart';
import 'package:doctak_app/data/models/chat_model/conversation_message_model.dart';
import 'package:doctak_app/data/models/chat_model/contacts_model.dart';
import 'package:doctak_app/data/models/chat_model/message_model.dart';
import 'package:doctak_app/data/models/chat_model/search_contacts_model.dart';
import 'package:doctak_app/data/services/chat_websocket_service.dart';
import 'package:doctak_app/widgets/toast_widget.dart';
import 'package:doctak_app/data/apiClient/services/moderation_api_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:image_picker/image_picker.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ConversationApiService _chatApi = ConversationApiService();
  final ChatWebSocketService _wsService = ChatWebSocketService();
  final ApiServiceManager apiManager = ApiServiceManager();
  StreamSubscription<ChatWsEvent>? _wsSub;
  Timer? _typingStopTimer;
  Timer? _typingPulseTimer;
  List<XFile> imagefiles = [];

  // Conversation list
  List<Conversation> conversationsList = [];

  // Search contacts (kept for backward compatibility with search screen)
  int contactPageNumber = 1;
  int contactNumberOfPage = 1;
  List<Data> searchContactsList = [];
  final int contactNextPageTrigger = 1;

  // Conversation messages
  List<ConversationMessage> conversationMessages = [];
  bool hasMoreMessages = true;
  bool isLoadingMore = false;
  /// True while the first page of messages for the open conversation is loading.
  bool isLoadingInitialMessages = false;

  // Current conversation
  int? currentConversationId;

  /// conversationId -> expiry timestamp (ms) for chat-list typing preview.
  final Map<int, int> typingExpiryByConversationId = {};

  /// Negative ids for optimistic (pending) outbound messages.
  int _pendingMessageId = 0;

  // Legacy compatibility fields
  int pageNumber = 1;
  int numberOfPage = 1;
  List<Contacts> contactsList = [];
  List<Groups> groupList = [];
  final int nextPageTrigger = 1;
  int messagePageNumber = 1;
  int messageNumberOfPage = 1;
  List<Messages> messagesList = [];
  final int messageNextPageTrigger = 1;
  String? roomId;

  ChatBloc() : super(DataInitial()) {
    on<LoadPageEvent>(_onLoadConversations);
    on<LoadContactsEvent>(_onGetSearchContacts);
    on<LoadConversationMessagesEvent>(_onLoadConversationMessages);
    on<SendConversationMessageEvent>(_onSendConversationMessage);
    on<DeleteConversationMessageEvent>(_onDeleteConversationMessage);
    on<MarkConversationReadEvent>(_onMarkConversationRead);
    on<LoadMoreMessagesEvent>(_onLoadMoreMessages);
    on<NewMessageReceivedEvent>(_onNewMessageReceived);
    // WebSocket events
    on<ConnectWebSocketEvent>(_onConnectWebSocket);
    on<DisconnectWebSocketEvent>(_onDisconnectWebSocket);
    on<SendTypingEvent>(_onSendTyping);
    on<EditMessageEvent>(_onEditMessage);
    on<ToggleReactionEvent>(_onToggleReaction);
    on<WsMessageCreatedEvent>(_onWsMessageCreated);
    on<WsMessageUpdatedEvent>(_onWsMessageUpdated);
    on<WsMessageDeletedEvent>(_onWsMessageDeleted);
    on<WsReactionsUpdatedEvent>(_onWsReactionsUpdated);
    on<WsTypingEvent>(_onWsTyping);
    on<WsPresenceEvent>(_onWsPresence);
    on<WsDeliveredEvent>(_onWsDelivered);
    on<WsReadEvent>(_onWsRead);
    on<ChatListMessageEvent>(_onChatListMessage);
    on<ChatListTypingEvent>(_onChatListTyping);
    on<ChatListTypingRefreshEvent>(_onChatListTypingRefresh);
    // Legacy events (kept for backward compat with search screen)
    on<LoadRoomMessageEvent>(_onGetMessages);
    on<SendMessageEvent>(_onSendMessages);
    on<DeleteMessageEvent>(_onDeleteMessages);
    on<ChatReadStatusEvent>(_updateChatReadStatus);
    on<SelectedFiles>(_selectedFile);
    on<CheckIfNeedMoreDataEvent>((event, emit) async {});
    on<CheckIfNeedMoreContactDataEvent>((event, emit) async {
      if (event.index == searchContactsList.length - contactNextPageTrigger) {
        add(LoadContactsEvent(page: contactPageNumber));
      }
    });
    on<CheckIfNeedMoreMessageDataEvent>((event, emit) async {});
  }

  // ======================== NEW CONVERSATION API ========================

  Future<void> _onLoadConversations(LoadPageEvent event, Emitter<ChatState> emit) async {
    if (event.page == 1) {
      conversationsList.clear();
      emit(PaginationLoadingState());
    }
    try {
      final response = await _chatApi.getConversations();
      conversationsList = response.conversations ?? [];
      emit(PaginationLoadedState());
    } catch (e) {
      debugPrint('Error loading conversations: $e');
      emit(PaginationLoadedState());
    }
  }

  Future<void> _onLoadConversationMessages(
    LoadConversationMessagesEvent event,
    Emitter<ChatState> emit,
  ) async {
    currentConversationId = event.conversationId;
    if (event.isFirstLoading) {
      conversationMessages.clear();
      hasMoreMessages = true;
      isLoadingInitialMessages = true;
      emit(PaginationLoadingState());
    }
    try {
      final response = await _chatApi.getMessages(
        conversationId: event.conversationId,
        limit: 50,
      );
      // Reverse so newest message is at index 0 (for reverse:true ListView)
      final fetched = (response.messages ?? []).reversed.toList();
      if (event.isFirstLoading || conversationMessages.isEmpty) {
        conversationMessages = fetched;
      } else {
        // Refresh (60s fallback timer): merge instead of replacing the list.
        // A blind replace drops messages that were sent/received via WebSocket
        // while this fetch was in flight, making them flicker (appear → hide).
        final fetchedIds =
            fetched.map((m) => m.id).whereType<int>().toSet();
        final newestFetchedId =
            fetched.isNotEmpty ? (fetched.first.id ?? 0) : 0;
        final localNewer = conversationMessages
            .where((m) =>
                m.id != null &&
                m.id! > newestFetchedId &&
                !fetchedIds.contains(m.id))
            .toList();
        conversationMessages = [...localNewer, ...fetched];
      }
      hasMoreMessages = response.hasMore ?? false;

      // Auto-mark as read using the latest message id
      if (conversationMessages.isNotEmpty && conversationMessages.first.id != null) {
        await _chatApi.markConversationAsRead(
          conversationId: event.conversationId,
          messageId: conversationMessages.first.id!,
        );
      }
    } catch (e) {
      debugPrint('Error loading messages: $e');
    } finally {
      if (event.isFirstLoading) {
        isLoadingInitialMessages = false;
      }
      emit(PaginationLoadedState());
    }
  }

  Future<void> _onLoadMoreMessages(
    LoadMoreMessagesEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (!hasMoreMessages || conversationMessages.isEmpty || isLoadingMore) return;
    isLoadingMore = true;
    emit(PaginationLoadedState()); // refresh UI to show spinner
    try {
      final oldestId = conversationMessages.last.id;
      final response = await _chatApi.getMessages(
        conversationId: event.conversationId,
        cursor: oldestId,
        limit: 50,
      );
      // Reverse so oldest is at the end (consistent with newest-first ordering)
      final newMessages = (response.messages ?? []).reversed.toList();
      hasMoreMessages = response.hasMore ?? false;

      // Append older messages
      conversationMessages.addAll(newMessages);
    } catch (e) {
      debugPrint('Error loading more messages: $e');
    } finally {
      isLoadingMore = false;
      emit(PaginationLoadedState());
    }
  }

  Future<void> _onSendConversationMessage(
    SendConversationMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    int? pendingId;
    try {
      // Check moderation before showing the optimistic bubble.
      if (event.receiverId != null && event.receiverId!.isNotEmpty) {
        final canComm = await ModerationApiService().canCommunicate(
          targetUserId: event.receiverId!,
        );
        if (canComm.success && canComm.data == false) {
          emit(DataError('Cannot send message. This user is blocked.'));
          return;
        }
      }

      pendingId = _insertPendingMessage(event);
      emit(PaginationLoadedState());

      ConversationMessage sentMessage;

      if (event.attachmentType == 'voice' && event.filePath != null && event.filePath!.isNotEmpty) {
        sentMessage = await _chatApi.sendVoiceMessage(
          conversationId: event.conversationId,
          audioPath: event.filePath!,
        );
      } else if (event.filePath != null && event.filePath!.isNotEmpty) {
        final file = File(event.filePath!);
        if (await file.exists()) {
          sentMessage = await _chatApi.sendFileMessage(
            conversationId: event.conversationId,
            filePath: event.filePath!,
            caption: event.message,
          );
        } else {
          sentMessage = await _chatApi.sendTextMessage(
            conversationId: event.conversationId,
            body: event.message ?? 'File not found',
          );
        }
      } else {
        sentMessage = await _chatApi.sendTextMessage(
          conversationId: event.conversationId,
          body: event.message ?? '',
        );
      }

      _finalizePendingMessage(pendingId, sentMessage);
      emit(PaginationLoadedState());
    } catch (e) {
      debugPrint('Error sending message: $e');
      if (pendingId != null) {
        _removePendingMessage(pendingId);
        emit(PaginationLoadedState());
      }
      showToast('Failed to send message');
    }
  }

  int _insertPendingMessage(SendConversationMessageEvent event) {
    final pendingId = --_pendingMessageId;
    final now = DateTime.now().toUtc().toIso8601String();
    final isVoice = event.attachmentType == 'voice' &&
        event.filePath != null &&
        event.filePath!.isNotEmpty;
    final hasFile = event.filePath != null && event.filePath!.isNotEmpty;

    conversationMessages.insert(
      0,
      ConversationMessage(
        id: pendingId,
        conversationId: event.conversationId,
        senderId: AppData.logInUserId,
        type: isVoice ? 'voice' : (hasFile ? 'file' : 'text'),
        body: event.message ?? '',
        content: event.message ?? '',
        receiptState: 'pending',
        createdAt: now,
        fileUrl: hasFile && !isVoice ? event.filePath : null,
      ),
    );
    return pendingId;
  }

  void _finalizePendingMessage(int pendingId, ConversationMessage serverMsg) {
    _removePendingMessage(pendingId);
    final normalized = serverMsg.receiptState == null ||
            serverMsg.receiptState == 'pending'
        ? serverMsg.copyWith(receiptState: 'sent')
        : serverMsg;
    _upsertConversationMessage(normalized);
  }

  void _removePendingMessage(int pendingId) {
    conversationMessages.removeWhere((m) => m.id == pendingId);
  }

  void _removeAllPendingMessages() {
    conversationMessages.removeWhere((m) => (m.id ?? 0) < 0);
  }

  /// Insert [msg] at the top, or replace the existing entry with the same id.
  /// This is the single guard against duplicate bubbles when the same message
  /// arrives from multiple sources (REST send response + WS echo + poll).
  void _upsertConversationMessage(ConversationMessage msg) {
    if (msg.id != null) {
      final idx = conversationMessages.indexWhere((m) => m.id == msg.id);
      if (idx != -1) {
        conversationMessages[idx] = msg;
        return;
      }
    }
    conversationMessages.insert(0, msg);
  }

  Future<void> _onDeleteConversationMessage(
    DeleteConversationMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _chatApi.deleteMessage(messageId: event.messageId);
      conversationMessages.removeWhere((m) => m.id == event.messageId);
      showToast('Message deleted');
      emit(PaginationLoadedState());
    } catch (e) {
      debugPrint('Error deleting message: $e');
      showToast('Failed to delete message');
      emit(PaginationLoadedState());
    }
  }

  Future<void> _onMarkConversationRead(
    MarkConversationReadEvent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      // Find the latest message ID in the current list
      int? latestId;
      if (conversationMessages.isNotEmpty) {
        latestId = conversationMessages.first.id;
      }
      if (latestId != null) {
        await _chatApi.markConversationAsRead(
          conversationId: event.conversationId,
          messageId: latestId,
        );
      }
      // Update local unread count
      final idx = conversationsList.indexWhere((c) => c.id == event.conversationId);
      if (idx != -1) {
        conversationsList[idx] = conversationsList[idx].copyWith(unreadCount: 0);
      }
      if (!isLoadingInitialMessages) {
        emit(PaginationLoadedState());
      }
    } catch (e) {
      debugPrint('Error marking read: $e');
    }
  }

  /// Handle real-time message from Pusher
  Future<void> _onNewMessageReceived(
    NewMessageReceivedEvent event,
    Emitter<ChatState> emit,
  ) async {
    // Add to messages list if we're in the same conversation
    if (currentConversationId == event.message.conversationId) {
      _upsertConversationMessage(event.message);
    }
    emit(PaginationLoadedState());
  }

  /// Create or find a conversation with a user and return the conversation ID
  Future<int?> getOrCreateConversation(String userId) async {
    try {
      final response = await _chatApi.createConversation(peerUserId: userId);
      return response.conversationId;
    } catch (e) {
      debugPrint('Error creating conversation: $e');
      return null;
    }
  }

  /// Whether a peer is currently typing in [conversationId] (chat list preview).
  bool isConversationTyping(int? conversationId) {
    if (conversationId == null) return false;
    final expiry = typingExpiryByConversationId[conversationId];
    if (expiry == null) return false;
    if (DateTime.now().millisecondsSinceEpoch > expiry) {
      typingExpiryByConversationId.remove(conversationId);
      return false;
    }
    return true;
  }

  void _updateListTyping(int conversationId, String userId, bool isTyping) {
    final myId = AppData.logInUserId?.toString() ?? '';
    if (userId == myId) return;
    if (isTyping) {
      final expiry =
          DateTime.now().add(const Duration(seconds: 4)).millisecondsSinceEpoch;
      typingExpiryByConversationId[conversationId] = expiry;
      _scheduleTypingListRefresh(conversationId, expiry);
    } else {
      typingExpiryByConversationId.remove(conversationId);
    }
  }

  void _scheduleTypingListRefresh(int conversationId, int expiryMs) {
    Future.delayed(const Duration(seconds: 4), () {
      if (isClosed) return;
      if (typingExpiryByConversationId[conversationId] != expiryMs) return;
      if (DateTime.now().millisecondsSinceEpoch < expiryMs) return;
      typingExpiryByConversationId.remove(conversationId);
      add(ChatListTypingRefreshEvent());
    });
  }

  /// Send typing indicator via WebSocket (auto-stops after 3.5s, pulses every 2s).
  Future<void> sendTypingIndicator(int conversationId) async {
    _wsService.sendTyping(isTyping: true);
    _chatApi
        .postTyping(conversationId: conversationId, isTyping: true)
        .catchError((_) {});
    _typingStopTimer?.cancel();
    _typingPulseTimer?.cancel();
    _typingPulseTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _wsService.sendTyping(isTyping: true);
      _chatApi
          .postTyping(conversationId: conversationId, isTyping: true)
          .catchError((_) {});
    });
    _typingStopTimer = Timer(const Duration(milliseconds: 3500), () {
      _typingPulseTimer?.cancel();
      _typingPulseTimer = null;
      _wsService.sendTyping(isTyping: false);
      _chatApi
          .postTyping(conversationId: conversationId, isTyping: false)
          .catchError((_) {});
    });
  }

  // ======================== WEBSOCKET HANDLERS ========================

  Future<void> _onConnectWebSocket(
    ConnectWebSocketEvent event,
    Emitter<ChatState> emit,
  ) async {
    await _wsSub?.cancel();
    _wsSub = _wsService.events.listen((wsEvent) {
      switch (wsEvent) {
        case WsMessageCreated e:
          add(WsMessageCreatedEvent(message: e.message));
        case WsMessageUpdated e:
          add(WsMessageUpdatedEvent(message: e.message));
        case WsMessageDeleted e:
          add(WsMessageDeletedEvent(
              messageId: e.messageId, conversationId: e.conversationId));
        case WsReactionsUpdated e:
          add(WsReactionsUpdatedEvent(
              messageId: e.messageId, reactions: e.reactions));
        case WsTyping e:
          add(WsTypingEvent(
              userId: e.userId,
              isTyping: e.isTyping,
              conversationId: e.conversationId));
        case WsPresence e:
          add(WsPresenceEvent(userId: e.userId, isOnline: e.isOnline));
        case WsDelivered e:
          add(WsDeliveredEvent(messageId: e.messageId, userId: e.userId));
        case WsRead e:
          add(WsReadEvent(messageId: e.messageId, userId: e.userId));
        case WsPong():
          break;
      }
    });
    await _wsService.connect(event.conversationId);
  }

  Future<void> _onDisconnectWebSocket(
    DisconnectWebSocketEvent event,
    Emitter<ChatState> emit,
  ) async {
    await _wsSub?.cancel();
    _wsSub = null;
    await _wsService.disconnect();
  }

  Future<void> _onSendTyping(
    SendTypingEvent event,
    Emitter<ChatState> emit,
  ) async {
    _wsService.sendTyping(isTyping: event.isTyping);
    final convId = currentConversationId;
    if (convId != null && convId > 0) {
      _chatApi
          .postTyping(conversationId: convId, isTyping: event.isTyping)
          .catchError((_) {});
    }
  }

  Future<void> _onEditMessage(
    EditMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final updated = await _chatApi.editMessage(
          messageId: event.messageId, body: event.body);
      final idx = conversationMessages.indexWhere((m) => m.id == event.messageId);
      if (idx != -1) conversationMessages[idx] = updated;
      emit(PaginationLoadedState());
    } catch (e) {
      debugPrint('Error editing message: $e');
    }
  }

  Future<void> _onToggleReaction(
    ToggleReactionEvent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final reactions = await _chatApi.toggleReaction(
          messageId: event.messageId, emoji: event.emoji);
      final idx = conversationMessages.indexWhere((m) => m.id == event.messageId);
      if (idx != -1) {
        conversationMessages[idx] =
            conversationMessages[idx].copyWith(reactions: reactions);
      }
      emit(PaginationLoadedState());
    } catch (e) {
      debugPrint('Error toggling reaction: $e');
    }
  }

  Future<void> _onWsMessageCreated(
    WsMessageCreatedEvent event,
    Emitter<ChatState> emit,
  ) async {
    final myId = AppData.logInUserId?.toString() ?? '';
    final isIncoming = event.message.senderId != myId;

    final msgConvId = event.message.conversationId;
    final belongsHere = msgConvId == currentConversationId ||
        (msgConvId == null && currentConversationId != null);

    if (belongsHere) {
      if (!isIncoming) {
        _removeAllPendingMessages();
      }

      final idx = conversationMessages.indexWhere((m) => m.id == event.message.id);
      if (idx != -1) {
        conversationMessages[idx] = _mergeIncomingMessage(conversationMessages[idx], event.message);
      } else {
        _upsertConversationMessage(event.message);
      }
      // User is viewing this conversation — mark as read (covers delivered too)
      final effectiveConvId = msgConvId ?? currentConversationId;
      if (isIncoming && event.message.id != null && effectiveConvId != null) {
        _chatApi.markConversationAsRead(
          conversationId: effectiveConvId,
          messageId: event.message.id!,
        ).catchError((_) {});
      }
    } else if (isIncoming && event.message.id != null) {
      // Background conversation — only mark delivered
      _chatApi.markMessageDelivered(messageId: event.message.id!).catchError((_) {});
    }
    emit(PaginationLoadedState());
  }

  Future<void> _onWsMessageUpdated(
    WsMessageUpdatedEvent event,
    Emitter<ChatState> emit,
  ) async {
    final idx = conversationMessages.indexWhere((m) => m.id == event.message.id);
    if (idx != -1) conversationMessages[idx] = event.message;
    emit(PaginationLoadedState());
  }

  Future<void> _onWsMessageDeleted(
    WsMessageDeletedEvent event,
    Emitter<ChatState> emit,
  ) async {
    final idx = conversationMessages.indexWhere((m) => m.id == event.messageId);
    if (idx != -1) {
      conversationMessages[idx] =
          conversationMessages[idx].copyWith(isDeleted: true);
    }
    emit(PaginationLoadedState());
  }

  Future<void> _onWsReactionsUpdated(
    WsReactionsUpdatedEvent event,
    Emitter<ChatState> emit,
  ) async {
    final idx = conversationMessages.indexWhere((m) => m.id == event.messageId);
    if (idx != -1) {
      conversationMessages[idx] =
          conversationMessages[idx].copyWith(reactions: event.reactions);
    }
    emit(PaginationLoadedState());
  }

  Future<void> _onWsDelivered(
    WsDeliveredEvent event,
    Emitter<ChatState> emit,
  ) async {
    final myId = AppData.logInUserId?.toString() ?? '';
    if (event.userId == myId) return;
    final idx = conversationMessages.indexWhere((m) => m.id == event.messageId);
    if (idx != -1) {
      final msg = conversationMessages[idx];
      // Only upgrade from sent → delivered (never downgrade from seen)
      if (msg.receiptState == null || msg.receiptState == 'sent') {
        conversationMessages[idx] = msg.copyWith(receiptState: 'delivered');
        emit(PaginationLoadedState());
      }
    }
  }

  Future<void> _onWsRead(
    WsReadEvent event,
    Emitter<ChatState> emit,
  ) async {
    final myId = AppData.logInUserId?.toString() ?? '';
    if (event.userId == myId) return;
    // Mark all my messages up to event.messageId as seen
    bool changed = false;
    for (int i = 0; i < conversationMessages.length; i++) {
      final msg = conversationMessages[i];
      if (msg.senderId == myId && msg.id != null && msg.id! <= event.messageId) {
        if (msg.receiptState != 'seen') {
          conversationMessages[i] = msg.copyWith(receiptState: 'seen');
          changed = true;
        }
      }
    }
    if (changed) emit(PaginationLoadedState());
  }

  Future<void> _onWsTyping(
    WsTypingEvent event,
    Emitter<ChatState> emit,
  ) async {
    final convId = event.conversationId;
    final myId = AppData.logInUserId?.toString() ?? '';
    if (event.userId.toString() == myId) return;

    if (convId != 0) {
      _updateListTyping(convId, event.userId.toString(), event.isTyping);
      emit(PaginationLoadedState());
    }

    if (convId != 0 &&
        currentConversationId != null &&
        currentConversationId != convId) {
      return;
    }

    if (isLoadingInitialMessages) return;

    emit(TypingState(userId: event.userId.toString(), isTyping: event.isTyping));
    if (conversationMessages.isNotEmpty) {
      emit(PaginationLoadedState());
    }
  }

  Future<void> _onWsPresence(
    WsPresenceEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (isLoadingInitialMessages) return;
    emit(PresenceUpdatedState(userId: event.userId, isOnline: event.isOnline));
  }

  Future<void> _onChatListMessage(
    ChatListMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    final myId = AppData.logInUserId?.toString() ?? '';
    final senderId = (event.message['senderId'] ?? event.message['sender_id'] ?? '')
        .toString();
    final isIncoming = senderId.isNotEmpty && senderId != myId;
    final body = (event.message['body'] ?? event.message['content'] ?? '') as String?;
    final msgId = event.message['id'];
    final createdAt = (event.message['createdAt'] ?? event.message['created_at'])?.toString();

    final idx = conversationsList.indexWhere((c) => c.id == event.conversationId);
    if (idx == -1) {
      add(LoadPageEvent(page: 1));
      return;
    }

    final conv = conversationsList.removeAt(idx);
    final unread = isIncoming && currentConversationId != event.conversationId
        ? (conv.unreadCount ?? 0) + 1
        : conv.unreadCount;

    conversationsList.insert(
      0,
      conv.copyWith(
        unreadCount: unread,
        updatedAt: createdAt ?? conv.updatedAt,
        lastMessage: ConversationLastMessage(
          id: msgId is int ? msgId : int.tryParse('$msgId'),
          conversationId: event.conversationId,
          senderId: senderId,
          body: body,
          createdAt: createdAt,
        ),
      ),
    );
    emit(PaginationLoadedState());
  }

  Future<void> _onChatListTyping(
    ChatListTypingEvent event,
    Emitter<ChatState> emit,
  ) async {
    _updateListTyping(event.conversationId, event.userId, event.isTyping);
    emit(PaginationLoadedState());
  }

  Future<void> _onChatListTypingRefresh(
    ChatListTypingRefreshEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(PaginationLoadedState());
  }

  @override
  Future<void> close() async {
    _typingStopTimer?.cancel();
    _typingPulseTimer?.cancel();
    await _wsSub?.cancel();
    await _wsService.disconnect();
    return super.close();
  }

  // ======================== LEGACY METHODS (backward compat) ========================


  Future<void> _onGetSearchContacts(LoadContactsEvent event, Emitter<ChatState> emit) async {
    if (event.page == 1) {
      searchContactsList.clear();
      contactPageNumber = 1;
      emit(PaginationLoadingState());
    }
    try {
      SearchContactsModel response = await apiManager.searchContacts('Bearer ${AppData.userToken}', '$contactPageNumber', event.keyword ?? '');
      contactNumberOfPage = response.lastPage ?? 0;
      if (contactPageNumber < contactNumberOfPage + 1) {
        contactPageNumber = contactPageNumber + 1;
        searchContactsList.addAll(response.records?.data ?? []);
      }
      emit(PaginationLoadedState());
    } catch (e) {
      debugPrint('Search contacts error: $e');
      emit(DataError('Failed to search contacts: $e'));
    }
  }

  Future<void> _updateChatReadStatus(ChatReadStatusEvent event, Emitter<ChatState> emit) async {
    try {
      // Find the conversation for this user using createConversation (find-or-create)
      if (event.userId != null && event.userId!.isNotEmpty) {
        final resp = await _chatApi.createConversation(peerUserId: event.userId!);
        if (resp.conversationId != null) {
          final idx = conversationsList.indexWhere((c) => c.id == resp.conversationId);
          if (idx != -1) {
            conversationsList[idx] = conversationsList[idx].copyWith(unreadCount: 0);
          }
        }
      }
      emit(PaginationLoadedState());
    } catch (e) {
      debugPrint('Error updating read status: $e');
      emit(PaginationLoadedState());
    }
  }

  Future<void> _onGetMessages(LoadRoomMessageEvent event, Emitter<ChatState> emit) async {
    // Legacy - no-op, use LoadConversationMessagesEvent instead
    emit(PaginationLoadedState());
  }

  Future<void> _onSendMessages(SendMessageEvent event, Emitter<ChatState> emit) async {
    // Legacy wrapper: find/create conversation, then send via new API
    try {
      if (event.receiverId == null || event.receiverId!.isEmpty) return;

      // Check moderation
      final canComm = await ModerationApiService().canCommunicate(
        targetUserId: event.receiverId!,
      );
      if (canComm.success && canComm.data == false) {
        emit(DataError('Cannot send message. This user is blocked.'));
        return;
      }

      // Get or create conversation
      final convId = await getOrCreateConversation(event.receiverId!);
      if (convId == null) {
        emit(DataError('Failed to create conversation'));
        return;
      }

      ConversationMessage sentMessage;

      if (event.file != null && event.file!.isNotEmpty) {
        final file = File(event.file!);
        if (await file.exists()) {
          emit(FileUploadingState());
          if (event.attachmentType == 'voice') {
            sentMessage = await _chatApi.sendVoiceMessage(
              conversationId: convId,
              audioPath: event.file!,
            );
          } else {
            sentMessage = await _chatApi.sendFileMessage(
              conversationId: convId,
              filePath: event.file!,
              caption: event.message,
            );
          }
          emit(FileUploadedState());
        } else {
          sentMessage = await _chatApi.sendTextMessage(
            conversationId: convId,
            body: event.message ?? 'File not found',
          );
        }
      } else {
        emit(FileUploadingState());
        sentMessage = await _chatApi.sendTextMessage(
          conversationId: convId,
          body: event.message ?? '',
        );
        emit(FileUploadedState());
      }

      // Update currentConversationId if not set
      currentConversationId ??= convId;

      // Upsert (dedup) — same guard as the primary send path.
      _upsertConversationMessage(sentMessage);
      emit(PaginationLoadedState());
    } catch (e) {
      debugPrint('Error sending message: $e');
      emit(FileUploadedState());
      emit(PaginationLoadedState());
    }
  }

  Future<void> _onDeleteMessages(DeleteMessageEvent event, Emitter<ChatState> emit) async {
    try {
      final messageId = int.tryParse(event.id ?? '');
      if (messageId == null) {
        showToast('Invalid message id');
        emit(PaginationLoadedState());
        return;
      }
      await _chatApi.deleteMessage(messageId: messageId);
      conversationMessages.removeWhere((m) => m.id == messageId);
      showToast('Message deleted');
      emit(PaginationLoadedState());
    } catch (e) {
      debugPrint('Delete message failed: $e');
      showToast('Failed to delete message');
      emit(PaginationLoadedState());
    }
  }

  Future<void> _selectedFile(SelectedFiles event, Emitter<ChatState> emit) async {
    if (event.isRemove) {
      imagefiles.remove(event.pickedfiles);
    } else {
      imagefiles.add(event.pickedfiles);
    }
    emit(PaginationLoadedState());
  }

  ConversationMessage _mergeIncomingMessage(
    ConversationMessage existing,
    ConversationMessage incoming,
  ) {
    final existingUrl = existing.resolvedFileUrl ?? '';
    final incomingUrl = incoming.resolvedFileUrl ?? '';

    if (incomingUrl.isNotEmpty && existingUrl.isEmpty) return incoming;
    if (incomingUrl.isNotEmpty && existingUrl.isNotEmpty) {
      // Prefer the richer attachment payload (WS may arrive before URL is set).
      final incomingHasAttachments = incoming.attachments?.isNotEmpty == true;
      final existingHasAttachments = existing.attachments?.isNotEmpty == true;
      if (incomingHasAttachments || !existingHasAttachments) return incoming;
      return incoming.copyWith(
        fileUrl: existing.fileUrl ?? incoming.fileUrl,
        fileType: incoming.fileType ?? existing.fileType,
        fileName: incoming.fileName ?? existing.fileName,
        fileSize: incoming.fileSize ?? existing.fileSize,
        thumbnailUrl: incoming.thumbnailUrl ?? existing.thumbnailUrl,
        attachments: incoming.attachments ?? existing.attachments,
        files: incoming.files ?? existing.files,
      );
    }
    if (existingUrl.isNotEmpty) {
      return incoming.copyWith(
        fileUrl: existing.fileUrl,
        fileType: existing.fileType ?? incoming.fileType,
        fileName: existing.fileName ?? incoming.fileName,
        fileSize: existing.fileSize ?? incoming.fileSize,
        thumbnailUrl: existing.thumbnailUrl ?? incoming.thumbnailUrl,
        attachments: existing.attachments ?? incoming.attachments,
        files: existing.files ?? incoming.files,
      );
    }
    return incoming;
  }
}
