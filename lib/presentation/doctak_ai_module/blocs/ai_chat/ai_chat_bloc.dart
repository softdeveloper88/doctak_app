import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:doctak_app/presentation/doctak_ai_module/data/models/ai_chat_model/ai_chat_message_model.dart';
import 'package:doctak_app/presentation/doctak_ai_module/data/api/ai_chat_api.dart' as aiChatApi;
import '../../data/local/ai_chat_local_storage.dart';
import '../../data/models/ai_chat_model/ai_chat_session_model.dart';

part 'ai_chat_event.dart';
part 'ai_chat_state.dart';

class AiChatBloc extends Bloc<AiChatEvent, AiChatState> {
  AiChatBloc() : super(AiChatInitial()) {
    on<LoadSessions>(_onLoadSessions);
    on<CreateSession>(_onCreateSession);
    on<SelectSession>(_onSelectSession);
    on<SendMessage>(_onSendMessage);
    on<DeleteSession>(_onDeleteSession);
    on<RenameSession>(_onRenameSession);
    on<SubmitFeedback>(_onSubmitFeedback);
    on<ClearCurrentSession>(_onClearCurrentSession);
  }
  
  // Helper method to send a message to the API
  Future<void> _sendMessageToAPI({
    required String sessionId,
    required SendMessage event,
    required AiChatState currentState,
    required AiChatMessageModel userMessage,
    required Emitter<AiChatState> emit,
  }) async {
    print("⚠️⚠️⚠️ Preparing to call sendMessage API");
    
    // Extract messages from current state
    List<AiChatMessageModel> updatedMessages;
    List<AiChatSessionModel> sessions;
    AiChatSessionModel selectedSession;
    bool isFirstMessage;
    
    if (currentState is MessageSending) {
      sessions = currentState.sessions;
      selectedSession = currentState.selectedSession;
      updatedMessages = currentState.messages;
      isFirstMessage = currentState.isFirstMessage;
    } else if (currentState is SessionSelected) {
      sessions = currentState.sessions;
      selectedSession = currentState.selectedSession;
      updatedMessages = [...currentState.messages, userMessage];
      isFirstMessage = currentState.messages.isEmpty;
    } else {
      print("⚠️⚠️⚠️ Unexpected state type: ${currentState.runtimeType}");
      return;
    }
    
    // Check if file exists and is valid before sending
    File? fileToSend;
    if (event.file != null) {
      try {
        final file = event.file!;
        if (await file.exists() && await file.length() > 0) {
          fileToSend = file;
          print("⚠️ Using valid file for message: ${file.path}");
        } else {
          print("⚠️ File invalid or empty, not sending: ${file.path}");
        }
      } catch (e) {
        print("⚠️ Error checking file: $e");
      }
    }

    print("⚠️⚠️⚠️ About to call aiChatApi.sendMessage");
    print("⚠️⚠️⚠️ Message params:");
    print("⚠️⚠️⚠️ sessionId: $sessionId");
    print("⚠️⚠️⚠️ message: ${event.message}");
    print("⚠️⚠️⚠️ model: ${event.model}");
    print("⚠️⚠️⚠️ temperature: ${event.temperature}");
    print("⚠️⚠️⚠️ maxTokens: ${event.maxTokens}");
    print("⚠️⚠️⚠️ webSearch: ${event.webSearch}");
    print("⚠️⚠️⚠️ file: ${fileToSend != null ? 'present' : 'not present'}");
    
    Map<String, dynamic> response;
    
    try {
      print("⚠️⚠️⚠️ ENTERING SENDMESSAGE FUNCTION");
      
      // Set timeout based on model
      int timeoutSeconds = 60;
      
      response = await aiChatApi.sendMessage(
        sessionId: sessionId,
        message: event.message,
        model: event.model,
        temperature: event.temperature,
        maxTokens: event.maxTokens,
        webSearch: event.webSearch,
        searchContextSize: event.searchContextSize,
        userLocationCountry: event.userLocationCountry,
        userLocationCity: event.userLocationCity,
        userLocationRegion: event.userLocationRegion,
        file: fileToSend, // Only pass the file if it's valid
      );
      print("⚠️⚠️⚠️ AFTER SENDMESSAGE FUNCTION RETURNS");
      print("⚠️⚠️⚠️ sendMessage API call successful: ${response.keys}");
    } catch (e) {
      print("⚠️⚠️⚠️ CRITICAL ERROR in sendMessage API call: $e");
      print("⚠️⚠️⚠️ Stack trace: ${StackTrace.current}");
      
      // Format user-friendly error message 
      String errorMessage = 'Failed to get AI response';
      
      // Add more context for specific error types
      if (e.toString().contains('timeout') || e.toString().contains('TimeoutException')) {
        errorMessage = 'Request timed out. Please check your connection and try again.';
      } else if (e.toString().contains('network') || e.toString().contains('socket')) {
        errorMessage = 'Network error. Please check your connection and try again.';
      } else if (e.toString().contains('parse')) {
        errorMessage = 'Error processing the response. Please try again.';
      } else if (e.toString().contains('session')) {
        errorMessage = 'Session error. Please try creating a new conversation.';
      }
      
      // Check if emit is still valid before emitting
      if (!emit.isDone) {
        emit(MessageSendError(
          sessions: sessions,
          selectedSession: selectedSession,
          messages: updatedMessages,
          message: errorMessage,
        ));
      }
      // Exit early
      return;
    }
    
    // Extract AI message from response
    AiChatMessageModel aiMessage;
    List? sources;
    try {
      if (response == null) {
        throw "Response is null";
      }
      
      print("⚠️⚠️⚠️ Response contents: $response");
      
      if (!response.containsKey('message')) {
        throw "Response is missing 'message' key. Response: ${response.keys}";
      }
      
      // Convert message data to AiChatMessageModel
      print("⚠️⚠️⚠️ BLOC LAYER - message type: ${response['message'].runtimeType}");
      Map<String, dynamic> messageData = response['message'] as Map<String, dynamic>;
      aiMessage = AiChatMessageModel.fromJson(messageData);
      sources = response['sources'] as List?;
      print("⚠️⚠️⚠️ Successfully extracted message from response");
    } catch (e) {
      print("⚠️⚠️⚠️ ERROR parsing response data: $e");
      print("⚠️⚠️⚠️ Response content: $response");
      print("⚠️⚠️⚠️ Response type: ${response?.runtimeType}");
      
      // Check if emit is still valid before emitting
      if (!emit.isDone) {
        emit(MessageSendError(
          sessions: sessions,
          selectedSession: selectedSession,
          messages: updatedMessages,
          message: 'Failed to parse AI response. Please try again later.',
        ));
      }
      return; // Exit early if parsing fails
    }
    
    // Add AI message to messages list
    final messagesWithResponse = [...updatedMessages, aiMessage];
    
    // Cache updated messages
    await AiChatLocalStorage.saveMessages(sessionId, messagesWithResponse);
    
    // Check if emit is still valid
    if (emit.isDone) return;
    
    // Suggest title if this is the first exchange
    if (isFirstMessage && event.suggestTitle) {
      try {
        final title = await aiChatApi.suggestTitle(
          sessionId,
          event.message,
          aiMessage.content,
        );
        
        // Update session name in current sessions list
        final updatedSessions = sessions.map((session) {
          if (session.id.toString() == sessionId) {
            session.name = title;
          }
          return session;
        }).toList();
        
        // Update local storage
        await AiChatLocalStorage.saveSessions(updatedSessions);
        
        // Update selected session
        final updatedSelectedSession = selectedSession;
        updatedSelectedSession.name = title;
        
        // Check if emit is still valid before emitting
        if (!emit.isDone) {
          print("⚠️⚠️⚠️ About to emit MessageSent state (title case) - current state: ${state.runtimeType}");
          
          // First emit temporary state to clear MessageSending state
          emit(SessionSelected(
            sessions: updatedSessions,
            selectedSession: updatedSelectedSession,
            messages: messagesWithResponse,
          ));
            
          // Now emit the final MessageSent state
          emit(MessageSent(
            sessions: updatedSessions,
            selectedSession: updatedSelectedSession,
            messages: messagesWithResponse,
            lastUserMessage: userMessage,
            lastAiMessage: aiMessage,
            sources: sources,
          ));
          print("⚠️⚠️⚠️ EMITTED MessageSent state successfully (title case) - new state: ${state.runtimeType}");
        }
      } catch (e) {
        print('Failed to suggest title: ${e.toString()}');
        // Continue with original session name
        if (!emit.isDone) {
          emit(MessageSent(
            sessions: sessions,
            selectedSession: selectedSession,
            messages: messagesWithResponse,
            lastUserMessage: userMessage,
            lastAiMessage: aiMessage,
            sources: sources,
          ));
        }
      }
    } else {
      // Just update with new message
      if (!emit.isDone) {
        print("⚠️⚠️⚠️ EMITTING MessageSent state - isDone: ${emit.isDone}");
        try {
          print("⚠️⚠️⚠️ About to emit MessageSent state - current state: ${state.runtimeType}");
            
          // First emit temporary state to clear MessageSending state
          emit(SessionSelected(
            sessions: sessions,
            selectedSession: selectedSession,
            messages: messagesWithResponse,
          ));
            
          // Now emit the final MessageSent state
          emit(MessageSent(
            sessions: sessions,
            selectedSession: selectedSession,
            messages: messagesWithResponse,
            lastUserMessage: userMessage,
            lastAiMessage: aiMessage,
            sources: sources,
          ));
          print("⚠️⚠️⚠️ EMITTED MessageSent state successfully - new state: ${state.runtimeType}");
        } catch (e) {
          print("⚠️⚠️⚠️ ERROR emitting MessageSent: $e");
        }
      } else {
        print("⚠️⚠️⚠️ NOT EMITTING MessageSent state - emit.isDone is true");
      }
    }
  }

