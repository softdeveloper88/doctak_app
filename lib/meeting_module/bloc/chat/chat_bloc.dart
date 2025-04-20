import 'package:doctak_app/meeting_module/models/message.dart';
import 'package:doctak_app/meeting_module/services/api_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ApiService _apiService;
  bool _isVisible = false;

  ChatBloc({required ApiService apiService})
      : _apiService = apiService,
        super(ChatInitial()) {
    on<LoadChatHistory>(_onLoadChatHistory);
    on<SendMessageEvent>(_onSendMessage);
    on<UploadAttachmentEvent>(_onUploadAttachment);
    on<NewMessageReceivedEvent>(_onNewMessageReceived);
    on<ClearChatEvent>(_onClearChat);
  }

  // Update visibility state
  set isVisible(bool value) {
    _isVisible = value;
  }

  Future<void> _onLoadChatHistory(
      LoadChatHistory event,
      Emitter<ChatState> emit,
      ) async {
    emit(ChatLoading());
    try {
      final messages = await _apiService.getChatHistory(event.meetingId);
      emit(ChatLoaded(messages: messages));
    } catch (e) {
      emit(ChatError('Failed to load chat history: $e'));
    }
  }

  Future<void> _onSendMessage(
      SendMessageEvent event,
      Emitter<ChatState> emit,
      ) async {
    final currentState = state;
    if (currentState is ChatLoaded) {
      try {
        await _apiService.sendMessage(
          meetingId: event.meetingId,
          userId: event.userId,
          message: event.message,
          attachmentUrl: event.attachmentUrl,
        );
        emit(MessageSent());
        emit(currentState); // Restore the previous state after sending
      } catch (e) {
        emit(ChatError('Failed to send message: $e'));
        emit(currentState); // Restore the previous state after error
      }
    }
  }

  Future<void> _onUploadAttachment(
      UploadAttachmentEvent event,
      Emitter<ChatState> emit,
      ) async {
    final currentState = state;
    emit(AttachmentUploading());
    try {
      final attachmentUrl = await _apiService.uploadChatAttachment(
        event.meetingId,
        event.file,
      );
      emit(AttachmentUploaded(attachmentUrl));
      if (currentState is ChatLoaded) {
        emit(currentState); // Restore chat loaded state
      }
    } catch (e) {
      emit(ChatError('Failed to upload attachment: $e'));
      if (currentState is ChatLoaded) {
        emit(currentState); // Restore chat loaded state
      }
    }
  }

  void _onNewMessageReceived(
      NewMessageReceivedEvent event,
      Emitter<ChatState> emit,
      ) {
    final currentState = state;
    if (currentState is ChatLoaded) {
      final updatedMessages = List<Message>.from(currentState.messages)
        ..add(event.message);

      // Increment unread count if chat is not visible
      int unreadCount = currentState.unreadCount;
      if (!_isVisible) {
        unreadCount++;
      }

      emit(currentState.copyWith(
        messages: updatedMessages,
        unreadCount: unreadCount,
      ));
    }
  }

  void _onClearChat(
      ClearChatEvent event,
      Emitter<ChatState> emit,
      ) {
    emit(ChatInitial());
  }

  // Reset unread counter when chat becomes visible
  void resetUnreadCounter() {
    final currentState = state;
    if (currentState is ChatLoaded && currentState.unreadCount > 0) {
      emit(currentState.copyWith(unreadCount: 0));
    }
  }
}