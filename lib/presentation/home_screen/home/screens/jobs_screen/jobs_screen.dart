import 'dart:async';

import '../../../../../main.dart';

import 'package:doctak_app/data/models/countries_model/countries_model.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_event.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/bloc/jobs_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/bloc/jobs_state.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/widgets/virtualized_jobs_list.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/splash_screen/bloc/splash_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../../widgets/shimmer_widget/jobs_shimmer_loader.dart';
import '../../../../splash_screen/bloc/splash_event.dart';
import '../../../../splash_screen/bloc/splash_state.dart';
import 'bloc/jobs_event.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  ProfileBloc profileBloc = ProfileBloc();
  JobsBloc jobsBloc = JobsBloc();
  Timer? _debounce;
  final TextEditingController _controller = TextEditingController();
  List<String> _filteredSpecialties = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    jobsBloc.add(
      JobLoadPageEvent(
          page: 1, countryId: '', searchTerm: ''),
    );
    profileBloc.add(UpdateSpecialtyDropdownValue1(''));
    super.initState();
  }

  void _filterSpecialties(String query) {
    try {
      setState(() {
        _filteredSpecialties = profileBloc.specialtyList!
            .where((specialty) =>
                specialty.toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    } catch (e) {
      // Handle potential error when processing specialty list
      debugPrint('Error filtering specialties: $e');
    }
  }

  String selectedValue = '';
  bool isShowingSuggestions = false;
  bool isSearchVisible = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isShowingSuggestions = false;
        });
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
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
                    Center(child: Text(translation(context).lbl_loading)),
                  ],
                );
              } else if (state is CountriesDataLoaded) {
                if (profileBloc.specialtyList?.isEmpty ?? true) {
                  profileBloc.add(UpdateSpecialtyDropdownValue1(''));
                }
                for (var element in state.countriesModel.countries!) {
                  if (element.countryName == state.countryFlag) {
                    selectedValue =
                        (state.countriesModel.countries?.first.countryName ?? '') + 
                            (element.countryName ?? '');
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
                            color: Colors.blue.withAlpha(25),
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
                            Icons.work_outline_rounded,
                            color: Colors.blue[600],
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            translation(context).lbl_jobs,
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
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withAlpha(25),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isSearchVisible ? Icons.close : Icons.search,
                              color: Colors.blue[600],
                              size: 16,
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              isSearchVisible = !isSearchVisible;
                              if (!isSearchVisible) {
                                // Clear search when closing
                                _controller.clear();
                                jobsBloc.add(JobLoadPageEvent(
                                  page: 1,
                                  countryId: state.countryFlag != ''
                                      ? state.countryFlag
                                      : '${state.countriesModel.countries?.first.id ?? 1}',
                                  searchTerm: ''
                                ));
                              }
                            });
                          },
                        ),
                        // Country dropdown with proper constraints
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
                                  child: SizedBox(
                                    width: 200, // Fixed width for popup items
                                    child: Row(
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
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          item.flag ?? '',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
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
                              jobsBloc.add(JobLoadPageEvent(
                                page: 1,
                                countryId: newValue.id.toString(),
                                searchTerm: state.searchTerms ?? ""
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
                            height: isSearchVisible ? 60 : 0,
                            child: SingleChildScrollView(
                              physics: const NeverScrollableScrollPhysics(),
                              child: isSearchVisible
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
                                              controller: _controller,
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
                                                  _filterSpecialties(searchTxt);
                                                  isShowingSuggestions = _filteredSpecialties.isNotEmpty;
                                                  BlocProvider.of<SplashBloc>(context).add(
                                                      LoadDropdownData(
                                                          state.countryFlag,
                                                          state.typeValue,
                                                          searchTxt,
                                                          ''));
                                                  jobsBloc.add(JobLoadPageEvent(
                                                      page: 1,
                                                      countryId: state.countryFlag != ''
                                                          ? state.countryFlag
                                                          : '${state.countriesModel.countries?.first.id ?? 1}',
                                                      searchTerm: searchTxt));
                                                });
                                              },
                                              decoration: InputDecoration(
                                                border: InputBorder.none,
                                                hintText: translation(context).lbl_search_by_specialty,
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
                                              _controller.clear();
                                              isShowingSuggestions = false;
                                              // Update search results
                                              jobsBloc.add(JobLoadPageEvent(
                                                page: 1,
                                                countryId: state.countryFlag != ''
                                                    ? state.countryFlag
                                                    : '${state.countriesModel.countries?.first.id ?? 1}',
                                                searchTerm: ''
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
                          
                          // Suggestions dropdown when searching
                          if (isShowingSuggestions)
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: _filteredSpecialties.length,
                                itemBuilder: (context, index) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      border: (index != _filteredSpecialties.length - 1) 
                                          ? Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2)))
                                          : const Border(),
                                    ),
                                    child: ListTile(
                                      title: Text(
                                        _filteredSpecialties[index],
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 14,
                                        ),
                                      ),
                                      onTap: () {
                                        setState(() {
                                          isShowingSuggestions = false;
                                          _controller.text = _filteredSpecialties[index];
                                        });
                                        BlocProvider.of<SplashBloc>(context).add(LoadDropdownData(
                                          state.countryFlag,
                                          state.typeValue,
                                          _filteredSpecialties[index],
                                          ''
                                        ));
                                        jobsBloc.add(JobLoadPageEvent(
                                          page: 1,
                                          countryId: state.countryFlag != ''
                                              ? state.countryFlag
                                              : '${state.countriesModel.countries?.first.id ?? 1}',
                                          searchTerm: _filteredSpecialties[index]
                                        ));
                                      },
                                    ),
                                  );
                                },
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
            BlocBuilder<JobsBloc, JobsState>(
              bloc: jobsBloc,
              builder: (context, state) {
                isShowingSuggestions = false;
                if (state is PaginationLoadingState) {
                  return const Expanded(child: JobsShimmerLoader());
                } else if (state is PaginationLoadedState) {
                  return Expanded(
                    child: VirtualizedJobsList(
                      jobsBloc: jobsBloc,
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
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}