import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/anousment_model/announcement_model.dart';
import 'package:doctak_app/presentation/notification_screen/bloc/notification_event.dart';
import 'package:doctak_app/presentation/notification_screen/user_announcement_detail_screen.dart';
import 'package:doctak_app/widgets/shimmer_widget/shimmer_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:timeago/timeago.dart' as timeAgo;

import 'bloc/notification_bloc.dart';
import 'bloc/notification_state.dart';

class UserAnnouncementScreen extends StatefulWidget {
  const UserAnnouncementScreen({Key? key}) : super(key: key);

  @override
  State<UserAnnouncementScreen> createState() => _UserAnnouncementScreenState();
}

class _UserAnnouncementScreenState extends State<UserAnnouncementScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  NotificationBloc notificationBloc = NotificationBloc();

  // JSON Data
  @override
  void initState() {
    notificationBloc.add(
      AnnouncementEvent(),
    );
    super.initState();
  }

  int selectIndex = -1;
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NotificationBloc, NotificationState>(
      bloc: notificationBloc,
      // listenWhen: (previous, current) => current is PaginationLoadedState,
      // buildWhen: (previous, current) => current is! PaginationLoadedState,
      listener: (BuildContext context, NotificationState state) {
        if (state is DataError) {
          // showDialog(
          //   context: context,
          //   builder: (context) => AlertDialog(
          //     content: Text(state.errorMessage),
          //   ),
          // );
        }
      },
      builder: (context, state) {
        if (state is PaginationLoadingState) {
          return const ShimmerLoader();
        } else if (state is PaginationLoadedState) {
          List<AnnouncementData> announcementData =
              notificationBloc.announcementModel?.data ?? [];
          if(announcementData.isNotEmpty) {
            return SizedBox(
              height: 430,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: announcementData.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      // Background Image
                      Positioned.fill(
                        child: Container(
                          height: 1000,
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage('assets/images/image_icon.png'),
                              fit: BoxFit
                                  .cover, // Ensures the image covers the entire background
                            ),
                          ),
                        ),
                      ), // Content
                      InkWell(
                        onTap: () {
                          UserAnnouncementDetailScreen(
                            announcementId: announcementData[index].id,
                          ).launch(context,
                              pageRouteAnimation: PageRouteAnimation.Slide);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () {},
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundImage: NetworkImage(
                                              "${AppData
                                                  .imageUrl}${announcementData[index]
                                                  .user?.profilePic ?? ""}",
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
                                                    '${announcementData[index]
                                                        .user
                                                        ?.firstName} ${announcementData[index]
                                                        .user?.lastName}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                      FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  const Text(
                                                    ' · ',
                                                    style: TextStyle(
                                                        fontSize: 16,
                                                        color: Colors.white,
                                                        fontWeight:
                                                        FontWeight.bold),
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
                                                    announcementData[index]
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
                                        announcementData[index].createdAt ??
                                            '')),
                                    style: const TextStyle(color: Colors.white),
                                  )
                                ],
                              ),
                              const SizedBox(height: 24),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: CustomImageView(
                                  imagePath:
                                  announcementData[index].image ?? '',
                                  fit: BoxFit.contain,
                                  height: 300,
                                  width: double.infinity,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Title and Details (Inside Slider)
                              Center(
                                child: Text(
                                  announcementData[index].title ?? "",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: selectIndex == index
                                              ? announcementData[index].details
                                              : (announcementData[index]
                                              .details
                                              ?.length ??
                                              0) >
                                              30
                                              ? '${announcementData[index].details
                                              ?.substring(0, 30)}...'
                                              : announcementData[index]
                                              .details,
                                          style: const TextStyle(
                                              fontSize: 16, color: Colors.white),
                                        ),
                                        if ((announcementData[index]
                                            .details
                                            ?.length ??
                                            0) >
                                            30)
                                          WidgetSpan(
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {

                                                  // if (selectIndex == index) {
                                                  //   selectIndex = -1;
                                                  // } else {
                                                  //   selectIndex = index;
                                                  // }
                                                });
                                              },
                                              child: Text(
                                                selectIndex == index
                                                    ? ' See Less'
                                                    : ' See More',
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
                              ),
                              // const SizedBox(height: 16),
                              Expanded(
                                flex: 8,
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      announcementData.length,
                                          (index) =>
                                          _buildDot(
                                              isActive: index == _currentPage),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          }else{
            return const SizedBox.shrink();
          }
        } else if (state is DataError) {
          return Center(
            child: Text(state.errorMessage),
          );
        } else {
          return const Center(child: Text('Something went wrong'));
        }
      },
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
