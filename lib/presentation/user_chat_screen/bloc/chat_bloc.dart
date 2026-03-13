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
  final ApiServiceManager apiManager = ApiServiceManager();
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

  // Current conversation
  int? currentConversationId;

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
      emit(PaginationLoadingState());
    }
    try {
      final response = await _chatApi.getMessages(
        conversationId: event.conversationId,
        limit: 50,
      );
      // Reverse so newest message is at index 0 (for reverse:true ListView)
      conversationMessages = (response.messages ?? []).reversed.toList();
      hasMoreMessages = response.hasMore ?? false;

      // Auto-mark as read
      await _chatApi.markConversationAsRead(conversationId: event.conversationId);

      emit(PaginationLoadedState());
    } catch (e) {
      debugPrint('Error loading messages: $e');
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
        beforeId: oldestId,
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
    try {
      // Check moderation
      if (event.receiverId != null && event.receiverId!.isNotEmpty) {
        final canComm = await ModerationApiService().canCommunicate(
          targetUserId: event.receiverId!,
        );
        if (canComm.success && canComm.data == false) {
          emit(DataError('Cannot send message. This user is blocked.'));
          return;
        }
      }

      ConversationMessage sentMessage;

      if (event.attachmentType == 'voice' && event.filePath != null && event.filePath!.isNotEmpty) {
        // Voice message
        emit(FileUploadingState());
        sentMessage = await _chatApi.sendVoiceMessage(
          conversationId: event.conversationId,
          audioPath: event.filePath!,
        );
        emit(FileUploadedState());
      } else if (event.filePath != null && event.filePath!.isNotEmpty) {
        // File attachment
        final file = File(event.filePath!);
        if (await file.exists()) {
          emit(FileUploadingState());
          sentMessage = await _chatApi.sendFileMessage(
            conversationId: event.conversationId,
            filePath: event.filePath!,
            message: event.message,
            type: event.attachmentType,
          );
          emit(FileUploadedState());
        } else {
          // File doesn't exist, send as text
          sentMessage = await _chatApi.sendTextMessage(
            conversationId: event.conversationId,
            message: event.message ?? 'File not found',
          );
        }
      } else {
        // Text message
        emit(FileUploadingState());
        sentMessage = await _chatApi.sendTextMessage(
          conversationId: event.conversationId,
          message: event.message ?? '',
        );
        emit(FileUploadedState());
      }

      // Insert at the beginning (newest first)
      conversationMessages.insert(0, sentMessage);
      emit(PaginationLoadedState());
    } catch (e) {
      debugPrint('Error sending message: $e');
      emit(FileUploadedState());
      emit(PaginationLoadedState());
    }
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
      await _chatApi.markConversationAsRead(conversationId: event.conversationId);
      // Update local unread count
      final idx = conversationsList.indexWhere((c) => c.id == event.conversationId);
      if (idx != -1) {
        conversationsList[idx] = conversationsList[idx].copyWith(unreadCount: 0);
      }
      emit(PaginationLoadedState());
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
      // Avoid duplicates
      if (!conversationMessages.any((m) => m.id == event.message.id)) {
        conversationMessages.insert(0, event.message);
      }
    }
    emit(PaginationLoadedState());
  }

  /// Create or find a conversation with a user and return the conversation ID
  Future<int?> getOrCreateConversation(String userId) async {
    try {
      final response = await _chatApi.createConversation(userId: userId);
      return response.conversationId;
    } catch (e) {
      debugPrint('Error creating conversation: $e');
      return null;
    }
  }

  /// Send typing indicator for a conversation
  Future<void> sendTypingIndicator(int conversationId) async {
    try {
      await _chatApi.sendTypingIndicator(conversationId: conversationId);
    } catch (e) {
      debugPrint('Error sending typing: $e');
    }
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
      // Try to find conversation and mark read via new API
      if (event.userId != null && event.userId!.isNotEmpty) {
        final findResp = await _chatApi.findConversation(userId: event.userId!);
        if (findResp.exists == true && findResp.conversationId != null) {
          await _chatApi.markConversationAsRead(conversationId: findResp.conversationId!);
          final idx = conversationsList.indexWhere((c) => c.id == findResp.conversationId);
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
              message: event.message,
              type: event.attachmentType,
            );
          }
          emit(FileUploadedState());
        } else {
          sentMessage = await _chatApi.sendTextMessage(
            conversationId: convId,
            message: event.message ?? 'File not found',
          );
        }
      } else {
        emit(FileUploadingState());
        sentMessage = await _chatApi.sendTextMessage(
          conversationId: convId,
          message: event.message ?? '',
        );
        emit(FileUploadedState());
      }

      // Update currentConversationId if not set
      currentConversationId ??= convId;

      // Insert into conversation messages
      conversationMessages.insert(0, sentMessage);
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
}
