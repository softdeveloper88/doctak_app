import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/SVProfileFragment.dart';
import 'package:doctak_app/presentation/user_chat_screen/bloc/chat_bloc.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/app_cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nb_utils/nb_utils.dart';

class UserChatComponent extends StatefulWidget {
  const UserChatComponent({Key? key}) : super(key: key);

  @override
  State<UserChatComponent> createState() => _UserChatComponentState();
}

class _UserChatComponentState extends State<UserChatComponent> {
  ChatBloc chatBloc = ChatBloc();

  @override
  void initState() {
    chatBloc.add(LoadPageEvent(page: 1));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return BlocBuilder<ChatBloc, ChatState>(
      bloc: chatBloc,
      builder: (context, state) {
        if (state is PaginationLoadedState) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                HorizontalList(
                  spacing: 12,
                  itemCount: chatBloc.contactsList.length,
                  itemBuilder: (context, index) {
                    final contact = chatBloc.contactsList[index];
                    final hasProfilePic =
                        contact.profilePic?.isNotEmpty == true;

                    return GestureDetector(
                      onTap: () {
                        SVProfileFragment(userId: contact.id).launch(context);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Avatar with gradient border
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  theme.primary,
                                  theme.primary.withOpacity(0.6),
                                ],
                              ),
                              boxShadow: theme.isDark
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: theme.primary.withOpacity(0.25),
                                        spreadRadius: 1,
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            padding: const EdgeInsets.all(2.5),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.scaffoldBackground,
                              ),
                              padding: const EdgeInsets.all(2),
                              child: ClipOval(
                                child: hasProfilePic
                                    ? AppCachedNetworkImage(
                                        imageUrl:
                                            '${AppData.imageUrl}${contact.profilePic}',
                                        height: 50,
                                        width: 50,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        width: 50,
                                        height: 50,
                                        color: theme.surfaceVariant,
                                        child: Icon(
                                          Icons.person_rounded,
                                          size: 28,
                                          color: theme.textSecondary,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Name
                          SizedBox(
                            width: 64,
                            child: Text(
                              '${contact.firstName.validate()} ${contact.lastName.validate()}',
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: theme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }
}
