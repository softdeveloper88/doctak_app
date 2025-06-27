import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/anousment_model/announcement_detail_model.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/notification_screen/bloc/notification_event.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:doctak_app/widgets/shimmer_widget/shimmer_card_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:timeago/timeago.dart' as timeAgo;

import '../../main.dart';
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
      backgroundColor: appStore.isDarkMode ? Colors.grey[900] : Colors.grey[50],
      appBar: DoctakAppBar(
        title: 'Announcement Detail',
        titleIcon: Icons.announcement_rounded,
        actions: [
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
                Icons.share_rounded,
                color: Colors.blue[600],
                size: 14,
              ),
            ),
            onPressed: () {
              // Add share functionality
            },
          ),
          const SizedBox(width: 16),
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
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main announcement card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: appStore.isDarkMode ? Colors.grey[850] : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(10),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // User info header
                          Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.blue.withAlpha(26),
                                ),
                                child: ClipOval(
                                  child: announcementData.user?.profilePic != null
                                      ? Image.network(
                                          "${AppData.imageUrl}${announcementData.user?.profilePic ?? ""}",
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Center(
                                              child: Text(
                                                announcementData.user?.firstName?.substring(0, 1).toUpperCase() ?? 'A',
                                                style: TextStyle(
                                                  color: Colors.blue[700],
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                ),
                                              ),
                                            );
                                          },
                                        )
                                      : Center(
                                          child: Text(
                                            announcementData.user?.firstName?.substring(0, 1).toUpperCase() ?? 'A',
                                            style: TextStyle(
                                              color: Colors.blue[700],
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              16.width,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '${announcementData.user?.firstName} ${announcementData.user?.lastName}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: appStore.isDarkMode
                                                ? Colors.white
                                                : Colors.grey[800],
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                        6.width,
                                        SvgPicture.asset(
                                          'assets/icon/ic_tick.svg',
                                          height: 16,
                                          width: 16,
                                          colorFilter: ColorFilter.mode(
                                            Colors.blue[600]!,
                                            BlendMode.srcIn,
                                          ),
                                        ),
                                      ],
                                    ),
                                    4.height,
                                    Row(
                                      children: [
                                        SvgPicture.asset(
                                          icSpecialty,
                                          height: 14,
                                          width: 14,
                                          colorFilter: ColorFilter.mode(
                                            Colors.grey[600]!,
                                            BlendMode.srcIn,
                                          ),
                                        ),
                                        6.width,
                                        Text(
                                          announcementData.user?.specialty ?? '',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withAlpha(26),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Official',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue[700],
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                  6.height,
                                  Text(
                                    timeAgo.format(DateTime.parse(
                                        announcementData.createdAt ?? '')),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          24.height,
                          // Title
                          Text(
                            announcementData.title ?? "",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: appStore.isDarkMode
                                  ? Colors.white
                                  : Colors.grey[900],
                              fontFamily: 'Poppins',
                            ),
                          ),
                          16.height,
                          // Announcement image
                          if (announcementData.image != null && announcementData.image!.isNotEmpty)
                            Container(
                              width: double.infinity,
                              height: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: Colors.grey[100],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: CustomImageView(
                                  imagePath: announcementData.image ?? '',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          if (announcementData.image != null && announcementData.image!.isNotEmpty)
                            20.height,
                          // Details section
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: appStore.isDarkMode ? Colors.grey[800] : Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blue.withAlpha(26),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline_rounded,
                                      color: Colors.blue[600],
                                      size: 20,
                                    ),
                                    8.width,
                                    Text(
                                      'Details',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue[700],
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ],
                                ),
                                12.height,
                                Text(
                                  _isExpanded
                                      ? announcementData.details ?? ''
                                      : (announcementData.details?.length ?? 0) > 200
                                          ? '${announcementData.details?.substring(0, 200)}...'
                                          : announcementData.details ?? '',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: appStore.isDarkMode
                                        ? Colors.grey[300]
                                        : Colors.grey[700],
                                    fontFamily: 'Poppins',
                                    height: 1.6,
                                  ),
                                ),
                                if ((announcementData.details?.length ?? 0) > 200)
                                  8.height,
                                if ((announcementData.details?.length ?? 0) > 200)
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isExpanded = !_isExpanded;
                                      });
                                    },
                                    child: Text(
                                      _isExpanded ? 'Show Less' : 'Show More',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.blue[600],
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Poppins',
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
                  24.height,
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Add bookmark functionality
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: appStore.isDarkMode ? Colors.grey[800] : Colors.grey[100],
                            foregroundColor: appStore.isDarkMode ? Colors.grey[300] : Colors.grey[700],
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.bookmark_border_rounded, size: 18),
                          label: const Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                      12.width,
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Add share functionality
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.share_rounded, size: 18),
                          label: const Text(
                            'Share',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Bottom padding for better scroll experience
                  32.height,
                ],
              ),
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
