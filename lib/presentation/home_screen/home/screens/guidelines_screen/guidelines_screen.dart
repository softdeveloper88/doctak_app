import 'dart:async';

import 'package:doctak_app/ads_setting/ads_widget/banner_ads_widget.dart';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/guidelines_screen/bloc/guideline_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/guidelines_screen/bloc/guideline_state.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/guidelines_screen/virtualized_guidelines_list.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVColors.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/widgets/shimmer_widget/guidelines_shimmer_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../../main.dart';
import 'bloc/guideline_event.dart';

class GuidelinesScreen extends StatefulWidget {
  const GuidelinesScreen({Key? key}) : super(key: key);

  @override
  State<GuidelinesScreen> createState() => _GuidelinesScreenState();
}

class _GuidelinesScreenState extends State<GuidelinesScreen> {
  Timer? _debounce;
  final ScrollController _scrollController = ScrollController();
  GuidelinesBloc guidelineBloc = GuidelinesBloc();
  bool isSearchShow = false;
  bool isBottomSearchVisible = false;
  TextEditingController searchController = TextEditingController();
  TextEditingController bottomSearchController = TextEditingController();

  @override
  void initState() {
    guidelineBloc.add(
      LoadPageEvent(page: 1, searchTerm: ''),
    );
    super.initState();
  }

  @override
  void dispose() {
    searchController.dispose();
    bottomSearchController.dispose();
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  // Function to show search bottom sheet
  void _showSearchBottomSheet() {
    setState(() {
      isBottomSearchVisible = true;
    });
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
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
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Search field
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Icon(
                              Icons.search,
                              color: Colors.grey[600],
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: bottomSearchController,
                              decoration: InputDecoration(
                                hintText: 'Search',
                                hintStyle: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                                border: InputBorder.none,
                              ),
                              onChanged: (value) {
                                if (_debounce?.isActive ?? false) _debounce?.cancel();
                                _debounce = Timer(const Duration(milliseconds: 500), () {
                                  guidelineBloc.add(LoadPageEvent(
                                    page: 1,
                                    searchTerm: value,
                                  ));
                                });
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              bottomSearchController.clear();
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
    ).then((value) {
      setState(() {
        isBottomSearchVisible = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: svGetBgColor(),
      body: Column(
        children: [
          // App Bar with Title and Actions
          AppBar(
            backgroundColor: svGetScaffoldColor(),
            iconTheme: IconThemeData(color: context.iconColor),
            elevation: 0,
            toolbarHeight: 70,
            surfaceTintColor: svGetScaffoldColor(),
            centerTitle: true,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.blue[600],
                  size: 16,
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
              }
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.medical_information,
                  color: Colors.blue[600],
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  translation(context).lbl_guidelines,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
            actions: [
              // Search icon button
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
                    isSearchShow ? Icons.close : Icons.search,
                    color: Colors.blue[600],
                    size: 14,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    isSearchShow = !isSearchShow;
                    if (!isSearchShow) {
                      // Clear search when closing
                      searchController.clear();
                      guidelineBloc.add(LoadPageEvent(
                        page: 1,
                        searchTerm: '',
                      ));
                    }
                  });
                },
              ),
              const SizedBox(width: 16),
            ],
          ),
          
          // Search Bar
          Container(
            color: svGetScaffoldColor(),
            child: Column(
              children: [
                // Search field with animated visibility
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: isSearchShow ? 60 : 0,
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: isSearchShow
                      ? Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          decoration: BoxDecoration(
                            color: appStore.isDarkMode
                                ? Colors.blueGrey[800]
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(24.0),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.2),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.05),
                                offset: const Offset(0, 2),
                                blurRadius: 6,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24.0),
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                  child: Icon(
                                    Icons.search_rounded,
                                    color: Colors.blue.withOpacity(0.6),
                                    size: 24,
                                  ),
                                ),
                                Expanded(
                                  child: AppTextField(
                                    controller: searchController,
                                    textFieldType: TextFieldType.NAME,
                                    textStyle: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      color: appStore.isDarkMode
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                    onChanged: (searchTxt) async {
                                      if (_debounce?.isActive ?? false)
                                        _debounce?.cancel();
                                      _debounce = Timer(
                                          const Duration(milliseconds: 500), () {
                                        guidelineBloc.add(LoadPageEvent(
                                          page: 1,
                                          searchTerm: searchTxt,
                                        ));
                                      });
                                    },
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: translation(context).lbl_search,
                                      hintStyle: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                        color: appStore.isDarkMode
                                            ? Colors.white60
                                            : Colors.black54,
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    // Clear the search text but keep search field visible
                                    searchController.clear();
                                    // Update search results
                                    guidelineBloc.add(LoadPageEvent(
                                      page: 1,
                                      searchTerm: '',
                                    ));
                                  },
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(24),
                                    bottomRight: Radius.circular(24),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(24),
                                        bottomRight: Radius.circular(24),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.clear,
                                      color: Colors.blue.withOpacity(0.6),
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox(),
                  ),
                ),
                SizedBox(height: 10,)
              ],
            ),
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
                return Expanded(
                  child: GuidelinesShimmerLoader()
                );
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
                    child: Text(state.errorMessage),
                  ),
                );
              } else {
                return Expanded(
                  child: Center(
                    child: Text(translation(context).msg_something_went_wrong)
                  )
                );
              }
            },
          ),
          
          // Banner Ad
          if (AppData.isShowGoogleBannerAds ?? false) BannerAdWidget()
        ],
      ),
      floatingActionButton: !isSearchShow ? FloatingActionButton(
        onPressed: _showSearchBottomSheet,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.search, color: Colors.white),
      ) : null,
    );
  }
}