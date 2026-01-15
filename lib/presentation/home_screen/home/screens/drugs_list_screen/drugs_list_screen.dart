import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/data/models/countries_model/countries_model.dart';
import 'package:doctak_app/presentation/chat_gpt_screen/ChatDetailScreen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/drugs_list_screen/bloc/drugs_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/drugs_list_screen/virtualized_drugs_list.dart';
import 'package:doctak_app/presentation/splash_screen/bloc/splash_bloc.dart';
import 'package:doctak_app/presentation/splash_screen/bloc/splash_event.dart';
import 'package:doctak_app/presentation/splash_screen/bloc/splash_state.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/doctak_searchable_app_bar.dart';
import 'package:flutter/material.dart';

import '../../../../../widgets/shimmer_widget/drugs_shimmer_loader.dart';
import 'bloc/drugs_event.dart';
import 'bloc/drugs_state.dart';

class DrugsListScreen extends StatefulWidget {
  const DrugsListScreen({super.key});

  @override
  State<DrugsListScreen> createState() => _DrugsListScreenState();
}

class _DrugsListScreenState extends State<DrugsListScreen> {
  final ScrollController _scrollController = ScrollController();
  DrugsBloc drugsBloc = DrugsBloc();
  bool isSearchShow = false;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    drugsBloc.add(LoadPageEvent(page: 1, countryId: '1', searchTerm: '', type: 'Brand'));
    super.initState();
  }

  @override
  void dispose() {
    searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  var selectedValue;

  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      body: Column(
        children: [
          BlocBuilder<SplashBloc, SplashState>(
            builder: (context, state) {
              if (state is CountriesDataInitial) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [Center(child: Text(translation(context).lbl_loading))],
                );
              } else if (state is CountriesDataLoaded) {
                for (var element in state.countriesModel.countries!) {
                  if (element.flag == state.countryFlag) {
                    selectedValue = state.countriesModel.countries?.first.flag ?? element.flag;
                  }
                }
                return Column(
                  children: [
                    DoctakAppBar(
                      title: translation(context).lbl_drug_list,
                      titleIcon: Icons.medication_rounded,
                      actions: [
                        // Search toggle button
                        DoctakSearchToggleButton(
                          isSearching: isSearchShow,
                          onTap: () {
                            setState(() {
                              isSearchShow = !isSearchShow;
                              if (!isSearchShow) {
                                // Clear search when closing
                                searchController.clear();
                                drugsBloc.add(
                                  LoadPageEvent(
                                    page: 1,
                                    countryId: state.countryFlag != '' ? state.countryFlag : '${state.countriesModel.countries?.first.id ?? 1}',
                                    searchTerm: '',
                                    type: state.typeValue,
                                  ),
                                );
                              }
                            });
                          },
                        ),
                        const SizedBox(width: 4),
                        // Country dropdown
                        PopupMenuButton<Countries>(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          offset: const Offset(0, 50),
                          tooltip: 'Select Country',
                          elevation: 8,
                          color: theme.cardBackground,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: theme.iconButtonDecoration(),
                            child: Center(
                              child: Text(
                                state.countryFlag != ''
                                    ? state.countriesModel.countries!.firstWhere((element) => element.id.toString() == state.countryFlag, orElse: () => state.countriesModel.countries!.first).flag ??
                                          ''
                                    : state.countriesModel.countries!.first.flag ?? '',
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                          itemBuilder: (BuildContext context) {
                            return state.countriesModel.countries?.map((Countries item) {
                                  return PopupMenuItem<Countries>(
                                    value: item,
                                    height: 48,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.countryName ?? '',
                                              style: TextStyle(color: theme.textPrimary, fontFamily: 'Poppins', fontWeight: FontWeight.w500, fontSize: 16),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(item.flag ?? '', style: const TextStyle(fontSize: 16)),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList() ??
                                [];
                          },
                          onSelected: (Countries newValue) {
                            BlocProvider.of<SplashBloc>(context).add(LoadDropdownData(newValue.id.toString(), state.typeValue, state.searchTerms ?? '', ''));
                            drugsBloc.add(LoadPageEvent(page: 1, countryId: newValue.id.toString(), searchTerm: state.searchTerms ?? "", type: state.typeValue));
                          },
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                    Container(
                      color: theme.scaffoldBackground,
                      child: Column(
                        children: [
                          // Search field with animated visibility
                          DoctakCollapsibleSearchField(
                            isVisible: isSearchShow,
                            hintText: translation(context).lbl_search,
                            controller: searchController,
                            height: 72,
                            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            onChanged: (searchTxt) {
                              BlocProvider.of<SplashBloc>(context).add(LoadDropdownData(state.countryFlag, state.typeValue, searchTxt, ''));
                              drugsBloc.add(
                                LoadPageEvent(
                                  page: 1,
                                  countryId: state.countryFlag != '' ? state.countryFlag : '${state.countriesModel.countries?.first.id ?? 1}',
                                  searchTerm: searchTxt,
                                  type: state.typeValue,
                                ),
                              );
                            },
                            onClear: () {
                              drugsBloc.add(
                                LoadPageEvent(
                                  page: 1,
                                  countryId: state.countryFlag != '' ? state.countryFlag : '${state.countriesModel.countries?.first.id ?? 1}',
                                  searchTerm: '',
                                  type: state.typeValue,
                                ),
                              );
                            },
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
                            height: 48,
                            decoration: BoxDecoration(color: theme.surfaceVariant, borderRadius: BorderRadius.circular(25)),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedIndex = 0;
                                      });
                                      BlocProvider.of<SplashBloc>(context).add(LoadDropdownData(state.countryFlag, "Brand", state.searchTerms ?? '', ''));
                                      drugsBloc.add(
                                        LoadPageEvent(
                                          page: 1,
                                          countryId: state.countryFlag != '' ? state.countryFlag : '${state.countriesModel.countries?.first.id ?? 1}',
                                          searchTerm: state.searchTerms ?? '',
                                          type: 'Brand',
                                        ),
                                      );
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(color: selectedIndex == 0 ? theme.primary : Colors.transparent, borderRadius: BorderRadius.circular(25)),
                                      child: Center(
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            if (selectedIndex == 0)
                                              Container(
                                                padding: const EdgeInsets.all(4),
                                                margin: const EdgeInsets.only(right: 8),
                                                decoration: BoxDecoration(color: theme.cardBackground, shape: BoxShape.circle),
                                                child: Icon(Icons.medical_services_outlined, size: 14, color: theme.primary),
                                              ),
                                            Text(
                                              translation(context).lbl_brand,
                                              style: TextStyle(color: selectedIndex == 0 ? theme.cardBackground : theme.textPrimary, fontSize: 14, fontFamily: 'Poppins', fontWeight: FontWeight.w600),
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
                                      BlocProvider.of<SplashBloc>(context).add(LoadDropdownData(state.countryFlag, "Generic", state.searchTerms ?? '', ''));
                                      drugsBloc.add(
                                        LoadPageEvent(
                                          page: 1,
                                          countryId: state.countryFlag != '' ? state.countryFlag : '${state.countriesModel.countries?.first.id ?? 1}',
                                          searchTerm: state.searchTerms ?? '',
                                          type: 'Generic',
                                        ),
                                      );
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(color: selectedIndex == 1 ? theme.primary : Colors.transparent, borderRadius: BorderRadius.circular(25)),
                                      child: Center(
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            if (selectedIndex == 1)
                                              Container(
                                                padding: const EdgeInsets.all(4),
                                                margin: const EdgeInsets.only(right: 8),
                                                decoration: BoxDecoration(color: theme.cardBackground, shape: BoxShape.circle),
                                                child: Icon(Icons.local_pharmacy_outlined, size: 14, color: theme.primary),
                                              ),
                                            Text(
                                              translation(context).lbl_generic,
                                              style: TextStyle(color: selectedIndex == 1 ? theme.cardBackground : theme.textPrimary, fontSize: 14, fontFamily: 'Poppins', fontWeight: FontWeight.w600),
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
                BlocProvider.of<SplashBloc>(context).add(LoadDropdownData('', '', '', ''));

                return Center(child: Text('${translation(context).lbl_error}: ${state.errorMessage}'));
              } else {
                BlocProvider.of<SplashBloc>(context).add(LoadDropdownData('', '', '', ''));

                return Center(child: Text(translation(context).lbl_unknown_state));
              }
            },
          ),
          BlocConsumer<DrugsBloc, DrugsState>(
            bloc: drugsBloc,
            listener: (BuildContext context, DrugsState state) {
              if (state is DataError) {
                // Error handling if needed
              }
            },
            builder: (context, state) {
              if (state is PaginationLoadingState) {
                return Expanded(child: DrugsShimmerLoader());
              } else if (state is PaginationLoadedState) {
                return Expanded(
                  child: VirtualizedDrugsList(drugsBloc: drugsBloc, scrollController: _scrollController),
                );
              } else if (state is DataError) {
                return Expanded(child: Center(child: Text(state.errorMessage)));
              } else {
                return Expanded(child: Center(child: Text(translation(context).msg_something_went_wrong)));
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
                  child: ChatDetailScreen(isFromMainScreen: false, question: '$question $genericName'),
                );
              },
            );
          },
        );
      },
    );
  }
}
