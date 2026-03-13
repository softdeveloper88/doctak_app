import 'dart:async';
import 'dart:convert';

import 'package:doctak_app/ads_setting/ads_widget/banner_ads_widget.dart';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/chat_model/conversation_model.dart';
import 'package:doctak_app/main.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/SVProfileFragment.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/home_screen/utils/shimmer_widget.dart';
import 'package:doctak_app/presentation/user_chat_screen/bloc/chat_bloc.dart';
import 'package:doctak_app/presentation/user_chat_screen/chat_ui_sceen/search_contact_screen.dart';
import 'package:doctak_app/widgets/retry_widget.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nb_utils/nb_utils.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:timeago/timeago.dart' as timeAgo;

import '../Pusher/PusherConfig.dart';
import 'chat_room_screen.dart';

class UserChatScreen extends StatefulWidget {
  const UserChatScreen({super.key});

  @override
  State<UserChatScreen> createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen> with WidgetsBindingObserver {
  ChatBloc chatBloc = ChatBloc();

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    setStatusBarColor(svGetScaffoldColor());
    _connectPusher();
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
      _connectPusher();
      chatBloc.add(LoadPageEvent(page: 1));
    }
  }

  PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();
  bool isSomeoneTyping = false;
  String? typingUserId;
  int? typingConversationId;
  Timer? typingTimer;
  final Set<String> _subscribedChannels = {};

  Future<dynamic> onAuthorizer(String channelName, String socketId, dynamic options) async {
    // Use the new API auth endpoint for conversation channels
    final String authUrl = channelName.startsWith('private-conversation')
        ? '${AppData.chatApiUrl}/pusher/auth'
        : '${AppData.chatifyUrl}chat/auth';
    final Uri uri = Uri.parse(authUrl);
    final Map<String, String> queryParams = {'socket_id': socketId, 'channel_name': channelName};
    final response = await http.post(uri.replace(queryParameters: queryParams), headers: {'Authorization': 'Bearer ${AppData.userToken!}'});
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(translation(context).msg_pusher_auth_failed);
    }
  }

  void _connectPusher() async {
    try {
      await pusher.init(
        apiKey: PusherConfig.key,
        cluster: PusherConfig.cluster,
        useTLS: false,
        onAuthorizer: onAuthorizer,
        onSubscriptionSucceeded: (channelName, data) {},
        onSubscriptionError: (message, e) {
          debugPrint("Pusher subscription error: $message");
        },
        onError: (message, code, e) {
          debugPrint("Pusher error: $message");
        },
        onEvent: (event) {},
        onSubscriptionCount: (channelName, count) {},
        onMemberAdded: (channelName, member) {},
        onMemberRemoved: (channelName, member) {},
        onDecryptionFailure: (event, reason) {},
      );
      await pusher.connect();
    } catch (e) {
      debugPrint('Pusher connection error: $e');
    }
  }

  /// Subscribe to Pusher channels for all conversations
  void _subscribeToConversations() {
    for (final conv in chatBloc.conversationsList) {
      final channelName = 'private-conversation.${conv.id}';
      if (_subscribedChannels.contains(channelName)) continue;
      _subscribedChannels.add(channelName);

      pusher.subscribe(
        channelName: channelName,
        onEvent: (event) {
          _handleConversationEvent(conv.id!, event);
        },
        onMemberAdded: (member) {},
        onMemberRemoved: (member) {},
      );
    }
  }

  void _handleConversationEvent(int conversationId, PusherEvent event) {
    final eventName = event.eventName;
    switch (eventName) {
      case 'message.sent':
        // New message - reload conversations to update preview and unread count
        chatBloc.add(LoadPageEvent(page: 1));
        break;
      case 'user.typing':
        final data = jsonDecode(event.data ?? '{}');
        final userId = (data['user']?['id'] ?? data['user_id'])?.toString();
        if (userId != AppData.logInUserId) {
          setState(() {
            isSomeoneTyping = true;
            typingUserId = userId;
            typingConversationId = conversationId;
          });
          typingTimer?.cancel();
          typingTimer = Timer(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                isSomeoneTyping = false;
                typingUserId = null;
                typingConversationId = null;
              });
            }
          });
        }
        break;
      case 'user.stopped.typing':
        setState(() {
          isSomeoneTyping = false;
          typingUserId = null;
          typingConversationId = null;
        });
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    typingTimer?.cancel();
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
                builder: (context) => AlertDialog(content: Text(state.errorMessage)),
              );
            }
            if (state is PaginationLoadedState) {
              // Subscribe to Pusher channels after conversations are loaded
              _subscribeToConversations();
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
              return Center(child: Text(translation(context).msg_notification_error));
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
        padding: EdgeInsets.only(left: 16, right: 16, bottom: MediaQuery.of(context).padding.bottom + 16),
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
    final userId = otherParticipant?.userId?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Mark as read
            if (conversation.id != null) {
              chatBloc.add(MarkConversationReadEvent(conversationId: conversation.id!));
            }
            ChatRoomScreen(
              username: displayName,
              profilePic: profilePic,
              id: userId,
              conversationId: conversation.id ?? 0,
            ).launch(context).then((_) {
              // Reload conversations when returning
              chatBloc.add(LoadPageEvent(page: 1));
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.divider, width: 1),
              boxShadow: theme.isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                _buildContactAvatar(theme, profilePic, userId),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sanitizeString(displayName),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: 'Poppins', color: theme.textPrimary, fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      _buildMessagePreview(theme, conversation),
                    ],
                  ),
                ),
                _buildTimeAndBadge(theme, conversation),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactAvatar(OneUITheme theme, String profilePic, String userId) {
    return InkWell(
      onTap: () {
        if (userId.isNotEmpty) {
          SVProfileFragment(userId: userId).launch(context);
        }
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: [theme.primary.withValues(alpha: 0.1), theme.primary.withValues(alpha: 0.05)]),
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: CustomImageView(
            placeHolder: 'images/socialv/faces/face_5.png',
            imagePath: AppData.fullImageUrl(profilePic),
            height: 52,
            width: 52,
            fit: BoxFit.cover,
          ).cornerRadiusWithClipRRect(50),
        ),
      ),
    );
  }

  Widget _buildMessagePreview(OneUITheme theme, Conversation conversation) {
    // Check typing indicator
    if (isSomeoneTyping && typingConversationId == conversation.id) {
      return Row(
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(color: theme.primary, shape: BoxShape.circle),
          ),
          Text(
            translation(context).lbl_typing,
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, fontSize: 14, color: theme.primary),
          ),
        ],
      );
    }

    final lastMsg = conversation.lastMessage;
    String preview = lastMsg?.body ?? lastMsg?.content ?? 'Start a conversation';

    // Show type indicator for non-text messages
    if (lastMsg?.type == 'image') preview = '📷 Photo';
    if (lastMsg?.type == 'video') preview = '📹 Video';
    if (lastMsg?.type == 'audio') preview = '🎵 Voice message';
    if (lastMsg?.type == 'file') preview = '📎 File';

    if (preview.length > 30) preview = '${preview.substring(0, 30)}...';

    return Text(
      preview,
      style: TextStyle(fontFamily: 'Poppins', color: theme.textSecondary, fontSize: 14, height: 1.5),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
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
