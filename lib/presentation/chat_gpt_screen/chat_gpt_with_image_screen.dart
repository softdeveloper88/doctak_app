import 'dart:async';
import 'dart:io';

import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/data/models/chat_gpt_model/ChatGPTResponse.dart';
import 'package:doctak_app/data/models/chat_gpt_model/ChatGPTSessionModel.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/main.dart';
import 'package:doctak_app/presentation/chat_gpt_screen/bloc/chat_gpt_bloc.dart';
import 'package:doctak_app/presentation/chat_gpt_screen/bloc/chat_gpt_event.dart';
import 'package:doctak_app/presentation/chat_gpt_screen/bloc/chat_gpt_state.dart';
import 'package:doctak_app/presentation/chat_gpt_screen/chat_history_screen.dart';
import 'package:doctak_app/presentation/chat_gpt_screen/widgets/chat_bubble.dart';
import 'package:doctak_app/presentation/chat_gpt_screen/widgets/typing_indicators.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:doctak_app/widgets/toast_widget.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:sizer/sizer.dart';

import '../../data/models/chat_gpt_model/chat_gpt_message_history/chat_gpt_message_history.dart';
import '../../widgets/image_upload_widget/bloc/image_upload_bloc.dart';
import '../../widgets/image_upload_widget/bloc/image_upload_event.dart';
import '../../widgets/image_upload_widget/bloc/image_upload_state.dart';
import '../../widgets/image_upload_widget/multiple_image_upload_widget.dart';
import '../../widgets/shimmer_widget/chat_shimmer_loader.dart';

@immutable
class ChatGptWithImageScreen extends StatefulWidget {
  bool isFromMainScreen;
  String? question;

  ChatGptWithImageScreen(
      {super.key, this.isFromMainScreen = true, this.question});

  @override
  ChatGPTScreenState createState() => ChatGPTScreenState();
}

class ChatGPTScreenState extends State<ChatGptWithImageScreen> {
  final ScrollController _scrollController = ScrollController();
  List<ChatGPTResponse> messages = [];
  late Future<List<Session>> futureSessions;
  int? selectedSessionId = 0;
  Future<List<ChatGPTResponse>> futureMessages = Future.value([]);
  final TextEditingController textController = TextEditingController();
  bool isLoadingMessages = true;
  bool isEmptyPage = true;
  bool isDrawerOpen = false;
  bool isWriting = false;
  String chatWithAi = "Preparing DocTak AI.";
  bool isDeleteButtonClicked = false;
  bool isAlreadyAsk = true;
  bool isEmpty = false;
  bool isOneTimeImageUploaded = false;
  bool isError = false;
  FocusNode focusNode = FocusNode();
  String imageType = '';
  List<XFile> selectedImageFiles = [];
  ImageUploadBloc imageUploadBloc = ImageUploadBloc();

  @override
  void initState() {
    super.initState();
    // Initialize the ChatGPT bloc with LoadDataValues event
    BlocProvider.of<ChatGPTBloc>(context).add(LoadDataValues());
  }

