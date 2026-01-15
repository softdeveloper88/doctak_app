import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/anousment_model/announcement_model.dart';
import 'package:doctak_app/presentation/notification_screen/bloc/notification_event.dart';
import 'package:doctak_app/presentation/notification_screen/user_announcement_detail_screen.dart';
import 'package:doctak_app/widgets/shimmer_widget/shimmer_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:doctak_app/core/utils/secure_storage_service.dart';
import 'package:timeago/timeago.dart' as timeAgo;

import 'bloc/notification_bloc.dart';
import 'bloc/notification_state.dart';

class UserAnnouncementScreen extends StatefulWidget {
  const UserAnnouncementScreen({super.key});

  @override
  State<UserAnnouncementScreen> createState() => _UserAnnouncementScreenState();
}

class _UserAnnouncementScreenState extends State<UserAnnouncementScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  NotificationBloc notificationBloc = NotificationBloc();
  Set<int> hiddenAnnouncementIds = <int>{};

  @override
  void initState() {
    _loadHiddenAnnouncements();
    notificationBloc.add(AnnouncementEvent());
    super.initState();
  }

  // Load hidden announcement IDs from cache
  Future<void> _loadHiddenAnnouncements() async {
    final prefs = SecureStorageService.instance;
    await prefs.initialize();
    final hiddenIds = await prefs.getStringList('hidden_announcements') ?? [];
    setState(() {
      hiddenAnnouncementIds = hiddenIds.map((id) => int.tryParse(id) ?? 0).toSet();
    });
  }

  // Hide an announcement and save to cache
  Future<void> _hideAnnouncement(int announcementId) async {
    final prefs = SecureStorageService.instance;
    await prefs.initialize();
    hiddenAnnouncementIds.add(announcementId);
    final hiddenIds = hiddenAnnouncementIds.map((id) => id.toString()).toList();
    await prefs.setStringList('hidden_announcements', hiddenIds);

    // Adjust current page if needed
    if (_currentPage > 0) {
      setState(() {
        _currentPage = _currentPage - 1;
      });
      _pageController.animateToPage(_currentPage, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      setState(() {});
    }
  }

  // Clear all hidden announcements (for testing/reset purposes)
  Future<void> _clearHiddenAnnouncements() async {
    final prefs = SecureStorageService.instance;
    await prefs.initialize();
    await prefs.remove('hidden_announcements');
    setState(() {
      hiddenAnnouncementIds.clear();
    });
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
          List<AnnouncementData> allAnnouncementData = notificationBloc.announcementModel?.data ?? [];
          // Filter out hidden announcements
          List<AnnouncementData> announcementData = allAnnouncementData.where((announcement) => !hiddenAnnouncementIds.contains(announcement.id)).toList();

          // TEMPORARY CHANGE: hide the first announcement card for now
          // If there are multiple announcements, drop the first one
          if (announcementData.length > 1) {
            announcementData = announcementData.sublist(1);
          } else {
            // If only zero/one announcement remain, don't show the announcement slider
            announcementData = [];
          }

          // Ensure current page is within bounds after filtering
          if (_currentPage >= announcementData.length && announcementData.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _currentPage = announcementData.length - 1;
              });
              if (_pageController.hasClients) {
                _pageController.animateToPage(_currentPage, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
              }
            });
          }

          if (announcementData.isNotEmpty) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.65, // Increased height for better display
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: announcementData.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.blue[400]!, Colors.blue[600]!]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.blue.withAlpha(77), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: Stack(
                      children: [
                        // Main content
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              // User info row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white.withAlpha(77), width: 2),
                                            image: DecorationImage(
                                              image: NetworkImage("${AppData.imageUrl}${announcementData[index].user?.profilePic ?? ""}"),
                                              fit: BoxFit.cover,
                                              onError: (exception, stackTrace) {},
                                            ),
                                          ),
                                          child: announcementData[index].user?.profilePic == null
                                              ? Container(
                                                  decoration: BoxDecoration(color: Colors.white.withAlpha(51), shape: BoxShape.circle),
                                                  child: const Icon(Icons.person, color: Colors.white, size: 24),
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Wrap(
                                                crossAxisAlignment: WrapCrossAlignment.center,
                                                children: [
                                                  Text(
                                                    '${announcementData[index].user?.firstName} ${announcementData[index].user?.lastName}',
                                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                                  ),
                                                  const Text(
                                                    ' · ',
                                                    style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                                                  ),
                                                  SvgPicture.asset('assets/icon/ic_tick.svg', height: 14, width: 14, fit: BoxFit.cover),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  SvgPicture.asset(icSpecialty, height: 14, width: 14, fit: BoxFit.contain),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      announcementData[index].user?.specialty ?? '',
                                                      style: const TextStyle(fontSize: 14, color: Colors.white),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(timeAgo.format(DateTime.parse(announcementData[index].createdAt ?? '')), style: const TextStyle(color: Colors.white)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Image Container with fixed size
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.white.withAlpha(26)),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: CustomImageView(
                                      imagePath: announcementData[index].image ?? '',
                                      fit: BoxFit.contain, // Changed to contain to show full image
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Title
                              Text(
                                announcementData[index].title ?? "",
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Poppins', color: Colors.white),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 16),
                              // View Details Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    UserAnnouncementDetailScreen(announcementId: announcementData[index].id).launch(context, pageRouteAnimation: PageRouteAnimation.Slide);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.blue[700],
                                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                    elevation: 0,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'View Details',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: Colors.blue[700]),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.blue[700]),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Dots indicator
                              Container(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(announcementData.length > 5 ? 5 : announcementData.length, (dotIndex) {
                                    int actualIndex = dotIndex;
                                    if (announcementData.length > 5) {
                                      if (_currentPage > 2 && _currentPage < announcementData.length - 2) {
                                        actualIndex = _currentPage - 2 + dotIndex;
                                      } else if (_currentPage >= announcementData.length - 2) {
                                        actualIndex = announcementData.length - 5 + dotIndex;
                                      }
                                    }
                                    return _buildDot(isActive: actualIndex == _currentPage);
                                  }),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Close button
                        Positioned(
                          top: 12,
                          right: 12,
                          child: GestureDetector(
                            onTap: () {
                              _hideAnnouncement(announcementData[index].id ?? 0);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          } else {
            return const SizedBox.shrink();
          }
        } else if (state is DataError) {
          return Center(child: Text(state.errorMessage));
        } else {
          return const Center(child: Text('Something went wrong'));
        }
      },
    );
  }

  // Dot Widget for Slider Indicator
  Widget _buildDot({required bool isActive}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isActive ? 24 : 8,
      height: 8,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withAlpha(102),
        borderRadius: BorderRadius.circular(4),
        boxShadow: isActive ? [BoxShadow(color: Colors.white.withAlpha(77), blurRadius: 4, offset: const Offset(0, 2))] : null,
      ),
    );
  }
}