  Future<void> _onLoadSessions(
    LoadSessions event,
    Emitter<AiChatState> emit,
  ) async {
    emit(SessionsLoading());
    
    // Try to load from local storage first for immediate display
    List<AiChatSessionModel> cachedSessions = [];
    bool hasCache = false;
    
    try {
      cachedSessions = await AiChatLocalStorage.getSessions() ?? [];
      if (cachedSessions.isNotEmpty) {
        hasCache = true;
        emit(SessionsLoaded(sessions: cachedSessions));
        print("⚠️⚠️⚠️ Emitted cached sessions: ${cachedSessions.length}");
      }
    } catch (e) {
      print("⚠️⚠️⚠️ Error loading cached sessions: $e");
    }
    
    // Then fetch from network - in a try/catch block to handle network errors
    try {
      print("⚠️⚠️⚠️ Fetching sessions from network");
      final networkSessions = await aiChatApi.getChatSessions();
      
      // Cache the latest data
      await AiChatLocalStorage.saveSessions(networkSessions);
      
      // Only emit if we have sessions or had no cache before
      if (networkSessions.isNotEmpty || !hasCache) {
        print("⚠️⚠️⚠️ Emitting network sessions: ${networkSessions.length}");
        emit(SessionsLoaded(sessions: networkSessions));
      }
    } catch (e) {
      print("⚠️⚠️⚠️ Error fetching sessions from network: $e");
      
      // If network fails but we have cache, keep showing cached data
      if (hasCache) {
        // Already emitted the cached sessions above, just log the error
        print("⚠️⚠️⚠️ Using cached sessions as fallback");
      } else {
        // No cache and network failed - emit error
        emit(SessionsLoadError(
          message: 'Failed to load sessions: ${e.toString()}',
        ));
      }
    }
  }

