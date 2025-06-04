
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/apiClient/api_service.dart';
import 'package:doctak_app/data/models/chat_model/contacts_model.dart';
import 'package:doctak_app/data/models/chat_model/message_model.dart';
import 'package:doctak_app/data/models/chat_model/search_contacts_model.dart';
import 'package:doctak_app/data/models/chat_model/send_message_model.dart';
import 'package:doctak_app/widgets/toast_widget.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nb_utils/nb_utils.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ApiService postService = ApiService(Dio());
  List<XFile> imagefiles = [];
  int pageNumber = 1;
  int numberOfPage = 1;
  List<Contacts> contactsList = [];
  List<Groups> groupList = [];
  final int nextPageTrigger = 1;

  // search contacts
  int contactPageNumber = 1;
  int contactNumberOfPage = 1;
  List<Data> searchContactsList = [];
  final int contactNextPageTrigger = 1;

  // room message
  int messagePageNumber = 1;
  int messageNumberOfPage = 1;
  List<Messages> messagesList = [];
  final int messageNextPageTrigger = 1;

  String? roomId;

  ChatBloc() : super(DataInitial()) {
    on<LoadPageEvent>(_onGetChat);
    on<LoadContactsEvent>(_onGetSearchContacts);
    on<LoadRoomMessageEvent>(_onGetMessages);
    on<SendMessageEvent>(_onSendMessages);
    on<DeleteMessageEvent>(_onDeleteMessages);
    on<ChatReadStatusEvent>(_updateChatReadStatus);
    on<SelectedFiles>(_selectedFile);
    on<CheckIfNeedMoreDataEvent>((event, emit) async {
      if (event.index == contactsList.length - nextPageTrigger) {
        add(LoadPageEvent(page: pageNumber));
      }
    });
    on<CheckIfNeedMoreContactDataEvent>((event, emit) async {
      if (event.index == searchContactsList.length - contactNextPageTrigger) {
        add(LoadContactsEvent(page: contactPageNumber));
      }
    });
    on<CheckIfNeedMoreMessageDataEvent>((event, emit) async {
      if (event.index == messagesList.length - messageNextPageTrigger) {
        add(LoadRoomMessageEvent(
            page: messagePageNumber,
            userId: event.userId,
            roomId: event.roomId));
      }
    });
  }

  _onGetChat(LoadPageEvent event, Emitter<ChatState> emit) async {
    if (event.page == 1) {
      contactsList.clear();
      pageNumber = 1;
      emit(PaginationLoadingState());
    }
    try {
      ContactsModel response = await postService.getContacts(
        'Bearer ${AppData.userToken}',
        '$pageNumber',
      );
      numberOfPage = response.lastPage ?? 0;
      if (pageNumber < numberOfPage + 1) {
        pageNumber = pageNumber + 1;
        contactsList.addAll(response.contacts ?? []);
        contactsList.removeWhere((element) => element.id == null);
        groupList.addAll(response.groups ?? []);
      }
      log(response.contacts!.length);
      emit(PaginationLoadedState());
    } catch (e) {
      print(e);

      emit(PaginationLoadedState());

      // emit(DataError('An error occurred $e'));
    }
  }

  _onGetSearchContacts(LoadContactsEvent event, Emitter<ChatState> emit) async {
    if (event.page == 1) {
      searchContactsList.clear();
      contactPageNumber = 1;
      emit(PaginationLoadingState());
    }
    try {
      SearchContactsModel response = await postService.searchContacts(
          'Bearer ${AppData.userToken}',
          '$contactPageNumber',
          event.keyword ?? '');
      contactNumberOfPage = response.lastPage ?? 0;
      if (contactPageNumber < contactNumberOfPage + 1) {
        contactPageNumber = contactPageNumber + 1;
        searchContactsList.addAll(response.records?.data ?? []);
      }

      emit(PaginationLoadedState());

      // emit(DataLoaded(contactsList));
    } catch (e) {
      print(e);

      emit(PaginationLoadedState());

      // emit(DataError('An error occurred $e'));
    }
  }
  _updateChatReadStatus(ChatReadStatusEvent event, Emitter<ChatState> emit) async {

    try {
      if(event.roomId !='') {
        await postService.updateReadStatus(
            'Bearer ${AppData.userToken}',
            event.userId ?? "", event.roomId ?? '');
      }
      emit(PaginationLoadedState());

      // emit(DataLoaded(contactsList));
    } catch (e) {
      print(e);

      emit(PaginationLoadedState());

      // emit(DataError('An error occurred $e'));
    }
  }

  void addUserIfNotExists(
      List<Messages> oldMessages, List<Messages> newMessages) {
    for (var message in newMessages) {
      if (!oldMessages.contains(message)) {
        oldMessages.add(message);
      }
    }
    messagesList = oldMessages;
  }

  _onGetMessages(LoadRoomMessageEvent event, Emitter<ChatState> emit) async {
    print('page ${event.page}');
    if (event.page == 1) {
      messagesList.clear();
      messagePageNumber = 1;
      if(event.isFirstLoading??false) {
        emit(PaginationLoadingState());
      }
      print('page ${event.page}');
    } else if (event.page == 0) {
      // messagesList.clear();
      messagePageNumber = 0;
    }
    try {
      print(event.page);

      MessageModel response = await postService.getRoomMessenger(
          'Bearer ${AppData.userToken}',
          '$messagePageNumber',
          event.userId??"",
          event.roomId??"");

      roomId = response.roomId.toString();
      await postService.updateReadStatus(
          'Bearer ${AppData.userToken}',
          event.userId ?? "", roomId ?? event.roomId??'');
      print(roomId);
      messageNumberOfPage = response.lastPage ?? 0;
      if (messagePageNumber < messageNumberOfPage + 1) {
        messagePageNumber = messagePageNumber + 1;
        if (event.page == 0) {
          // messagesList.addAll(response.messages ?? []);
          messagesList = response.messages ?? [];
          // addUserIfNotExists(messagesList, response.messages ?? []);
          // messagesList.addAll(response.messages ?? []);
          // messagesList=messagesList.reversed.toList();
        } else {
          messagesList.addAll(response.messages ?? []);
        }
      }
      log("response ${response.toJson()}");
      emit(PaginationLoadedState());
    } catch (e) {
      print('eee$e');

      emit(PaginationLoadedState());

      // emit(DataError('An error occurred $e'));
    }
  }

  Future<SendMessageModel> _sendMessageWithFile({
    required String token,
    required String userId,
    required String roomId,
    required String receiverId,
    required String attachmentType,
    required String message,
    required String filePath,
  }) async {
    try {
      // Check if file exists before uploading
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist: $filePath');
      }
      
      final fileSize = await file.length();
      print("=== FILE VALIDATION ===");
      print("File exists: true");
      print("File size: $fileSize bytes");
      print("File can read: ${file.existsSync()}");
      print("====================");
      
      final Dio dio = Dio();
      
      // Add interceptor for debugging
      dio.interceptors.add(LogInterceptor(
        request: true,
        requestBody: false, // Don't log body to avoid huge logs
        responseBody: true,
        requestHeader: true,
        responseHeader: true,
      ));
      
      // Create FormData for file upload
      final String fileName = filePath.split('/').last;
      
      final formData = FormData.fromMap({
        'user_id': userId,
        'room_id': roomId,
        'receiver_id': receiverId,
        'attachment_type': attachmentType,
        'message': message,
        'file': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
      });
      
      print("=== SENDING FILE UPLOAD REQUEST ===");
      print("URL: https://doctak.net/api/v1/send-message");
      print("File path: $filePath");
      print("File name: $fileName");
      print("Attachment type: $attachmentType");
      print("Message: $message");
      
      // Log FormData fields
      print("FormData fields:");
      formData.fields.forEach((field) {
        print("  ${field.key}: ${field.value}");
      });
      print("FormData files: ${formData.files.length}");
      if (formData.files.isNotEmpty) {
        for (var file in formData.files) {
          print("  File field: ${file.key}");
          print("  File name: ${file.value.filename}");
          print("  File length: ${file.value.length}");
          print("  Content type: ${file.value.contentType}");
        }
      }
      
      final response = await dio.post(
        'https://doctak.net/api/v1/send-message',
        data: formData,
        options: Options(
          headers: {
            'Authorization': token,
            'Accept': 'application/json',
          },
        ),
      );
      
      print("=== RAW API RESPONSE ===");
      print("Status code: ${response.statusCode}");
      print("Response data: ${response.data}");
      print("=======================");
      
      return SendMessageModel.fromJson(response.data);
    } catch (e) {
      print('Error in custom file upload: $e');
      rethrow;
    }
  }

  _onSendMessages(SendMessageEvent event, Emitter<ChatState> emit) async {
    print(event.roomId);
    print(event.userId);
    print(event.receiverId);
    print(event.message);
    print(event.file);
    print(event.attachmentType);
    
    try {
      print("Processing file: ${event.file}");
      SendMessageModel response;
      
      if (event.file != null && event.file!.isNotEmpty) {
        // Check if file exists
        final File file = File(event.file!);
        if (await file.exists()) {
          final fileSize = await file.length();
          print("=== FILE DETAILS ===");
          print("File path: ${file.path}");
          print("File size: $fileSize bytes");
          print("Attachment type: ${event.attachmentType}");
          print("===================");
          
          // Emit uploading state
          emit(FileUploadingState());
          
          // Try using the original API service method
          try {
            response = await postService.sendMessage(
              'Bearer ${AppData.userToken}',
              event.userId ?? '',
              event.roomId ?? '',
              event.receiverId ?? '',
              event.attachmentType ?? '',
              event.message ?? '',
              file.path,
            );
          } catch (originalApiError) {
            print("Original API failed: $originalApiError");
            print("Falling back to custom method...");
            
            // Fallback to custom method if original fails
            response = await _sendMessageWithFile(
              token: 'Bearer ${AppData.userToken}',
              userId: event.userId ?? '',
              roomId: event.roomId ?? '',
              receiverId: event.receiverId ?? '',
              attachmentType: event.attachmentType ?? '',
              message: event.message ?? '',
              filePath: file.path,
            );
          }
          
          print("=== FILE UPLOAD RESPONSE ===");
          print("Response body: ${response.body}");
          print("Response attachment: ${response.attachment}");
          print("Response attachmentType: ${response.attachmentType}");
          print("Response userId: ${response.userId}");
          print("==========================");
          
          // Emit uploaded state
          emit(FileUploadedState());
        } else {
          print("File does not exist: ${event.file}");
          // Send without file if file doesn't exist
          response = await postService.sendMessageWithoutFile(
            'Bearer ${AppData.userToken}',
            event.userId!,
            event.roomId!,
            event.receiverId!,
            event.attachmentType!,
            'File upload failed - file not found',
          );
        }
      } else {
        // For text messages, show a brief loading state
        if (event.attachmentType == 'text') {
          emit(FileUploadingState());
        }
        
        response = await postService.sendMessageWithoutFile(
          'Bearer ${AppData.userToken}',
          event.userId!,
          event.roomId!,
          event.receiverId!,
          event.attachmentType!,
          event.message!,
        );
        
        if (event.attachmentType == 'text') {
          emit(FileUploadedState());
        }
      }
      
      messagesList.insert(
          0,
          Messages(
            id: DateTime.now().millisecondsSinceEpoch.toString(), // Generate temporary ID
            userId: response.userId!,
            profile: response.profile,
            body: response.body,
            attachment: response.attachment,
            attachmentType: response.attachmentType,
            createdAt: response.createdAt,
            seen: 0,
          ));
      // Force rebuild by emitting a different state first
      emit(PaginationLoadingState());
      // Then emit the loaded state to trigger UI update
      emit(PaginationLoadedState());

    } catch (e) {
      print('Error sending message: $e');

      // Emit upload finished state on error
      emit(FileUploadedState());

      // Don't show error message for file uploads - just log it
      if (event.file == null || event.file!.isEmpty) {
        // Only show error for text messages
        messagesList.insert(
            0,
            Messages(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              userId: AppData.logInUserId,
              profile: '',
              body: 'Failed to send message: ${e.toString()}',
              attachment: '',
              attachmentType: 'text',
              createdAt: DateTime.now().toIso8601String(),
              seen: 0,
            ));
      }

      emit(PaginationLoadedState());
    }
  }

  _onDeleteMessages(DeleteMessageEvent event, Emitter<ChatState> emit) async {
    // try {

    await postService.deleteMessage(
      'Bearer ${AppData.userToken}',
      event.id ?? '',
    );
    print(event.id);
    messagesList.removeWhere((message) => message.id == event.id);
    showToast('Message deleted');
    // print("hello${response.toJson()}");
    emit(PaginationLoadedState());

    // emit(DataLoaded(contactsList));
    // } catch (e) {
    //   print(e);
    //
    //   emit(PaginationLoadedState());
    //
    //   // emit(DataError('An error occurred $e'));
    // }
  }

  _selectedFile(SelectedFiles event, Emitter<ChatState> emit) async {
    if (event.isRemove) {
      imagefiles.remove(event.pickedfiles);
      emit(PaginationLoadedState());
    } else {
      imagefiles.add(event.pickedfiles);
      // print(imagefiles);
      emit(PaginationLoadedState());
    }
    // emit(DataLoaded(searchPeopleData));
  }
}
