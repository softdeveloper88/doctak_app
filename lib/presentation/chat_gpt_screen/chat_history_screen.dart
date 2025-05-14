import 'package:doctak_app/core/utils/image_constant.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/chat_gpt_screen/bloc/chat_gpt_bloc.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVColors.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/widgets/AnimatedBackground.dart';
import 'package:doctak_app/widgets/shimmer_widget/chat_shimmer_loader.dart';
import 'package:doctak_app/widgets/shimmer_widget/comment_list_shimmer.dart';
import 'package:doctak_app/widgets/shimmer_widget/shimmer_card_list.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';

// import 'package:timeago/timeago.dart' as timeAgo;
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:sizer/sizer.dart';

import '../../data/models/chat_gpt_model/ChatGPTResponse.dart';
import '../../data/models/chat_gpt_model/ChatGPTSessionModel.dart';
import '../../data/models/chat_gpt_model/chat_gpt_sesssion/chat_gpt_session.dart';
import 'bloc/chat_gpt_event.dart';
import 'bloc/chat_gpt_state.dart';
import 'chat_delete_dialog.dart';

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen(
      {required this.onTap, required this.onNewSessionTap, super.key});

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
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: svGetBodyColor(),size: 17,),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: false,
        surfaceTintColor: context.cardColor,
        backgroundColor: context.cardColor,
        title: Text(
          translation(context).lbl_history_ai,
          style: TextStyle(fontSize: 17,fontWeight: FontWeight.w400),
        ),
      ),
      body: BlocConsumer<ChatGPTBloc, ChatGPTState>(
          listener: (context, state) {},
          bloc: chatGPTBloc,
          builder: (context, state1) {
            if (selectedSessionId == 0 && state1 is DataLoaded) {
              selectedSessionId = state1.response.newSessionId;
              chatWithAi =
                  state1.response.sessions?.first.name ?? translation(context).lbl_next_session;
            }
            if (state1 is DataInitial) {
              return Scaffold(
                backgroundColor: svGetBgColor(),
                body: AnimatedBackground(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      SizedBox(
                          height: 90.h,
                          child: ShimmerCardList())
                    ],
                  ),
                ),
              );
            } else if (state1 is DataLoaded) {
              return AnimatedBackground(
                  child: Column(
                children: [
                  Expanded(
                    child: Container(
                      color: svGetBgColor(),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: state1.response.sessions?.length,
                        itemBuilder: (context, index) {
                          Sessions session = state1.response.sessions![index];
                          // bool isSelected = session.id == selectedSessionId;
                          return Slidable(
                              key: ValueKey(session.id),
                              // Use session's id as a unique key
                              startActionPane: const ActionPane(
                                motion: ScrollMotion(),
                                children: [
                                  // SlidableAction(
                                  //   onPressed: (context) =>
                                  //       deleteRecord(context, session.id),
                                  //   // Reference to your delete method
                                  //   backgroundColor: Color(0xFFFE4A49),
                                  //   foregroundColor: Colors.white,
                                  //   icon: Icons.delete,
                                  //   label: 'Delete',
                                  // ),
                                  // SlidableAction(
                                  //   onPressed: (context) =>
                                  //       editRecord(context, session.id),
                                  //   // Reference to your edit method
                                  //   backgroundColor: Color(0xFF21B7CA),
                                  //   foregroundColor: Colors.white,
                                  //   icon: Icons.edit,
                                  //   label: 'Edit',
                                  // ),
                                ],
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                    color: context.cardColor,
                                    borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.all(16),
                                margin: const EdgeInsets.only(
                                  top: 8,
                                  left: 8,
                                  right: 8,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => widget.onTap(session),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              session.name ?? "",
                                              overflow: TextOverflow.clip,
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w400,
                                                  color: svGetBodyColor()),
                                            ),
                                            Row(
                                              children: <Widget>[
                                               SvgPicture.asset(icTimeDate,
                                                    height: 16,
                                                    width: 16,
                                                    color: svGetBodyColor()),
                                                const SizedBox(
                                                  width: 2,
                                                ),
                                                Text(
                                                  DateFormat('MM dd, yyyy, h:mm a')
                                                      .format(DateTime.parse(
                                                          session.createdAt!)),
                                                  // timeAgo.format(DateTime.parse(
                                                  //     session.createdAt!)),
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      color: svGetBodyColor()),
                                                ),
                                              ],
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return ChatDeleteDialog(
                                                  title:
                                                      ' ${session.name ?? ''}',
                                                  callback: () {
                                                    chatGPTBloc.add(
                                                        DeleteChatSession(
                                                            session.id ?? 0));
                                                    Navigator.of(context).pop();
                                                  });
                                            });
                                      },
                                      child: Container(
                                          decoration: BoxDecoration(
                                              color:
                                                  Colors.red.withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(6)),
                                          padding: const EdgeInsets.all(4),
                                          child: const Icon(
                                            CupertinoIcons.delete,
                                            color: Colors.red,
                                          )),
                                    )
                                  ],
                                ),
                                // title: Text(session.name!),
                                // subtitle: Text(DateFormat('m d, y, h:mm a')
                                //     .format(DateTime.parse(session.createdAt!))),
                                // tileColor: isSelected ? Colors.grey[300] : null,
                                // onTap:()=>widget.onTap(session)),
                              ));
                        },
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8.0),
                    child: svAppButton(
                      context: context,
                      onTap: () => widget.onNewSessionTap(),
                      text: translation(context).lbl_new_chat,
                    ),
                  ),
                ],
              ));
            } else {
              return Container();
            }
          }),
    );
  }
}