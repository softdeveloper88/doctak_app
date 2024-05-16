import 'dart:async';

import 'package:doctak_app/ads_setting/ads_widget/banner_ads_widget.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_event.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/bloc/jobs_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/bloc/jobs_state.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVColors.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/splash_screen/bloc/splash_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:url_launcher/url_launcher.dart';

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
      JobLoadPageEvent(
          page: 1, countryId: '1', isExpired: 'New', searchTerm: ''),
    );
    profileBloc.add(UpdateSpecialtyDropdownValue1(''));
    super.initState();
  }

  void _filterSuggestions(String query) {
    try {
      setState(() {
        _filteredSuggestions = profileBloc.specialtyList!
            .where((suggestion) =>
                suggestion.toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    } catch (e) {}
  }

  var selectedValue;
  bool isShownSuggestion = false;
  int selectedIndex = 0;

  Future<void> _launchInBrowser(Uri url) async {
    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isShownSuggestion = false;
        });
      },
      child: Scaffold(
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
                if (profileBloc.specialtyList?.isEmpty ?? true) {
                  profileBloc.add(UpdateSpecialtyDropdownValue1(''));
                }
                for (var element in state.countriesModel.countries!) {
                  if (element.countryName == state.countryFlag) {
                    selectedValue =
                        state.countriesModel.countries?.first.countryName ??
                            element.countryName;
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
                                var index = state.countriesModel.countries!
                                    .indexWhere((element) =>
                                        newValue == element.countryName);
                                var countryId =
                                    state.countriesModel.countries![index].id;
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
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.black),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      elevation: 0,
                      centerTitle: true,
                    ),
                    Column(
                      children: [
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.only(left: 8.0),
                              margin: const EdgeInsets.only(
                                left: 16,
                                top: 16.0,
                                bottom: 16.0,
                                right: 16,
                              ),
                              decoration: BoxDecoration(
                                  color: context.dividerColor.withOpacity(0.4),
                                  borderRadius: radius(5),
                                  border: Border.all(
                                      color: Colors.black, width: 0.3)),
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
                                  // if (_debounce?.isActive ?? false)
                                  //   _debounce?.cancel();
                                  // _debounce = Timer(const Duration(milliseconds: 500), () {
                                  _filterSuggestions(searchTxt);
                                  isShownSuggestion = true;
                                  // jobsBloc.add(
                                  //   GetPost(
                                  //     page: '1',
                                  //     countryId: AppData.countryName,
                                  //     searchTerm: searchTxt,
                                  //   ),
                                  // );
                                  // BlocProvider.of<SplashBloc>(context).add(
                                  //     LoadDropdownData(
                                  //         state.countryFlag,
                                  //         state.typeValue,
                                  //         searchTxt ?? '',
                                  //         state.isExpired));
                                  // jobsBloc.add(JobLoadPageEvent(
                                  //   page: 1,
                                  //   countryId: state.countryFlag != ''
                                  //       ? state.countryFlag
                                  //       : '${state.countriesModel.countries?.first.id ?? 1}',
                                  //   searchTerm: searchTxt,
                                  // ));
                                  // });
                                  // BlocProvider.of<SplashBloc>(context).add(LoadDropdownData(newValue,state.typeValue));
                                },
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Search by Specialty',
                                  hintStyle: secondaryTextStyle(
                                      color: svGetBodyColor()),
                                  suffixIcon: GestureDetector(
                                    onTap: () {
                                      isShownSuggestion = true;
                                      BlocProvider.of<SplashBloc>(context).add(
                                          LoadDropdownData(
                                              state.countryFlag,
                                              state.typeValue,
                                              _controller.text ?? '',
                                              state.isExpired));
                                      jobsBloc.add(JobLoadPageEvent(
                                        page: 1,
                                        countryId: state.countryFlag != ''
                                            ? state.countryFlag
                                            : '${state.countriesModel.countries?.first.id ?? 1}',
                                        searchTerm: _controller.text,
                                      ));
                                    },
                                    child: Image.asset(
                                            'images/socialv/icons/ic_Search.png',
                                            height: 16,
                                            width: 16,
                                            fit: BoxFit.cover,
                                            color: svGetBodyColor())
                                        .paddingAll(16),
                                  ),
                                ),
                              ),
                            ),
                            if (isShownSuggestion)
                              ListView.builder(
                                shrinkWrap: true,
                                itemCount: _filteredSuggestions.length,
                                itemBuilder: (context, index) {
                                  return Container(
                                    color: Colors.white,
                                    child: ListTile(
                                      title: Text(_filteredSuggestions[index]),
                                      onTap: () {
                                        setState(() {});
                                        isShownSuggestion = false;
                                        _controller.text =
                                            _filteredSuggestions[index];
                                        BlocProvider.of<SplashBloc>(context)
                                            .add(LoadDropdownData(
                                                state.countryFlag,
                                                state.typeValue,
                                                _filteredSuggestions[index] ??
                                                    '',
                                                state.isExpired));
                                        jobsBloc.add(JobLoadPageEvent(
                                          page: 1,
                                          countryId: state.countryFlag != ''
                                              ? state.countryFlag
                                              : '${state.countriesModel.countries?.first.id ?? 1}',
                                          searchTerm:
                                              _filteredSuggestions[index],
                                        ));
                                        // Do something with the selected suggestion
                                      },
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      selectedIndex = 0;
                                      BlocProvider.of<SplashBloc>(context).add(
                                          LoadDropdownData(
                                              state.countryFlag,
                                              "New",
                                              state.searchTerms ?? '',
                                              'New'));
                                      jobsBloc.add(JobLoadPageEvent(
                                          page: 1,
                                          countryId: state.countryFlag != ''
                                              ? state.countryFlag
                                              : '${state.countriesModel.countries?.first.id ?? 1}',
                                          searchTerm: state.searchTerms ?? '',
                                          isExpired: 'New'));
                                    },
                                    child: Text(
                                      'New',
                                      style: TextStyle(
                                        color: SVAppColorPrimary,
                                        fontSize: 14,
                                        fontWeight: selectedIndex == 0
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 2,
                                    width: context.width() / 2 - 10,
                                    color: selectedIndex == 0
                                        ? SVAppColorPrimary
                                        : SVAppColorPrimary.withOpacity(0.2),
                                  ),
                                ],
                              ),
                              Center(
                                  child: Container(
                                color: Colors.grey,
                                height: 30,
                                width: 1,
                              )),
                              Column(
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      selectedIndex = 1;
                                      BlocProvider.of<SplashBloc>(context).add(
                                          LoadDropdownData(
                                              state.countryFlag,
                                              "Expired",
                                              state.searchTerms ?? '',
                                              'Expired'));
                                      jobsBloc.add(JobLoadPageEvent(
                                          page: 1,
                                          countryId: state.countryFlag != ''
                                              ? state.countryFlag
                                              : '${state.countriesModel.countries?.first.id ?? 1}',
                                          searchTerm: state.searchTerms ?? '',
                                          isExpired: 'Expired'));
                                    },
                                    child: Text(
                                      'Expired',
                                      style: TextStyle(
                                        color: SVAppColorPrimary,
                                        fontSize: 14,
                                        fontWeight: selectedIndex == 1
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 2,
                                    width: context.width() / 2 - 10,
                                    color: selectedIndex == 1
                                        ? SVAppColorPrimary
                                        : SVAppColorPrimary.withOpacity(0.2),
                                  ),
                                ],
                              ),
                              16.height,
                            ],
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
                        //       // jobsBloc.add(
                        //       //   GetPost(
                        //       //       page: '1',
                        //       //       countryId: state.countryFlag,
                        //       //       searchTerm: '',
                        //       //       type: newValue!),
                        //       // );
                        //       BlocProvider.of<SplashBloc>(context).add(
                        //           LoadDropdownData(
                        //               state.countryFlag,
                        //               newValue ?? "",
                        //               state.searchTerms ?? '',
                        //               newValue!));
                        //       jobsBloc.add(JobLoadPageEvent(
                        //           page: 1,
                        //           countryId: state.countryFlag != ''
                        //               ? state.countryFlag
                        //               : '${state.countriesModel.countries?.first.id ?? 1}',
                        //           searchTerm: state.searchTerms ?? '',
                        //           isExpired: newValue));
                        //     },
                        //   ),
                        // ),
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
                isShownSuggestion = false;
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
      ),
    );
  }

  Widget _buildPostList(BuildContext context) {
    final bloc = jobsBloc;
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
                return bloc.numberOfPage != bloc.pageNumber - 1 &&
                        index >= bloc.drugsData.length - 1
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : Container(
                        margin: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: context.cardColor,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Material(
                          elevation: 4,
                          borderRadius:
                              const BorderRadius.all(Radius.circular(10)),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      selectedIndex == 0 ? "New" : "Expired",
                                      style: GoogleFonts.poppins(
                                          color: Colors.red,
                                          fontWeight: FontWeight.w500,
                                          fontSize: kDefaultFontSize),
                                    ),
                                    const Icon(Icons.bookmark_border),
                                  ],
                                ),
                                Text(
                                  bloc.drugsData[index].jobTitle ?? "",
                                  style: GoogleFonts.poppins(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                ),
                                const SizedBox(height: 5),
                                Text(bloc.drugsData[index].companyName ?? 'N/A',
                                    style: secondaryTextStyle(
                                        color: svGetBodyColor())),
                                const SizedBox(height: 10),
                                Row(
                                  children: <Widget>[
                                    const Icon(
                                      Icons.location_on,
                                      size: 20,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(
                                      width: 5,
                                    ),
                                    Expanded(
                                      child: Text(
                                          bloc.drugsData[index].location ??
                                              'N/A',
                                          style: secondaryTextStyle(
                                              color: svGetBodyColor())),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Text('Apply Date',
                                    style: GoogleFonts.poppins(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w400,
                                        fontSize: 14)),
                                Row(
                                  children: [
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Date From',
                                            style: secondaryTextStyle(
                                                color: Colors.black)),
                                        Row(
                                          children: <Widget>[
                                            const Icon(
                                              Icons.date_range_outlined,
                                              size: 20,
                                              color: Colors.black,
                                            ),
                                            const SizedBox(
                                              width: 5,
                                            ),
                                            Text(
                                                DateFormat('MMM dd, yyyy')
                                                    .format(DateTime.parse(bloc
                                                            .drugsData[index]
                                                            .createdAt ??
                                                        'N/A'.toString())),
                                                style: secondaryTextStyle(
                                                    color: svGetBodyColor())),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      width: 20,
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Text('Date To',
                                            style: secondaryTextStyle(
                                              color: Colors.black,
                                            )),
                                        Row(
                                          children: <Widget>[
                                            const Icon(
                                              Icons.date_range_outlined,
                                              size: 20,
                                              color: Colors.black,
                                            ),
                                            const SizedBox(
                                              width: 5,
                                            ),
                                            Text(
                                                DateFormat('MMM dd, yyyy')
                                                    .format(DateTime.parse(bloc
                                                            .drugsData[index]
                                                            .lastDate ??
                                                        'N/A'.toString())),
                                                style: secondaryTextStyle(
                                                    color: svGetBodyColor())),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Text(
                                    'Experience: ${bloc.drugsData[index].experience ?? 'N/A'}',
                                    style: secondaryTextStyle(
                                      color: Colors.black,
                                    )),
                                const SizedBox(height: 5),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: HtmlWidget(
                                    '<p>${bloc.drugsData[index].description}</p>',
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      TextButton(
                                        onPressed: () async {
                                          // final Uri url = Uri.parse(bloc
                                          //     .drugsData[index]
                                          //     .link!); // Assuming job.link is a non-null String
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
                                                  onPressed: () {
                                                    Navigator.of(context)
                                                        .pop(true);
                                                    final Uri url = Uri.parse(
                                                        bloc.drugsData[index]
                                                            .link!);
                                                    _launchInBrowser(url);
                                                  },
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
                                            decoration:
                                                TextDecoration.underline,
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
                      );
                // return PostItem(bloc.drugsData[index].title, bloc.posts[index].body);
              },
            ),
    );
  }
}
