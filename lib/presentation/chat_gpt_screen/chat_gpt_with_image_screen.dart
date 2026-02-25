import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/data/models/chat_gpt_model/ChatGPTResponse.dart';
import 'package:doctak_app/data/models/chat_gpt_model/ChatGPTSessionModel.dart';
import 'package:doctak_app/data/models/chat_gpt_model/chat_gpt_sesssion/chat_gpt_session.dart';
import 'package:doctak_app/presentation/chat_gpt_screen/bloc/chat_gpt_bloc.dart';
import 'package:doctak_app/presentation/chat_gpt_screen/bloc/chat_gpt_event.dart';
import 'package:doctak_app/presentation/chat_gpt_screen/bloc/chat_gpt_state.dart';
import 'package:doctak_app/presentation/chat_gpt_screen/chat_history_screen.dart';
import 'package:doctak_app/presentation/chat_gpt_screen/widgets/chat_bubble.dart';
import 'package:doctak_app/presentation/chat_gpt_screen/widgets/typing_indicators.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/widgets/ai_quota_banner.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../data/models/chat_gpt_model/chat_gpt_message_history/chat_gpt_message_history.dart';
import '../../widgets/image_upload_widget/bloc/image_upload_bloc.dart';
import '../../widgets/image_upload_widget/bloc/image_upload_event.dart';
import '../../widgets/image_upload_widget/bloc/image_upload_state.dart';
import '../../widgets/shimmer_widget/chat_shimmer_loader.dart';
import 'widgets/medical_citation_widget.dart';

@immutable
class ChatGptWithImageScreen extends StatefulWidget {
  final bool isFromMainScreen;
  final String? question;

  const ChatGptWithImageScreen({
    super.key,
    this.isFromMainScreen = true,
    this.question,
  });

  @override
  ChatGPTScreenState createState() => ChatGPTScreenState();
}

