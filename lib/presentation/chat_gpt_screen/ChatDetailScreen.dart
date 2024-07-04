import 'dart:async';

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
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/widgets/AnimatedBackground.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import to use Clipboard
import 'package:nb_utils/nb_utils.dart';
import 'package:sizer/sizer.dart';

import '../../data/models/chat_gpt_model/chat_gpt_message_history/chat_gpt_message_history.dart';

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

  void drugsAskQuestion(state1,context) {
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

  // Future<List<Session>> fetchSessions() async {
  //   final response = await http.get(
  //     Uri.parse("${AppData.remoteUrl}/gptChat-session"),
  //     headers: {
  //       "Authorization": "Bearer ${AppData.userToken}",
  //       "Content-Type": "application/json"
  //     },
  //   );
  //
  //   isLoadingMessages = true;
  //   if (response.statusCode == 200) {
  //     List<dynamic> sessionsJson = jsonDecode(response.body)['sessions'];
  //     int sessionId = jsonDecode(response.body)['newSessionId'];
  //     selectedSessionId = sessionId;
  //
  //     loadMessages(selectedSessionId.toString()).then((loadedMessages) {
  //       // Check again if the widget is still mounted
  //       if (!mounted) return;
  //
  //       setState(() {
  //         messages = loadedMessages;
  //         scrollToBottom();
  //         chatWithAi = "New Session";
  //         isLoadingMessages = false;
  //       });
  //     });
  //
  //     return sessionsJson.map((json) => Session.fromJson(json)).toList();
  //   } else {
  //     isLoadingMessages = false;
  //     throw Exception('Failed to load sessions');
  //   }
  // }

  // Future<Session> createNewChatSession() async {
  //   final response = await http.get(
  //     Uri.parse("${AppData.remoteUrl}/new-chat"),
  //     headers: {
  //       "Authorization": "Bearer ${AppData.userToken}",
  //       "Content-Type": "application/json"
  //     },
  //   );
  //
  //   if (response.statusCode == 200) {
  //     var data = jsonDecode(response.body);
  //     if (data['success']) {
  //       return Session.fromJson({
  //         'id': data['session_id'],
  //         'name': 'New Session',
  //         'created_at': DateTime.now().toString(),
  //         'updated_at': DateTime.now().toString()
  //       });
  //     } else {
  //       throw Exception('Failed to create new session');
  //     }
  //   } else {
  //     throw Exception('Failed to create new session');
  //   }
  // }

  // Future<List<ChatGPTResponse>> loadMessages(String id) async {
  //   final response = await http.get(
  //     Uri.parse("${AppData.remoteUrl}/gptChat-history/$id"),
  //     headers: {
  //       "Authorization": "Bearer ${AppData.userToken}",
  //       "Content-Type": "application/json"
  //     },
  //   );
  //
  //   if (response.statusCode == 200) {
  //     List<dynamic> messagesJson = jsonDecode(response.body)['messages'];
  //
  //     return messagesJson
  //         .map((json) => ChatGPTResponse.fromJson(json))
  //         .toList();
  //   } else {
  //     throw Exception('Failed to load messages');
  //   }
  // }

  // ... (existing methods including fetchSessions, createNewChatSession, loadMessages)

  // Future<ChatGPTResponse> askQuestion(String sessionId, String question) async {
  //   final response = await http.get(
  //     Uri.parse("${AppData.remoteUrl}/ask-question/$sessionId/$question"),
  //     headers: {
  //       "Authorization": "Bearer ${AppData.userToken}",
  //       "Content-Type": "application/json"
  //     },
  //   );
  //
  //   if (response.statusCode == 200) {
  //     var data = jsonDecode(response.body);
  //     return ChatGPTResponse(
  //         id: data['responseMessageId'],
  //         gptSessionId: sessionId,
  //         question: question,
  //         response: data['content'],
  //         createdAt: DateTime.now().toString(),
  //         updatedAt: DateTime.now().toString());
  //   } else {
  //     throw Exception('Failed to get response');
  //   }
  // }

  // ... (rest of the existing methods)
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        create: (context) => ChatGPTBloc()..add(LoadDataValues()),
        child: BlocBuilder<ChatGPTBloc, ChatGPTState>(
            builder: (context, state1) {
          if (selectedSessionId == 0 && state1 is DataLoaded) {
            selectedSessionId = state1.response.newSessionId;
            chatWithAi = state1.response.sessions?.first.name ?? 'New Session';

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
            print('response ${state1.response.toString()}');

            if (!widget.isFromMainScreen) {
              if (isAlreadyAsk) {
                isAlreadyAsk = false;
                // Future.delayed(const Duration(seconds: 1),(){
                  drugsAskQuestion(state1,context);
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
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    chatWithAi.length > 50
                                        ? '${chatWithAi.substring(0, 50)}...'
                                        : chatWithAi,
                                    style: boldTextStyle(),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: isLoadingMessages
                                      ? TypingIndicators(
                                          color: svGetBodyColor(),
                                          size: 2.0) // Custom typing indicator
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
                    if (state1.response1.messages!.isEmpty)
                      Expanded(
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(16.0),
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    textAlign: TextAlign.center,
                                    'Your personal & medical assistant powered by Artificial Intelligence',
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16.0),
                                   Text(
                                    textAlign: TextAlign.center,
                                    'Welcome, Doctor!',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16.0),
                                  Text(
                                    textAlign: TextAlign.center,
                                    'Thank you for using our AI assistant. Here are some things you can do:',
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 16.0),
                                  Text(
                                    textAlign: TextAlign.center,
                                    'Request diagnostic suggestions based on symptoms.',
                                    style: TextStyle(
                                      fontSize: 8.sp,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                  const SizedBox(height: 8.0),
                                  Text(
                                    textAlign: TextAlign.center,
                                    'Review medication interactions or dosages.',
                                    style: TextStyle(
                                      fontSize: 8.sp,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                  const SizedBox(height: 8.0),
                                  Text(
                                    textAlign: TextAlign.center,
                                    'Detect CPT or ICD code.',
                                    style: TextStyle(
                                      fontSize: 8.sp,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                  const SizedBox(height: 8.0),
                                  Text(
                                    textAlign: TextAlign.center,
                                    'And much more! Feel free to explore.',
                                    style: TextStyle(
                                      fontSize: 8.sp,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                  const SizedBox(height: 16.0),
                                  Text(
                                    textAlign: TextAlign.center,
                                    "If you need assistance or have questions, don't hesitate to ask.",
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      color: Colors.grey[700],
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
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: state1.response1.messages!.length,
                          itemBuilder: (context, index) {
                            Messages message = state1.response1.messages![index];

                            return Column(
                              children: [
                                ChatBubble(
                                  text: message.question ?? '',
                                  isUserMessage: true,
                                ),
                                ChatBubble(
                                  text: message.response ?? "",
                                  isUserMessage: false,
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
                                          response: 'Generating response...',
                                          createdAt: DateTime.now().toString(),
                                          updatedAt: DateTime.now().toString());
                                      state1.response1.messages!.add(myMessage);
                                      BlocProvider.of<ChatGPTBloc>(context).add(
                                        GetPost(
                                          sessionId:
                                              selectedSessionId.toString(),
                                          question:
                                              question, // replace with real input
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
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    Container(
                      color: context.cardColor,
                      // margin: const EdgeInsets.all(10.0),
                      // Add margin of 10.0 to all sides
                      // decoration: BoxDecoration(
                      //   color: Colors.white,
                      //   border: Border.all(color: Colors.grey),
                      //   borderRadius: BorderRadius.circular(20.0),
                      // ),
                      padding: const EdgeInsets.all(10.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.only(left: 8, right: 8),
                              decoration: BoxDecoration(
                                color: appStore.isDarkMode
                                    ? svGetScaffoldColor()
                                    : cardLightColor,
                                // border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              child: TextField(
                                controller: textController,
                                minLines: 1,
                                // Minimum lines
                                maxLines: null,
                                // Allows for unlimited lines
                                decoration: const InputDecoration(
                                  hintText: 'Ask DocTak AI',
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
                                        updatedAt: DateTime.now().toString());
                                    state1.response1.messages!.add(myMessage);
                                    BlocProvider.of<ChatGPTBloc>(context).add(
                                      GetPost(
                                        sessionId: selectedSessionId.toString(),
                                        question:
                                            question, // replace with real input
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

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUserMessage;
  final Function? onTapReginarate;

  ChatBubble(
      {Key? key,
      required this.text,
      required this.isUserMessage,
      this.onTapReginarate})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double bubbleMaxWidth = screenWidth * 0.6;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4),
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment:
              isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isUserMessage) ...[
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: 8.0,
                children: [
                  CircleAvatar(
                    backgroundColor: svGetBodyColor(),
                    child: Image.asset(
                      'assets/logo/ic_web.png',
                      width: 25,
                      height: 25,
                    ),
                  ),
                  Container(
                    width: 75.w,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(10),
                          topLeft: Radius.circular(10),
                          bottomRight: Radius.circular(10)),
                      color:
                          appStore.isDarkMode ? Colors.white30 : Colors.white,
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 0.0, vertical: 6.0),
                          child: ConstrainedBox(
                            constraints:
                                BoxConstraints(maxWidth: bubbleMaxWidth),
                            child: text=='Generating response...'?Column(
                              children: [
                                Text(
                                  // fitContent: true,
                                  // selectable: true,
                                  // softLineBreak: true,
                                  // shrinkWrap: true,
                                  text.replaceAll("*", '').replaceAll('#', ''),
                                ),
                                 const SizedBox(height: 10,),
                                 CircularProgressIndicator(color: svGetBodyColor(),),
                              ],
                            ):Text(
                              // fitContent: true,
                              // selectable: true,
                              // softLineBreak: true,
                              // shrinkWrap: true,
                              text.replaceAll("*", '').replaceAll('#', ''),
                            ),
                          ),
                        ),
                        Divider(
                          color: Colors.grey[200],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // InkWell(
                            //   onTap: () => onTapReginarate!(),
                            //   child: const Padding(
                            //     padding: EdgeInsets.all(8.0),
                            //     child: Row(
                            //       children: [
                            //         Icon(Icons.change_circle_outlined),
                            //         Text(' Regenerate')
                            //       ],
                            //     ),
                            //   ),
                            // ),
                            IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: () {
                                // Copy text to clipboard
                                Clipboard.setData(ClipboardData(text: text));
                                // You can show a snackbar or any other feedback here
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Text copied to clipboard'),
                                  ),
                                );
                              },
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
              // Expanded(
              //   flex: 1,
              //   child: Align(
              //     alignment: Alignment.topLeft,
              //     child: IconButton(
              //       icon: const Icon(Icons.copy),
              //       onPressed: () {
              //         // Copy text to clipboard
              //         Clipboard.setData(ClipboardData(text: text));
              //         // You can show a snackbar or any other feedback here
              //         ScaffoldMessenger.of(context).showSnackBar(
              //           const SnackBar(
              //             content: Text('Text copied to clipboard'),
              //           ),
              //         );
              //       },
              //     ),
              //   ),
              // ),
            ] else ...[
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: 8.0,
                children: [
                  Material(
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                        bottomLeft: Radius.circular(10)),
                    color: Colors.blue[300],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14.0, vertical: 10.0),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: bubbleMaxWidth),
                        child: Text(text,
                            style: const TextStyle(color: Colors.white)),
                      ),
                    ),
                  ),
                  CircleAvatar(
                    backgroundImage: CachedNetworkImageProvider(
                        AppData.imageUrl + AppData.profile_pic),
                    radius: 12,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class TypingIndicators extends StatefulWidget {
  final Color color;
  final double size;

  const TypingIndicators({Key? key, required this.color, this.size = 10.0})
      : super(key: key);

  @override
  _TypingIndicatorState createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicators>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(3, (index) {
      return AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      )..repeat();
    });

    _animations = _controllers
        .asMap()
        .map((i, controller) {
          return MapEntry(
            i,
            Tween(begin: 0.0, end: 8.0).animate(
              CurvedAnimation(
                parent: controller,
                curve: Interval(0.2 * i, 1.0, curve: Curves.easeInOut),
              ),
            ),
          );
        })
        .values
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, -_animations[index].value),
              child: child,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: CircleAvatar(
              radius: widget.size,
              backgroundColor: widget.color,
            ),
          ),
        );
      }),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
