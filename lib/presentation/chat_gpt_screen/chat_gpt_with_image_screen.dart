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
import 'package:doctak_app/presentation/chat_gpt_screen/widgets/card_intro.dart';
import 'package:doctak_app/presentation/chat_gpt_screen/widgets/chat_bubble.dart';
import 'package:doctak_app/presentation/chat_gpt_screen/widgets/typing_indicators.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/widgets/AnimatedBackground.dart';
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
  FocusNode focusNode = FocusNode();

  void drugsAskQuestion(state1, context) {
    String question = widget.question ?? "";
    if (question.isEmpty) return;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update the chatWithAi string with the localized version if needed
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
bool isError=false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: svGetBgColor(),
      body: BlocProvider(
          create: (context) => ChatGPTBloc()..add(LoadDataValues()),
          child: BlocBuilder<ChatGPTBloc, ChatGPTState>(
              builder: (context, state1) {
            if (selectedSessionId == 0 && state1 is DataLoaded) {
              selectedSessionId = state1.response.newSessionId;
              chatWithAi =
                  state1.response.sessions?.first.name ?? translation(context).lbl_preparing_ai;
            } else if (state1 is DataError) {

              showToast(translation(context).msg_something_wrong);
              try {
                if(isError) {
                  BlocProvider.of<ChatGPTBloc>(context).add(GetNewChat());
                  isOneTimeImageUploaded = false;
                  isError=false;
                  selectedSessionId =
                      BlocProvider
                          .of<ChatGPTBloc>(context)
                          .newChatSessionId;
                  // Session newSession = await createNewChatSession();
                  // setState(() {
                  //   futureSessions = Future(() =>
                  //       [newSession, ...(snapshot.data ?? [])]);
                  // });
                }
              } catch (e) {
                // Error logging suppressed
              }

            }
            if (state1 is DataInitial) {
              return AnimatedBackground(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  SizedBox(
                      height: 80.h,
                      child: ChatShimmerLoader())
                ],
              ));
            } else if (state1 is DataLoaded) {
              isEmpty = state1.response1.messages?.isEmpty ?? false;
              // Response data received
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
              return Column(
                children: <Widget>[
                  AppBar(
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
                                  BlocProvider.of<ChatGPTBloc>(context)
                                      .newChatSessionId;

                              // Session newSession = await createNewChatSession();
                              // setState(() {
                              //   futureSessions = Future(() =>
                              //       [newSession, ...(snapshot.data ?? [])]);
                              // });
                            } catch (e) {
                              // Error logging suppressed
                            }
                          },
                          onTap: (session) {
                            isError=true;
                            chatWithAi = session.name!;
                            isEmptyPage = false;
                            // Session ID selected
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
                                      // side: const BorderSide(
                                      //     color: Colors.black, width: 1.0),
                                    ),
                                    color: Colors.lightBlue,
                                    onPressed: () {
                                      isOneTimeImageUploaded = false;
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
                                        // Error logging suppressed
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        translation(context).lbl_next_image,
                                        style:
                                            TextStyle(color: white,fontFamily: 'Poppins',),
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
                                Text(
                                  translation(context).lbl_welcome_doctor,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  translation(context).msg_ai_assistant_intro,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 16,fontFamily: 'Poppins',),
                                ),
                                const SizedBox(height: 30),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    cardIntro(translation(context).lbl_medical_images,
                                        translation(context).msg_upload_images_prompt,
                                        () async {
                                      // Medication Review: check interactions and dosage
                                      // widget.question = 'initial assessment';

                                      if (isOneTimeImageUploaded) {
                                        toasty(context,
                                            translation(context).lbl_only_one_image_allowed);
                                      } else {
                                        const permission = Permission.photos;
                                        if (await permission.isGranted) {
                                          // Permission is already granted
                                          _showBeforeFileOptions();
                                        } else if (await permission.isDenied) {
                                          // Permission was denied; request it
                                          final result =
                                              await permission.request();
                                          debugPrint(result.toString());
                                          // Check the result after requesting permission
                                          if (result.isGranted) {
                                            _showBeforeFileOptions();
                                          } else if (result
                                              .isPermanentlyDenied) {
                                            // Permission is permanently denied
                                            debugPrint(
                                                "Permission is permanently denied.");
                                            // _permissionDialog(context);
                                            _showBeforeFileOptions();
                                          } else if (result.isGranted) {
                                            _showBeforeFileOptions();

                                            // Permission is still denied
                                            debugPrint("Permission is denied.");
                                          }
                                        } else if (await permission
                                            .isPermanentlyDenied) {
                                          // Permission was permanently denied
                                          debugPrint(
                                              "Permission is permanently denied.");
                                          _permissionDialog();
                                        }
                                      }
                                      // Future.delayed(const Duration(seconds: 1),(){

                                      // });
                                      // textController.text = widget.question.toString();
                                    }),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  translation(context).msg_upload_images_prompt,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 14,fontFamily: 'Poppins',),
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
                          debugPrint(
                              state1.response1.messages?[index].gptSessionId);
                          Messages message =
                              state1.response1.messages?[index] ?? Messages();
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
                                responseImageUrl1:
                                    index != 0 ? '' : message.imageUrl1 ?? '',
                                responseImageUrl2:
                                    index != 0 ? '' : message.imageUrl2 ?? '',
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
                                        sessionId: selectedSessionId.toString(),
                                        question: question,
                                        // imageUrl: _uploadedFile??''// replace with real input
                                      ),
                                    );
                                    textController.clear();
                                    scrollToBottom();
                                  });
                                  try {
                                    isWriting = false;
                                    // });
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

                  _buildImagePreview(),
                  Container(
                    padding: const EdgeInsets.all(10.0),
                    color: context.cardColor,
                    child: Container(
                      margin: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: appStore.isDarkMode
                            ? svGetScaffoldColor()
                            : cardLightColor,
                        // border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(20.0),
                      ),

                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.attach_file),
                            onPressed: () async {
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
                                  debugPrint(result.toString());
                                  // Check the result after requesting permission
                                  if (result.isGranted) {
                                    _showBeforeFileOptions();
                                  } else if (result.isPermanentlyDenied) {
                                    // Permission is permanently denied
                                    debugPrint(
                                        "Permission is permanently denied.");
                                    // _permissionDialog(context);
                                    _showBeforeFileOptions();
                                  } else if (result.isGranted) {
                                    _showBeforeFileOptions();
                                    // Permission is still denied
                                    debugPrint("Permission is denied.");
                                  }
                                } else if (await permission.isPermanentlyDenied) {
                                  // Permission was permanently denied
                                  debugPrint("Permission is permanently denied.");
                                  _permissionDialog();
                                }
                              }
                            },
                          ),
                          const SizedBox(width: 8.0),
                          Expanded(
                            child: Container(
                              constraints: const BoxConstraints(maxHeight: 200),
                              padding: const EdgeInsets.only(left: 8, right: 8),
                              child: TextField(
                                focusNode: focusNode,
                                controller: textController,
                                minLines: 1,
                                // Minimum lines
                                maxLines: null,
                                // Allows for unlimited lines
                                decoration: InputDecoration(
                                  hintStyle: const TextStyle(color: Colors.grey,fontFamily: 'Poppins',),
                                  hintText:
                                      translation(context).msg_clinical_summary_hint,
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
                                    : const Icon(Icons.send, color: Colors.white),
                                onPressed: () async {
                                  isError=true;
                                  focusNode.unfocus();
                                  debugPrint(selectedSessionId.toString());
                                  if (selectedImageFiles.isEmpty) {
                                    return;
                                  } else if (imageUploadBloc.imagefiles.isEmpty &&
                                      isOneTimeImageUploaded) {
                                    String question = textController.text.trim();
                                    // String sessionId = selectedSessionId.toString();
                                    // var tempId =
                                    //     -1; // Unique temporary ID for the response
                                    if (question != '') {
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
                                          imageUrl1: '',
                                          imageUrl2: '',
                                        );
                                        state1.response1.messages!.add(myMessage);

                                        BlocProvider.of<ChatGPTBloc>(context).add(
                                          GetPost(
                                              sessionId:
                                                  selectedSessionId.toString(),
                                              question: question,
                                              imageUrl1: null,
                                              imageUrl2: null,
                                              // replace with real input
                                              imageType: imageType),
                                        );
                                        imageUploadBloc.imagefiles.clear();
                                        textController.clear();

                                        scrollToBottom();
                                      });

                                      try {
                                        isWriting = false;
                                        // });
                                      } catch (e) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content: Text('Error: $e')));
                                      }
                                    } else {
                                      toasty(context, translation(context).lbl_please_ask_question);
                                    }
                                  } else if (imageUploadBloc
                                          .imagefiles.isNotEmpty &&
                                      !isOneTimeImageUploaded) {
                                    String question = textController.text.trim();
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
                                        imageUrl1:
                                            imageUploadBloc.imagefiles.first.path,
                                        imageUrl2:
                                            imageUploadBloc.imagefiles.first.path,
                                      );
                                      state1.response1.messages!.add(myMessage);

                                      BlocProvider.of<ChatGPTBloc>(context).add(
                                        GetPost(
                                            sessionId:
                                                selectedSessionId.toString(),
                                            question: question == ""
                                                ? translation(context).lbl_analyse_image
                                                : question,
                                            imageUrl1: imageUploadBloc
                                                .imagefiles.first.path,
                                            imageUrl2: imageUploadBloc
                                                .imagefiles.last.path,
                                            // replace with real input
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
                              ),
                            ),
                          ),
                        ],
                      ),
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
                        child: Text(
                            translation(context).msg_ai_disclaimer)),
                  )
                ],
              );
            }
            else if (state1 is DataError) {
              return Container(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      translation(context).lbl_error,
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.red,
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      state1.errorMessage.toString(),
                      style: const TextStyle(color: black,fontFamily: 'Poppins',),
                    ),
                    MaterialButton(
                      onPressed: () {
                        try {
                          BlocProvider.of<ChatGPTBloc>(context)
                              .add(GetNewChat());

                          isOneTimeImageUploaded = false;
                          selectedSessionId =
                              BlocProvider.of<ChatGPTBloc>(context)
                                  .newChatSessionId;

                          // Session newSession = await createNewChatSession();
                          // setState(() {
                          //   futureSessions = Future(() =>
                          //       [newSession, ...(snapshot.data ?? [])]);
                          // });
                        } catch (e) {
                          // Error logging suppressed
                        }
                      },
                      color: appButtonBackgroundColorGlobal,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: Text(
                        translation(context).lbl_try_again,
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  ],
                ),
              );
            }
            else {
              return Text(translation(context).lbl_error);
            }
          })),
    );
  }

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

  String imageType = '';

  void _showFileOptions() {
    int imageLimit = 0;
    debugPrint(imageType);
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
              imageType: imageType,
              imageUploadBloc,
              imageLimit: imageLimit, (imageFiles) {
            selectedImageFiles = imageFiles;
            debugPrint(selectedImageFiles.toString());
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
                  translation(context).lbl_select_option,
                  style: TextStyle(fontSize: 18),
                ),
                _buildHorizontalOption(
                  icon: Icons.image_search,
                  text: translation(context).lbl_dermatological_assessment,
                  onTap: () async {
                    Navigator.pop(context);
                    imageType = 'Dermatological';
                    _showFileOptions();
                  },
                ),
                // _buildHorizontalOption(
                //   icon: Icons.image_search,
                //   text: 'ECG analysis',
                //   onTap: () async {
                //     Navigator.pop(context);
                //     imageType = 'ECG';
                //     _showFileOptions();
                //   },
                // ),
                _buildHorizontalOption(
                  icon: Icons.image_search,
                  text: translation(context).lbl_xray_evaluation,
                  onTap: () async {
                    Navigator.pop(context);
                    imageType = 'X-ray';
                    _showFileOptions();
                  },
                ),
                _buildHorizontalOption(
                  icon: Icons.image_search,
                  text: translation(context).lbl_ct_scan_evaluation,
                  onTap: () async {
                    Navigator.pop(context);
                    imageType = 'CT Scan';
                    _showFileOptions();
                  },
                ),
                _buildHorizontalOption(
                  icon: Icons.image_search,
                  text: translation(context).lbl_mri_evaluation,
                  onTap: () async {
                    Navigator.pop(context);
                    imageType = 'MRI Scan';
                    _showFileOptions();
                  },
                ),
                _buildHorizontalOption(
                  icon: Icons.image_search,
                  text: translation(context).lbl_mammography_analysis,
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

  Future<void> _permissionDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          // <-- SEE HERE
          title: Text(
            translation(context).msg_something_wrong,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.sp),
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