class ChatGPTScreenState extends State<ChatGptWithImageScreen>
    with WidgetsBindingObserver {
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
  late StreamSubscription imageUploadSubscription;
  List<int>? imageBytes1;
  List<int>? imageBytes2;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize the ChatGPT bloc with LoadDataValues event
    try {
      BlocProvider.of<ChatGPTBloc>(context).add(LoadDataValues());
    } catch (_) {}

    // Listen for image upload bloc updates
    imageUploadSubscription = imageUploadBloc.stream.listen((state) {
      if (state is FileLoadedState) {
        if (mounted) {
          setState(() {
            selectedImageFiles = List.from(imageUploadBloc.imagefiles);
          });
          // Read image bytes asynchronously
          _readImageBytes();
        }
      }
    });
  }

  // Helper used with compute() to read file bytes on a background isolate
  static Future<List<int>?> _readFileBytesIsolate(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) return await file.readAsBytes();
    } catch (_) {}
    return null;
  }

  // Read image bytes to avoid file access issues on Android
  Future<void> _readImageBytes() async {
    imageBytes1 = null;
    imageBytes2 = null;
    if (selectedImageFiles.isNotEmpty) {
      try {
        final path1 = selectedImageFiles.first.path;
        imageBytes1 = await compute(_readFileBytesIsolate, path1);
        print('Read imageBytes1: ${imageBytes1?.length ?? 0} bytes');
      } catch (e) {
        print('Error reading first image bytes: $e');
      }
      if (selectedImageFiles.length == 2) {
        try {
          final path2 = selectedImageFiles.last.path;
          imageBytes2 = await compute(_readFileBytesIsolate, path2);
          print('Read imageBytes2: ${imageBytes2?.length ?? 0} bytes');
        } catch (e) {
          print('Error reading second image bytes: $e');
        }
      }
    }
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
      updatedAt: DateTime.now().toString(),
    );

    state1.response1.messages!.add(myMessage);

    BlocProvider.of<ChatGPTBloc>(
      context,
    ).add(GetPost(sessionId: selectedSessionId.toString(), question: question));
    textController.clear();
    scrollToBottom();

    try {
      isWriting = false;
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
    WidgetsBinding.instance.removeObserver(this);
    focusNode.unfocus();
    _scrollController.dispose();
    textController.dispose();
    imageUploadSubscription.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('Main: App lifecycle changed to: $state');
    if (state == AppLifecycleState.resumed) {
      print('Main: App resumed from background');
      // Force a UI refresh when returning from gallery
      if (mounted) {
        setState(() {
          // Sync with current BLoC state
          selectedImageFiles = List.from(imageUploadBloc.imagefiles);
          print(
            'Main: Force refresh - selectedImageFiles has ${selectedImageFiles.length} files',
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: DoctakAppBar(
        title: translation(context).lbl_ai_image_analysis,
        titleIcon: Icons.image_search_rounded,
        actions: [
          // History button - OneUI 8.5 style
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history_rounded,
                color: theme.primary,
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
                    selectedImageFiles.clear();
                    imageUploadBloc.imagefiles.clear();
                    selectedSessionId = BlocProvider.of<ChatGPTBloc>(
                      context,
                    ).newChatSessionId;
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
                  BlocProvider.of<ChatGPTBloc>(
                    context,
                  ).add(GetMessages(sessionId: selectedSessionId.toString()));
                  Navigator.of(context).pop();
                },
              ).launch(context);
            },
          ),
          // New Analysis button - OneUI 8.5 style
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_photo_alternate_rounded,
                  color: theme.primary,
                  size: 16,
                ),
              ),
              onPressed: () {
                isOneTimeImageUploaded = false;
                selectedImageFiles.clear();
                imageUploadBloc.imagefiles.clear();
                try {
                  BlocProvider.of<ChatGPTBloc>(context).add(GetNewChat());
                  selectedSessionId = BlocProvider.of<ChatGPTBloc>(
                    context,
                  ).newChatSessionId;
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
          final bloc = BlocProvider.of<ChatGPTBloc>(context);

          if (selectedSessionId == 0 && state1 is DataLoaded) {
            selectedSessionId = state1.response.newSessionId;
            chatWithAi =
                (state1.response.sessions?.isNotEmpty == true
                    ? state1.response.sessions!.first.name
                    : null) ??
                translation(context).lbl_preparing_ai;
          }

          // Show SnackBar for question errors (lastError set by _askQuestion)
          // without leaving DataLoaded state — chat UI stays visible.
          if (state1 is DataLoaded && bloc.lastError != null) {
            final error = bloc.lastError!;
            bloc.lastError = null;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.red[700],
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            });
          }

          if (state1 is DataInitial || state1 is DataLoading) {
            return ChatShimmerLoader();
          } else if (state1 is DataLoaded) {
            // Only recalculate isEmpty when not actively sending a message
            // (otherwise mid-send BLoC emissions can flicker back to empty state)
            final bool hasMessages = state1.response1.messages?.isNotEmpty ?? false;
            if (hasMessages) {
              isEmpty = false;
            } else if (!bloc.isWait) {
              isEmpty = true;
            }

            // Reset send-button loading indicator when BLoC finishes
            if (isWriting && !bloc.isWait) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => isWriting = false);
              });
            }

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
                      color: theme.scaffoldBackground,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Usage/Plan banner
                            if (state1.response.usage != null) ...[  
                              const SizedBox(height: 6),
                              _buildUsageBanner(theme, state1.response.usage!),
                            ],
                            const SizedBox(height: 8),

                            // Hero Icon
                            Container(
                              width: 52,
                              height: 52,
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: theme.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.primary.withValues(alpha: 0.3),
                                    spreadRadius: 2,
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(Icons.image_search_rounded, color: Colors.white, size: 28),
                              ),
                            ),

                            // Title
                            Text(
                              'Medical Image Analysis',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                                color: theme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Upload a medical image and select the analysis type for AI-powered diagnostic insights.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11, fontFamily: 'Poppins', height: 1.4, color: theme.textSecondary),
                            ),
                            const SizedBox(height: 10),

                            // Analysis Type Cards Grid — fills remaining space
                            Expanded(
                              child: GridView.count(
                                crossAxisCount: 3,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                childAspectRatio: 0.88,
                                padding: const EdgeInsets.only(bottom: 8),
                                children: [
                                  _buildAnalysisCard(theme, Icons.medical_services, 'X-Ray Analysis', 'Analyze chest, bone & joint X-rays', 'X-ray'),
                                  _buildAnalysisCard(theme, Icons.monitor_heart_outlined, 'ECG Interpretation', 'Interpret ECG / EKG tracings', 'ECG'),
                                  _buildAnalysisCard(theme, Icons.scanner, 'CT Scan Review', 'Review CT scan images & cross-sections', 'CT Scan'),
                                  _buildAnalysisCard(theme, Icons.psychology_rounded, 'MRI Analysis', 'Analyze MRI images for abnormalities', 'MRI Scan'),
                                  _buildAnalysisCard(theme, Icons.favorite_border_rounded, 'Mammogram Review', 'Evaluate mammogram findings', 'Mammography'),
                                  _buildAnalysisCard(theme, Icons.face_retouching_natural, 'Dermatology', 'Analyze skin lesions & conditions', 'Dermatological'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Container(
                      color: theme.scaffoldBackground,
                      child: Column(
                        children: [
                          // Compact usage banner in chat view
                          if (state1.response.usage != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                              child: _buildUsageBanner(theme, state1.response.usage!),
                            ),
                          Expanded(
                            child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: state1.response1.messages?.length,
                        itemBuilder: (context, index) {
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
                                imageBytes1: index != 0
                                    ? null
                                    : (message.imageBytes1 ?? imageBytes1),
                                imageBytes2: index != 0
                                    ? null
                                    : (message.imageBytes2 ?? imageBytes2),
                                responseImageUrl1: index != 0
                                    ? ''
                                    : message.imageUrl1 ?? '',
                                responseImageUrl2: index != 0
                                    ? ''
                                    : message.imageUrl2 ?? '',
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
                                imageBytes1: message.imageBytes1 ?? imageBytes1,
                                imageBytes2: message.imageBytes2 ?? imageBytes2,
                                responseImageUrl1: message.imageUrl1 ?? '',
                                responseImageUrl2: message.imageUrl2 ?? '',
                                onTapReginarate: () {
                                  String question = message.question ?? "";
                                  if (question.isEmpty) return;

                                  setState(() {
                                    var myMessage = Messages(
                                      id: -1,
                                      gptSessionId: selectedSessionId
                                          .toString(),
                                      question: question,
                                      imageUrl1: message.imageUrl1,
                                      imageUrl2: message.imageUrl2,
                                      response: translation(
                                        context,
                                      ).lbl_generating_response,
                                      createdAt: DateTime.now().toString(),
                                      updatedAt: DateTime.now().toString(),
                                    );
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
                                      SnackBar(content: Text('Error: $e')),
                                    );
                                  }
                                },
                              ),
                              // Apple Guideline 1.4.1: show medical citation sources
                              if ((message.sources?.isNotEmpty ?? false))
                                MedicalCitationWidget(sources: message.sources!),
                              // Disclaimer on every AI response
                              if ((message.response?.isNotEmpty ?? false) &&
                                  message.response != translation(context).lbl_generating_response)
                                const MedicalDisclaimerBanner(),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                  ),
                    ),
                  ),

                // Image Preview Section - redesigned
                _buildImagePreview(),

                // Quota banner — shared component, shows warning/block/upgrade button
                AiQuotaBanner(usage: state1.response.usage),

                // Input Section - completely redesigned using drugs_list pattern
                IgnorePointer(
                  ignoring: state1.response.usage != null && !state1.response.usage!.canUse,
                  child: Opacity(
                    opacity: (state1.response.usage != null && !state1.response.usage!.canUse) ? 0.4 : 1.0,
                    child: Container(
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackground,
                    boxShadow: [
                      BoxShadow(
                        color: theme.primary.withValues(alpha: 0.05),
                        offset: const Offset(0, -3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  padding: EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    top: 8.0,
                    bottom: 8.0 + MediaQuery.of(context).viewPadding.bottom,
                  ),
                  child: Column(
                    children: [
                      // Analysis type chips — hidden (selection via cards on empty state)
                      // Uncomment to restore horizontal chip row:
                      // SizedBox(height: 36, child: ListView(...)),
                      // const SizedBox(height: 6),

                      Container(
                        decoration: BoxDecoration(
                          color: theme.inputBackground,
                          borderRadius: BorderRadius.circular(24.0),
                          border: Border.all(
                            color: theme.primary.withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.primary.withValues(alpha: 0.05),
                              offset: const Offset(0, 2),
                              blurRadius: 8,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Attachment button - OneUI 8.5 style
                            IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.attach_file_rounded,
                                  color: theme.primary,
                                  size: 20,
                                ),
                              ),
                              onPressed: () {
                                if (isOneTimeImageUploaded) {
                                  toasty(
                                    context,
                                    translation(context).lbl_only_one_image_allowed,
                                  );
                                } else {
                                  _showFileOptions();
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
                                  fontSize: 13,
                                  color: theme.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  hintStyle: TextStyle(
                                    color: theme.textSecondary,
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                  ),
                                  hintText: translation(
                                    context,
                                  ).msg_clinical_summary_hint,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical: 10.0,
                                  ),
                                ),
                              ),
                            ),

                            // Send button
                            Container(
                              margin: const EdgeInsets.only(right: 8.0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.primary,
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.primary.withValues(alpha: 0.3),
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
                                    // Dismiss keyboard reliably on both iOS and Android
                                    FocusScope.of(context).unfocus();
                                    FocusManager.instance.primaryFocus
                                        ?.unfocus();

                                    isError = true;

                                    if (selectedImageFiles.isEmpty &&
                                        imageUploadBloc.imagefiles.isEmpty &&
                                        !isOneTimeImageUploaded) {
                                      // No image selected and no previous image uploaded
                                      // Allow text-only message if field is not empty
                                      String question = textController.text.trim();
                                      if (question.isEmpty) {
                                        toasty(
                                          context,
                                          translation(context).lbl_please_ask_question,
                                        );
                                        return;
                                      }
                                      setState(() {
                                        isWriting = true;
                                        isOneTimeImageUploaded = false;
                                        isEmpty = false;
                                        var myMessage = Messages(
                                          id: -1,
                                          gptSessionId: selectedSessionId.toString(),
                                          question: question,
                                          response: translation(context).lbl_generating_response,
                                          createdAt: DateTime.now().toString(),
                                          updatedAt: DateTime.now().toString(),
                                        );
                                        state1.response1.messages ??= [];
                                        state1.response1.messages!.add(myMessage);
                                        BlocProvider.of<ChatGPTBloc>(context).add(
                                          GetPost(
                                            sessionId: selectedSessionId.toString(),
                                            question: question,
                                            imageUrl1: null,
                                            imageUrl2: null,
                                            imageType: imageType.isEmpty ? 'General' : imageType,
                                          ),
                                        );
                                        textController.clear();
                                        scrollToBottom();
                                      });
                                      try {
                                        isWriting = false;
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error: $e')),
                                        );
                                      }
                                    } else if (selectedImageFiles.isEmpty &&
                                        imageUploadBloc.imagefiles.isEmpty &&
                                        isOneTimeImageUploaded) {
                                      String question = textController.text
                                          .trim();
                                      if (question != '') {
                                        setState(() {
                                          isWriting = true;
                                          isOneTimeImageUploaded = true;
                                          var myMessage = Messages(
                                            id: -1,
                                            gptSessionId: selectedSessionId
                                                .toString(),
                                            question: question,
                                            response: translation(
                                              context,
                                            ).lbl_generating_response,
                                            createdAt: DateTime.now()
                                                .toString(),
                                            updatedAt: DateTime.now()
                                                .toString(),
                                            imageUrl1: '',
                                            imageUrl2: '',
                                            imageBytes1: imageBytes1,
                                            imageBytes2: imageBytes2,
                                          );
                                          state1.response1.messages!.add(
                                            myMessage,
                                          );

                                          BlocProvider.of<ChatGPTBloc>(
                                            context,
                                          ).add(
                                            GetPost(
                                              sessionId: selectedSessionId
                                                  .toString(),
                                              question: question,
                                              imageUrl1: null,
                                              imageUrl2: null,
                                              imageType: imageType,
                                            ),
                                          );
                                          imageUploadBloc.imagefiles.clear();
                                          selectedImageFiles.clear();
                                          textController.clear();
                                          scrollToBottom();
                                        });

                                        try {
                                          isWriting = false;
                                        } catch (e) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text('Error: $e'),
                                            ),
                                          );
                                        }
                                      } else {
                                        toasty(
                                          context,
                                          translation(
                                            context,
                                          ).lbl_please_ask_question,
                                        );
                                      }
                                    } else if (imageUploadBloc
                                            .imagefiles
                                            .isNotEmpty &&
                                        !isOneTimeImageUploaded) {
                                      String question = textController.text
                                          .trim();

                                      // mark used immediately (sync); heavy work below
                                      setState(() {
                                        isWriting = true;
                                        isOneTimeImageUploaded = true;
                                      });

                                      // Read bytes off the UI thread so the optimistic
                                      // message includes in-memory bytes (stable UI).
                                      List<int>? outgoingBytes1;
                                      List<int>? outgoingBytes2;
                                      try {
                                        final path1 = imageUploadBloc
                                            .imagefiles
                                            .first
                                            .path;
                                        outgoingBytes1 = await compute(
                                          _readFileBytesIsolate,
                                          path1,
                                        );
                                        if (imageUploadBloc.imagefiles.length >
                                            1) {
                                          final path2 = imageUploadBloc
                                              .imagefiles
                                              .last
                                              .path;
                                          outgoingBytes2 = await compute(
                                            _readFileBytesIsolate,
                                            path2,
                                          );
                                        }
                                      } catch (e) {
                                        try {
                                          final f1 = File(
                                            imageUploadBloc
                                                .imagefiles
                                                .first
                                                .path,
                                          );
                                          if (await f1.exists())
                                            outgoingBytes1 = await f1
                                                .readAsBytes();
                                          if (imageUploadBloc
                                                  .imagefiles
                                                  .length >
                                              1) {
                                            final f2 = File(
                                              imageUploadBloc
                                                  .imagefiles
                                                  .last
                                                  .path,
                                            );
                                            if (await f2.exists())
                                              outgoingBytes2 = await f2
                                                  .readAsBytes();
                                          }
                                        } catch (_) {
                                          outgoingBytes1 = null;
                                          outgoingBytes2 = null;
                                        }
                                      }

                                      var myMessage = Messages(
                                        id: -1,
                                        gptSessionId: selectedSessionId
                                            .toString(),
                                        question: question,
                                        response: translation(
                                          context,
                                        ).lbl_generating_response,
                                        createdAt: DateTime.now().toString(),
                                        updatedAt: DateTime.now().toString(),
                                        imageUrl1: imageUploadBloc
                                            .imagefiles
                                            .first
                                            .path,
                                        imageUrl2:
                                            imageUploadBloc.imagefiles.length >
                                                1
                                            ? imageUploadBloc
                                                  .imagefiles
                                                  .last
                                                  .path
                                            : imageUploadBloc
                                                  .imagefiles
                                                  .first
                                                  .path,
                                        imageBytes1:
                                            outgoingBytes1 ?? imageBytes1,
                                        imageBytes2:
                                            outgoingBytes2 ?? imageBytes2,
                                      );

                                      // Add the optimistic message and start the request
                                      setState(() {
                                        isEmpty = false;
                                        state1.response1.messages ??= [];
                                        state1.response1.messages!.add(myMessage);
                                      });
                                      BlocProvider.of<ChatGPTBloc>(context).add(
                                        GetPost(
                                          sessionId: selectedSessionId
                                              .toString(),
                                          question: question == ""
                                              ? translation(
                                                  context,
                                                ).lbl_analyse_image
                                              : question,
                                          imageUrl1: imageUploadBloc
                                              .imagefiles
                                              .first
                                              .path,
                                          imageUrl2: imageUploadBloc
                                              .imagefiles
                                              .last
                                              .path,
                                          imageType: imageType,
                                        ),
                                      );

                                      imageUploadBloc.imagefiles.clear();
                                      selectedImageFiles.clear();
                                      textController.clear();
                                      scrollToBottom();
                                      try {
                                        isWriting = false;
                                      } catch (e) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(content: Text('Error: $e')),
                                        );
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
                          color: theme.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                  ),
                ),
              ],
            );
          } else if (state1 is DataError) {
            return _buildErrorState(context, state1.errorMessage.toString());
          } else {
            return Text(translation(context).lbl_error);
          }
        },
      ),
    );
  }

  // ── Analysis Type Card (for empty state grid) ──────────────────────────
  Widget _buildAnalysisCard(
    dynamic theme,
    IconData icon,
    String title,
    String subtitle,
    String type,
  ) {
    return GestureDetector(
      onTap: () {
        if (isOneTimeImageUploaded) {
          toasty(context, translation(context).lbl_only_one_image_allowed);
          return;
        }
        imageType = type;
        _showFileOptions();
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.primary.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: theme.primary, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                color: theme.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontFamily: 'Poppins',
                color: theme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Usage / Plan Banner (like website) ────────────────────────────────
  Widget _buildUsageBanner(dynamic theme, AiUsageInfo usage) {
    final isFreePlan = !usage.isPaid;
    final percent = usage.dailyLimit > 0
        ? (usage.dailyUsed / usage.dailyLimit).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isFreePlan
            ? theme.warning.withValues(alpha: 0.10)
            : theme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFreePlan
              ? theme.warning.withValues(alpha: 0.30)
              : theme.primary.withValues(alpha: 0.30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isFreePlan ? Icons.workspace_premium : Icons.verified,
                size: 18,
                color: isFreePlan ? theme.warning : theme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                usage.planName.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                  color: isFreePlan ? theme.warning : theme.primary,
                ),
              ),
              const Spacer(),
              Text(
                '${usage.dailyRemaining} left today',
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: theme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 5,
              backgroundColor: theme.textSecondary.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(
                isFreePlan ? theme.warning : theme.primary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${usage.dailyUsed} of ${usage.dailyLimit} analyses used today',
            style: TextStyle(
              fontSize: 10,
              fontFamily: 'Poppins',
              color: theme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // Image Preview Widget - simplified to use selectedImageFiles directly
  Widget _buildImagePreview() {
    print(
      'Main: _buildImagePreview - selectedImageFiles has ${selectedImageFiles.length} images',
    );
    return Container(
      color: svGetScaffoldColor(),
      child: selectedImageFiles.isNotEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: selectedImageFiles.map((imageone) {
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
                              color: Colors.blue.withValues(alpha: 0.2),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              File(imageone.path),
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: -4,
                          right: -4,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {});
                              selectedImageFiles.remove(imageone);
                              imageUploadBloc.add(
                                SelectedFiles(
                                  pickedfiles: imageone,
                                  isRemove: true,
                                ),
                              );
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
            )
          : Container(),
    );
  }

  // Error State Widget - redesigned using drugs_list pattern
  Widget _buildErrorState(BuildContext context, String errorMessage) {
    final errorTheme = OneUITheme.of(context);
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
              color: errorTheme.error.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              color: errorTheme.error,
              size: 30,
            ),
          ),
          Text(
            translation(context).lbl_error,
            style: TextStyle(
              color: errorTheme.error,
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
              color: errorTheme.textPrimary,
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
                  color: errorTheme.primary.withAlpha(51),
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
                  selectedImageFiles.clear();
                  imageUploadBloc.imagefiles.clear();
                  selectedSessionId = BlocProvider.of<ChatGPTBloc>(
                    context,
                  ).newChatSessionId;
                } catch (e) {
                  debugPrint(e.toString());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: errorTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
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

  // ── Native image picker (Gallery / Camera) ────────────────────────────
  void _showFileOptions() {
    // X-ray and Mammography allow 2 images; everything else is limited to 1
    final int imageLimit =
        (imageType == 'X-ray' || imageType == 'Mammography') ? 2 : 1;
    final String typeName =
        imageType.isEmpty ? 'Medical' : imageType;
    final String limitDesc = imageLimit == 1
        ? 'Select up to 1 image for AI analysis'
        : 'Select up to $imageLimit images for AI analysis';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (ctx) {
        final t = OneUITheme.of(ctx);
        return Container(
          decoration: BoxDecoration(
            color: t.cardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 18,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(
            20, 16, 20, 24 + MediaQuery.of(ctx).viewPadding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: t.textSecondary.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title + limit description
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: t.primary,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: t.primary.withValues(alpha: 0.28),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.cloud_upload_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upload $typeName Image${imageLimit > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                            color: t.textPrimary,
                          ),
                        ),
                        Text(
                          limitDesc,
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'Poppins',
                            color: t.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Info tip banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: t.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: t.primary.withValues(alpha: 0.18)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: t.primary, size: 15),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'High-quality images provide better AI analysis results',
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'Poppins',
                          color: t.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _pickerOption(
                t,
                Icons.photo_library_rounded,
                'Choose from Gallery',
                imageLimit > 1
                    ? 'Pick up to $imageLimit images from your device'
                    : 'Pick an existing photo from your device',
                () async {
                  Navigator.pop(ctx);
                  await _pickImages(ImageSource.gallery, imageLimit);
                },
              ),
              const SizedBox(height: 12),
              _pickerOption(
                t,
                Icons.camera_alt_rounded,
                'Take a Photo',
                'Use your camera to capture a medical image',
                () async {
                  Navigator.pop(ctx);
                  await _pickImages(ImageSource.camera, 1);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _pickerOption(
    dynamic theme,
    IconData icon,
    String title,
    String subtitle,
    Future<void> Function() onTap,
  ) {
    return GestureDetector(
      onTap: () => onTap(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.inputBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.primary.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: theme.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                      color: theme.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'Poppins',
                      color: theme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: theme.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImages(ImageSource source, int limit) async {
    try {
      final picker = ImagePicker();
      List<XFile> picked = [];

      if (source == ImageSource.camera || limit == 1) {
        // Camera always produces a single shot; Gallery with limit=1 also single
        final XFile? file = await picker.pickImage(
          source: source,
          imageQuality: 90,
        );
        if (file != null) picked = [file];
      } else {
        // Gallery multi-select (X-ray / Mammography allow up to 2)
        // Note: limit parameter not universally supported on Android — enforce via sublist
        final List<XFile> files = await picker.pickMultiImage(
          imageQuality: 90,
        );
        picked = files;
      }

      if (picked.isEmpty || !mounted) return;

      // Enforce hard limit
      if (picked.length > limit) picked = picked.sublist(0, limit);

      imageUploadBloc.imagefiles
        ..clear()
        ..addAll(picked);
      setState(() {
        selectedImageFiles = List.from(picked);
      });
      await _readImageBytes();
    } catch (e) {
      debugPrint('Image pick error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open image picker: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
