import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/anousment_model/announcement_detail_model.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/notification_screen/bloc/notification_event.dart';
import 'package:doctak_app/widgets/shimmer_widget/shimmer_card_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:timeago/timeago.dart' as timeAgo;

import 'bloc/notification_bloc.dart';
import 'bloc/notification_state.dart';

class UserAnnouncementDetailScreen extends StatefulWidget {
  UserAnnouncementDetailScreen({this.announcementId, Key? key})
      : super(key: key);
  int? announcementId;
  @override
  State<UserAnnouncementDetailScreen> createState() =>
      _UserAnnouncementDetailScreenState();
}

class _UserAnnouncementDetailScreenState
    extends State<UserAnnouncementDetailScreen> {
  NotificationBloc notificationBloc = NotificationBloc();

  // JSON Data
  @override
  void initState() {
    notificationBloc.add(
      AnnouncementDetailEvent(announcementId: widget.announcementId ?? 0),
    );
    super.initState();
  }

  bool _isExpanded = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: svGetScaffoldColor(),
      appBar: AppBar(
        backgroundColor: context.cardColor,
        iconTheme: IconThemeData(color: context.iconColor),
        title: Text('Announcement Detail',
            style: boldTextStyle(
              size: 20,
            )),
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
            icon:
                Icon(Icons.arrow_back_ios_new_rounded, color: svGetBodyColor()),
            onPressed: () {
              Navigator.pop(context);
            }),
        actions: const [
          // IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
        ],
      ),
      body: BlocConsumer<NotificationBloc, NotificationState>(
        bloc: notificationBloc,
        // listenWhen: (previous, current) => current is PaginationLoadedState,
        // buildWhen: (previous, current) => current is! PaginationLoadedState,
        listener: (BuildContext context, NotificationState state) {
          if (state is DataError) {}
        },
        builder: (context, state) {
          if (state is PaginationLoadingState) {
            return ShimmerCardList();
          } else if (state is PaginationLoadedState) {
            AnnouncementDetailData announcementData =
                notificationBloc.announcementDetailModel?.data ??
                    AnnouncementDetailData();
            return Stack(
              children: [
                // Background Image
                Positioned.fill(
                  child: Container(
                    width: double.maxFinite,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/image_icon.png'),
                        fit: BoxFit
                            .fill, // Ensures the image covers the entire background
                      ),
                    ),
                  ),
                ), // Content
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {},
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundImage: NetworkImage(
                                        "${AppData.imageUrl}${announcementData.user?.profilePic ?? ""}",
                                      ),
                                      radius: 25,
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            Text(
                                              '${announcementData.user?.firstName} ${announcementData.user?.lastName}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const Text(
                                              ' · ',
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            SvgPicture.asset(
                                             'assets/icon/ic_tick.svg',
                                              height: 14,
                                              width: 14,
                                              fit: BoxFit.cover,
                                            ),
                                          ],
                                        ),
                                        Row(
                                          spacing: 10,
                                          children: [
                                            SvgPicture.asset(
                                              icSpecialty,
                                              height: 14,
                                              width: 14,
                                              fit: BoxFit.contain,
                                            ),
                                            Text(
                                              announcementData
                                                  .user
                                                  ?.specialty ??
                                                  '',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.white,
                                              ),
                                            ),
                                            // const Text(
                                            //   ' · ',
                                            //   style: TextStyle(
                                            //       fontSize: 16,
                                            //       color: Colors.white,
                                            //       fontWeight:
                                            //           FontWeight.bold),
                                            // ),
                                            // SvgPicture.asset(
                                            //   icGlob,
                                            //   color: Colors.white,
                                            //   height: 12,
                                            //   width: 12,
                                            // ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Text(
                              timeAgo.format(DateTime.parse(
                                  announcementData.createdAt ?? '')),
                              style: const TextStyle(color: Colors.white),
                            )
                          ],
                        ),
                        const SizedBox(height: 24),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CustomImageView(
                            imagePath: announcementData.image ?? '',
                            fit: BoxFit.cover,
                            height: 300,
                            width: double.infinity,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Title and Details (Inside Slider)
                        Center(
                          child: Text(
                            announcementData.title ?? "",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Center(
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: _isExpanded
                                      ? announcementData.details
                                      : (announcementData.details?.length ??
                                                  0) >
                                              100
                                          ? '${announcementData.details?.substring(0, 100)}...'
                                          : announcementData.details,
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.white),
                                ),
                                if ((announcementData.details?.length ?? 0) >
                                    100)
                                  WidgetSpan(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _isExpanded = !_isExpanded;
                                        });
                                      },
                                      child: Text(
                                        _isExpanded ? ' See Less' : ' See More',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            );
          } else if (state is DataError) {
            return Center(
              child: Text(state.errorMessage),
            );
          } else {
            return const Center(
              child: Text('Something went wrong'),
            );
          }
        },
      ),
    );
  }

  // Dot Widget for Slider Indicator
  Widget _buildDot({required bool isActive}) {
    return Container(
      width: isActive ? 10 : 8,
      height: isActive ? 10 : 8,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : const Color(0xFF96B8D5),
        shape: BoxShape.circle,
      ),
    );
  }
}
