import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import to use Clipboard
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:markdown_widget/config/configs.dart';
import 'package:markdown_widget/widget/markdown_block.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:sizer/sizer.dart';

import '../../data/models/chat_gpt_model/chat_gpt_message_history/chat_gpt_message_history.dart';
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
  FocusNode focusNode=FocusNode();

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

  cardIntro(title, subTitle, onTap) {
    return InkWell(
      onTap: onTap,
      child: Card(
          elevation: 2,
          child: SizedBox(
            width: 40.w,
            height: 20.h,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500),
                    ),
                    Text(
                      subTitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontSize: 8.sp,
                          fontWeight: FontWeight.normal),
                    ),
                  ]),
            ),
          )),
    );
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
                    Center(
                        child: CircularProgressIndicator(
                      color: svGetBodyColor(),
                    )),
                  ],
                ),
              ),
            );
          } else if (state1 is DataLoaded) {
            isEmpty = state1.response1.messages?.isEmpty??false;
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
                  centerTitle: true,
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
                                    side: const BorderSide(
                                        color: Colors.black, width: 1.0),
                                  ),
                                  color: Colors.lightBlue,
                                  onPressed: () {
                                    // if (chatWithAi == "New Session") {
                                      try {
                                        BlocProvider.of<ChatGPTBloc>(context)
                                            .add(GetNewChat());
                                        // Navigator.of(context).pop();

                                        selectedSessionId =
                                            BlocProvider.of<ChatGPTBloc>(
                                                    context)
                                                .newChatSessionId;

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
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      'Next Session',
                                      style: GoogleFonts.poppins(color: white),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),

                                IconButton(
                                  icon: isLoadingMessages
                                      ? Image.asset(
                                          'assets/images/docktak_ai_dark.png',
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
                                Icons.cancel_outlined,
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
                                    children: [
                                      cardIntro('Code Detection',
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
                                      cardIntro('Diagnostic \nSuggestions',
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
                                                            GoogleFonts.poppins(
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
                                                            GoogleFonts.poppins(
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
                                  // Wrap(
                                  //   alignment: WrapAlignment.center,
                                  //   // mainAxisAlignment: MainAxisAlignment.center,
                                  //   children: [
                                  //     cardIntro('Code Detection',
                                  //         'Identify CPT or ICD codes', () {
                                  //       // Code Detection: Identify CPT or ICD codes
                                  //       isAlreadyAsk = true;
                                  //       widget.question =
                                  //           'Code Detection: Identify CPT or ICD codes';
                                  //       if (isAlreadyAsk) {
                                  //         setState(() {
                                  //           isEmpty = false;
                                  //         });
                                  //         isAlreadyAsk = false;
                                  //
                                  //         // Future.delayed(const Duration(seconds: 1),(){
                                  //         drugsAskQuestion(state1, context);
                                  //         // });
                                  //         // textController.text = widget.question.toString();
                                  //       }
                                  //     }),
                                  //     const SizedBox(width: 10),
                                  //     cardIntro('Diagnostic \nSuggestions',
                                  //         'Request suggestions based on symptoms',
                                  //         () {
                                  //       isAlreadyAsk = true;
                                  //       widget.question =
                                  //           'Diagnostic Suggestions: Request suggestions based on symptoms';
                                  //       if (isAlreadyAsk) {
                                  //         isAlreadyAsk = false;
                                  //         // Future.delayed(const Duration(seconds: 1),(){
                                  //         setState(() {
                                  //           isEmpty = false;
                                  //         });
                                  //         drugsAskQuestion(state1, context);
                                  //         // });
                                  //         // textController.text = widget.question.toString();
                                  //       }
                                  //     }),
                                  //     const SizedBox(width: 10),
                                  //     cardIntro('Medication Review',
                                  //         'Check interactions and dosage', () {
                                  //       // Medication Review: check interactions and dosage
                                  //
                                  //       widget.question =
                                  //           'Medication Review: check interactions and dosage';
                                  //       // Future.delayed(const Duration(seconds: 1),(){
                                  //       setState(() {
                                  //         isEmpty = false;
                                  //       });
                                  //       drugsAskQuestion(state1, context);
                                  //       // });
                                  //       // textController.text = widget.question.toString();
                                  //     }),
                                  //     cardIntro('Medical images',
                                  //         'initial assessment', () async {
                                  //       // Medication Review: check interactions and dosage
                                  //           widget.question =
                                  //           'initial assessment';
                                  //
                                  //           const permission = Permission.photos;
                                  //           if (await permission.isGranted) {
                                  //             _showFileOptions();
                                  //           } else if (await permission
                                  //               .isDenied) {
                                  //             final result =
                                  //                 await permission.request();
                                  //             if (result.isGranted) {
                                  //               _showFileOptions();
                                  //             } else if (result.isDenied) {
                                  //               print("isDenied");
                                  //               // _permissionDialog(context);
                                  //               _showFileOptions();
                                  //
                                  //             } else if (result
                                  //                 .isPermanentlyDenied) {
                                  //               print("isPermanentlyDenied");
                                  //               _permissionDialog(context);
                                  //             }
                                  //           } else if (await permission
                                  //               .isPermanentlyDenied) {
                                  //             print("isPermanentlyDenied");
                                  //             _permissionDialog(context);
                                  //           }
                                  //       // Future.delayed(const Duration(seconds: 1),(){
                                  //       setState(() {
                                  //         isEmpty = false;
                                  //       });
                                  //       drugsAskQuestion(state1, context);
                                  //       // });
                                  //       // textController.text = widget.question.toString();
                                  //     }),
                                  //   ],
                                  // ),
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
                                state1.response1.messages?[index]??Messages();
                            return Column(
                              children: [
                                ChatBubble(
                                  text: message.question ?? '',
                                  isUserMessage: true,
                                  imageUrl1: null,
                                  responseImageUrl1: message.imageUrl1 ?? '', imageUrl2: null,
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
                                  }, imageUrl2: null,
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
                                        imageUrl1:  '');
                                    state1.response1.messages!.add(myMessage);
                                    BlocProvider.of<ChatGPTBloc>(context).add(
                                      GetPost(
                                          sessionId:
                                              selectedSessionId.toString(),
                                          question: question,
                                          imageUrl1: '' // replace with real input
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
            return Scaffold(body: Text(state1.errorMessage.toString()));
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
//
// class ChatBubble extends StatelessWidget {
//   final String text;
//   final bool isUserMessage;
//   final Function? onTapReginarate;
//   File? imageUrl;
//   String responseImageUrl;
//
//   ChatBubble(
//       {Key? key,
//       required this.text,
//       required this.isUserMessage,
//       this.onTapReginarate,
//       required this.imageUrl,
//       this.responseImageUrl = ''})
//       : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     double screenWidth = MediaQuery.of(context).size.width;
//     double bubbleMaxWidth = screenWidth * 0.6;
//     // print("response1 ${responseImageUrl}");
//
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0),
//       child: IntrinsicHeight(
//         child: Row(
//           mainAxisAlignment:
//               isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
//           children: [
//             if (!isUserMessage) ...[
//               Wrap(
//                 crossAxisAlignment: WrapCrossAlignment.end,
//                 spacing: 8.0,
//                 children: [
//                   CircleAvatar(
//                     backgroundColor: svGetBodyColor(),
//                     child: Image.asset(
//                       'assets/logo/ic_web.png',
//                       width: 25,
//                       height: 25,
//                     ),
//                   ),
//                   Container(
//                     width: 75.w,
//                     decoration: BoxDecoration(
//                       borderRadius: const BorderRadius.only(
//                           topRight: Radius.circular(10),
//                           topLeft: Radius.circular(10),
//                           bottomRight: Radius.circular(10)),
//                       color:
//                           appStore.isDarkMode ? Colors.white30 : Colors.white,
//                     ),
//                     child: Column(
//                       children: [
//                         Padding(
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 0.0, vertical: 6.0),
//                           child: ConstrainedBox(
//                             constraints:
//                                 BoxConstraints(maxWidth: bubbleMaxWidth),
//                             child: text == 'Generating response...'
//                                 ? Column(
//                                     children: [
//                                       Text(
//                                         // fitContent: true,
//                                         // selectable: true,
//                                         // softLineBreak: true,
//                                         // shrinkWrap: true,
//                                         text
//                                             .replaceAll("*", '')
//                                             .replaceAll('#', ''),
//                                         style: GoogleFonts.poppins(
//                                             color: Colors.black,
//                                             fontSize: 12.sp),
//                                       ),
//                                       const SizedBox(
//                                         height: 10,
//                                       ),
//                                       CircularProgressIndicator(
//                                         color: svGetBodyColor(),
//                                       ),
//                                     ],
//                                   )
//                                 : MarkdownBlock(
//                                     data: text,
//                                     config: MarkdownConfig(configs: [])),
//                             // Text(
//                             //         // fitContent: true,
//                             //         // selectable: true,
//                             //         // softLineBreak: true,
//                             //         // shrinkWrap: true,
//                             //         style: GoogleFonts.poppins(
//                             //             fontSize: 12.sp, color: Colors.black),
//                             //         text
//                             //             .replaceAll("*", '')
//                             //             .replaceAll('#', ''),
//                             //       ),
//                           ),
//                         ),
//                         Divider(
//                           color: Colors.grey[200],
//                         ),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.end,
//                           children: [
//                             // InkWell(
//                             //   onTap: () => onTapReginarate!(),
//                             //   child: const Padding(
//                             //     padding: EdgeInsets.all(8.0),
//                             //     child: Row(
//                             //       children: [
//                             //         Icon(Icons.change_circle_outlined),
//                             //         Text(' Regenerate')
//                             //       ],
//                             //     ),
//                             //   ),
//                             // ),
//                             IconButton(
//                               icon: const Icon(Icons.copy),
//                               onPressed: () {
//                                 // Copy text to clipboard
//                                 Clipboard.setData(ClipboardData(text: text));
//                                 // You can show a snackbar or any other feedback here
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   const SnackBar(
//                                     content: Text('Text copied to clipboard'),
//                                   ),
//                                 );
//                               },
//                             ),
//                           ],
//                         )
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//               // Expanded(
//               //   flex: 1,
//               //   child: Align(
//               //     alignment: Alignment.topLeft,
//               //     child: IconButton(
//               //       icon: const Icon(Icons.copy),
//               //       onPressed: () {
//               //         // Copy text to clipboard
//               //         Clipboard.setData(ClipboardData(text: text));
//               //         // You can show a snackbar or any other feedback here
//               //         ScaffoldMessenger.of(context).showSnackBar(
//               //           const SnackBar(
//               //             content: Text('Text copied to clipboard'),
//               //           ),
//               //         );
//               //       },
//               //     ),
//               //   ),
//               // ),
//             ] else ...[
//               Wrap(
//                 crossAxisAlignment: WrapCrossAlignment.end,
//                 spacing: 8.0,
//                 children: [
//                   Material(
//                     borderRadius: const BorderRadius.only(
//                         topLeft: Radius.circular(10),
//                         topRight: Radius.circular(10),
//                         bottomLeft: Radius.circular(10)),
//                     color: Colors.blue[300],
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 14.0, vertical: 10.0),
//                       child: ConstrainedBox(
//                           constraints: BoxConstraints(maxWidth: bubbleMaxWidth),
//                           child: Column(
//                             children: [
//                               if (responseImageUrl != '')
//                                 CustomImageView(imagePath: responseImageUrl)
//                               else if (imageUrl != null)
//                                 Image.file(imageUrl!),
//                               Text(text,
//                                   style: const TextStyle(color: Colors.white)),
//                             ],
//                           )),
//                     ),
//                   ),
//                   CircleAvatar(
//                     backgroundImage: CachedNetworkImageProvider(
//                         AppData.imageUrl + AppData.profile_pic),
//                     radius: 12,
//                   ),
//                 ],
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class TypingIndicators extends StatefulWidget {
//   final Color color;
//   final double size;
//
//   const TypingIndicators({Key? key, required this.color, this.size = 10.0})
//       : super(key: key);
//
//   @override
//   _TypingIndicatorState createState() => _TypingIndicatorState();
// }
//
// class _TypingIndicatorState extends State<TypingIndicators>
//     with TickerProviderStateMixin {
//   late List<AnimationController> _controllers;
//   late List<Animation<double>> _animations;
//
//   @override
//   void initState() {
//     super.initState();
//
//     _controllers = List.generate(3, (index) {
//       return AnimationController(
//         duration: const Duration(milliseconds: 600),
//         vsync: this,
//       )..repeat();
//     });
//
//     _animations = _controllers
//         .asMap()
//         .map((i, controller) {
//           return MapEntry(
//             i,
//             Tween(begin: 0.0, end: 8.0).animate(
//               CurvedAnimation(
//                 parent: controller,
//                 curve: Interval(0.2 * i, 1.0, curve: Curves.easeInOut),
//               ),
//             ),
//           );
//         })
//         .values
//         .toList();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: List.generate(3, (index) {
//         return AnimatedBuilder(
//           animation: _animations[index],
//           builder: (context, child) {
//             return Transform.translate(
//               offset: Offset(0, -_animations[index].value),
//               child: child,
//             );
//           },
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 2.0),
//             child: CircleAvatar(
//               radius: widget.size,
//               backgroundColor: widget.color,
//             ),
//           ),
//         );
//       }),
//     );
//   }
//
//   @override
//   void dispose() {
//     for (var controller in _controllers) {
//       controller.dispose();
//     }
//     super.dispose();
//   }
// }
