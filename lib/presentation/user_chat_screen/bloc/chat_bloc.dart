import 'dart:math';

import 'package:dio/dio.dart';
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
        var response1 = await postService.updateReadStatus(
            'Bearer ${AppData.userToken}',
            event.userId ?? "", event.roomId ?? '');
        print('response1 $response1');
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
      var response1 = await postService.updateReadStatus(
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
      emit(PaginationLoadedState());
    } catch (e) {
      print('eee$e');

      emit(PaginationLoadedState());

      // emit(DataError('An error occurred $e'));
    }
  }

  _onSendMessages(SendMessageEvent event, Emitter<ChatState> emit) async {
    print(event.roomId);
    print(event.userId);
    print(event.receiverId);
    print(event.message);
    print(event.file);
    print(event.attachmentType);
    // try {
    print("hii${event.file}");
    SendMessageModel response;
    if (event.file != '') {
      response = await postService.sendMessage(
        'Bearer ${AppData.userToken}',
        event.userId ?? '',
        event.roomId ?? '',
        event.receiverId ?? '',
        event.attachmentType ?? '',
        event.message ?? '',
        event.file ?? '',
      );
      print("hii_file${response.body}");
    } else {
      response = await postService.sendMessageWithoutFile(
        'Bearer ${AppData.userToken}',
        event.userId!,
        event.roomId!,
        event.receiverId!,
        event.attachmentType!,
        event.message!,
      );
    }
    messagesList.insert(
        0,
        Messages(
          userId: response.userId!,
          profile: response.profile,
          body: response.body,
          attachment: response.attachment,
          attachmentType: response.attachmentType,
          createdAt: response.createdAt,
        ));
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

  _onDeleteMessages(DeleteMessageEvent event, Emitter<ChatState> emit) async {
    // try {

    var response1 = await postService.deleteMessage(
      'Bearer ${AppData.userToken}',
      event.id ?? '',
    );
    print(event.id);
    print(response1.data);
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
