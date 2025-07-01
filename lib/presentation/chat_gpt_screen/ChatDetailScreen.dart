import 'dart:async';

import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/data/models/chat_gpt_model/ChatGPTResponse.dart';
import 'package:doctak_app/data/models/chat_gpt_model/ChatGPTSessionModel.dart';
import 'package:doctak_app/main.dart';
import 'package:doctak_app/presentation/chat_gpt_screen/bloc/chat_gpt_bloc.dart';
import 'package:doctak_app/presentation/chat_gpt_screen/bloc/chat_gpt_event.dart';
import 'package:doctak_app/presentation/chat_gpt_screen/bloc/chat_gpt_state.dart';
import 'package:doctak_app/presentation/chat_gpt_screen/chat_history_screen.dart';
import 'package:doctak_app/presentation/chat_gpt_screen/widgets/chat_bubble.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/widgets/AnimatedBackground.dart';
import 'package:doctak_app/widgets/shimmer_widget/chat_shimmer_loader.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:sizer/sizer.dart';

import '../../data/models/chat_gpt_model/chat_gpt_message_history/chat_gpt_message_history.dart';
import 'widgets/card_intro.dart';
import 'widgets/typing_indicators.dart';

class ChatDetailScreen extends StatefulWidget {
  bool isFromMainScreen;
  String? question;

  ChatDetailScreen({super.key, this.isFromMainScreen = true, this.question});

  @override
  _ChatGPTScreenState createState() => _ChatGPTScreenState();
}

class _ChatGPTScreenState extends State<ChatDetailScreen> {
  // ... (existing variables)

  final ScrollController _scrollController = ScrollController();

  List<ChatGPTResponse> messages = []; // Add this line

  late Future<List<Session>> futureSessions;
  int? selectedSessionId = 0; // State variable for tracking selected session
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
  FocusNode focusNode = FocusNode();

