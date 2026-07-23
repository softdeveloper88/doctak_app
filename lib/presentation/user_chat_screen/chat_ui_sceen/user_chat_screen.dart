import 'dart:async';

import 'package:doctak_app/ads_setting/ads_widget/banner_ads_widget.dart';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/display_identity.dart';
import 'package:doctak_app/data/models/chat_model/conversation_message_model.dart';
import 'package:doctak_app/data/models/chat_model/conversation_model.dart';
import 'package:doctak_app/data/services/notifications_websocket_service.dart';
import 'package:doctak_app/main.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/SVProfileFragment.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/home_screen/utils/shimmer_widget.dart';
import 'package:doctak_app/presentation/user_chat_screen/bloc/chat_bloc.dart';
import 'package:doctak_app/presentation/user_chat_screen/chat_ui_sceen/search_contact_screen.dart';
import 'package:doctak_app/widgets/profile_list_item_card.dart';
import 'package:doctak_app/widgets/retry_widget.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:timeago/timeago.dart' as timeAgo;

import 'chat_room_screen.dart';

class UserChatScreen extends StatefulWidget {
  const UserChatScreen({super.key});

  @override
  State<UserChatScreen> createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen>
    with WidgetsBindingObserver {
  ChatBloc chatBloc = ChatBloc();
  final NotificationsWebSocketService _notificationsWs =
      NotificationsWebSocketService();
  StreamSubscription<NotificationWsEvent>? _wsSub;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    setStatusBarColor(svGetScaffoldColor());
    _connectNotificationsWs();
    chatBloc.add(LoadPageEvent(page: 1));
    super.initState();
  }

  String sanitizeString(String input) {
    try {
      return String.fromCharCodes(input.codeUnits);
    } catch (e) {
      return translation(context).msg_invalid_string;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _connectNotificationsWs();
      chatBloc.add(LoadPageEvent(page: 1));
    }
  }

  void _connectNotificationsWs() {
    _wsSub ??= _notificationsWs.events.listen(_onNotificationWsEvent);
    _notificationsWs.connect();
  }

