import 'dart:async';

import 'package:doctak_app/ads_setting/ads_widget/native_ads_widget.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/SVDashboardScreen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/conferences_screen/virtualized_conferences_list.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/splash_screen/bloc/splash_bloc.dart';
import 'package:doctak_app/presentation/splash_screen/bloc/splash_event.dart';
import 'package:doctak_app/presentation/splash_screen/bloc/splash_state.dart';
import 'package:doctak_app/widgets/custom_dropdown_button_from_field.dart';
import 'package:doctak_app/widgets/retry_widget.dart';
import 'package:doctak_app/widgets/shimmer_widget/conferences_shimmer_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../../main.dart' show appStore;
import 'bloc/conference_bloc.dart';
import 'bloc/conference_event.dart';
import 'bloc/conference_state.dart';

class ConferencesScreen extends StatefulWidget {
  const ConferencesScreen({this.isFromSplash = false, super.key});

  final bool isFromSplash;

  @override
  State<ConferencesScreen> createState() => _ConferencesScreenState();
}

class _ConferencesScreenState extends State<ConferencesScreen> {
  final ScrollController _scrollController = ScrollController();
  final ConferenceBloc conferenceBloc = ConferenceBloc();
  Timer? _debounce;
  bool isSearchShow = true;
  TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    conferenceBloc.add(LoadPageEvent(
      page: 1,
      countryName: 'all',
      searchTerm: '',
    ));
    BlocProvider.of<SplashBloc>(context).add(
      LoadDropdownData1('', ''),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: svGetBgColor(),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56), // Increased app bar height
        child: _buildAppBar(),
      ),
      body: Column(
        children: [
          _buildSearchField(),
          _buildConferenceList(),
          // if (AppData.isShowGoogleBannerAds ?? false) BannerAdWidget()
        ],
      ),
    );
  }

  // Build app bar with country selector and title
  AppBar _buildAppBar() {
    return AppBar(
      leading: GestureDetector(
        onTap: () {
          if (widget.isFromSplash) {
            const SVDashboardScreen().launch(context, isNewTask: true);
          } else {
            Navigator.of(context).pop();
          }
        },
        child: Container(
          padding: const EdgeInsets.all(6),
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.arrow_back_ios,
            color: Colors.blue[600],
            size: 16,
          ),
        ),
      ),
      backgroundColor: svGetScaffoldColor(),
      iconTheme: IconThemeData(color: context.iconColor),
      surfaceTintColor: svGetScaffoldColor(),
      title: BlocConsumer<SplashBloc, SplashState>(
        bloc: SplashBloc()..add(
          LoadDropdownData1('', ''),
        ),
        listener: (_, __) {},
        builder: (context, state) {
          if (state is CountriesDataLoaded1) {
            List<dynamic> list = state.countriesModelList;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Title section with icon (more compact)
                Expanded(
                  flex: 4,
                  child: Row(
                    children: [
                      Icon(
                        Icons.event,
                        color: Colors.blue[600],
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          translation(context).lbl_conference, 
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                            color: Colors.blue[800],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                // Country dropdown and search
                Expanded(
                  flex: 4,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Country flag selector (even more compact)
                      Container(
                        margin: const EdgeInsets.only(right: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: PopupMenuButton<dynamic>(
                          tooltip: 'Select Country',
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          offset: const Offset(0, 32),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  list.first.toString(),
                                  style: const TextStyle(fontSize: 11),
                                ),
                                const Icon(Icons.arrow_drop_down, size: 12),
                              ],
                            ),
                          ),
                          itemBuilder: (context) {
                            return list.map((dynamic item) {
                              return PopupMenuItem<dynamic>(
                                value: item,
                                child: Text(
                                  item.toString(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              );
                            }).toList();
                          },
                          onSelected: (dynamic newValue) {
                            conferenceBloc.add(
                              LoadPageEvent(
                                page: 1,
                                countryName: newValue.toString(),
                                searchTerm: state.searchTerms!,
                              ),
                            );
                            BlocProvider.of<SplashBloc>(context).add(
                              LoadDropdownData1(newValue.toString(), state.searchTerms ?? ''),
                            );
                          },
                        ),
                      ),
                      // Search button (larger size)
                      InkWell(
                        onTap: () {
                          setState(() {
                            isSearchShow = !isSearchShow;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isSearchShow ? Icons.close : Icons.search,
                            color: Colors.blue[600],
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else if (state is CountriesDataError) {
            return Center(child: Text('${translation(context).lbl_error}: $state'));
          } else {
            return const Center(child: Text(''));
          }
        },
      ),
      elevation: 0,
      centerTitle: false,
    );
  }

  // Build search field
  Widget _buildSearchField() {
    return BlocConsumer<SplashBloc, SplashState>(
      listener: (_, __) {},
      builder: (context, state) {
        if (state is CountriesDataLoaded1) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: isSearchShow ? 70 : 0,
            child: isSearchShow
              ? Container(
                  color: svGetScaffoldColor(),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Container(
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
                                if (_debounce?.isActive ?? false) {
                                  _debounce?.cancel();
                                }
                                _debounce = Timer(
                                  const Duration(milliseconds: 500), () {
                                    conferenceBloc.add(
                                      LoadPageEvent(
                                        page: 1,
                                        countryName: state.countryName,
                                        searchTerm: searchTxt,
                                      ),
                                    );
                                    BlocProvider.of<SplashBloc>(context)
                                      .add(LoadDropdownData1(
                                        state.countryName,
                                        searchTxt,
                                      ));
                                  },
                                );
                              },
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: translation(context).lbl_search_conferences,
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
                              conferenceBloc.add(LoadPageEvent(
                                page: 1,
                                countryName: state.countryName,
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
                  ),
                )
              : const SizedBox(),
          );
        } else if (state is DataError) {
          BlocProvider.of<SplashBloc>(context).add(
            LoadDropdownData1('', ''),
          );
          return RetryWidget(
            errorMessage: translation(context).msg_something_went_wrong_retry,
            onRetry: () {
              try {
                conferenceBloc.add(LoadPageEvent(
                  page: 1,
                  countryName: 'all',
                  searchTerm: '',
                ));
              } catch (e) {
                debugPrint(e.toString());
              }
            },
          );
        } else {
          return const Center();
        }
      },
    );
  }

  // Build conference list
  Widget _buildConferenceList() {
    return BlocConsumer<ConferenceBloc, ConferenceState>(
      bloc: conferenceBloc,
      listener: (BuildContext context, ConferenceState state) {
        if (state is DataError) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              content: Text(state.errorMessage),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is PaginationLoadingState) {
          return Expanded(
            child: ConferencesShimmerLoader(),
          );
        } else if (state is PaginationLoadedState) {
          return Expanded(
            child: VirtualizedConferencesList(
              conferenceBloc: conferenceBloc,
              scrollController: _scrollController,
            ),
          );
        } else if (state is DataError) {
          return RetryWidget(
            errorMessage: translation(context).msg_something_went_wrong_retry,
            onRetry: () {
              try {
                conferenceBloc.add(LoadPageEvent(
                  page: 1,
                  countryName: 'all',
                  searchTerm: '',
                ));
              } catch (e) {
                debugPrint(e.toString());
              }
            },
          );
        } else {
          return const Expanded(child: Center(child: Text('')));
        }
      },
    );
  }
}