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
import '../../widgets/image_upload_widget/bloc/image_upload_bloc.dart';
import '../../widgets/image_upload_widget/bloc/image_upload_event.dart';
import '../../widgets/image_upload_widget/bloc/image_upload_state.dart';
import '../../widgets/image_upload_widget/multiple_image_upload_widget.dart';

class ChatGptWithImageScreen extends StatefulWidget {
  bool isFromMainScreen;
  String? question;

  ChatGptWithImageScreen(
      {super.key, this.isFromMainScreen = true, this.question});

  @override
  _ChatGPTScreenState createState() => _ChatGPTScreenState();
}

class _ChatGPTScreenState extends State<ChatGptWithImageScreen> {
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
  bool isOneTimeImageUploaded = false;
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
            width: 80.w,
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
  Widget build(BuildContext context) {
    return BlocProvider(
        create: (context) =>
        ChatGPTBloc()
          ..add(LoadDataValues()),
        child:
        BlocBuilder<ChatGPTBloc, ChatGPTState>(builder: (context, state1) {
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
            isEmpty = state1.response1.messages!.isEmpty;
            print('response ${state1.response.toString()}');
            if (!widget.isFromMainScreen) {
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
                            isOneTimeImageUploaded = false;
                            selectedSessionId =
                                BlocProvider
                                    .of<ChatGPTBloc>(context)
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
                          print(session.id);
                          selectedSessionId =
                              session.id; // Update the selected session
                          isLoadingMessages = true;
                          isOneTimeImageUploaded = true;
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
                                    isOneTimeImageUploaded = false;
                                    try {
                                      BlocProvider.of<ChatGPTBloc>(context)
                                          .add(GetNewChat());
                                      // Navigator.of(context).pop();

                                      selectedSessionId =
                                          BlocProvider
                                              .of<ChatGPTBloc>(context)
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
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text('Next Image',
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
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      cardIntro('Medical images',
                                          'Please upload the medical images for potential diagnoses and analysis', () async {
                                            // Medication Review: check interactions and dosage
                                            // widget.question = 'initial assessment';

                                            if (isOneTimeImageUploaded) {
                                              toasty(context,
                                                  'Only allowed one time image in one session');
                                            } else {
                                              const permission = Permission
                                                  .photos;
                                              if (await permission.isGranted) {
                                                // Permission is already granted
                                                _showBeforeFileOptions();
                                              } else
                                              if (await permission.isDenied) {
                                                // Permission was denied; request it
                                                final result = await permission
                                                    .request();
                                                print(result);
                                                // Check the result after requesting permission
                                                if (result.isGranted) {
                                                  _showBeforeFileOptions();
                                                } else if (result
                                                    .isPermanentlyDenied) {
                                                  // Permission is permanently denied
                                                  print(
                                                      "Permission is permanently denied.");
                                                  // _permissionDialog(context);
                                                  _showBeforeFileOptions();
                                                } else if (result.isGranted) {
                                                  _showBeforeFileOptions();

                                                  // Permission is still denied
                                                  print(
                                                      "Permission is denied.");
                                                }
                                              } else if (await permission
                                                  .isPermanentlyDenied) {
                                                // Permission was permanently denied
                                                print(
                                                    "Permission is permanently denied.");
                                                _permissionDialog(context);
                                              }
                                            }
                                            // Future.delayed(const Duration(seconds: 1),(){

                                            // });
                                            // textController.text = widget.question.toString();
                                          }),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    'Please upload the medical images for potential diagnoses and analysis',
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
                          itemCount: state1.response1.messages!.length,
                          itemBuilder: (context, index) {
                            print(state1.response1.messages![index].gptSessionId);
                            Messages message =
                            state1.response1.messages![index];
                            return Column(
                              children: [
                                ChatBubble(
                                  text: message.question ?? '',
                                  isUserMessage: true,
                                  imageUrl1: index!=0?null:
                                  selectedImageFiles.isNotEmpty
                                      ? File(
                                      selectedImageFiles.first.path ?? '')
                                      : null,
                                  imageUrl2: index!=0?null:selectedImageFiles.isNotEmpty
                                      ? selectedImageFiles.length == 2
                                      ? File(selectedImageFiles.last.path ?? '')
                                      : null
                                      : null,
                                  responseImageUrl1: index!=0?'': message.imageUrl1 ?? '',
                                  responseImageUrl2:  index!=0?'':message.imageUrl2 ?? '',
                                ),
                                ChatBubble(
                                  text: message.response ?? "",
                                  isUserMessage: false,
                                  imageUrl1:
                                  selectedImageFiles.isNotEmpty
                                      ? File(
                                      selectedImageFiles.first.path ?? '')
                                      : null,
                                  imageUrl2: selectedImageFiles.isNotEmpty
                                      ? selectedImageFiles.length == 2
                                      ? File(selectedImageFiles.last.path ?? '')
                                      : null
                                      : null,
                                  responseImageUrl1: message.imageUrl1 ?? '',
                                  responseImageUrl2: message.imageUrl2 ?? '',
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
                                          imageUrl2: message.imageUrl2,
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
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                    _buildImagePreview(),

                    Container(
                      color: context.cardColor,
                      padding: const EdgeInsets.all(10.0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.attach_file),
                            onPressed: () async {
                              // const permission = Permission.photos;
                              // if (await permission.isGranted) {
                              //   // _showFileOptions();
                              // } else if (await permission.isDenied) {
                              //   final result = await permission.request();
                              //
                              //   if (result.isGranted) {
                              //     _showFileOptions();
                              //   } else if (result.isDenied) {
                              //     print("isDenied");
                              //     return;
                              //     // _permissionDialog(context);
                              //     // _showFileOptions();
                              //     return;
                              //   } else if (result.isPermanentlyDenied) {
                              //     print("isPermanentlyDenied1");
                              //     _permissionDialog(context);
                              //     return;
                              //   }
                              // } else if (await permission.isPermanentlyDenied) {
                              //   print("isPermanentlyDenied2");
                              //   _permissionDialog(context);
                              //
                              //   return;
                              // }
                              if (isOneTimeImageUploaded) {
                                toasty(context,
                                    'Only allowed one time image in one session');
                              } else {
                                const permission = Permission.photos;
                                var status = await Permission.storage.request();
                                if (status.isGranted ||
                                    await permission.isGranted) {
                                  // Permission is already granted
                                  _showBeforeFileOptions();
                                } else if (await permission.isDenied) {
                                  // Permission was denied; request it
                                  final result = await permission.request();
                                  print(result);
                                  // Check the result after requesting permission
                                  if (result.isGranted) {
                                    _showBeforeFileOptions();
                                  } else if (result.isPermanentlyDenied) {
                                    // Permission is permanently denied
                                    print("Permission is permanently denied.");
                                    // _permissionDialog(context);
                                    _showBeforeFileOptions();
                                  } else if (result.isGranted) {
                                    _showBeforeFileOptions();
                                    // Permission is still denied
                                    print("Permission is denied.");
                                  }
                                } else if (await permission
                                    .isPermanentlyDenied) {
                                  // Permission was permanently denied
                                  print("Permission is permanently denied.");
                                  _permissionDialog(context);
                                }
                              }
                            },
                          ),
                          const SizedBox(width: 8.0),
                          Expanded(
                            child: Container(
                              constraints: const BoxConstraints(
                                maxHeight: 200
                              ),
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
                                  hintText: 'Clinical Summary e.g age, gender, medical history',
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

                                  print(selectedSessionId.toString());
                                  if (selectedImageFiles.isEmpty) {
                                    return;
                                  }
                                  else if (imageUploadBloc.imagefiles.isEmpty &&
                                      isOneTimeImageUploaded) {
                                    String question = textController.text
                                        .trim();
                                    // String sessionId = selectedSessionId.toString();
                                    // var tempId =
                                    //     -1; // Unique temporary ID for the response
                                    if(question !=''){
                                    setState(() {
                                      isOneTimeImageUploaded = true;
                                      var myMessage = Messages(
                                        id: -1,
                                        gptSessionId:
                                        selectedSessionId.toString(),
                                        question: question,
                                        response: 'Generating response...',
                                        createdAt: DateTime.now().toString(),
                                        updatedAt: DateTime.now().toString(),
                                        imageUrl1: '',imageUrl2: '',);
                                      state1.response1.messages!.add(myMessage);

                                      BlocProvider.of<ChatGPTBloc>(context).add(
                                        GetPost(
                                            sessionId:
                                            selectedSessionId.toString(),
                                            question:  question,
                                            imageUrl1: null,
                                            imageUrl2: null,
                                            // replace with real input
                                            imageType: imageType),
                                      );
                                      imageUploadBloc.imagefiles.clear();
                                      textController.clear();
                                      _uploadedFile = _selectedFile;

                                      _selectedFile = null;
                                      scrollToBottom();
                                    });

                                    try {

                                      isWriting = false;
                                      // });
                                    } catch (e) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                          SnackBar(content: Text('Error: $e')));
                                    }
                                    }else{
                                      toasty(context, 'Please ask Question');
                                    }
                                  } else if (imageUploadBloc.imagefiles.isNotEmpty &&
                                      !isOneTimeImageUploaded) {
                                    String question = textController.text
                                        .trim();
                                    // String sessionId = selectedSessionId.toString();
                                    // var tempId =
                                    //     -1; // Unique temporary ID for the response
                                    setState(() {
                                      isOneTimeImageUploaded = true;
                                      var myMessage = Messages(
                                        id: -1,
                                        gptSessionId:
                                        selectedSessionId.toString(),
                                        question: question,
                                        response: 'Generating response...',
                                        createdAt: DateTime.now().toString(),
                                        updatedAt: DateTime.now().toString(),
                                        imageUrl1: imageUploadBloc.imagefiles
                                            .first.path ??
                                            '', imageUrl2: imageUploadBloc.imagefiles
                                            .first.path ??
                                            '',);
                                      state1.response1.messages!.add(myMessage);

                                      BlocProvider.of<ChatGPTBloc>(context).add(
                                        GetPost(
                                            sessionId:
                                            selectedSessionId.toString(),
                                            question: question == ""
                                                ? 'Analyse Image'
                                                : question,
                                            imageUrl1:
                                            imageUploadBloc.imagefiles.first
                                                .path ??
                                                '',
                                            imageUrl2:
                                            imageUploadBloc.imagefiles.last
                                                .path ?? '',
                                            // replace with real input
                                            imageType: imageType),
                                      );
                                      imageUploadBloc.imagefiles.clear();
                                      textController.clear();
                                      _uploadedFile = _selectedFile;

                                      _selectedFile = null;
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
                                          .showSnackBar(
                                          SnackBar(content: Text('Error: $e')));
                                    }
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

  bool _isImageFile(File? file) {
    // Check if the file is an image
    return true; // Implement your logic here
  }

  bool _isDocumentFile(File? file) {
    // Check if the file is a document
    return false; // Implement your logic here
  }

  File? _selectedFile;
  File? _uploadedFile;
  bool _isFileUploading = false;
  List<XFile> selectedImageFiles = [];

  Widget _buildImagePreview() {
    return Container(
      color: Colors.white,
      width: 100.w,
      // margin: const EdgeInsets.all(8.0),
      child: BlocBuilder<ImageUploadBloc, ImageUploadState>(
          bloc: imageUploadBloc,
          builder: (context, state) {
            if (state is FileLoadedState) {
              return imageUploadBloc.imagefiles != []
                  ? Wrap(
                children: imageUploadBloc.imagefiles.map((imageone) {
                  return Stack(children: [
                    Card(
                      child: SizedBox(
                        height: 60, width: 60,
                        child: buildMediaItem(File(imageone.path)),
                        // child: Image.file(File(imageone.path,),fit: BoxFit.fill,),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: GestureDetector(
                          onTap: () {
                            setState(() {});
                            selectedImageFiles.remove(imageone);
                            imageUploadBloc.add(SelectedFiles(
                                pickedfiles: imageone, isRemove: true));
                          },
                          child: const Icon(
                            Icons.remove_circle_outlined,
                            color: Colors.red,
                          )),
                    )
                  ]);
                }).toList(),
              )
                  : Container();
            } else {
              return Container();
            }
          }),
      // child:
      // ListTile(
      //   leading: CircleAvatar(
      //     backgroundImage: FileImage(file),
      //   ),
      //   title: Text(file.path.split('/').last),
      //   trailing: IconButton(
      //     icon: const Icon(Icons.clear),
      //     onPressed: () {
      //       setState(() {
      //         _selectedFile = null;
      //       });
      //     },
      //   ),
      // ),
    );
  }

  Widget _buildVideoPreview(File? file) {
    // Implement video preview widget
    return Container();
  }

  Widget _buildDocumentPreview(File file) {
    // Implement document preview widget
    return Container();
  }

  String imageType = '';

  void _showFileOptions() {
    int imageLimit = 0;
    print(imageType);
    if (imageType == 'X-ray' || imageType == 'Mammography') {
      imageLimit = 2;
    } else {
      imageLimit = 1;
    }
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: MultipleImageUploadWidget(
              imageType: imageType, imageUploadBloc, imageLimit: imageLimit, (
              imageFiles) {
            selectedImageFiles = imageFiles;
            print(selectedImageFiles);
            setState(() {});
            Navigator.pop(context);
          }),
          // Column(
          //   mainAxisSize: MainAxisSize.min,
          //   children: <Widget>[
          //     ListTile(
          //       leading: const Icon(Icons.photo),
          //       title: const Text('Choose from gallery'),
          //       onTap: () async {
          //         Navigator.pop(context);
          //         File? file = await _pickFile(ImageSource.gallery);
          //         if (file != null) {
          //           setState(() {
          //             _selectedFile = file;
          //           });
          //         }
          //       },
          //     ),
          //     ListTile(
          //       leading: const Icon(Icons.camera_alt),
          //       title: const Text('Take a picture'),
          //       onTap: () async {
          //         Navigator.pop(context);
          //         File? file = await _pickFile(ImageSource.camera);
          //         if (file != null) {
          //           setState(() {
          //             _selectedFile = file;
          //           });
          //         }
          //       },
          //     ),
          //     // ListTile(
          //     //   leading: const Icon(Icons.insert_drive_file),
          //     //   title: const Text('Select a document'),
          //     //   onTap: () async {
          //     //     Navigator.pop(context);
          //     //     File? file = await _pickFile(ImageSource.gallery);
          //     //     if (file != null) {
          //     //       setState(() {
          //     //         _selectedFile = file;
          //     //       });
          //     //     }
          //     //   },
          //     // ),
          //   ],
          // ),
        );
      },
    );
  }

  ImageUploadBloc imageUploadBloc = ImageUploadBloc();

  void _showBeforeFileOptions() {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  "Select Option",
                  style: GoogleFonts.poppins(fontSize: 18),
                ),
                _buildHorizontalOption(
                  icon: Icons.image_search,
                  text: 'Dermatological assessment',
                  onTap: () async {
                    Navigator.pop(context);
                    imageType = 'Dermatological';
                    _showFileOptions();
                  },
                ),
                _buildHorizontalOption(
                  icon: Icons.image_search,
                  text: 'ECG analysis',
                  onTap: () async {
                    Navigator.pop(context);
                    imageType = 'ECG';
                    _showFileOptions();
                  },
                ),
                _buildHorizontalOption(
                  icon: Icons.image_search,
                  text: 'X-ray evaluation',
                  onTap: () async {
                    Navigator.pop(context);
                    imageType = 'X-ray';
                    _showFileOptions();
                  },
                ),
                _buildHorizontalOption(
                  icon: Icons.image_search,
                  text: 'CT scan evaluation',
                  onTap: () async {
                    Navigator.pop(context);
                    imageType = 'CT Scan';
                    _showFileOptions();
                  },
                ),
                _buildHorizontalOption(
                  icon: Icons.image_search,
                  text: 'MRI evaluation',
                  onTap: () async {
                    Navigator.pop(context);
                    imageType = 'MRI Scan';
                    _showFileOptions();
                  },
                ),
                _buildHorizontalOption(
                  icon: Icons.image_search,
                  text: 'Mammography analysis',
                  onTap: () async {
                    Navigator.pop(context);
                    imageType = 'Mammography';
                    _showFileOptions();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHorizontalOption({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          color: Colors.grey[200],
        ),
        child: Row(
          children: <Widget>[
            Icon(
              icon,
              size: 30.0,
              color: Colors.blue,
            ),
            const SizedBox(width: 15.0),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16.0,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Future<File?> _pickFile(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      return File(pickedFile.path);
    } else {
      return null;
    }
  }

  Future<File?> _pickVideoFile(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: source);

    if (pickedFile != null) {
      return File(pickedFile.path);
    } else {
      return null;
    }
  }

  onSubscriptionCount(String channelName, int subscriptionCount) {}

  Future<void> _permissionDialog(context) async {
    return showDialog(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          // <-- SEE HERE
          title: Text(
            'You want to enable permission?',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 14.sp),
          ),
          // content: const SingleChildScrollView(
          //   child: ListBody(
          // //     children: <Widget>[
          // //       Text('Are you sure want to enable permission?'),
          // //     ],
          //   ),
          // ),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Yes'),
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

  deleteRecord(BuildContext context, int id) {}

  editRecord(BuildContext context, int id) {}
}

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUserMessage;
  final Function? onTapReginarate;
  File? imageUrl1;
  File? imageUrl2;
  String responseImageUrl1;
  String responseImageUrl2;

  ChatBubble({
    Key? key,
    required this.text,
    required this.isUserMessage,
    this.onTapReginarate,
    required this.imageUrl1,
    required this.imageUrl2,
    this.responseImageUrl1 = '',
    this.responseImageUrl2 = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    double bubbleMaxWidth = screenWidth * 0.6;
    // print("response1 ${responseImageUrl}");

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
                              child: text == 'Generating response...'
                                  ? Column(
                                children: [
                                  MarkdownBlock(
                                      data: text,
                                      config: MarkdownConfig(configs: [])),
                                  // Text(
                                  //   // fitContent: true,
                                  //   // selectable: true,
                                  //   // softLineBreak: true,
                                  //   // shrinkWrap: true,
                                  //   text
                                  //       .replaceAll("*", '')
                                  //       .replaceAll('#', ''),
                                  //   style: GoogleFonts.poppins(
                                  //       color: Colors.black,
                                  //       fontSize: 12.sp),
                                  // ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  CircularProgressIndicator(
                                    color: svGetBodyColor(),
                                  ),
                                ],
                              )
                                  : MarkdownBlock(
                                data: text,
                              )),
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
            ] else
              ...[
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
                            constraints: BoxConstraints(
                                maxWidth: bubbleMaxWidth),
                            child: Column(
                              children: [
                                if (imageUrl2 != null)
                                  Row(
                                    children: [
                                      if (responseImageUrl1 != '')
                                        SizedBox(
                                            height: 100,
                                            width: 25.w,
                                            child: CustomImageView(
                                              imagePath: responseImageUrl1,
                                            ))
                                      else
                                        if (imageUrl1 != null)
                                          SizedBox(
                                              height: 100,
                                              width: 25.w,
                                              child: imageUrl1 != null
                                                  ? Image.file(
                                                imageUrl1!,
                                                errorBuilder: (BuildContext
                                                context,
                                                    Object exception,
                                                    StackTrace? stackTrace) {
                                                  return const SizedBox();
                                                },
                                              )
                                                  : const SizedBox()),
                                      const SizedBox(
                                        width: 4,
                                      ),
                                      if (responseImageUrl2 != '')
                                        SizedBox(
                                            height: 100,
                                            width: 25.w,
                                            child: CustomImageView(
                                              imagePath: responseImageUrl2,
                                            ))
                                      else
                                        if (imageUrl2 != null)
                                          SizedBox(
                                              height: 100,
                                              width: 25.w,
                                              child: imageUrl2 != null
                                                  ? Image.file(
                                                imageUrl2!,
                                                errorBuilder: (BuildContext
                                                context,
                                                    Object exception,
                                                    StackTrace? stackTrace) {
                                                  return const SizedBox();
                                                },
                                              )
                                                  : const SizedBox()),
                                    ],
                                  )
                                else
                                  if (responseImageUrl1 != '')
                                    CustomImageView(
                                      imagePath: responseImageUrl1,
                                    )
                                  else
                                    if (imageUrl1 != null)
                                      Image.file(
                                        imageUrl1!, errorBuilder: (BuildContext
                                      context,
                                          Object exception,
                                          StackTrace? stackTrace) {
                                        return const SizedBox();
                                      },),
                                Text(text,
                                    style: const TextStyle(
                                        color: Colors.white)),
                              ],
                            )),
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
      )
        ..repeat();
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