  Future<void> _onCreateSession(
    CreateSession event,
    Emitter<AiChatState> emit,
  ) async {
    // Begin with loading state but preserve current sessions
    List<AiChatSessionModel> currentSessions = [];
    if (state is SessionsLoaded) {
      currentSessions = (state as SessionsLoaded).sessions;
    } else if (state is SessionSelected) {
      currentSessions = (state as SessionSelected).sessions;
    } else if (state is MessageSent) {
      currentSessions = (state as MessageSent).sessions;
    }
    
    emit(SessionCreating(sessions: currentSessions));
    
    try {
      final newSession = await aiChatApi.createChatSession(
        name: event.name,
      );
      
      // Add to current sessions
      final updatedSessions = [newSession, ...currentSessions];
      
      // Update local storage
      await AiChatLocalStorage.saveSessions(updatedSessions);
      
      // Emit the created session state
      emit(SessionCreated(
        sessions: updatedSessions,
        newSession: newSession,
      ));
      
      // Wait a small amount of time before selecting the session to avoid state conflicts
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Only add next event if emitter is still valid
      if (!emit.isDone) {
        // Automatically select the new session but don't use add() to avoid nested events
        await _onSelectSession(SelectSession(sessionId: newSession.id.toString()), emit);
      }
    } catch (e) {
      emit(SessionCreateError(
        message: 'Failed to create session: ${e.toString()}',
        sessions: currentSessions,
      ));
    }
  }

