import 'dart:async';

import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/data/models/chat_gpt_model/ChatGPTResponse.dart';
import 'package:doctak_app/data/models/chat_gpt_model/ChatGPTSessionModel.dart';
import 'package:doctak_app/main.dart';
import 'package:doctak_app/presentation/chat_gpt_screen/bloc/chat_gpt_bloc.dart';
import 'package:doctak_app/presentation/chat_gpt_screen/bloc/chat_gpt_event.dart';
import 'package:doctak_app/presentation/chat_gpt_screen/bloc/chat_gpt_state.dart';
import 'package:doctak_app/presentation/chat_gpt_screen/chat_history_screen.dart';
import 'package:doctak_app/presentation/chat_gpt_screen/widgets/chat_bubble.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/widgets/shimmer_widget/chat_shimmer_loader.dart';
import 'package:flutter/material.dart';
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
  String chatWithAi = "";
  bool isDeleteButtonClicked = false;
  bool isAlreadyAsk = true;
  bool isEmpty = false;
  FocusNode focusNode = FocusNode();

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
  void initState() {
    super.initState();
    chatWithAi = "Preparing DocTak AI.";
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    chatWithAi = translation(context).lbl_preparing_ai;
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
      body: Column(
        children: [
          // App Bar - completely redesigned using drugs_list pattern
          AppBar(
            backgroundColor: svGetScaffoldColor(),
            iconTheme: IconThemeData(color: context.iconColor),
            elevation: 0,
            toolbarHeight: 70,
            surfaceTintColor: svGetScaffoldColor(),
            centerTitle: true,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.blue[600],
                  size: 16,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.psychology_rounded,
                  color: Colors.blue[600],
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  "DocTak AI",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
            actions: [
              // History button
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.history_rounded,
                    color: Colors.blue[600],
                    size: 14,
                  ),
                ),
                onPressed: () {
                  ChatHistoryScreen(
                    onNewSessionTap: () {
                      try {
                        BlocProvider.of<ChatGPTBloc>(context).add(GetNewChat());
                        Navigator.of(context).pop();
                        selectedSessionId = BlocProvider.of<ChatGPTBloc>(context).newChatSessionId;
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
              // New chat button
              Container(
                margin: const EdgeInsets.only(right: 16),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add,
                      color: Colors.blue[600],
                      size: 14,
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
          
          // Main content - completely redesigned
          Expanded(
            child: BlocBuilder<ChatGPTBloc, ChatGPTState>(
              builder: (context, state1) {
                  if (selectedSessionId == 0 && state1 is DataLoaded) {
                    selectedSessionId = state1.response.newSessionId;
                    chatWithAi = state1.response.sessions?.first.name ?? translation(context).lbl_next_session;
                  }
                  
                  if (state1 is DataInitial || state1 is DataLoading) {
                    return ChatShimmerLoader();
                  } else if (state1 is DataLoaded) {
                    isEmpty = state1.response1.messages?.isEmpty ?? false;
                    
                    if (!widget.isFromMainScreen) {
                      if (isAlreadyAsk) {
                        isEmpty = false;
                        isAlreadyAsk = false;
                        drugsAskQuestion(state1, context);
                      }
                    }
                    
                    return Column(
                      children: [
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
                                        translation(context).lbl_welcome_doctor,
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Poppins',
                                          letterSpacing: 0.5,
                                          color: appStore.isDarkMode ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      
                                      // Description
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 24),
                                        child: Text(
                                          translation(context).msg_ai_assistant_intro,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontFamily: 'Poppins',
                                            height: 1.5,
                                            color: appStore.isDarkMode 
                                                ? Colors.white70
                                                : Colors.black.withAlpha(179),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 40),
                                      
                                      // Feature Cards Title
                                      Text(
                                        translation(context).lbl_select_option,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Poppins',
                                          color: Colors.blue[700],
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      
                                      // Feature Options Grid - redesigned
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildFeatureCard(
                                              context,
                                              Icons.qr_code_rounded,
                                              translation(context).lbl_code_detection,
                                              translation(context).lbl_identify_cpt_icd,
                                              [Colors.purple[400]!, Colors.purple[600]!],
                                              () {
                                                widget.question = translation(context).lbl_code_detection_question;
                                                setState(() {
                                                  isEmpty = false;
                                                });
                                                drugsAskQuestion(state1, context);
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: _buildFeatureCard(
                                              context,
                                              Icons.healing_rounded,
                                              translation(context).lbl_diagnostic_suggestions,
                                              translation(context).lbl_request_suggestions,
                                              [Colors.teal[400]!, Colors.teal[600]!],
                                              () {
                                                widget.question = translation(context).lbl_diagnostic_suggestions_question;
                                                setState(() {
                                                  isEmpty = false;
                                                });
                                                drugsAskQuestion(state1, context);
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      
                                      // Full width medication card
                                      _buildFeatureCard(
                                        context,
                                        Icons.medication_rounded,
                                        translation(context).lbl_medication_review,
                                        translation(context).lbl_check_interactions,
                                        [Colors.blue[400]!, Colors.blue[600]!],
                                        () {
                                          widget.question = translation(context).lbl_medication_review_question;
                                          setState(() {
                                            isEmpty = false;
                                          });
                                          drugsAskQuestion(state1, context);
                                        },
                                        isFullWidth: true,
                                      ),
                                      
                                      const SizedBox(height: 32),
                                      
                                      // Info Container - redesigned
                                      Container(
                                        decoration: BoxDecoration(
                                          color: appStore.isDarkMode
                                              ? Colors.blue.withAlpha(26)
                                              : Colors.blue.withAlpha(13),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: Colors.blue.withAlpha(51),
                                            width: 1.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.blue.withAlpha(13),
                                              offset: const Offset(0, 2),
                                              blurRadius: 8,
                                              spreadRadius: 0,
                                            ),
                                          ],
                                        ),
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.amber.withAlpha(51),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.lightbulb_rounded,
                                                color: Colors.amber[700],
                                                size: 18,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                translation(context).lbl_ready_to_start,
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.blue[700],
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
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: appStore.isDarkMode
                                      ? [Colors.blueGrey[900]!, Colors.blueGrey[800]!]
                                      : [Colors.white, Colors.blue.withAlpha(13)],
                                ),
                              ),
                              child: ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(16),
                                itemCount: state1.response1.messages?.length,
                                itemBuilder: (context, index) {
                                  Messages message = state1.response1.messages?[index] ?? Messages();
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
                                          
                                          setState(() {
                                            var myMessage = Messages(
                                                id: -1,
                                                gptSessionId: selectedSessionId.toString(),
                                                question: question,
                                                imageUrl1: message.imageUrl1,
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
                                        imageUrl2: null,
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        
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
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
                                          hintText: translation(context).lbl_ask_medical_ai,
                                          border: InputBorder.none,
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 20.0, 
                                            vertical: 16.0
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.only(right: 8.0),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [Colors.blue[400]!, Colors.blue[600]!],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.blue.withAlpha(77),
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
                                            focusNode.unfocus();
                                            String question = textController.text.trim();
                                            if (question.isEmpty) return;
                                            
                                            setState(() {
                                              var myMessage = Messages(
                                                id: -1,
                                                gptSessionId: selectedSessionId.toString(),
                                                question: question,
                                                response: translation(context).lbl_generating_response,
                                                createdAt: DateTime.now().toString(),
                                                updatedAt: DateTime.now().toString(),
                                                imageUrl1: '',
                                              );
                                              state1.response1.messages!.add(myMessage);
                                              BlocProvider.of<ChatGPTBloc>(context).add(
                                                GetPost(
                                                  sessionId: selectedSessionId.toString(),
                                                  question: question,
                                                  imageUrl1: ''
                                                ),
                                              );

                                              textController.clear();
                                              scrollToBottom();
                                            });
                                            
                                            try {
                                              isWriting = false;
                                            } catch (e) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Error: $e'),
                                                  behavior: SnackBarBehavior.floating,
                                                ),
                                              );
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
                              const SizedBox(height: 8),
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
                    return _buildErrorState(context);
                  } else {
                    return const Text('error');
                  }
                }
              ),
          ),
        ],
      ),
    );
  }

  // Feature Card Widget - completely redesigned using drugs_list pattern
  Widget _buildFeatureCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    List<Color> gradientColors,
    VoidCallback onTap, {
    bool isFullWidth = false,
  }) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: appStore.isDarkMode
                  ? Colors.blueGrey[800]
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: gradientColors.first.withAlpha(51),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: gradientColors.first.withAlpha(26),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors.first.withAlpha(102),
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
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    color: appStore.isDarkMode ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
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
        ),
      ),
    );
  }

  // Error State Widget - redesigned using drugs_list pattern
  Widget _buildErrorState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.red.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              color: Colors.red[600],
              size: 40,
            ),
          ),
          Text(
            translation(context).lbl_error,
            style: TextStyle(
              color: Colors.red[700],
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 16),
          Text(
            translation(context).msg_something_went_wrong_try_again,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: appStore.isDarkMode ? Colors.white70 : Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 32),
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
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
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