  void drugsAskQuestion(state1, context) {
    String question = widget.question ?? "";
    if (question.isEmpty) return;

    // String sessionId = selectedSessionId.toString();
    // var tempId =
    //     -1; // Unique temporary ID for the response
    print('object');
    // setState(() {
    var myMessage = Messages(
        id: -1,
        gptSessionId: selectedSessionId.toString(),
        question: question,
        response: 'Generating response...',
        createdAt: DateTime.now().toString(),
        updatedAt: DateTime.now().toString());

    state1.response1.messages!.add(myMessage);

    BlocProvider.of<ChatGPTBloc>(context).add(
      GetPost(
        sessionId: selectedSessionId.toString(),
        question: question, // replace with real input
      ),
    );
    textController.clear();
    scrollToBottom();
    // });
    try {
      isWriting = false;
      // });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
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
    return BlocProvider(
        create: (context) => ChatGPTBloc()..add(LoadDataValues()),
        child:
            BlocBuilder<ChatGPTBloc, ChatGPTState>(builder: (context, state1) {
          if (selectedSessionId == 0 && state1 is DataLoaded) {
            selectedSessionId = state1.response.newSessionId;
            chatWithAi = state1.response.sessions?.first.name ?? 'Next Session';
          }
          if (state1 is DataInitial) {
            return Scaffold(
              body: AnimatedBackground(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    SizedBox(
                        height: 80.h,
                        child: ChatShimmerLoader())
                    // Center(
                    //     child: CircularProgressIndicator(
                    //   color: svGetBodyColor(),
                    // )),
                  ],
                ),
              ),
            );
          } else if (state1 is DataLoaded) {
            print('response ${state1.response.toString()}');
            
            // Handle drugs list prompts first
            if (!widget.isFromMainScreen && (widget.question?.isNotEmpty ?? false)) {
              // Always show chat UI for drug questions
              isEmpty = false;
              
              if (isAlreadyAsk  ) {
                print('🔥 Executing drug question: "${widget.question}"');
                // hasExecutedQuestion = true;
                isAlreadyAsk = false;
                drugsAskQuestion(state1, context);
              }
            } else {
              // Default behavior for main screen
              isEmpty = state1.response1.messages?.isEmpty ?? false;
            }
            return Scaffold(
                backgroundColor: svGetBgColor(),
                appBar: DoctakAppBar(
                  title: "DocTak AI",
                  titleIcon: Icons.psychology_rounded,
                  actions: [
                    // Chat history button
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
                              BlocProvider.of<ChatGPTBloc>(context)
                                  .add(GetNewChat());
                              Navigator.of(context).pop();

                              selectedSessionId =
                                  BlocProvider.of<ChatGPTBloc>(context)
                                      .newChatSessionId;
                            } catch (e) {
                              print(e);
                            }
                          },
                          onTap: (session) {
                            chatWithAi = session.name!;
                            isEmptyPage = false;
                            selectedSessionId = session.id;
                            isLoadingMessages = true;
                            BlocProvider.of<ChatGPTBloc>(context).add(
                              GetMessages(sessionId: selectedSessionId.toString()),
                            );
                            Navigator.of(context).pop();
                          },
                        ).launch(context);
                      },
                    ),
                    // New session button
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
                            color: Colors.green.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add,
                            color: Colors.green[600],
                            size: 16,
                          ),
                        ),
                        onPressed: () {
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
                body: Column(
                  children: [
                    // const SizedBox(height: 10,),
                    if (isEmpty)
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: appStore.isDarkMode
                                  ? [Colors.blueGrey[900]!, Colors.blueGrey[800]!]
                                  : [Colors.white, Colors.blue.withAlpha(13)],
                            ),
                          ),
                          child: SafeArea(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 40),
                                  
                                  // Hero Icon - redesigned
                                  Container(
                                    width: 120,
                                    height: 120,
                                    margin: const EdgeInsets.only(bottom: 32),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [Colors.blue[400]!, Colors.blue[700]!],
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blue.withAlpha(77),
                                          spreadRadius: 3,
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.psychology_rounded,
                                        color: Colors.white,
                                        size: 60,
                                      ),
                                    ),
                                  ),
                                  
                                  // Welcome Text
                                  Text(
                                    'Welcome, Doctor!',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Poppins',
                                      color: appStore.isDarkMode ? Colors.white : Colors.blue[900],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Your AI-powered medical assistant is ready to help with diagnostics, treatments, and medical insights.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'Poppins',
                                      color: appStore.isDarkMode ? Colors.grey[300] : Colors.grey[600],
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  
                                  // Modern suggestion cards
                                  GridView.count(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 1.2,
                                    children: [
                                      _buildSuggestionCard(
                                        'Code Detection',
                                        'Identify CPT or ICD codes',
                                        Icons.code_rounded,
                                        Colors.purple,
                                        () => _executeSuggestion('Code Detection: Identify CPT or ICD codes', state1, context),
                                      ),
                                      _buildSuggestionCard(
                                        'Diagnostic Suggestions',
                                        'Based on symptoms',
                                        Icons.medical_information_rounded,
                                        Colors.green,
                                        () => _executeSuggestion('Diagnostic Suggestions: Request suggestions based on symptoms', state1, context),
                                      ),
                                      _buildSuggestionCard(
                                        'Drug Information',
                                        'Dosage & interactions',
                                        Icons.medication_rounded,
                                        Colors.orange,
                                        () => _executeSuggestion('Drug Information: Provide dosage and interaction details', state1, context),
                                      ),
                                      _buildSuggestionCard(
                                        'Treatment Plans',
                                        'Evidence-based care',
                                        Icons.healing_rounded,
                                        Colors.blue,
                                        () => _executeSuggestion('Treatment Plans: Suggest evidence-based treatment options', state1, context),
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 32),
                                  
                                  // Footer text
                                  Text(
                                    'Ready to start? Type your question below or choose a suggested topic.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontFamily: 'Poppins',
                                      color: appStore.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: state1.response1.messages?.length,
                          itemBuilder: (context, index) {
                            Messages message =
                                state1.response1.messages?[index] ?? Messages();
                            return Column(
                              children: [
                                ChatBubble(
                                  text: message.question ?? '',
                                  isUserMessage: true,
                                  imageUrl1: null,
                                  responseImageUrl1: message.imageUrl1 ?? '',
                                  imageUrl2: null,
                                ),
                                ChatBubble(
                                  text: message.response ?? "",
                                  isUserMessage: false,
                                  imageUrl1: null,
                                  responseImageUrl1: message.imageUrl1 ?? '',
                                  onTapReginarate: () {
                                    String question = message.question ?? "";
                                    if (question.isEmpty) return;
                                    // String sessionId = selectedSessionId.toString();
                                    // var tempId =
                                    //     -1; // Unique temporary ID for the response
                                    setState(() {
                                      var myMessage = Messages(
                                          id: -1,
                                          gptSessionId:
                                              selectedSessionId.toString(),
                                          question: question,
                                          imageUrl1: message.imageUrl1,
                                          response: 'Generating response...',
                                          createdAt: DateTime.now().toString(),
                                          updatedAt: DateTime.now().toString());
                                      state1.response1.messages!.add(myMessage);
                                      BlocProvider.of<ChatGPTBloc>(context).add(
                                        GetPost(
                                          sessionId:
                                              selectedSessionId.toString(),
                                          question: question,
                                          // imageUrl: _uploadedFile??''// replace with real input
                                        ),
                                      );
                                      textController.clear();
                                      scrollToBottom();
                                    });
                                    // // Add the temporary message (User's question)
                                    // // setState(() {
                                    // // message.add(myMessage);
                                    // // scrollToBottom();
                                    // // });
                                    //
                                    try {
                                      //   for (int i = 0; i <= state1.response2.content!.length; i++) {
                                      //     await Future.delayed(const Duration(
                                      //         milliseconds:
                                      //             100)); // Delay to simulate typing speed
                                      //
                                      //     int index = state1.response1.messages!
                                      //         .indexWhere((msg) => msg.id == -1);
                                      //     if (index != -1) {
                                      //       // Update the temporary message with gradually more characters of the response
                                      //       String typingText = state1
                                      //           .response2.content!
                                      //           .substring(0, i);
                                      //       state1.response1.messages![index] =
                                      //           Messages(
                                      //               id: -1,
                                      //               gptSessionId: state1.response.sessions!.first??'',
                                      //               question: question,
                                      //               response: typingText,
                                      //               createdAt:
                                      //                   DateTime.now().toString(),
                                      //               updatedAt: DateTime.now()
                                      //                   .toString());
                                      //       print(typingText);
                                      //       if (state1
                                      //               .response2.content!.length ==
                                      //           i) {
                                      //         state1.response1.messages![index] =
                                      //             Messages(
                                      //                 id: -1,
                                      //                 gptSessionId: state1.response.sessions!.first??'',
                                      //                 question: question,
                                      //                 response: typingText,
                                      //                 createdAt: DateTime.now()
                                      //                     .toString(),
                                      //                 updatedAt: DateTime.now()
                                      //                     .toString());
                                      //       }
                                      //     }
                                      //   }
                                      // ChatGPTResponse newMessage =
                                      //     await askQuestion(
                                      //         sessionId, question);

                                      // for (int i = 0;
                                      //     i <= state1.response2.content!.length;
                                      //     i++) {
                                      //   await Future.delayed(const Duration(
                                      //       milliseconds:
                                      //           1)); // Delay to simulate typing speed
                                      //
                                      //   // setState(() {
                                      //     int index = state1.response1.messages!.indexWhere(
                                      //         (msg) => msg.id == tempId);
                                      //     if (index != -1) {
                                      //       // Update the temporary message with gradually more characters of the response
                                      //       String typingText = state1.response2.content!.substring(0, i);
                                      //       state1.response1.messages![index] = Messages(
                                      //           id: tempId,
                                      //           gptSessionId: state1.response.sessions!.first??'',
                                      //           question: question,
                                      //           response: typingText,
                                      //           createdAt:
                                      //               DateTime.now().toString(),
                                      //           updatedAt:
                                      //               DateTime.now().toString());
                                      //       if (state1.response2.content!.length ==
                                      //           i) {
                                      //         state1.response1.messages![index] = Messages(
                                      //             id: -1,
                                      //             gptSessionId: state1.response.sessions!.first??'',
                                      //             question: question,
                                      //             response: typingText,
                                      //             createdAt:
                                      //                 DateTime.now().toString(),
                                      //             updatedAt: DateTime.now()
                                      //                 .toString());
                                      //       }
                                      //     }
                                      //   // });
                                      //   scrollToBottom();
                                      // }
                                      // setState(() {
                                      isWriting = false;
                                      // });
                                    } catch (e) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              content: Text('Error: $e')));
                                    }
                                  },
                                  imageUrl2: null,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    Container(
                      color: context.cardColor,
                      padding: const EdgeInsets.all(10.0),
                      child: Row(
                        children: [
                          // IconButton(
                          //   icon: const Icon(Icons.attach_file),
                          //   onPressed: () async {
                          //     // const permission = Permission.photos;
                          //     // if (await permission.isGranted) {
                          //     //   // _showFileOptions();
                          //     // } else if (await permission.isDenied) {
                          //     //   final result = await permission.request();
                          //     //
                          //     //   if (result.isGranted) {
                          //     //     _showFileOptions();
                          //     //   } else if (result.isDenied) {
                          //     //     print("isDenied");
                          //     //     return;
                          //     //     // _permissionDialog(context);
                          //     //     // _showFileOptions();
                          //     //     return;
                          //     //   } else if (result.isPermanentlyDenied) {
                          //     //     print("isPermanentlyDenied1");
                          //     //     _permissionDialog(context);
                          //     //     return;
                          //     //   }
                          //     // } else if (await permission.isPermanentlyDenied) {
                          //     //   print("isPermanentlyDenied2");
                          //     //   _permissionDialog(context);
                          //     //
                          //     //   return;
                          //     // }
                          //     const permission = Permission.photos;
                          //
                          //     if (await permission.isGranted) {
                          //       // Permission is already granted
                          //       _showFileOptions();
                          //     } else if (await permission.isDenied) {
                          //       // Permission was denied; request it
                          //       final result = await permission.request();
                          //       print(result);
                          //       // Check the result after requesting permission
                          //       if (result.isGranted) {
                          //         _showFileOptions();
                          //       } else if (result.isPermanentlyDenied) {
                          //         // Permission is permanently denied
                          //         print("Permission is permanently denied.");
                          //         // _permissionDialog(context);
                          //         _showFileOptions();
                          //       } else if (result.isGranted) {
                          //         _showFileOptions();
                          //
                          //         // Permission is still denied
                          //         print("Permission is denied.");
                          //       }
                          //     } else if (await permission.isPermanentlyDenied) {
                          //       // Permission was permanently denied
                          //       print("Permission is permanently denied.");
                          //       _permissionDialog(context);
                          //     }
                          //   },
                          // ),
                          // const SizedBox(width: 8.0),
                          Expanded(
                            child: Container(
                              constraints: const BoxConstraints(maxHeight: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: Colors.grey.withOpacity(0.3),
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(25.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    offset: const Offset(0, 2),
                                    blurRadius: 8,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: TextField(
                                focusNode: focusNode,
                                controller: textController,
                                minLines: 1,
                                maxLines: 4,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Poppins',
                                ),
                                decoration: InputDecoration(
                                  hintStyle: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 16,
                                    fontFamily: 'Poppins',
                                  ),
                                  hintText: 'Ask Medical AI...',
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(30),
                                onTap: () async {
                                  focusNode.unfocus();
                                  String question = textController.text.trim();
                                  if (question.isEmpty) return;
                                  // String sessionId = selectedSessionId.toString();
                                  // var tempId =
                                  //     -1; // Unique temporary ID for the response
                                  setState(() {
                                    var myMessage = Messages(
                                        id: -1,
                                        gptSessionId:
                                            selectedSessionId.toString(),
                                        question: question,
                                        response: 'Generating response...',
                                        createdAt: DateTime.now().toString(),
                                        updatedAt: DateTime.now().toString(),
                                        imageUrl1: '');
                                    state1.response1.messages!.add(myMessage);
                                    BlocProvider.of<ChatGPTBloc>(context).add(
                                      GetPost(
                                          sessionId:
                                              selectedSessionId.toString(),
                                          question: question,
                                          imageUrl1:
                                              '' // replace with real input
                                          ),
                                    );

                                    textController.clear();
                                    scrollToBottom();
                                  });
                                  // // Add the temporary message (User's question)
                                  // // setState(() {
                                  // // message.add(myMessage);
                                  // // scrollToBottom();
                                  // // });
                                  //
                                  try {
                                    //   for (int i = 0; i <= state1.response2.content!.length; i++) {
                                    //     await Future.delayed(const Duration(
                                    //         milliseconds:
                                    //             100)); // Delay to simulate typing speed
                                    //
                                    //     int index = state1.response1.messages!
                                    //         .indexWhere((msg) => msg.id == -1);
                                    //     if (index != -1) {
                                    //       // Update the temporary message with gradually more characters of the response
                                    //       String typingText = state1
                                    //           .response2.content!
                                    //           .substring(0, i);
                                    //       state1.response1.messages![index] =
                                    //           Messages(
                                    //               id: -1,
                                    //               gptSessionId: state1.response.sessions!.first??'',
                                    //               question: question,
                                    //               response: typingText,
                                    //               createdAt:
                                    //                   DateTime.now().toString(),
                                    //               updatedAt: DateTime.now()
                                    //                   .toString());
                                    //       print(typingText);
                                    //       if (state1
                                    //               .response2.content!.length ==
                                    //           i) {
                                    //         state1.response1.messages![index] =
                                    //             Messages(
                                    //                 id: -1,
                                    //                 gptSessionId: state1.response.sessions!.first??'',
                                    //                 question: question,
                                    //                 response: typingText,
                                    //                 createdAt: DateTime.now()
                                    //                     .toString(),
                                    //                 updatedAt: DateTime.now()
                                    //                     .toString());
                                    //       }
                                    //     }
                                    //   }
                                    // ChatGPTResponse newMessage =
                                    //     await askQuestion(
                                    //         sessionId, question);

                                    // for (int i = 0;
                                    //     i <= state1.response2.content!.length;
                                    //     i++) {
                                    //   await Future.delayed(const Duration(
                                    //       milliseconds:
                                    //           1)); // Delay to simulate typing speed
                                    //
                                    //   // setState(() {
                                    //     int index = state1.response1.messages!.indexWhere(
                                    //         (msg) => msg.id == tempId);
                                    //     if (index != -1) {
                                    //       // Update the temporary message with gradually more characters of the response
                                    //       String typingText = state1.response2.content!.substring(0, i);
                                    //       state1.response1.messages![index] = Messages(
                                    //           id: tempId,
                                    //           gptSessionId: state1.response.sessions!.first??'',
                                    //           question: question,
                                    //           response: typingText,
                                    //           createdAt:
                                    //               DateTime.now().toString(),
                                    //           updatedAt:
                                    //               DateTime.now().toString());
                                    //       if (state1.response2.content!.length ==
                                    //           i) {
                                    //         state1.response1.messages![index] = Messages(
                                    //             id: -1,
                                    //             gptSessionId: state1.response.sessions!.first??'',
                                    //             question: question,
                                    //             response: typingText,
                                    //             createdAt:
                                    //                 DateTime.now().toString(),
                                    //             updatedAt: DateTime.now()
                                    //                 .toString());
                                    //       }
                                    //     }
                                    //   // });
                                    //   scrollToBottom();
                                    // }
                                    // setState(() {
                                    isWriting = false;
                                    // });
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error: $e')));
                                  }
                                },
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [Colors.blue[400]!, Colors.blue[700]!],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.withOpacity(0.3),
                                        offset: const Offset(0, 2),
                                        blurRadius: 8,
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    isWriting ? Icons.more_horiz : Icons.send_rounded,
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
                    Container(
                      padding: const EdgeInsets.all(4),
                      color: Colors.white,
                      child: Marquee(
                          pauseDuration: const Duration(milliseconds: 100),
                          direction: Axis.horizontal,
                          directionMarguee: DirectionMarguee.oneDirection,
                          textDirection: TextDirection.ltr,
                          child: const Text(
                              'Artificial Intelligence can make mistakes. Consider checking important information.')),
                    )
                  ],
                ));
          } else if (state1 is DataError) {
            return Scaffold(
                body: Container(
                  width: 100.w,
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment:CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Error!",
                    style: TextStyle(
                        color: Colors.red,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Something went wrong.Please try again...',
                    style: TextStyle(color: black,fontSize: 16,fontWeight: FontWeight.w500),
                  ),
                  MaterialButton(
                    onPressed: () {
                      try {
                        BlocProvider.of<ChatGPTBloc>(context).add(GetNewChat());
                        selectedSessionId =
                            BlocProvider.of<ChatGPTBloc>(context)
                                .newChatSessionId;

                        // Session newSession = await createNewChatSession();
                        // setState(() {
                        //   futureSessions = Future(() =>
                        //       [newSession, ...(snapshot.data ?? [])]);
                        // });
                      } catch (e) {
                        debugPrint(e.toString());
                      }
                    },
                    color: appButtonBackgroundColorGlobal,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    child: const Text(
                      "Try Again",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                ],
              ),
            ));
          } else {
            return const Text('error');
          }
        }));
  }

  onSubscriptionCount(String channelName, int subscriptionCount) {}

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

  deleteRecord(BuildContext context, int id) {}

  editRecord(BuildContext context, int id) {}

  // Helper method to build modern suggestion cards
  Widget _buildSuggestionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              offset: const Offset(0, 4),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'Poppins',
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to execute suggestions
  void _executeSuggestion(String question, dynamic state1, BuildContext context) {
    setState(() {
      isAlreadyAsk = true;
      isEmpty = false;
    });
    widget.question = question;
    isAlreadyAsk = false;
    drugsAskQuestion(state1, context);
  }
}