  Future<void> _onSelectSession(
    SelectSession event,
    Emitter<AiChatState> emit,
  ) async {
    // Preserve current sessions list - handle more state types
    List<AiChatSessionModel> currentSessions = [];
    if (state is SessionsLoaded) {
      currentSessions = (state as SessionsLoaded).sessions;
    } else if (state is SessionCreated) {
      currentSessions = (state as SessionCreated).sessions;
    } else if (state is MessageSent) {
      currentSessions = (state as MessageSent).sessions;
    } else if (state is SessionSelected) {
      currentSessions = (state as SessionSelected).sessions;
    } else if (state is MessageSending) {
      currentSessions = (state as MessageSending).sessions;
    } else if (state is SessionDeleted) {
      currentSessions = (state as SessionDeleted).sessions;
    } else if (state is SessionUpdating) {
      currentSessions = (state as SessionUpdating).sessions;
    } else if (state is AiChatInitial) {
      // If in initial state, try to load sessions first
      try {
        final sessions = await aiChatApi.getChatSessions();
        currentSessions = sessions;
        
        // Cache the sessions
        await AiChatLocalStorage.saveSessions(sessions);
      } catch (e) {
        // Try to get from cache if network fails
        try {
          final cachedSessions = await AiChatLocalStorage.getSessions() ?? [];
          currentSessions = cachedSessions;
        } catch (cacheError) {
          // Both network and cache failed
          print("⚠️⚠️⚠️ Failed to load sessions from API and cache: $e, $cacheError");
        }
      }
    }
    
    debugPrint("⚠️⚠️⚠️ Selecting session: ${event.sessionId} (current state: ${state.runtimeType})");
    emit(SessionLoading(sessions: currentSessions));
    
    // First find the session in the current sessions list
    AiChatSessionModel? selectedSession;
    for (var session in currentSessions) {
      if (session.id.toString() == event.sessionId) {
        selectedSession = session;
        break;
      }
    }
    
    // If no session found in memory, try to load it directly from network
    if (selectedSession == null) {
      debugPrint("⚠️⚠️⚠️ Session not found in current sessions, loading specific session directly");
      try {
        // Try to get the specific session directly first - this has better chance of success
        // if the session exists but wasn't in our cached list
        final sessionData = await aiChatApi.getChatSession(event.sessionId);
        selectedSession = sessionData['session'] as AiChatSessionModel;
        
        // Also refresh our sessions list to ensure consistency
        try {
          final sessions = await aiChatApi.getChatSessions();
          currentSessions = sessions;
          await AiChatLocalStorage.saveSessions(sessions);
        } catch (listError) {
          // Add the selected session to our current list if not already there
          bool found = false;
          for (var session in currentSessions) {
            if (session.id.toString() == event.sessionId) {
              found = true;
              break;
            }
          }
          
          if (!found) {
            currentSessions = [selectedSession, ...currentSessions];
            await AiChatLocalStorage.saveSessions(currentSessions);
          }
        }
      } catch (e) {
        debugPrint("⚠️⚠️⚠️ Failed to load specific session from API: $e");
        
        // Last attempt - try to get all sessions again
        try {
          final sessions = await aiChatApi.getChatSessions();
          currentSessions = sessions;
          
          // Find the session in the refreshed list
          for (var session in sessions) {
            if (session.id.toString() == event.sessionId) {
              selectedSession = session;
              break;
            }
          }
        } catch (refreshError) {
          debugPrint("⚠️⚠️⚠️ Failed to refresh sessions list: $refreshError");
        }
      }
    }
    
    // If we still can't find the session, return an error
    if (selectedSession == null) {
      emit(SessionLoadError(
        message: 'Session not found. It may have been deleted or is unavailable.',
        sessions: currentSessions,
      ));
      return;
    }
    
    try {
      // Try to load from local storage first for immediate feedback
      List<AiChatMessageModel>? cachedMessages;
      try {
        cachedMessages = await AiChatLocalStorage.getMessages(event.sessionId);
      } catch (cacheError) {
        debugPrint("⚠️⚠️⚠️ Error loading cached messages: $cacheError");
        // Continue without cache
      }
      
      // If we found cached data, emit it immediately to improve perceived performance
      if (cachedMessages != null && cachedMessages.isNotEmpty) {
        debugPrint("⚠️⚠️⚠️ Found ${cachedMessages.length} cached messages for session ${event.sessionId}");
        if (!emit.isDone) {
          emit(SessionSelected(
            sessions: currentSessions,
            selectedSession: selectedSession,
            messages: cachedMessages,
          ));
        }
      } else {
        debugPrint("⚠️⚠️⚠️ No cached messages found for session ${event.sessionId}");
      }
      
      // Then fetch from network
      try {
        final sessionData = await aiChatApi.getChatSession(event.sessionId);
        final session = sessionData['session'] as AiChatSessionModel;
        final messages = sessionData['messages'] as List<AiChatMessageModel>;
        
        // Cache the latest data
        await AiChatLocalStorage.saveMessages(event.sessionId, messages);
        
        // Only emit if we got new data and emitter is still valid
        if (!emit.isDone) {
          emit(SessionSelected(
            sessions: currentSessions,
            selectedSession: session,
            messages: messages,
          ));
        }
      } catch (networkError) {
        debugPrint("⚠️⚠️⚠️ Network error loading session messages: $networkError");
        
        // If we already emitted cached data, only emit an error if we have no messages
        if (cachedMessages == null || cachedMessages.isEmpty) {
          if (!emit.isDone) {
            emit(SessionLoadError(
              message: 'Failed to load messages. Check your connection and try again.',
              sessions: currentSessions,
              selectedSession: selectedSession,
              messages: cachedMessages ?? [],
            ));
          }
        } else {
          // We have cached messages, so maintain the selected state but show a warning
          if (!emit.isDone && cachedMessages.isNotEmpty) {
            // First make sure we're in the correct state
            emit(SessionSelected(
              sessions: currentSessions,
              selectedSession: selectedSession,
              messages: cachedMessages,
            ));
          }
        }
      }
    } catch (e) {
      debugPrint("⚠️⚠️⚠️ Error in _onSelectSession: $e");
      // Handle any other errors
      if (!emit.isDone) {
        emit(SessionLoadError(
          message: 'Failed to load session: ${e.toString()}',
          sessions: currentSessions,
        ));
      }
    }
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<AiChatState> emit,
  ) async {
    print("⚠️⚠️⚠️ _onSendMessage event handler called with state: ${state.runtimeType}");
    
    // If no session is selected, create one first
    if (!(state is SessionSelected || state is MessageSent)) {
      print("⚠️⚠️⚠️ No session selected - creating a new session first");
      
      // Get current sessions if available
      List<AiChatSessionModel> currentSessions = [];
      if (state is SessionsLoaded) {
        currentSessions = (state as SessionsLoaded).sessions;
      } else if (state is SessionCreating) {
        currentSessions = (state as SessionCreating).sessions;
      } else if (state is SessionCreated) {
        // If we're in SessionCreated state, just select that session instead of creating a new one
        final createdState = state as SessionCreated;
        print("⚠️⚠️⚠️ Already have SessionCreated state, using that session: ${createdState.newSession.id}");
        
        // Wait for state to stabilize before continuing
        await Future.delayed(const Duration(milliseconds: 50));
        
        // Select the session first
        await _onSelectSession(SelectSession(sessionId: createdState.newSession.id.toString()), emit);
        
        // Now get the current state again
        if (state is SessionSelected) {
          // Continue with regular message sending below
          print("⚠️⚠️⚠️ Successfully selected the session, continuing with message");
          // The function will continue below with the new state
        } else {
          // Something went wrong, bail out
          print("⚠️⚠️⚠️ Failed to select the session: ${state.runtimeType}");
          return;
        }
      }
      
      // Only create a new session if we didn't already select one above
      if (!(state is SessionSelected)) {
        try {
          // Create a new session
          final newSession = await aiChatApi.createChatSession();
          
          // Add to current sessions
          final updatedSessions = [newSession, ...currentSessions];
          
          // Update local storage
          await AiChatLocalStorage.saveSessions(updatedSessions);
          
          // Select the new session
          final sessionId = newSession.id;
          print("⚠️⚠️⚠️ Created and selected new session: $sessionId");
          
          // Continue with sending the message using the new session
          // Create and add user message
          final userMessage = AiChatMessageModel(
            id: DateTime.now().millisecondsSinceEpoch,
            sessionId: sessionId,
            role: MessageRole.user,
            content: event.message,
            createdAt: DateTime.now(),
          );
          
          final updatedMessages = [userMessage];
          
          // Update state to show user message immediately
          emit(MessageSending(
            sessions: updatedSessions,
            selectedSession: newSession,
            messages: updatedMessages,
            isFirstMessage: true,
          ));
          
          print("⚠️⚠️⚠️ Proceeding to send message with new session");
          
          // Continue with the rest of the sendMessage logic using the new session
          await _sendMessageToAPI(
            sessionId: sessionId.toString(),
            event: event,
            currentState: MessageSending(
              sessions: updatedSessions,
              selectedSession: newSession,
              messages: updatedMessages,
              isFirstMessage: true,
            ),
            userMessage: userMessage,
            emit: emit,
          );
          
          return;
        } catch (e) {
          print("⚠️⚠️⚠️ Error creating new session: $e");
          emit(SessionCreateError(
            message: 'Failed to create session: ${e.toString()}',
            sessions: currentSessions,
          ));
          return;
        }
      }
    }
    
    // Handle both SessionSelected and MessageSent states
    int sessionId;
    List<AiChatSessionModel> currentSessions = [];
    List<AiChatMessageModel> currentMessages = [];
    AiChatSessionModel selectedSession;
    
    if (state is SessionSelected) {
      sessionId = (state as SessionSelected).selectedSession.id;
      currentSessions = (state as SessionSelected).sessions;
      currentMessages = (state as SessionSelected).messages;
      selectedSession = (state as SessionSelected).selectedSession;
    } else if (state is MessageSent) {
      sessionId = (state as MessageSent).selectedSession.id;
      currentSessions = (state as MessageSent).sessions;
      currentMessages = (state as MessageSent).messages;
      selectedSession = (state as MessageSent).selectedSession;
    } else {
      debugPrint("⚠️⚠️⚠️ Unexpected state type in _onSendMessage: ${state.runtimeType}");
      return;
    }
    
    print("⚠️⚠️⚠️ Selected session ID: $sessionId");

    // Create and add user message
    final userMessage = AiChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch, // Temporary ID
      sessionId: sessionId,
      role: MessageRole.user,
      content: event.message,
      createdAt: DateTime.now(),
    );
    
