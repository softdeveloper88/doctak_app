import 'package:doctak_app/presentation/chat_gpt_screen/bloc/chat_gpt_bloc.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVColors.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/widgets/AnimatedBackground.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';

// import 'package:timeago/timeago.dart' as timeAgo;
import 'package:intl/intl.dart';

import '../../data/models/chat_gpt_model/ChatGPTResponse.dart';
import '../../data/models/chat_gpt_model/ChatGPTSessionModel.dart';
import '../../data/models/chat_gpt_model/chat_gpt_sesssion/chat_gpt_session.dart';
import 'bloc/chat_gpt_event.dart';
import 'bloc/chat_gpt_state.dart';
import 'chat_delete_dialog.dart';

class ChatHistoryScreen extends StatefulWidget {
  ChatHistoryScreen(
      {required this.onTap, required this.onNewSessionTap, super.key});

  Function(Sessions) onTap;
  Function onNewSessionTap;

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        surfaceTintColor: Colors.white,
        backgroundColor: Colors.white,
        title: Text(
          'History Doctak AI',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w400),
        ),
      ),
      backgroundColor: SVAppColorPrimary,
      body: BlocProvider(
          create: (context) => ChatGPTBloc()..add(LoadDataValues()),
          child: BlocBuilder<ChatGPTBloc, ChatGPTState>(
              builder: (context, state1) {
            if (selectedSessionId == 0 && state1 is DataLoaded) {
              selectedSessionId = state1.response.newSessionId;
              chatWithAi =
                  state1.response.sessions?.first.name ?? 'New Session';
            }
            if (state1 is DataInitial) {
              return const Scaffold(
                body: AnimatedBackground(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Center(child: CircularProgressIndicator()),
                    ],
                  ),
                ),
              );
            } else if (state1 is DataLoaded) {
              return AnimatedBackground(
                  child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: state1.response.sessions?.length,
                      itemBuilder: (context, index) {
                        Sessions session = state1.response.sessions![index];
                        bool isSelected = session.id == selectedSessionId;
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
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(
                                top: 16,
                                left: 16,
                                right: 16,
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
                                            style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w400,
                                                color: Colors.black),
                                          ),
                                          Row(
                                            children: <Widget>[
                                              const Icon(Icons.calendar_month,
                                                  size: 15,
                                                  color: Colors.black45),
                                              const SizedBox(
                                                width: 2,
                                              ),
                                              Text(
                                                DateFormat(
                                                        'MM dd, yyyy, h:mm a')
                                                    .format(DateTime.parse(
                                                        session.createdAt!)),
                                                // timeAgo.format(DateTime.parse(
                                                //     session.createdAt!)),
                                                style: GoogleFonts.poppins(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w400,
                                                    color: Colors.black45),
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
                                                title: ' ${session.name??''}',
                                                callback: ()  {

                                                });
                                          });
                                    },
                                    child: Container(
                                        decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.3),
                                            borderRadius:
                                                BorderRadius.circular(6)),
                                        padding: const EdgeInsets.all(4),
                                        child: const Icon(
                                          Icons.delete,
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8.0),
                    child: svAppButton(
                      context: context,
                      // style: svAppButton(text: text, onTap: onTap, context: context),
                      onTap: () => widget.onNewSessionTap(),
                      text: 'New Chat',
                    ),
                  ),
                ],
              ));
            } else {
              return Container();
            }
          })),
    );
  }
}