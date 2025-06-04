import 'dart:async';

import 'package:doctak_app/ads_setting/ads_widget/native_ads_widget.dart';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/countries_model/countries_model.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/chat_gpt_screen/ChatDetailScreen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/drugs_list_screen/bloc/drugs_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/drugs_list_screen/virtualized_drugs_list.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVColors.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/splash_screen/bloc/splash_bloc.dart';
import 'package:doctak_app/presentation/splash_screen/bloc/splash_event.dart';
import 'package:doctak_app/presentation/splash_screen/bloc/splash_state.dart';
import 'package:doctak_app/widgets/custom_dropdown_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:sizer/sizer.dart';

import '../../../../../main.dart';
import '../../../../../widgets/shimmer_widget/drugs_shimmer_loader.dart';
import 'bloc/drugs_event.dart';
import 'bloc/drugs_state.dart';

class DrugsListScreen extends StatefulWidget {
  const DrugsListScreen({Key? key}) : super(key: key);

  @override
  State<DrugsListScreen> createState() => _DrugsListScreenState();
}

class _DrugsListScreenState extends State<DrugsListScreen> {
  Timer? _debounce;

  final ScrollController _scrollController = ScrollController();
  DrugsBloc drugsBloc = DrugsBloc();
  bool isSearchShow = false;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    drugsBloc.add(
      LoadPageEvent(page: 1, countryId: '1', searchTerm: '', type: 'Brand'),
    );
    super.initState();
  }

  @override
  void dispose() {
    searchController.dispose();
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  var selectedValue;

  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: svGetBgColor(),
      body: Column(
        children: [
          BlocBuilder<SplashBloc, SplashState>(builder: (context, state) {
            if (state is CountriesDataInitial) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Center(
                      child: Text(translation(context).lbl_loading,
                  )),
                ],
              );
            } else if (state is CountriesDataLoaded) {
              for (var element in state.countriesModel.countries!) {
                if (element.flag == state.countryFlag) {
                  selectedValue = state.countriesModel.countries?.first.flag ??
                      element.flag;
                }
              }
              return Column(
                children: [
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
                          Icons.medication_rounded,
                          color: Colors.blue[600],
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          translation(context).lbl_drug_list,
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
                      // Search icon button (more compact)
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
                              drugsBloc.add(LoadPageEvent(
                                page: 1,
                                countryId: state.countryFlag != ''
                                    ? state.countryFlag
                                    : '${state.countriesModel.countries?.first.id ?? 1}',
                                searchTerm: '',
                                type: state.typeValue
                              ));
                            }
                          });
                        },
                      ),
                      // Country dropdown (simplified like jobs screen)
                      Container(
                        margin: const EdgeInsets.only(right: 16),
                        child: PopupMenuButton<Countries>(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          offset: const Offset(0, 50),
                          tooltip: 'Select Country',
                          elevation: 8,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withAlpha(25),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              state.countryFlag != '' 
                                ? state.countriesModel.countries!.firstWhere(
                                    (element) => element.id.toString() == state.countryFlag,
                                    orElse: () => state.countriesModel.countries!.first
                                  ).flag ?? ''
                                : state.countriesModel.countries!.first.flag ?? '',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          itemBuilder: (BuildContext context) {
                            return state.countriesModel.countries?.map((Countries item) {
                              return PopupMenuItem<Countries>(
                                value: item,
                                height: 40,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.countryName ?? '',
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      item.flag ?? '',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              );
                            }).toList() ?? [];
                          },
                          onSelected: (Countries newValue) {
                            BlocProvider.of<SplashBloc>(context).add(
                              LoadDropdownData(
                                newValue.id.toString(),
                                state.typeValue,
                                state.searchTerms ?? '',
                                ''
                              )
                            );
                            drugsBloc.add(LoadPageEvent(
                              page: 1,
                              countryId: newValue.id.toString(),
                              searchTerm: state.searchTerms ?? "",
                              type: state.typeValue
                            ));
                          },
                        ),
                      ),
                    ],
                  ),
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
                                                BlocProvider.of<SplashBloc>(context).add(
                                                    LoadDropdownData(
                                                        state.countryFlag,
                                                        state.typeValue,
                                                        searchTxt ?? '',
                                                        ''));
                                                drugsBloc.add(LoadPageEvent(
                                                    page: 1,
                                                    countryId: state.countryFlag != ''
                                                        ? state.countryFlag
                                                        : '${state.countriesModel.countries?.first.id ?? 1}',
                                                    searchTerm: searchTxt,
                                                    type: state.typeValue));
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
                                            drugsBloc.add(LoadPageEvent(
                                              page: 1,
                                              countryId: state.countryFlag != ''
                                                  ? state.countryFlag
                                                  : '${state.countriesModel.countries?.first.id ?? 1}',
                                              searchTerm: '',
                                              type: state.typeValue
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
                        // Padding(
                        //   padding: const EdgeInsets.all(16.0),
                        //   child: CustomDropdownButtonFormField(
                        //     items: list1,
                        //     value: list1.first,
                        //     width: 100,
                        //     contentPadding: const EdgeInsets.symmetric(
                        //       horizontal: 10,
                        //       vertical: 0,
                        //     ),
                        //     onChanged: (String? newValue) {
                        //       print(newValue);
                        //       // BlocProvider.of<DrugsBloc>(context).add(
                        //       //   GetPost(
                        //       //       page: '1',
                        //       //       countryId: state.countryFlag,
                        //       //       searchTerm: '',
                        //       //       type: newValue!),
                        //       // );
                        //       BlocProvider.of<SplashBloc>(context).add(
                        //           LoadDropdownData(
                        //               state.countryFlag,
                        //               newValue ?? "Brand",
                        //               state.searchTerms ?? '',
                        //               ''));
                        //       drugsBloc.add(LoadPageEvent(
                        //           page: 1,
                        //           countryId: state.countryFlag != ''
                        //               ? state.countryFlag
                        //               : '${state.countriesModel.countries?.first.id ?? 1}',
                        //           searchTerm: state.searchTerms ?? '',
                        //           type: newValue!));
                        //     },
                        //   ),
                        // ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedIndex = 0;
                                    });
                                    BlocProvider.of<SplashBloc>(context).add(
                                      LoadDropdownData(
                                        state.countryFlag,
                                        "Brand",
                                        state.searchTerms ?? '',
                                        ''
                                      )
                                    );
                                    drugsBloc.add(LoadPageEvent(
                                      page: 1,
                                      countryId: state.countryFlag != ''
                                        ? state.countryFlag
                                        : '${state.countriesModel.countries?.first.id ?? 1}',
                                      searchTerm: state.searchTerms ?? '',
                                      type: 'Brand'
                                    ));
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: selectedIndex == 0 
                                        ? Colors.blue
                                        : Colors.transparent,
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          if (selectedIndex == 0)
                                            Container(
                                              padding: const EdgeInsets.all(4),
                                              margin: const EdgeInsets.only(right: 8),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.medical_services_outlined,
                                                size: 14,
                                                color: Colors.blue,
                                              ),
                                            ),
                                          Text(
                                            translation(context).lbl_brand,
                                            style: TextStyle(
                                              color: selectedIndex == 0 
                                                ? Colors.white
                                                : Colors.black87,
                                              fontSize: 14,
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedIndex = 1;
                                    });
                                    BlocProvider.of<SplashBloc>(context).add(
                                      LoadDropdownData(
                                        state.countryFlag,
                                        "Generic",
                                        state.searchTerms ?? '',
                                        ''
                                      )
                                    );
                                    drugsBloc.add(LoadPageEvent(
                                      page: 1,
                                      countryId: state.countryFlag != ''
                                        ? state.countryFlag
                                        : '${state.countriesModel.countries?.first.id ?? 1}',
                                      searchTerm: state.searchTerms ?? '',
                                      type: 'Generic'
                                    ));
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: selectedIndex == 1 
                                        ? Colors.blue
                                        : Colors.transparent,
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          if (selectedIndex == 1)
                                            Container(
                                              padding: const EdgeInsets.all(4),
                                              margin: const EdgeInsets.only(right: 8),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.local_pharmacy_outlined,
                                                size: 14,
                                                color: Colors.blue,
                                              ),
                                            ),
                                          Text(
                                            translation(context).lbl_generic,
                                            style: TextStyle(
                                              color: selectedIndex == 1 
                                                ? Colors.white
                                                : Colors.black87,
                                              fontSize: 14,
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            } else if (state is CountriesDataError) {
              BlocProvider.of<SplashBloc>(context).add(
                LoadDropdownData('', '', '', ''),
              );

              return Center(child: Text('${translation(context).lbl_error}: ${state.errorMessage}'));
            } else {
              BlocProvider.of<SplashBloc>(context).add(
                LoadDropdownData('', '', '', ''),
              );

              return Center(child: Text(translation(context).lbl_unknown_state));
            }
          }),
          BlocConsumer<DrugsBloc, DrugsState>(
            bloc: drugsBloc,
            listener: (BuildContext context, DrugsState state) {
              if (state is DataError) {
                // Error handling if needed
              }
            },
            builder: (context, state) {
              if (state is PaginationLoadingState) {
                return Expanded(
                  child: DrugsShimmerLoader()
                );
              } else if (state is PaginationLoadedState) {
                return Expanded(
                  child: VirtualizedDrugsList(
                    drugsBloc: drugsBloc,
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
          // if (AppData.isShowGoogleBannerAds ?? false) BannerAdWidget()
        ],
      ),
    );
  }

  // Bottom sheet for drug details
  void _showBottomSheet(BuildContext context, String genericName, String question) {
    showModalBottomSheet(
      showDragHandle: true,
      enableDrag: true,
      isScrollControlled: true,
      isDismissible: false,
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.9,
              maxChildSize: 1.0,
              expand: false,
              builder: (BuildContext context, ScrollController scrollController) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: ChatDetailScreen(
                    isFromMainScreen: false,
                    question: '$question $genericName',
                  ),
                );
              }
            );
          }
        );
      },
    );
  }

}
