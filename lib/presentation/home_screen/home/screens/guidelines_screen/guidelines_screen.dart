import 'package:doctak_app/ads_setting/ads_widget/banner_ads_widget.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/guidelines_screen/bloc/guideline_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/guidelines_screen/bloc/guideline_state.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/guidelines_screen/virtualized_guidelines_list.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:doctak_app/widgets/doctak_searchable_app_bar.dart';
import 'package:doctak_app/widgets/shimmer_widget/guidelines_shimmer_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/guideline_event.dart';

class GuidelinesScreen extends StatefulWidget {
  const GuidelinesScreen({Key? key}) : super(key: key);

  @override
  State<GuidelinesScreen> createState() => _GuidelinesScreenState();
}

class _GuidelinesScreenState extends State<GuidelinesScreen> {
  final ScrollController _scrollController = ScrollController();
  GuidelinesBloc guidelineBloc = GuidelinesBloc();
  bool isSearchShow = false;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    guidelineBloc.add(LoadPageEvent(page: 1, searchTerm: ''));
    super.initState();
  }

  @override
  void dispose() {
    searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Function to show search bottom sheet with One UI 8.5 styling
  void _showSearchBottomSheet(OneUITheme theme) {
    final TextEditingController dialogSearchController =
        TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.cardBackground,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.textTertiary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.primary.withOpacity(0.2),
                                  theme.primary.withOpacity(0.1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.search_rounded,
                              color: theme.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            translation(context).lbl_search,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: theme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Search field
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: theme.surfaceVariant,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.primary.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Icon(
                              Icons.search_rounded,
                              size: 22,
                              color: theme.textSecondary,
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: dialogSearchController,
                              autofocus: true,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 15,
                                color: theme.textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: translation(context).lbl_search,
                                hintStyle: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 15,
                                  color: theme.textTertiary,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              onSubmitted: (value) {
                                guidelineBloc.add(
                                  LoadPageEvent(page: 1, searchTerm: value),
                                );
                                Navigator.of(context).pop();
                              },
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              color: theme.textSecondary,
                              size: 22,
                            ),
                            onPressed: () {
                              dialogSearchController.clear();
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      body: Column(
        children: [
          // App Bar with Title and Actions
          DoctakAppBar(
            title: translation(context).lbl_guidelines,
            titleIcon: Icons.medical_information_rounded,
            actions: [
              // Search icon button with centralized styling
              DoctakSearchToggleButton(
                isSearching: isSearchShow,
                onTap: () {
                  setState(() {
                    isSearchShow = !isSearchShow;
                    if (!isSearchShow) {
                      // Clear search when closing
                      searchController.clear();
                      guidelineBloc.add(LoadPageEvent(page: 1, searchTerm: ''));
                    }
                  });
                },
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Search Bar with centralized component
          DoctakCollapsibleSearchField(
            isVisible: isSearchShow,
            hintText: translation(context).lbl_search,
            controller: searchController,
            height: 72,
            margin: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            onChanged: (searchTxt) {
              guidelineBloc.add(LoadPageEvent(page: 1, searchTerm: searchTxt));
            },
            onClear: () {
              guidelineBloc.add(LoadPageEvent(page: 1, searchTerm: ''));
            },
          ),

          // Guidelines List
          BlocConsumer<GuidelinesBloc, GuidelineState>(
            bloc: guidelineBloc,
            listener: (BuildContext context, GuidelineState state) {
              if (state is DataError) {
                // Error handling if needed
              }
            },
            builder: (context, state) {
              if (state is PaginationLoadingState) {
                return const Expanded(child: GuidelinesShimmerLoader());
              } else if (state is PaginationLoadedState) {
                return Expanded(
                  child: VirtualizedGuidelinesList(
                    guidelineBloc: guidelineBloc,
                    scrollController: _scrollController,
                  ),
                );
              } else if (state is DataError) {
                return Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.error_outline_rounded,
                            color: theme.error,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.errorMessage,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: theme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                return Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.warning_amber_rounded,
                            color: theme.warning,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          translation(context).msg_something_went_wrong,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: theme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
          ),

          // Banner Ad
          if (AppData.isShowGoogleBannerAds ?? false) BannerAdWidget(),
        ],
      ),
      // FAB with One UI 8.5 gradient styling
      floatingActionButton: !isSearchShow
          ? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.primary, theme.primary.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: theme.primary.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _showSearchBottomSheet(theme),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Icon(
                      Icons.search_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