  void _onNotificationWsEvent(NotificationWsEvent event) {
    switch (event) {
      case ChatMessageNotification e:
        chatBloc.add(ChatListMessageEvent(
          conversationId: e.conversationId,
          message: e.message,
        ));
      case ChatTypingNotification e:
        chatBloc.add(ChatListTypingEvent(
          conversationId: e.conversationId,
          userId: e.userId,
          isTyping: e.isTyping,
        ));
      default:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _wsSub?.cancel();
    chatBloc.close();
    super.dispose();
  }

  Future<void> _refresh() async {
    chatBloc.add(LoadPageEvent(page: 1));
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: DoctakAppBar(
        title: translation(context).lbl_chats,
        titleIcon: Icons.chat_rounded,
        actions: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: Icon(Icons.search_rounded, color: theme.primary, size: 22),
            onPressed: () {
              SearchContactScreen().launch(context);
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: RefreshIndicator(
        color: theme.primary,
        backgroundColor: theme.surfaceVariant,
        strokeWidth: 2.5,
        onRefresh: _refresh,
        child: BlocConsumer<ChatBloc, ChatState>(
          bloc: chatBloc,
          listener: (BuildContext context, ChatState state) {
            if (state is DataError) {
              showDialog(
                context: context,
                builder: (context) =>
                    AlertDialog(content: Text(state.errorMessage)),
              );
            }
          },
          builder: (context, state) {
            if (state is PaginationLoadingState) {
              return const UserShimmer();
            } else if (state is PaginationLoadedState) {
              return _buildChatContent(theme);
            } else if (state is DataError) {
              return RetryWidget(
                errorMessage: translation(context).msg_chat_error,
                onRetry: () {
                  chatBloc.add(LoadPageEvent(page: 1));
                },
              );
            } else {
              return Center(
                child: Text(translation(context).msg_notification_error),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildChatContent(OneUITheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isCurrentlyOnNoInternet)
          Container(
            padding: const EdgeInsets.all(10),
            color: theme.error,
            child: Text(
              translation(context).msg_no_internet,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Poppins', fontWeight: FontWeight.w500),
            ),
          ),

        // Conversations List
        if (chatBloc.conversationsList.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Text(
              translation(context).lbl_message,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Poppins', color: theme.textPrimary),
            ),
          ),
          _buildConversationsList(theme),
        ] else
          Expanded(
            child: Center(
              child: Text(
                translation(context).msg_no_chats,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: theme.textSecondary),
              ),
            ),
          ),

        if (AppData.isShowGoogleBannerAds ?? false) BannerAdWidget(),
      ],
    );
  }

  Widget _buildConversationsList(OneUITheme theme) {
    return Expanded(
      child: ListView.builder(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16),
        itemCount: chatBloc.conversationsList.length,
        itemBuilder: (context, index) {
          return _buildConversationCard(theme, chatBloc.conversationsList[index]);
        },
      ),
    );
  }

  Widget _buildConversationCard(OneUITheme theme, Conversation conversation) {
    // Get the other participant for direct conversations
    final otherParticipant = conversation.getOtherParticipant(AppData.logInUserId);
    final displayName = conversation.name ?? otherParticipant?.user?.fullName ?? 'Unknown';
    final profilePic = conversation.avatar ?? otherParticipant?.user?.profilePic ?? '';
    // Peer id: the v6 API's `peer` is authoritative; participants are a
    // fallback. An empty id breaks calls and profile navigation
    // ("Could not identify this user").
    final peerId = conversation.peer?.id ?? '';
    final userId = peerId.isNotEmpty
        ? peerId
        : (otherParticipant?.userId?.toString() ?? '');

    return ProfileListItemCard(
      title: sanitizeString(formatDisplayName(displayName, 'Unknown')),
      avatarUrl: AppData.fullImageUrl(profilePic),
      subtitle: _conversationPreviewText(theme, conversation),
      trailing: _buildTimeAndBadge(theme, conversation),
      onTap: () {
        if (conversation.id != null) {
          chatBloc.add(MarkConversationReadEvent(conversationId: conversation.id!));
        }
        ChatRoomScreen(
          username: displayName,
          profilePic: profilePic,
          id: userId,
          conversationId: conversation.id ?? 0,
        ).launch(context).then((_) {
          chatBloc.add(LoadPageEvent(page: 1));
        });
      },
      onAvatarTap: userId.isNotEmpty
          ? () => SVProfileFragment(userId: userId).launch(context)
          : null,
    );
  }

  String _conversationPreviewText(OneUITheme theme, Conversation conversation) {
    if (chatBloc.isConversationTyping(conversation.id)) {
      return translation(context).lbl_typing;
    }

    final lastMsg = conversation.lastMessage;
    String preview = lastMsg?.body ?? lastMsg?.content ?? 'Start a conversation';

    if (ConversationMessage.looksLikeVoiceFileName(preview)) {
      preview = '🎵 Voice message';
    } else if (lastMsg?.type == 'image') {
      preview = '📷 Photo';
    } else if (lastMsg?.type == 'video') {
      preview = '📹 Video';
    } else if (lastMsg?.type == 'audio' || lastMsg?.type == 'voice') {
      preview = '🎵 Voice message';
    } else if (lastMsg?.type == 'file') {
      preview = '📎 File';
    }

    if (preview.length > 30) preview = '${preview.substring(0, 30)}...';
    return preview;
  }

  Widget _buildTimeAndBadge(OneUITheme theme, Conversation conversation) {
    final lastMsg = conversation.lastMessage;
    final timeStr = lastMsg?.createdAt ?? conversation.updatedAt ?? conversation.createdAt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (timeStr != null)
          Text(
            timeAgo.format(DateTime.parse(timeStr)),
            style: TextStyle(fontFamily: 'Poppins', color: theme.textTertiary, fontSize: 12),
          ),
        const SizedBox(height: 8),
        if ((conversation.unreadCount ?? 0) > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.error,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: theme.error.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Text(
              '${conversation.unreadCount}',
              style: const TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}