import 'dart:async';

import 'package:doctak_app/ads_setting/ads_widget/banner_ads_widget.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_event.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/bloc/jobs_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/bloc/jobs_state.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/splash_screen/bloc/splash_bloc.dart';
import 'package:doctak_app/widgets/custom_dropdown_button_from_field.dart';
import 'package:doctak_app/widgets/custom_dropdown_search.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../../widgets/custom_dropdown_field.dart';
import '../../../../splash_screen/bloc/splash_event.dart';
import '../../../../splash_screen/bloc/splash_state.dart';
import 'bloc/jobs_event.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({Key? key}) : super(key: key);

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  ProfileBloc profileBloc = ProfileBloc();
  JobsBloc jobsBloc = JobsBloc();
  Timer? _debounce;
  final TextEditingController _controller = TextEditingController();
  List<String> _filteredSuggestions = [];
  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    jobsBloc.add(
      JobLoadPageEvent(page: 1, countryId: '1', searchTerm: ''),
    );
    profileBloc.add(UpdateSpecialtyDropdownValue1(''));
    super.initState();
  }
  void _filterSuggestions(String query) {
    setState(() {
      _filteredSuggestions = profileBloc.specialtyList!
          .where((suggestion) =>
          suggestion.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }
  var selectedValue;
 bool isShownSuggestion=false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: svGetScaffoldColor(),
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
                      child: CircularProgressIndicator(
                    color: context.iconColor,
                  )),
                ],
              );
            } else if (state is CountriesDataLoaded) {
              List<String> list1 = ['New', 'Expired'];
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
                    title: Row(
                      // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                            child: Center(
                                child: Text('Jobs',
                                    style: boldTextStyle(size: 18)))),
                        Expanded(
                          child: CustomDropdownField(
                            items: state.countriesModel.countries ?? [],
                            value: state.countriesModel.countries?.first
                                    .countryName ??
                                '',
                            width: 50,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 0,
                            ),
                            onChanged: (String? newValue) {
                              print("ddd ${state.countryFlag}");
                              var index = state.countriesModel.countries!
                                  .indexWhere((element) =>
                                      newValue == element.countryName);
                              var countryId =
                                  state.countriesModel.countries![index].id;
                              // jobsBloc.add(
                              //   GetPost(
                              //       page: '1',
                              //       countryId: countryId.toString(),
                              //       searchTerm: '',
                              //       type: state.typeValue),
                              // );
                              // countryId = countryIds.toString();
                              BlocProvider.of<SplashBloc>(context).add(
                                  LoadDropdownData(
                                      countryId.toString(),
                                      state.typeValue,
                                      state.searchTerms ?? '',
                                      state.isExpired));
                              jobsBloc.add(JobLoadPageEvent(
                                  page: 1,
                                  countryId: countryId.toString(),
                                  searchTerm: state.searchTerms ?? "",
                                  isExpired: state.isExpired));
                          
                              // jobsBloc
                              //     .add(UpdateFirstDropdownValue(newValue!));
                            },
                          ),
                        ),
                      ],
                    ),
                    elevation: 0,
                    centerTitle: true,
                    actions: const [
                      // IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                                padding: const EdgeInsets.only(left: 8.0),
                                margin: const EdgeInsets.only(
                                    left: 16, top: 16.0, bottom: 16.0),
                                decoration: BoxDecoration(
                                    color: context.cardColor,
                                    borderRadius: radius(8)),
                                child:
                                // CustomDropdownSearch(
                                //   onChanged: (searchTxt) {
                                //     if (_debounce?.isActive ?? false)
                                //       _debounce?.cancel();
                                //
                                //     _debounce = Timer(
                                //         const Duration(milliseconds: 500), () {
                                //       // jobsBloc.add(
                                //       //   GetPost(
                                //       //     page: '1',
                                //       //     countryId: AppData.countryName,
                                //       //     searchTerm: searchTxt,
                                //       //   ),
                                //       // );
                                //       BlocProvider.of<SplashBloc>(context).add(
                                //           LoadDropdownData(
                                //               state.countryFlag,
                                //               state.typeValue,
                                //               searchTxt ?? '',
                                //               state.isExpired));
                                //       jobsBloc.add(JobLoadPageEvent(
                                //         page: 1,
                                //         countryId: state.countryFlag != ''
                                //             ? state.countryFlag
                                //             : '${state.countriesModel.countries?.first.id ?? 1}',
                                //         searchTerm: searchTxt,
                                //       ));
                                //     });
                                //     // BlocProvider.of<SplashBloc>(context).add(LoadDropdownData(newValue,state.typeValue));
                                //   },
                                //   hintText: 'Search speciality',
                                //   textController: _controller,
                                //   items: profileBloc.specialtyList ?? [],
                                //   dropdownHeight: 300,
                                //   onSelect: (searchTxt) {
                                //     if (_debounce?.isActive ?? false)
                                //       _debounce?.cancel();
                                //
                                //     _debounce = Timer(
                                //         const Duration(milliseconds: 500), () {
                                //       // jobsBloc.add(
                                //       //   GetPost(
                                //       //     page: '1',
                                //       //     countryId: AppData.countryName,
                                //       //     searchTerm: searchTxt,
                                //       //   ),
                                //       // );
                                //       BlocProvider.of<SplashBloc>(context).add(
                                //           LoadDropdownData(
                                //               state.countryFlag,
                                //               state.typeValue,
                                //               searchTxt ?? '',
                                //               state.isExpired));
                                //       jobsBloc.add(JobLoadPageEvent(
                                //         page: 1,
                                //         countryId: state.countryFlag != ''
                                //             ? state.countryFlag
                                //             : '${state.countriesModel.countries?.first.id ?? 1}',
                                //         searchTerm: searchTxt,
                                //       ));
                                //     });
                                //     // BlocProvider.of<SplashBloc>(context).add(LoadDropdownData(newValue,state.typeValue));
                                //   },
                                // )
                                AppTextField(
                                  controller: _controller,
                                  textFieldType: TextFieldType.NAME,
                                  onChanged: (searchTxt) async {
                                    if (_debounce?.isActive ?? false)
                                      _debounce?.cancel();
                                    _debounce = Timer(const Duration(milliseconds: 500), () {
                                          _filterSuggestions(searchTxt);
                                          isShownSuggestion=true;
                                      // jobsBloc.add(
                                      //   GetPost(
                                      //     page: '1',
                                      //     countryId: AppData.countryName,
                                      //     searchTerm: searchTxt,
                                      //   ),
                                      // );
                                      BlocProvider.of<SplashBloc>(context).add(
                                          LoadDropdownData(
                                              state.countryFlag,
                                              state.typeValue,
                                              searchTxt ?? '',
                                              state.isExpired));
                                      jobsBloc.add(JobLoadPageEvent(
                                        page: 1,
                                        countryId: state.countryFlag != ''
                                            ? state.countryFlag
                                            : '${state.countriesModel.countries?.first.id ?? 1}',
                                        searchTerm: searchTxt,
                                      ));
                                    });
                                    // BlocProvider.of<SplashBloc>(context).add(LoadDropdownData(newValue,state.typeValue));
                                  },
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Search Here',
                                    hintStyle:
                                        secondaryTextStyle(color: svGetBodyColor()),
                                    suffixIcon: Image.asset(
                                            'images/socialv/icons/ic_Search.png',
                                            height: 16,
                                            width: 16,
                                            fit: BoxFit.cover,
                                            color: svGetBodyColor())
                                        .paddingAll(16),
                                  ),
                                ),
                                ),
                           if(isShownSuggestion) ListView.builder(
                              shrinkWrap: true,
                              itemCount: _filteredSuggestions.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  color: Colors.white,
                                  child: ListTile(
                                    title: Text(_filteredSuggestions[index]),
                                    onTap: () {
                                      setState(() {
                                      });
                                      isShownSuggestion=false;
                                      _controller.text = _filteredSuggestions[index];
                                      BlocProvider.of<SplashBloc>(context).add(
                                          LoadDropdownData(
                                              state.countryFlag,
                                              state.typeValue,
                                              _filteredSuggestions[index] ?? '',
                                              state.isExpired));
                                      jobsBloc.add(JobLoadPageEvent(
                                        page: 1,
                                        countryId: state.countryFlag != ''
                                            ? state.countryFlag
                                            : '${state.countriesModel.countries?.first.id ?? 1}',
                                        searchTerm: _filteredSuggestions[index],
                                      ));
                                      // Do something with the selected suggestion
                                    },
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: CustomDropdownButtonFormField(
                          items: list1,
                          value: list1.first,
                          width: 100,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 0,
                          ),
                          onChanged: (String? newValue) {
                            print(newValue);
                            // jobsBloc.add(
                            //   GetPost(
                            //       page: '1',
                            //       countryId: state.countryFlag,
                            //       searchTerm: '',
                            //       type: newValue!),
                            // );
                            BlocProvider.of<SplashBloc>(context).add(
                                LoadDropdownData(
                                    state.countryFlag,
                                    newValue ?? "",
                                    state.searchTerms ?? '',
                                    newValue!));
                            jobsBloc.add(JobLoadPageEvent(
                                page: 1,
                                countryId: state.countryFlag != ''
                                    ? state.countryFlag
                                    : '${state.countriesModel.countries?.first.id ?? 1}',
                                searchTerm: state.searchTerms ?? '',
                                isExpired: newValue));
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              );
            } else if (state is CountriesDataError) {
              BlocProvider.of<SplashBloc>(context).add(
                LoadDropdownData('', '', '', ''),
              );

              return Center(child: Text('Error: ${state.errorMessage}'));
            } else {
              BlocProvider.of<SplashBloc>(context).add(
                LoadDropdownData('', '', '', ''),
              );

              return const Center(child: Text('Unknown state'));
            }
          }),
          BlocConsumer<JobsBloc, JobsState>(
            bloc: jobsBloc,
            // listenWhen: (previous, current) => current is PaginationLoadedState,
            // buildWhen: (previous, current) => current is! PaginationLoadedState,
            listener: (BuildContext context, JobsState state) {
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
              isShownSuggestion=false;
              print("state $state");
              if (state is PaginationLoadingState) {
                return const Expanded(
                    child: Center(child: CircularProgressIndicator()));
              } else if (state is PaginationLoadedState) {
                // print(state.drugsModel.length);
                return _buildPostList(context);
              } else if (state is DataError) {
                return Expanded(
                  child: Center(
                    child: Text(state.errorMessage),
                  ),
                );
              } else {
                return const Expanded(
                    child: Center(child: Text('Something went wrong')));
              }
            },
          ),
          if (AppData.isShowGoogleBannerAds ?? false) BannerAdWidget()
        ],
      ),
    );
  }

  Widget _buildPostList(BuildContext context) {
    final bloc = jobsBloc;
    print("bloc$bloc");
    print("len${bloc.drugsData.length}");
    return Expanded(
      child: bloc.drugsData.isEmpty
          ? const Center(
              child: Text("No Jobs Found"),
            )
          : ListView.builder(
              itemCount: bloc.drugsData.length,
              itemBuilder: (context, index) {
                if (bloc.pageNumber <= bloc.numberOfPage) {
                  if (index == bloc.drugsData.length - bloc.nextPageTrigger) {
                    bloc.add(JobCheckIfNeedMoreDataEvent(index: index));
                  }
                }
                log('hello ${bloc.drugsData[index].description} end helo\n');
                return bloc.numberOfPage != bloc.pageNumber - 1 &&
                        index >= bloc.drugsData.length - 1
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : Container(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: context.cardColor,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bloc.drugsData[index].jobTitle ?? "",
                              style: secondaryTextStyle(
                                  color: svGetBodyColor(), size: 18),
                            ),
                            const SizedBox(height: 5),
                            Text(
                                'Company: ${bloc.drugsData[index].companyName ?? 'N/A'}',
                                style: secondaryTextStyle(
                                    color: svGetBodyColor())),
                            const SizedBox(height: 10),
                            Text(
                                'Experience: ${bloc.drugsData[index].experience ?? 'N/A'}',
                                style: secondaryTextStyle(
                                    color: svGetBodyColor())),
                            const SizedBox(height: 5),
                            HtmlWidget(
                              bloc.drugsData[index].description ?? '<p>N/A</p>',
                            ),
                            const SizedBox(height: 5),
                            Text(
                                "Location: ${bloc.drugsData[index].location ?? 'N/A'}",
                                style: secondaryTextStyle(
                                    color: svGetBodyColor())),
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Apply before: ${bloc.drugsData[index].lastDate != null ? DateFormat('dd MMM, yyyy').format(DateTime.parse(bloc.drugsData[index].lastDate!)) : 'N/A'}',
                                    style: TextStyle(
                                      color: bloc.drugsData[index].lastDate !=
                                                  null &&
                                              DateTime.now().isAfter(
                                                  DateTime.parse(bloc
                                                      .drugsData[index]
                                                      .lastDate!))
                                          ? Colors
                                              .red // Change font color to red for expired jobs
                                          : svGetBodyColor(),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  GestureDetector(
                                    onTap: () async {
                                      final Uri url = Uri.parse(bloc
                                          .drugsData[index]
                                          .link!); // Assuming job.link is a non-null String
                                      // Show dialog asking the user to confirm navigation
                                      final shouldLeave =
                                          await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Leave App'),
                                          content: const Text(
                                              'Would you like to leave the app to view this content?'),
                                          actions: <Widget>[
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context)
                                                      .pop(false),
                                              child: const Text('No'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context)
                                                      .pop(true),
                                              child: const Text('Yes'),
                                            ),
                                          ],
                                        ),
                                      );
                                      // If the user confirmed, launch the URL
                                      if (shouldLeave == true) {
                                        // await launchUrl(url);
                                      } else if (shouldLeave == false) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Leaving the app canceled.')),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Leaving the app canceled.')),
                                        );
                                      }
                                    },
                                    child: const Text(
                                      'Apply ',
                                      style: TextStyle(
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                // return PostItem(bloc.drugsData[index].title, bloc.posts[index].body);
              },
            ),
    );
  }
}
