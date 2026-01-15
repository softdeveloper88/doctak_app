import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/chat_gpt_screen/bloc/chat_gpt_bloc.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:doctak_app/widgets/shimmer_widget/shimmer_card_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

// import 'package:timeago/timeago.dart' as timeAgo;
import 'package:intl/intl.dart';

import '../../data/models/chat_gpt_model/ChatGPTResponse.dart';
import '../../main.dart';
import '../../data/models/chat_gpt_model/ChatGPTSessionModel.dart';
import '../../data/models/chat_gpt_model/chat_gpt_sesssion/chat_gpt_session.dart';
import 'bloc/chat_gpt_event.dart';
import 'bloc/chat_gpt_state.dart';
import 'chat_delete_dialog.dart';

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({required this.onTap, required this.onNewSessionTap, super.key});

  final Function(Sessions) onTap;
  final Function onNewSessionTap;

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  // final ScrollController _scrollController = ScrollController();

  List<ChatGPTResponse> messages = [];
  // Add this line
  late Future<List<Session>> futureSessions;

  int? selectedSessionId = 0;
  // State variable for tracking selected session
  Future<List<ChatGPTResponse>> futureMessages = Future.value([]);

  final TextEditingController textController = TextEditingController();

  bool isLoadingMessages = true;

  bool isEmptyPage = true;

  bool isDrawerOpen = false;

  bool isWriting = false;

  String chatWithAi = "";

  bool isDeleteButtonClicked = false;
  final ChatGPTBloc chatGPTBloc = ChatGPTBloc()..add(LoadDataValues());

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    chatWithAi = translation(context).lbl_preparing_ai;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: svGetBgColor(),
      appBar: DoctakAppBar(
        title: translation(context).lbl_history_ai,
        titleIcon: Icons.history_rounded,
        actions: [
          // New chat button
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(Icons.add, color: Colors.blue[600], size: 14),
              ),
              onPressed: () {
                widget.onNewSessionTap();
              },
            ),
          ),
        ],
      ),
      body: BlocConsumer<ChatGPTBloc, ChatGPTState>(
        listener: (context, state) {},
        bloc: chatGPTBloc,
        builder: (context, state1) {
          if (selectedSessionId == 0 && state1 is DataLoaded) {
            selectedSessionId = state1.response.newSessionId;
            chatWithAi = state1.response.sessions?.first.name ?? translation(context).lbl_next_session;
          }
          if (state1 is DataInitial) {
            return const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [Expanded(child: ShimmerCardList())],
            );
          } else if (state1 is DataLoaded) {
            return Column(
              children: [
                Expanded(
                  child: Container(
                    color: svGetScaffoldColor(),
                    child: ListView.builder(
                      padding: EdgeInsets.only(top: 12, left: 0, right: 0, bottom: MediaQuery.of(context).padding.bottom + 12),
                      itemCount: state1.response.sessions?.length,
                      itemBuilder: (context, index) {
                        Sessions session = state1.response.sessions![index];
                        return Slidable(
                          key: ValueKey(session.id),
                          endActionPane: ActionPane(
                            motion: const ScrollMotion(),
                            extentRatio: 0.25,
                            children: [
                              SlidableAction(
                                onPressed: (context) {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return ChatDeleteDialog(
                                        title: ' ${session.name ?? ''}',
                                        callback: () {
                                          chatGPTBloc.add(DeleteChatSession(session.id ?? 0));
                                          Navigator.of(context).pop();
                                        },
                                      );
                                    },
                                  );
                                },
                                backgroundColor: Colors.red[400]!,
                                foregroundColor: Colors.white,
                                icon: Icons.delete_outline_rounded,
                                label: 'Delete',
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ],
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: appStore.isDarkMode ? Colors.blueGrey[800] : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.blue.withAlpha(26), width: 1),
                              boxShadow: [BoxShadow(color: Colors.blue.withAlpha(13), blurRadius: 8, spreadRadius: 0, offset: const Offset(0, 2))],
                            ),
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => widget.onTap(session),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        margin: const EdgeInsets.only(right: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[600],
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.2), blurRadius: 4, spreadRadius: 0, offset: const Offset(0, 2))],
                                        ),
                                        child: Center(child: Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 18)),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              session.name ?? "",
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: appStore.isDarkMode ? Colors.white : Colors.black87),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: <Widget>[
                                                Icon(Icons.access_time_rounded, size: 14, color: Colors.grey[600]),
                                                const SizedBox(width: 4),
                                                Text(
                                                  DateFormat('MMM dd, yyyy, h:mm a').format(DateTime.parse(session.createdAt!)),
                                                  style: TextStyle(fontSize: 12, fontFamily: 'Poppins', fontWeight: FontWeight.w400, color: Colors.grey[600]),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 24),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: MediaQuery.of(context).padding.bottom + 16.0),
                  decoration: BoxDecoration(
                    color: svGetScaffoldColor(),
                    boxShadow: [BoxShadow(color: Colors.blue.withAlpha(13), offset: const Offset(0, -3), blurRadius: 6)],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.2), offset: const Offset(0, 4), blurRadius: 8, spreadRadius: 0)],
                    ),
                    child: ElevatedButton(
                      onPressed: () => widget.onNewSessionTap(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_circle_outline_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            translation(context).lbl_new_chat,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return Container();
          }
        },
      ),
    );
  }
}
