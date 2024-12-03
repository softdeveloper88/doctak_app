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
            isEmpty = state1.response1.messages?.isEmpty ?? false;
            print('response ${state1.response.toString()}');
            if (!widget.isFromMainScreen) {
              if (isAlreadyAsk) {
                // setState(() {
                isEmpty = false;
                // });
                isAlreadyAsk = false;
                // Future.delayed(const Duration(seconds: 1),(){
                drugsAskQuestion(state1, context);
                // });
                // textController.text = widget.question.toString();
              }
            }
            return Scaffold(
                backgroundColor: svGetBgColor(),
                appBar: AppBar(
                  leading: GestureDetector(
                    onTap: () {
                      ChatHistoryScreen(
                        onNewSessionTap: () {
                          try {
                            BlocProvider.of<ChatGPTBloc>(context)
                                .add(GetNewChat());
                            Navigator.of(context).pop();

                            selectedSessionId =
                                BlocProvider.of<ChatGPTBloc>(context)
                                    .newChatSessionId;

                            // Session newSession = await createNewChatSession();
                            // setState(() {
                            //   futureSessions = Future(() =>
                            //       [newSession, ...(snapshot.data ?? [])]);
                            // });
                          } catch (e) {
                            print(e);
                          }
                        },
                        onTap: (session) {
                          chatWithAi = session.name!;
                          isEmptyPage = false;
                          selectedSessionId =
                              session.id; // Update the selected session
                          isLoadingMessages = true;
                          // });
                          BlocProvider.of<ChatGPTBloc>(context).add(
                            GetMessages(
                                sessionId: selectedSessionId.toString()),
                          );
                          // loadMessages(selectedSessionId.toString())
                          //     .then((loadedMessages) {
                          //   setState(() {
                          //     messages = loadedMessages;
                          //
                          //     scrollToBottom();
                          //     chatWithAi = session.name!;
                          //
                          //     isLoadingMessages = false;
                          //   });
                          // });
                          Navigator.of(context)
                              .pop(); // This line will close the drawer
                        },
                      ).launch(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Image.asset(
                        'assets/icon/ic_chat_history.png',
                        color: svGetBodyColor(),
                      ),
                    ),
                  ),
                  centerTitle: false,
                  surfaceTintColor: context.cardColor,
                  backgroundColor: context.cardColor,
                  title: Builder(
                    builder: (context) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            // Wrap the Text widget with Expanded
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                MaterialButton(
                                  minWidth: 40.w,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    // side: const BorderSide(
                                    //     color: Colors.black, width: 1.0),
                                  ),
                                  color: Colors.lightBlue,
                                  onPressed: () {
                                    // if (chatWithAi == "New Session") {

                                    try {
                                      String isEmpty =
                                          state1.response2.content ?? '';

                                      if (isEmpty != "") {
                                        BlocProvider.of<ChatGPTBloc>(context)
                                            .add(GetNewChat());
                                        // Navigator.of(context).pop();

                                        selectedSessionId =
                                            BlocProvider.of<ChatGPTBloc>(
                                                    context)
                                                .newChatSessionId;
                                      }
                                      // Session newSession = await createNewChatSession();
                                      // setState(() {
                                      //   futureSessions = Future(() =>
                                      //       [newSession, ...(snapshot.data ?? [])]);
                                      // });
                                    } catch (e) {
                                      print(e);
                                    }
                                    // }
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      'Next Session',
                                      style: TextStyle(  fontFamily:  'Poppins',color: white),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: isLoadingMessages
                                      ? Image.asset(
                                          'assets/images/docktak_ai_light.png',
                                          height: 25,
                                          width: 25,
                                        )
                                      // ? TypingIndicators(
                                      //     color: svGetBodyColor(),
                                      //     size: 2.0) // Custom typing indicator
                                      : const Text(""),
                                  onPressed: () {},
                                )
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: appStore.isDarkMode
                                      ? svGetScaffoldColor()
                                      : cardLightColor),
                              child: Icon(
                                Icons.close,
                                color: svGetBodyColor(),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                body: Column(
                  children: <Widget>[
                    // const SizedBox(height: 10,),
                    if (isEmpty)
                      Expanded(
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(16.0),
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 20),
                                  const Text(
                                    'Welcome, Doctor!',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Your personal & medical assistant powered by Artificial Intelligence',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(height: 30),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      cardIntro(
                                           width: 40.w,                                          'Code Detection',
                                          'Identify CPT or ICD codes', () {
                                        // Code Detection: Identify CPT or ICD codes
                                        isAlreadyAsk = true;
                                        widget.question =
                                            'Code Detection: Identify CPT or ICD codes';
                                        if (isAlreadyAsk) {
                                          setState(() {
                                            isEmpty = false;
                                          });
                                          isAlreadyAsk = false;

                                          // Future.delayed(const Duration(seconds: 1),(){
                                          drugsAskQuestion(state1, context);
                                          // });
                                          // textController.text = widget.question.toString();
                                        }
                                      }),
                                      const SizedBox(width: 10),
                                      cardIntro(
                                          width: 40.w,
                                          'Diagnostic \nSuggestions',
                                          'Request suggestions based on symptoms',
                                          () {
                                        isAlreadyAsk = true;
                                        widget.question =
                                            'Diagnostic Suggestions: Request suggestions based on symptoms';
                                        if (isAlreadyAsk) {
                                          isAlreadyAsk = false;
                                          // Future.delayed(const Duration(seconds: 1),(){
                                          setState(() {
                                            isEmpty = false;
                                          });
                                          drugsAskQuestion(state1, context);
                                          // });
                                          // textController.text = widget.question.toString();
                                        }
                                      }),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,

                                    children: [
                                      InkWell(
                                        onTap: () {
                                          widget.question =
                                              'Medication Review: check interactions and dosage';
                                          // Future.delayed(const Duration(seconds: 1),(){
                                          setState(() {
                                            isEmpty = false;
                                          });
                                          drugsAskQuestion(state1, context);
                                          // });
                                          // textController.text = widget.question.toString();
                                        },
                                        child: Card(
                                            elevation: 2,
                                            child: SizedBox(
                                              width: 85.w,
                                              height: 20.h,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(16.0),
                                                child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        'Medication Review',
                                                        textAlign:
                                                            TextAlign.center,
                                                        style:
                                                            TextStyle(
                                                                color: Colors
                                                                    .black,
                                                                fontSize: 12.sp,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500),
                                                      ),
                                                      Text(
                                                        'Check interactions and dosage',
                                                        textAlign:
                                                            TextAlign.center,
                                                        style:
                                                            TextStyle(
                                                                color: Colors
                                                                    .black,
                                                                fontSize: 8.sp,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .normal),
                                                      ),
                                                    ]),
                                              ),
                                            )),
                                      ),
                                      const SizedBox(width: 10),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    'Ready to start? Type your question below or choose a suggested topic.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 14),
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
                              padding: const EdgeInsets.only(left: 8, right: 8),
                              decoration: BoxDecoration(
                                color: appStore.isDarkMode
                                    ? svGetScaffoldColor()
                                    : cardLightColor,
                                // border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              child: TextField(
                                focusNode: focusNode,
                                controller: textController,
                                minLines: 1,
                                // Minimum lines
                                maxLines: null,
                                // Allows for unlimited lines
                                decoration: const InputDecoration(
                                  hintStyle: TextStyle(color: Colors.grey),
                                  hintText: 'Ask Medical Ai',
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30.0),
                                gradient: const LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [Colors.blueAccent, Colors.blue],
                                  stops: [0.37, 1.0],
                                ),
                              ),
                              child: IconButton(
                                icon: isWriting
                                    ? const TypingIndicators(
                                        color: Colors.white,
                                        size: 2.0) // Custom typing indicator
                                    : const Icon(Icons.send,
                                        color: Colors.white),
                                onPressed: () async {
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
}