    // Add user message to existing messages
    final updatedMessages = [...currentMessages, userMessage];
    
    // Update state to show user message immediately
    print("⚠️⚠️⚠️ BEFORE MessageSending - Current state: ${state.runtimeType}");
    emit(MessageSending(
      sessions: currentSessions,
      selectedSession: selectedSession,
      messages: updatedMessages,
      isFirstMessage: currentMessages.isEmpty,
    ));
    print("⚠️⚠️⚠️ AFTER MessageSending - Current state: ${state.runtimeType}");
    
    // Use the helper method for the rest of the message sending process
    print("⚠️⚠️⚠️ STARTING message sending process with state type: ${state.runtimeType}");
    try {
      await _sendMessageToAPI(
        sessionId: sessionId.toString(),
        event: event,
        currentState: MessageSending(
          sessions: currentSessions,
          selectedSession: selectedSession,
          messages: updatedMessages,
          isFirstMessage: currentMessages.isEmpty,
        ),
        userMessage: userMessage,
        emit: emit,
      );
      print("⚠️⚠️⚠️ COMPLETED message sending process - Final state type: ${state.runtimeType}");
    } catch (e) {
      print("⚠️⚠️⚠️ ERROR in message sending process: $e");
    }
  }

  Future<void> _onDeleteSession(
    DeleteSession event,
    Emitter<AiChatState> emit,
  ) async {
    if (state is! SessionsLoaded) return;
    
    final currentState = state as SessionsLoaded;
    final currentSessions = currentState.sessions;
    
    emit(SessionDeleting(sessions: currentSessions));
    
    try {
      final response = await aiChatApi.deleteSession(event.sessionId);
      
      // Remove deleted session from list
      final updatedSessions = currentSessions.where(
        (session) => session.id != event.sessionId
      ).toList();
      
      // Update local storage
      await AiChatLocalStorage.saveSessions(updatedSessions);
      
      emit(SessionDeleted(
        sessions: updatedSessions,
        nextSession: response['nextSession'],
      ));
      
      // If there's a next session and we were viewing the deleted session,
      // automatically select the next session
      if (response['nextSession'] != null && 
          state is SessionSelected && 
          (state as SessionSelected).selectedSession.id == event.sessionId) {
        add(SelectSession(sessionId: response['nextSession'].id));
      }
    } catch (e) {
      emit(SessionDeleteError(
        message: 'Failed to delete session: ${e.toString()}',
        sessions: currentSessions,
      ));
    }
  }

  Future<void> _onRenameSession(
    RenameSession event,
    Emitter<AiChatState> emit,
  ) async {
    debugPrint("⚠️⚠️⚠️ Starting session rename for session: ${event.sessionId}");
    
    // Get current sessions list from any state that has it
    List<AiChatSessionModel> currentSessions = [];
    List<AiChatMessageModel>? currentMessages;
    AiChatSessionModel? currentSelectedSession;
    
    // Support more state types for better robustness
    if (state is SessionsLoaded) {
      currentSessions = (state as SessionsLoaded).sessions;
      // Find the selected session
      for (var session in currentSessions) {
        if (session.id.toString() == event.sessionId) {
          currentSelectedSession = session;
          break;
        }
      }
    } else if (state is SessionSelected) {
      currentSessions = (state as SessionSelected).sessions;
      currentMessages = (state as SessionSelected).messages;
      currentSelectedSession = (state as SessionSelected).selectedSession;
    } else if (state is MessageSending) {
      currentSessions = (state as MessageSending).sessions;
      currentMessages = (state as MessageSending).messages;
      currentSelectedSession = (state as MessageSending).selectedSession;
    } else if (state is MessageSent) {
      currentSessions = (state as MessageSent).sessions;
      currentMessages = (state as MessageSent).messages;
      currentSelectedSession = (state as MessageSent).selectedSession;
    } else if (state is SessionCreated) {
      currentSessions = (state as SessionCreated).sessions;
      // Set current selected session to the newly created one if it matches
      if ((state as SessionCreated).newSession.id.toString() == event.sessionId) {
        currentSelectedSession = (state as SessionCreated).newSession;
      }
    } else {
      // If we don't have sessions in the current state, abort
      debugPrint("Cannot rename: No sessions available in current state: ${state.runtimeType}");
      return;
    }
    
    // First emit a temporary "renaming" state to indicate operation in progress
    emit(SessionUpdating(
      sessions: currentSessions,
      selectedSession: currentSelectedSession,
      messages: currentMessages ?? [],
    ));
    
    try {
      debugPrint("⚠️⚠️⚠️ Making API call to rename session");
      final updatedSession = await aiChatApi.renameSession(
        event.sessionId,
        event.name,
      );
      
      debugPrint("⚠️⚠️⚠️ Session renamed successfully");
      
      // Update session in sessions list
      final updatedSessions = currentSessions.map((session) {
        if (session.id.toString() == event.sessionId) {
          return updatedSession;
        }
        return session;
      }).toList();
      
      // Update local storage
      await AiChatLocalStorage.saveSessions(updatedSessions);
      
      // Determine if the renamed session is the currently selected one
      bool isSelectedSession = currentSelectedSession != null && 
          currentSelectedSession.id.toString() == event.sessionId;
      
      // Update state based on current state and selection
      if (isSelectedSession && currentMessages != null) {
        debugPrint("⚠️⚠️⚠️ Updating current selected session state");
        // If we're in a session with messages and it's the one being renamed
        if (state is SessionSelected || state is SessionUpdating) {
          emit(SessionSelected(
            sessions: updatedSessions,
            selectedSession: updatedSession,
            messages: currentMessages,
          ));
        } else if (state is MessageSending) {
          emit(MessageSending(
            sessions: updatedSessions,
            selectedSession: updatedSession,
            messages: currentMessages,
            isFirstMessage: (state as MessageSending).isFirstMessage,
          ));
        } else if (state is MessageSent) {
          emit(MessageSent(
            sessions: updatedSessions,
            selectedSession: updatedSession,
            messages: currentMessages,
            lastUserMessage: (state as MessageSent).lastUserMessage,
            lastAiMessage: (state as MessageSent).lastAiMessage,
            sources: (state as MessageSent).sources,
          ));
        }
      } else {
        // Not the selected session or no messages - just update sessions list
        debugPrint("⚠️⚠️⚠️ Updating sessions list only");
        emit(SessionsLoaded(sessions: updatedSessions));
      }
    } catch (e) {
      debugPrint("⚠️⚠️⚠️ Error renaming session: $e");
      emit(SessionUpdateError(
        message: 'Failed to rename session: ${e.toString()}',
        sessions: currentSessions,
      ));
    }
  }

  Future<void> _onSubmitFeedback(
    SubmitFeedback event,
    Emitter<AiChatState> emit,
  ) async {
    if (state is! SessionSelected) return;
    
    final currentState = state as SessionSelected;
    
    try {
      final updatedMessage = await aiChatApi.submitFeedback(
        event.messageId,
        event.feedback,
      );
      
      if (emit.isDone) return;
      
      // Update message in messages list
      final updatedMessages = currentState.messages.map((message) {
        if (message.id == event.messageId) {
          return updatedMessage;
        }
        return message;
      }).toList();
      
      // Update local storage
      await AiChatLocalStorage.saveMessages(
        currentState.selectedSession.id.toString(),
        updatedMessages,
      );
      
      if (!emit.isDone) {
        emit(SessionSelected(
          sessions: currentState.sessions,
          selectedSession: currentState.selectedSession,
          messages: updatedMessages,
        ));
      }
    } catch (e) {
      if (emit.isDone) return;
      
      // Just show a temporary error, but don't change state
      emit(FeedbackError(
        sessions: currentState.sessions,
        selectedSession: currentState.selectedSession,
        messages: currentState.messages,
        message: 'Failed to submit feedback: ${e.toString()}',
      ));
      
      // Use a safer approach for delayed state changes
      if (!emit.isDone) {
        try {
          // Use a separate event to revert state instead of delayed emit
          add(ClearCurrentSession());
        } catch (e) {
          // Just log the error if something goes wrong
          print('Error reverting feedback error state: $e');
        }
      }
    }
  }
  
  void _onClearCurrentSession(
    ClearCurrentSession event,
    Emitter<AiChatState> emit,
  ) {
    if (state is SessionsLoaded) {
      emit(SessionsLoaded(sessions: (state as SessionsLoaded).sessions));
    }
  }
}