  void drugsAskQuestion(state1, context) {
    String question = widget.question ?? "";
    if (question.isEmpty) return;

    var myMessage = Messages(
        id: -1,
        gptSessionId: selectedSessionId.toString(),
        question: question,
        response: translation(context).lbl_generating_response,
        createdAt: DateTime.now().toString(),
        updatedAt: DateTime.now().toString());

    state1.response1.messages!.add(myMessage);

    BlocProvider.of<ChatGPTBloc>(context).add(
      GetPost(
        sessionId: selectedSessionId.toString(),
        question: question,
      ),
    );
    textController.clear();
    scrollToBottom();
    
    try {
      isWriting = false;
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (chatWithAi == "Preparing DocTak AI.") {
      chatWithAi = translation(context).lbl_preparing_ai;
    }
  }

  @override
  void dispose() {
    focusNode.unfocus();
    _scrollController.dispose();
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: svGetBgColor(),
      appBar: DoctakAppBar(
        title: "AI Image Analysis",
        titleIcon: Icons.image_search_rounded,
        actions: [
          // History button
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 36,
            ),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history_rounded,
                color: Colors.blue[600],
                size: 16,
              ),
            ),
            onPressed: () {
              ChatHistoryScreen(
                onNewSessionTap: () {
                  try {
                    BlocProvider.of<ChatGPTBloc>(context).add(GetNewChat());
                    Navigator.of(context).pop();
                    isOneTimeImageUploaded = false;
                    selectedSessionId = BlocProvider.of<ChatGPTBloc>(context).newChatSessionId;
                  } catch (e) {
                    print(e);
                  }
                },
                onTap: (session) {
                  isError = true;
                  chatWithAi = session.name!;
                  isEmptyPage = false;
                  selectedSessionId = session.id;
                  isLoadingMessages = true;
                  isOneTimeImageUploaded = true;
                  BlocProvider.of<ChatGPTBloc>(context).add(
                    GetMessages(sessionId: selectedSessionId.toString()),
                  );
                  Navigator.of(context).pop();
                },
              ).launch(context);
            },
          ),
          // New Analysis button
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(

                      Icons.add_photo_alternate_rounded,
                      color: Colors.blue[600],
                      size: 16,
                    ),
                  ),
                  onPressed: () {
                    isOneTimeImageUploaded = false;
                    try {
                      BlocProvider.of<ChatGPTBloc>(context).add(GetNewChat());
                      selectedSessionId = BlocProvider.of<ChatGPTBloc>(context).newChatSessionId;
                    } catch (e) {
                      print(e);
                    }
                  },
                ),
              ),
            ],
          ),
      body: BlocBuilder<ChatGPTBloc, ChatGPTState>(
              builder: (context, state1) {
                  if (selectedSessionId == 0 && state1 is DataLoaded) {
                    selectedSessionId = state1.response.newSessionId;
                    chatWithAi = state1.response.sessions?.first.name ?? translation(context).lbl_preparing_ai;
                  } else if (state1 is DataError) {
                    showToast(translation(context).msg_something_wrong);
                    if (isError) {
                      try {
                        BlocProvider.of<ChatGPTBloc>(context).add(GetNewChat());
                        isOneTimeImageUploaded = false;
                        isError = false;
                        selectedSessionId = BlocProvider.of<ChatGPTBloc>(context).newChatSessionId;
                      } catch (e) {
                        // Error logging suppressed
                      }
                    }
                  }
                  
                  if (state1 is DataInitial || state1 is DataLoading) {
                    return ChatShimmerLoader();
                  } else if (state1 is DataLoaded) {
                    // Check if messages exist and are not null
                    isEmpty = state1.response1.messages?.isEmpty ?? true;
                    
                    if (!widget.isFromMainScreen) {
                      if (isAlreadyAsk) {
                        setState(() {
                          isEmpty = false;
                        });
                        isAlreadyAsk = false;
                        drugsAskQuestion(state1, context);
                      }
                    }
                    
                    return Column(
                      children: [
                        if (isEmpty)
                          Expanded(
                            child: Container(
                              color: svGetScaffoldColor(),
                              child: SafeArea(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      const SizedBox(height: 20),
                                      
                                      // Hero Icon - simplified
                                      Container(
                                        width: 80,
                                        height: 80,
                                        margin: const EdgeInsets.only(bottom: 20),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[600],
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.blue.withOpacity(0.3),
                                              spreadRadius: 2,
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.image_search_rounded,
                                            color: Colors.white,
                                            size: 40,
                                          ),
                                        ),
                                      ),
                                      
                                      // Welcome Text
                                      Text(
                                        translation(context).lbl_welcome_doctor,
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Poppins',
                                          letterSpacing: 0.5,
                                          color: appStore.isDarkMode ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      
                                      // Description
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Text(
                                          "Upload medical images for AI-powered analysis and insights",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontFamily: 'Poppins',
                                            height: 1.5,
                                            color: appStore.isDarkMode 
                                                ? Colors.white70
                                                : Colors.black.withAlpha(179),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      
                                      // Upload Section
                                      Text(
                                        "Select Medical Image Type",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Poppins',
                                          color: Colors.blue[800],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      
                                      // Upload Button - simplified
                                      Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(24),
                                          color: Colors.blue[600],
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.blue.withOpacity(0.3),
                                              offset: const Offset(0, 4),
                                              blurRadius: 12,
                                              spreadRadius: 0,
                                            ),
                                          ],
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(24),
                                            onTap: () async {
                                              if (isOneTimeImageUploaded) {
                                                toasty(context, translation(context).lbl_only_one_image_allowed);
                                              } else {
                                                const permission = Permission.photos;
                                                if (await permission.isGranted) {
                                                  _showBeforeFileOptions();
                                                } else if (await permission.isDenied) {
                                                  final result = await permission.request();
                                                  if (result.isGranted) {
                                                    _showBeforeFileOptions();
                                                  } else if (result.isPermanentlyDenied) {
                                                    _showBeforeFileOptions();
                                                  }
                                                } else if (await permission.isPermanentlyDenied) {
                                                  _permissionDialog();
                                                }
                                              }
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.all(6),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withOpacity(0.2),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.add_photo_alternate_rounded, 
                                                      color: Colors.white,
                                                      size: 24
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Text(
                                                    translation(context).lbl_medical_images,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w600,
                                                      fontFamily: 'Poppins',
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 20),
                                      
                                      // Info Container - simplified
                                      Container(
                                        decoration: BoxDecoration(
                                          color: appStore.isDarkMode
                                              ? Colors.blue.withOpacity(0.1)
                                              : Colors.blue.withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: Colors.blue.withOpacity(0.2),
                                            width: 1.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.blue.withOpacity(0.05),
                                              offset: const Offset(0, 2),
                                              blurRadius: 8,
                                              spreadRadius: 0,
                                            ),
                                          ],
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.amber.withOpacity(0.2),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.lightbulb_rounded,
                                                color: Colors.amber[700],
                                                size: 16,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                translation(context).msg_upload_images_prompt,
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.blue[800],
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
                            ),
                          )
                        else
                          Expanded(
                            child: Container(
                              color: svGetScaffoldColor(),
                              child: ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(12),
                                itemCount: state1.response1.messages?.length,
                                itemBuilder: (context, index) {
                                  Messages message = state1.response1.messages?[index] ?? Messages();
                                  return Column(
                                    children: [
                                      ChatBubble(
                                        text: message.question ?? '',
                                        isUserMessage: true,
                                        imageUrl1: index != 0
                                            ? null
                                            : selectedImageFiles.isNotEmpty
                                                ? File(selectedImageFiles.first.path)
                                                : null,
                                        imageUrl2: index != 0
                                            ? null
                                            : selectedImageFiles.isNotEmpty
                                                ? selectedImageFiles.length == 2
                                                    ? File(selectedImageFiles.last.path)
                                                    : null
                                                : null,
                                        responseImageUrl1: index != 0 ? '' : message.imageUrl1 ?? '',
                                        responseImageUrl2: index != 0 ? '' : message.imageUrl2 ?? '',
                                      ),
                                      ChatBubble(
                                        text: message.response ?? "",
                                        isUserMessage: false,
                                        imageUrl1: selectedImageFiles.isNotEmpty
                                            ? File(selectedImageFiles.first.path)
                                            : null,
                                        imageUrl2: selectedImageFiles.isNotEmpty
                                            ? selectedImageFiles.length == 2
                                                ? File(selectedImageFiles.last.path)
                                                : null
                                            : null,
                                        responseImageUrl1: message.imageUrl1 ?? '',
                                        responseImageUrl2: message.imageUrl2 ?? '',
                                        onTapReginarate: () {
                                          String question = message.question ?? "";
                                          if (question.isEmpty) return;
                                          
                                          setState(() {
                                            var myMessage = Messages(
                                                id: -1,
                                                gptSessionId: selectedSessionId.toString(),
                                                question: question,
                                                imageUrl1: message.imageUrl1,
                                                imageUrl2: message.imageUrl2,
                                                response: translation(context).lbl_generating_response,
                                                createdAt: DateTime.now().toString(),
                                                updatedAt: DateTime.now().toString());
                                            state1.response1.messages!.add(myMessage);
                                            BlocProvider.of<ChatGPTBloc>(context).add(
                                              GetPost(
                                                sessionId: selectedSessionId.toString(),
                                                question: question,
                                              ),
                                            );
                                            textController.clear();
                                            scrollToBottom();
                                          });
                                          
                                          try {
                                            isWriting = false;
                                          } catch (e) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Error: $e')));
                                          }
                                        },
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        
                        // Image Preview Section - redesigned
                        _buildImagePreview(),
                        
                        // Input Section - completely redesigned using drugs_list pattern
                        Container(
                          decoration: BoxDecoration(
                            color: svGetScaffoldColor(),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withAlpha(13),
                                offset: const Offset(0, -3),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: appStore.isDarkMode
                                      ? Colors.blueGrey[800]
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(24.0),
                                  border: Border.all(
                                    color: Colors.blue.withOpacity(0.2),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.05),
                                      offset: const Offset(0, 2),
                                      blurRadius: 8,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // Attachment button
                                    IconButton(
                                      icon: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.attach_file_rounded,
                                          color: Colors.blue[600],
                                          size: 20,
                                        ),
                                      ),
                                      onPressed: () async {
                                        if (isOneTimeImageUploaded) {
                                          toasty(context, 'Only allowed one time image in one session');
                                        } else {
                                          const permission = Permission.photos;
                                          var status = await Permission.storage.request();
                                          if (status.isGranted || await permission.isGranted) {
                                            _showBeforeFileOptions();
                                          } else if (await permission.isDenied) {
                                            final result = await permission.request();
                                            if (result.isGranted) {
                                              _showBeforeFileOptions();
                                            } else if (result.isPermanentlyDenied) {
                                              _showBeforeFileOptions();
                                            }
                                          } else if (await permission.isPermanentlyDenied) {
                                            _permissionDialog();
                                          }
                                        }
                                      },
                                    ),
                                    
                                    // Text input
                                    Expanded(
                                      child: TextField(
                                        focusNode: focusNode,
                                        controller: textController,
                                        minLines: 1,
                                        maxLines: 4,
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 14,
                                          color: appStore.isDarkMode 
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                        decoration: InputDecoration(
                                          hintStyle: TextStyle(
                                            color: appStore.isDarkMode
                                                ? Colors.white60
                                                : Colors.black54,
                                            fontFamily: 'Poppins',
                                          ),
                                          hintText: translation(context).msg_clinical_summary_hint,
                                          border: InputBorder.none,
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 8.0, 
                                            vertical: 16.0
                                          ),
                                        ),
                                      ),
                                    ),
                                    
                                    // Send button
                                    Container(
                                      margin: const EdgeInsets.only(right: 8.0),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.blue[600],
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.blue.withOpacity(0.3),
                                            offset: const Offset(0, 2),
                                            blurRadius: 8,
                                            spreadRadius: 0,
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(30),
                                          onTap: () async {
                                            isError = true;
                                            focusNode.unfocus();
                                            
                                            if (selectedImageFiles.isEmpty) {
                                              return;
                                            } else if (imageUploadBloc.imagefiles.isEmpty && isOneTimeImageUploaded) {
                                              String question = textController.text.trim();
                                              if (question != '') {
                                                setState(() {
                                                  isOneTimeImageUploaded = true;
                                                  var myMessage = Messages(
                                                    id: -1,
                                                    gptSessionId: selectedSessionId.toString(),
                                                    question: question,
                                                    response: translation(context).lbl_generating_response,
                                                    createdAt: DateTime.now().toString(),
                                                    updatedAt: DateTime.now().toString(),
                                                    imageUrl1: '',
                                                    imageUrl2: '',
                                                  );
                                                  state1.response1.messages!.add(myMessage);

                                                  BlocProvider.of<ChatGPTBloc>(context).add(
                                                    GetPost(
                                                        sessionId: selectedSessionId.toString(),
                                                        question: question,
                                                        imageUrl1: null,
                                                        imageUrl2: null,
                                                        imageType: imageType),
                                                  );
                                                  imageUploadBloc.imagefiles.clear();
                                                  textController.clear();
                                                  scrollToBottom();
                                                });

                                                try {
                                                  isWriting = false;
                                                } catch (e) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text('Error: $e')));
                                                }
                                              } else {
                                                toasty(context, translation(context).lbl_please_ask_question);
                                              }
                                            } else if (imageUploadBloc.imagefiles.isNotEmpty && !isOneTimeImageUploaded) {
                                              String question = textController.text.trim();
                                              setState(() {
                                                isOneTimeImageUploaded = true;
                                                var myMessage = Messages(
                                                  id: -1,
                                                  gptSessionId: selectedSessionId.toString(),
                                                  question: question,
                                                  response: translation(context).lbl_generating_response,
                                                  createdAt: DateTime.now().toString(),
                                                  updatedAt: DateTime.now().toString(),
                                                  imageUrl1: imageUploadBloc.imagefiles.first.path,
                                                  imageUrl2: imageUploadBloc.imagefiles.first.path,
                                                );
                                                state1.response1.messages!.add(myMessage);

                                                BlocProvider.of<ChatGPTBloc>(context).add(
                                                  GetPost(
                                                      sessionId: selectedSessionId.toString(),
                                                      question: question == ""
                                                          ? translation(context).lbl_analyse_image
                                                          : question,
                                                      imageUrl1: imageUploadBloc.imagefiles.first.path,
                                                      imageUrl2: imageUploadBloc.imagefiles.last.path,
                                                      imageType: imageType),
                                                );
                                                imageUploadBloc.imagefiles.clear();
                                                textController.clear();
                                                scrollToBottom();
                                              });
                                              try {
                                                isWriting = false;
                                              } catch (e) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text('Error: $e')));
                                              }
                                            }
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: isWriting
                                              ? const TypingIndicators(
                                                  color: Colors.white,
                                                  size: 3.0,
                                                )
                                              : const Icon(
                                                  Icons.send_rounded,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                translation(context).msg_ai_disclaimer,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  } else if (state1 is DataError) {
                    return _buildErrorState(context, state1.errorMessage.toString());
                  } else {
                    return Text(translation(context).lbl_error);
                  }
                }
              ),
    );
  }

  // Image Preview Widget - redesigned using drugs_list pattern
  Widget _buildImagePreview() {
    return Container(
      color: svGetScaffoldColor(),
      child: BlocBuilder<ImageUploadBloc, ImageUploadState>(
          bloc: imageUploadBloc,
          builder: (context, state) {
        if (state is FileLoadedState && imageUploadBloc.imagefiles.isNotEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: imageUploadBloc.imagefiles.map((imageone) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.2),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: buildMediaItem(File(imageone.path)),
                        ),
                      ),
                      Positioned(
                        top: -4,
                        right: -4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {});
                            selectedImageFiles.remove(imageone);
                            imageUploadBloc.add(SelectedFiles(
                                pickedfiles: imageone, isRemove: true));
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red[500],
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withAlpha(77),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          );
        } else {
          return Container();
        }
      }),
    );
  }

  // Error State Widget - redesigned using drugs_list pattern
  Widget _buildErrorState(BuildContext context, String errorMessage) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              color: Colors.red[600],
              size: 30,
            ),
          ),
          Text(
            translation(context).lbl_error,
            style: TextStyle(
              color: Colors.red[700],
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: appStore.isDarkMode ? Colors.white70 : Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withAlpha(51),
                  offset: const Offset(0, 4),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                try {
                  BlocProvider.of<ChatGPTBloc>(context).add(GetNewChat());
                  isOneTimeImageUploaded = false;
                  selectedSessionId = BlocProvider.of<ChatGPTBloc>(context).newChatSessionId;
                } catch (e) {
                  debugPrint(e.toString());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                translation(context).lbl_try_again,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // File Options Dialog - redesigned using drugs_list pattern  
  void _showBeforeFileOptions() {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: appStore.isDarkMode ? Colors.grey[850] : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withAlpha(26),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue[600],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.medical_services_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            translation(context).lbl_select_option,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Poppins',
                              color: appStore.isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            'Choose medical image type for AI analysis',
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Poppins',
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Options Grid
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildAdvancedOption(
                            icon: Icons.face_retouching_natural,
                            color: Colors.pink[600]!,
                            title: 'Dermatological',
                            subtitle: 'Skin analysis',
                            onTap: () {
                              Navigator.pop(context);
                              imageType = 'Dermatological';
                              _showFileOptions();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildAdvancedOption(
                            icon: Icons.medical_services,
                            color: Colors.blue[600]!,
                            title: 'X-Ray',
                            subtitle: 'Radiograph scan',
                            onTap: () {
                              Navigator.pop(context);
                              imageType = 'X-ray';
                              _showFileOptions();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildAdvancedOption(
                            icon: Icons.scanner,
                            color: Colors.blue[600]!,
                            title: 'CT Scan',
                            subtitle: 'Tomography',
                            onTap: () {
                              Navigator.pop(context);
                              imageType = 'CT Scan';
                              _showFileOptions();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildAdvancedOption(
                            icon: Icons.document_scanner_sharp,
                            color: Colors.teal[600]!,
                            title: 'MRI',
                            subtitle: 'Magnetic scan',
                            onTap: () {
                              Navigator.pop(context);
                              imageType = 'MRI Scan';
                              _showFileOptions();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildAdvancedOption(
                      icon: Icons.medical_information,
                      color: Colors.orange[600]!,
                      title: 'Mammography',
                      subtitle: 'Breast tissue analysis',
                      fullWidth: true,
                      onTap: () {
                        Navigator.pop(context);
                        imageType = 'Mammography';
                        _showFileOptions();
                      },
                    ),
                  ],
                ),
              ),
              SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'AI-powered medical image analysis',
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'Poppins',
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAdvancedOption({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool fullWidth = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: appStore.isDarkMode ? Colors.grey[800] : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                  color: appStore.isDarkMode ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'Poppins',
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFileOptions() {
    int imageLimit = 0;
    if (imageType == 'X-ray' || imageType == 'Mammography') {
      imageLimit = 2;
    } else {
      imageLimit = 1;
    }
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: appStore.isDarkMode ? Colors.grey[900] : Colors.grey[50],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(26),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Upload area
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: appStore.isDarkMode
                                  ? Colors.grey[850]
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.blue.withAlpha(26),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withAlpha(13),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: MultipleImageUploadWidget(
                              imageType: imageType,
                              imageUploadBloc,
                              imageLimit: imageLimit, (imageFiles) {
                                selectedImageFiles = imageFiles;
                                setState(() {});
                                Navigator.pop(context);
                              }
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _permissionDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            translation(context).msg_something_wrong,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(translation(context).lbl_cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(translation(context).lbl_try_again),
              onPressed: () {
                openAppSettings();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
    });
  }
}