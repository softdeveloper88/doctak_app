import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/ads_setting/ads_widget/banner_ads_widget.dart';
import 'package:doctak_app/ads_setting/ads_widget/native_ads_widget.dart';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/case_model/case_discuss_model.dart';
import 'package:doctak_app/data/models/countries_model/countries_model.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_event.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/case_discussion/add_case_discuss_screen.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/splash_screen/bloc/splash_bloc.dart';
import 'package:doctak_app/widgets/shimmer_widget/shimmer_card_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../widgets/custom_dropdown_field.dart';
import '../../../../splash_screen/bloc/splash_event.dart';
import '../../../../splash_screen/bloc/splash_state.dart';
import 'bloc/case_discussion_bloc.dart';
import 'bloc/case_discussion_event.dart';
import 'bloc/case_discussion_state.dart';
import 'case_discuss_details_screen.dart';

class CaseDiscussionScreen extends StatefulWidget {
  const CaseDiscussionScreen({Key? key}) : super(key: key);

  @override
  State<CaseDiscussionScreen> createState() => _CaseDiscussionScreenState();
}

class _CaseDiscussionScreenState extends State<CaseDiscussionScreen> {
  // ProfileBloc profileBloc = ProfileBloc();
  CaseDiscussionBloc caseDiscusstionBloc = CaseDiscussionBloc();
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
    caseDiscusstionBloc.add(
      CaseDiscussionLoadPageEvent(page: 1, countryId: '', searchTerm: ''),
    );
    super.initState();
  }


  var selectedValue;
  bool isShownSuggestion = false;
  bool isSearchShow = true;
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
                        child: CircularProgressIndicator(
                      color: context.iconColor,
                    )),
                  ],
                );
              } else if (state is CountriesDataLoaded) {

                for (var element in state.countriesModel.countries!) {
                  if (element.countryName == state.countryFlag) {
                    selectedValue =
                        state.countriesModel.countries?.first.countryName ??
                            element.countryName;
                  }
                }
                return Container(
                  color: svGetScaffoldColor(),
                  child: Column(
                    children: [
                      AppBar(
                        surfaceTintColor: svGetScaffoldColor(),
                        backgroundColor: svGetScaffoldColor(),
                        iconTheme: IconThemeData(color: context.iconColor),
                        title: Row(
                          // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                                child: Text(translation(context).lbl_case_discussion,
                                    textAlign: TextAlign.center,
                                    style: boldTextStyle(size: 18))),
                            Expanded(
                              child: CustomDropdownField(
                                selectedItemBuilder: (context) {
                                  return [
                                    for (Countries item in state.countriesModel.countries ?? [])
                                      Text(
                                        item.flag ?? '', // The flag or emoji
                                        style: const TextStyle(fontSize: 18), // Adjust font size for the flag
                                      ),
                                  ];
                                },
                                itemBuilder: (item) => Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      item.countryName??'',
                                      style: const TextStyle(color: Colors.black),
                                    ),
                                    Text(item.flag??'')
                                  ],
                                ),
                                height: 50,
                                items: state.countriesModel.countries ?? [],
                                value: state.countriesModel.countries?.first,
                                width: 50,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 0,
                                ),
                                onChanged: (newValue) {
                                  // var index = state.countriesModel.countries!
                                  //     .indexWhere((element) =>
                                  //         newValue == element.countryName);
                                  // var countryId =
                                  //     state.countriesModel.countries![index].id;
                                  BlocProvider.of<SplashBloc>(context).add(
                                      LoadDropdownData(
                                          newValue.id.toString(),
                                          state.typeValue,
                                          state.searchTerms ?? '',
                                           'New'));
                                  caseDiscusstionBloc.add(CaseDiscussionLoadPageEvent(
                                    page: 1,
                                    countryId: newValue.id.toString(),
                                    searchTerm: state.searchTerms ?? "",
                                  ));

                                  // caseDiscusstionBloc
                                  //     .add(UpdateFirstDropdownValue(newValue!));
                                },
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                setState(() {});
                                isSearchShow = !isSearchShow;
                              },
                              child: isSearchShow
                                  ? Icon(Icons.close,
                                          size: 25,
                                          // height: 16,
                                          // width: 16,
                                          // fit: BoxFit.cover,
                                          color: svGetBodyColor())
                                      .paddingLeft(4)
                                  : Image.asset(
                                      'assets/images/search.png',
                                      height: 20,
                                      width: 20,
                                      color: svGetBodyColor(),
                                    ),
                            ).paddingRight(16)
                          ],
                        ),
                        leading: IconButton(
                          icon: Icon(Icons.arrow_back_ios_new_rounded,
                              color: svGetBodyColor()),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        elevation: 0,
                        centerTitle: false,
                      ),
                      Column(
                        children: [
                          if (isSearchShow)
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Container(
                                padding: const EdgeInsets.only(left: 8.0),
                                decoration: BoxDecoration(
                                    color: context.dividerColor.withOpacity(0.4),
                                    borderRadius: radius(5),
                                    border: Border.all(
                                        color: svGetBodyColor(), width: 0.5)),
                                child: AppTextField(
                                  controller: _controller,
                                  textFieldType: TextFieldType.NAME,
                                  onChanged: (searchTxt) async {
                                    if (_debounce?.isActive ?? false)
                                      _debounce?.cancel();
                                    _debounce = Timer(const Duration(milliseconds: 500), () {
                                    isShownSuggestion = true;
                                    // caseDiscusstionBloc.add(
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
                                            ''));
                                    caseDiscusstionBloc.add(CaseDiscussionLoadPageEvent(
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
                                    hintText: translation(context).hint_search_by_keyword,
                                    hintStyle: secondaryTextStyle(
                                        color: svGetBodyColor()),
                                    suffixIcon: GestureDetector(
                                      onTap: () {
                                        isShownSuggestion = true;
                                        BlocProvider.of<SplashBloc>(context)
                                            .add(LoadDropdownData(
                                                state.countryFlag,
                                                state.typeValue,
                                                _controller.text ?? '',
                                               ''));
                                        caseDiscusstionBloc
                                            .add(CaseDiscussionLoadPageEvent(
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
                            ),
                          // if (isShownSuggestion)
                          //   ListView.builder(
                          //     shrinkWrap: true,
                          //     itemCount: _filteredSuggestions.length,
                          //     itemBuilder: (context, index) {
                          //       return Container(
                          //         color: Colors.white,
                          //         child: ListTile(
                          //           title: Text(_filteredSuggestions[index]),
                          //           onTap: () {
                          //             setState(() {});
                          //             isShownSuggestion = false;
                          //             _controller.text =
                          //             _filteredSuggestions[index];
                          //             BlocProvider.of<SplashBloc>(context)
                          //                 .add(LoadDropdownData(
                          //                 state.countryFlag,
                          //                 state.typeValue,
                          //                 _filteredSuggestions[index] ??
                          //                     '',
                          //                 state.isExpired));
                          //             caseDiscusstionBloc.add(CaseDiscussionLoadPageEvent(
                          //               page: 1,
                          //               countryId: state.countryFlag != ''
                          //                   ? state.countryFlag
                          //                   : '${state.countriesModel.countries?.first.id ?? 1}',
                          //               searchTerm:
                          //               _filteredSuggestions[index],
                          //             ));
                          //             // Do something with the selected suggestion
                          //           },
                          //         ),
                          //       );
                          //     },
                          //   ),
                        ],
                      ),
                    ],
                  ),
                );
              } else if (state is CountriesDataError) {
                BlocProvider.of<SplashBloc>(context).add(
                  LoadDropdownData('', '', '', ''),
                );

                return Center(child: Text(translation(context).msg_error_occurred(state.errorMessage)));
              } else {
                BlocProvider.of<SplashBloc>(context).add(
                  LoadDropdownData('', '', '', ''),
                );

                return Center(child: Text(translation(context).msg_unknown_state));
              }
            }),
            BlocConsumer<CaseDiscussionBloc, CaseDiscussionState>(
              bloc: caseDiscusstionBloc,
              // listenWhen: (previous, current) => current is PaginationLoadedState,
              // buildWhen: (previous, current) => current is! PaginationLoadedState,
              listener: (BuildContext context, CaseDiscussionState state) {
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
                  return Expanded(
                      child: ShimmerCardList(),);
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
                  return Expanded(
                      child: Center(child: Text(translation(context).msg_something_went_wrong)));
                }
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () {
            AddCaseDiscussScreen().launch(context);
          },
        ),
      ),
    );
  }

  Widget _buildPostList(BuildContext context) {
    final bloc = caseDiscusstionBloc;
    return Expanded(
      child: bloc.caseDiscussList.isEmpty
          ? Center(
              child: Text(translation(context).msg_no_case_found),
            )
          : ListView.builder(
        padding: const EdgeInsets.all(10),
              itemCount: bloc.caseDiscussList.length,
              itemBuilder: (context, index) {
                if (bloc.pageNumber <= bloc.numberOfPage) {
                  if (index ==
                      bloc.caseDiscussList.length - bloc.nextPageTrigger) {
                    bloc.add(CaseDiscussionCheckIfNeedMoreDataEvent(index: index));
                  }
                }
                if (bloc.numberOfPage != bloc.pageNumber - 1 &&
                    index >= bloc.caseDiscussList.length - 1) {
                  return SizedBox(
                      height: 400,
                      child: ShimmerCardList());
                }  else if ((index % 5 == 0 && index != 0) &&
                    AppData.isShowGoogleNativeAds) {
                  return NativeAdWidget();
                }
                else {
                  return InkWell(
                    onTap: () {
                      // JobsDetailsScreen(
                      //     jobId: '${bloc.caseDiscussList[index].id ?? ''}')
                      //     .launch(context);
                    },
                    child: PostCard(bloc.caseDiscussList[index], bloc),
                    // child: Column(
                    //                 //   crossAxisAlignment: CrossAxisAlignment.start,
                    //                 //   children: [
                    //                 //     Row(
                    //                 //       mainAxisAlignment:
                    //                 //       MainAxisAlignment.spaceBetween,
                    //                 //       children: [
                    //                 //         Text(
                    //                 //           selectedIndex == 0 ? "New" : "Expired",
                    //                 //           style: TextStyle(
                    //                 //               color: Colors.red,
                    //                 //               fontWeight: FontWeight.w500,
                    //                 //               fontSize: kDefaultFontSize),
                    //                 //         ),
                    //                 //         InkWell(
                    //                 //           splashColor: Colors.transparent,
                    //                 //           highlightColor: Colors.transparent,
                    //                 //           onTap: () {
                    //                 //             // _showBottomSheet(context,widget
                    //                 //             //     .homeBloc
                    //                 //             //     .postList[index]);
                    //                 //             createDynamicLink(
                    //                 //                 '${bloc.caseDiscussList[index].jobTitle ?? ""} \n  Apply Link: ${bloc.caseDiscussList[index].link ?? ''}',
                    //                 //                 'https://doctak.net/job/${bloc.caseDiscussList[index].id}',
                    //                 //                 bloc.caseDiscussList[index].link ?? '');
                    //                 //             // Share.share("Job Title: ${bloc.caseDiscussList[index].jobTitle ?? ""}\n"
                    //                 //             //     "Company : ${bloc.caseDiscussList[index].companyName}\n"
                    //                 //             //     "Location: ${bloc.caseDiscussList[index].location ?? 'N/A'}\n"
                    //                 //             //     "Date From: ${ bloc.caseDiscussList[index]
                    //                 //             //     .createdAt ??
                    //                 //             //     'N/A'}\n"
                    //                 //             //     "Date To: ${ bloc.caseDiscussList[index]
                    //                 //             //     .lastDate ??
                    //                 //             //     'N/A'}\n"
                    //                 //             //     "Experience: ${ bloc.caseDiscussList[index]
                    //                 //             //     .experience ??
                    //                 //             //     'N/A'}\n"
                    //                 //             //     "Job Apply Link: ${ bloc.caseDiscussList[index]
                    //                 //             //     .link ??
                    //                 //             //     'N/A'}\n" );
                    //                 //           },
                    //                 //           child: Icon(
                    //                 //             Icons.share_sharp,
                    //                 //             size: 22,
                    //                 //             // 'images/socialv/icons/ic_share.png',
                    //                 //             // height: 22,
                    //                 //             // width: 22,
                    //                 //             // fit: BoxFit.cover,
                    //                 //             color: context.iconColor,
                    //                 //           ),
                    //                 //         ),
                    //                 //       ],
                    //                 //     ),
                    //                 //     Text(
                    //                 //       bloc.caseDiscussList[index].jobTitle ?? "",
                    //                 //       style: TextStyle(fontFamily: 'Poppins',
                    //                 //           color: svGetBodyColor(),
                    //                 //           fontWeight: FontWeight.bold,
                    //                 //           fontSize: 18),
                    //                 //     ),
                    //                 //     const SizedBox(height: 5),
                    //                 //     Text(bloc.caseDiscussList[index].companyName ?? 'N/A',
                    //                 //         style: secondaryTextStyle(
                    //                 //             color: svGetBodyColor())),
                    //                 //     const SizedBox(height: 10),
                    //                 //     Row(
                    //                 //       children: <Widget>[
                    //                 //         const Icon(
                    //                 //           Icons.location_on,
                    //                 //           size: 20,
                    //                 //           color: Colors.grey,
                    //                 //         ),
                    //                 //         const SizedBox(
                    //                 //           width: 5,
                    //                 //         ),
                    //                 //         Expanded(
                    //                 //           child: Text(
                    //                 //               bloc.caseDiscussList[index].location ?? 'N/A',
                    //                 //               style: secondaryTextStyle(
                    //                 //                   color: svGetBodyColor())),
                    //                 //         ),
                    //                 //       ],
                    //                 //     ),
                    //                 //     const SizedBox(height: 20),
                    //                 //     Text('Apply Date',
                    //                 //         style:  TextStyle(fontFamily: 'Poppins',
                    //                 //             color: svGetBodyColor(),
                    //                 //             fontWeight: FontWeight.w400,
                    //                 //             fontSize: 14)),
                    //                 //     Row(
                    //                 //       children: [
                    //                 //         Column(
                    //                 //           mainAxisAlignment: MainAxisAlignment.start,
                    //                 //           crossAxisAlignment:
                    //                 //           CrossAxisAlignment.start,
                    //                 //           children: [
                    //                 //             Text('Date From',
                    //                 //                 style: secondaryTextStyle(
                    //                 //                     color: svGetBodyColor())),
                    //                 //             Row(
                    //                 //               children: <Widget>[
                    //                 //                 Icon(
                    //                 //                   Icons.date_range_outlined,
                    //                 //                   size: 20,
                    //                 //                   color: svGetBodyColor(),
                    //                 //                 ),
                    //                 //                 const SizedBox(
                    //                 //                   width: 5,
                    //                 //                 ),
                    //                 //                 Text(
                    //                 //                     DateFormat('MMM dd, yyyy').format(
                    //                 //                         DateTime.parse(bloc
                    //                 //                             .caseDiscussList[index]
                    //                 //                             .createdAt ??
                    //                 //                             'N/A'.toString())),
                    //                 //                     style: secondaryTextStyle(
                    //                 //                         color: svGetBodyColor())),
                    //                 //               ],
                    //                 //             ),
                    //                 //           ],
                    //                 //         ),
                    //                 //         const SizedBox(
                    //                 //           width: 20,
                    //                 //         ),
                    //                 //         Column(
                    //                 //           crossAxisAlignment:
                    //                 //           CrossAxisAlignment.start,
                    //                 //           mainAxisAlignment: MainAxisAlignment.start,
                    //                 //           children: [
                    //                 //             Text('Date To',
                    //                 //                 style: secondaryTextStyle(
                    //                 //                   color: svGetBodyColor(),
                    //                 //                 )),
                    //                 //             Row(
                    //                 //               children: <Widget>[
                    //                 //                 Icon(
                    //                 //                   Icons.date_range_outlined,
                    //                 //                   size: 20,
                    //                 //                   color: svGetBodyColor(),
                    //                 //                 ),
                    //                 //                 const SizedBox(
                    //                 //                   width: 5,
                    //                 //                 ),
                    //                 //                 Text(
                    //                 //                     DateFormat('MMM dd, yyyy').format(
                    //                 //                         DateTime.parse(bloc
                    //                 //                             .caseDiscussList[index]
                    //                 //                             .lastDate ??
                    //                 //                             'N/A'.toString())),
                    //                 //                     style: secondaryTextStyle(
                    //                 //                         color: svGetBodyColor())),
                    //                 //               ],
                    //                 //             ),
                    //                 //           ],
                    //                 //         ),
                    //                 //       ],
                    //                 //     ),
                    //                 //     Text(
                    //                 //         'Experience: ${bloc.caseDiscussList[index].experience ?? 'N/A'}',
                    //                 //         style: secondaryTextStyle(
                    //                 //           color: svGetBodyColor(),
                    //                 //         )),
                    //                 //     const SizedBox(height: 5),
                    //                 //     SingleChildScrollView(
                    //                 //       clipBehavior: Clip.hardEdge,
                    //                 //       scrollDirection: Axis.horizontal,
                    //                 //       child: Container(
                    //                 //         color: Colors.white,
                    //                 //         child: HtmlWidget(
                    //                 //           '<p>${bloc.caseDiscussList[index].description}</p>',
                    //                 //         ),
                    //                 //       ),
                    //                 //     ),
                    //                 //     const SizedBox(height: 5),
                    //                 //     Padding(
                    //                 //       padding: const EdgeInsets.only(top: 16),
                    //                 //       child: Column(
                    //                 //         crossAxisAlignment: CrossAxisAlignment.start,
                    //                 //         children: [
                    //                 //           TextButton(
                    //                 //             onPressed: () async {
                    //                 //               // final Uri url = Uri.parse(bloc
                    //                 //               //     .caseDiscussList[index]
                    //                 //               //     .link!); // Assuming job.link is a non-null String
                    //                 //               // Show dialog asking the user to confirm navigation
                    //                 //               final shouldLeave =
                    //                 //               await showDialog<bool>(
                    //                 //                 context: context,
                    //                 //                 builder: (context) => AlertDialog(
                    //                 //                   title: const Text('Leave App'),
                    //                 //                   content: const Text(
                    //                 //                       'Would you like to leave the app to view this content?'),
                    //                 //                   actions: <Widget>[
                    //                 //                     TextButton(
                    //                 //                       onPressed: () =>
                    //                 //                           Navigator.of(context)
                    //                 //                               .pop(false),
                    //                 //                       child: const Text('No'),
                    //                 //                     ),
                    //                 //                     TextButton(
                    //                 //                       onPressed: () {
                    //                 //                         Navigator.of(context)
                    //                 //                             .pop(true);
                    //                 //                         final Uri url = Uri.parse(bloc
                    //                 //                             .caseDiscussList[index].link!);
                    //                 //                         _launchInBrowser(url);
                    //                 //                       },
                    //                 //                       child: const Text('Yes'),
                    //                 //                     ),
                    //                 //                   ],
                    //                 //                 ),
                    //                 //               );
                    //                 //               // If the user confirmed, launch the URL
                    //                 //               if (shouldLeave == true) {
                    //                 //                 // await launchUrl(url);
                    //                 //               } else if (shouldLeave == false) {
                    //                 //                 ScaffoldMessenger.of(context)
                    //                 //                     .showSnackBar(
                    //                 //                   const SnackBar(
                    //                 //                       content: Text(
                    //                 //                           'Leaving the app canceled.')),
                    //                 //                 );
                    //                 //               } else {
                    //                 //                 ScaffoldMessenger.of(context)
                    //                 //                     .showSnackBar(
                    //                 //                   const SnackBar(
                    //                 //                       content: Text(
                    //                 //                           'Leaving the app canceled.')),
                    //                 //                 );
                    //                 //               }
                    //                 //             },
                    //                 //             child: const Text(
                    //                 //               'Apply ',
                    //                 //               style: TextStyle(
                    //                 //                 color: Colors.blue,
                    //                 //                 decoration: TextDecoration.underline,
                    //                 //               ),
                    //                 //             ),
                    //                 //           ),
                    //                 //         ],
                    //                 //       ),
                    //                 //     ),
                    //                 //   ],
                    //                 // ),
                    //
                  );
                }
                // return PostItem(bloc.caseDiscussList[index].title, bloc.posts[index].body);
              },
            ),
    );
  }
}

class PostCard extends StatelessWidget {
  PostCard(this.caseDiscussList, this.caseDiscussionBloc, {super.key});

  Data caseDiscussList;
  CaseDiscussionBloc caseDiscussionBloc;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: (){
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CaseDiscussDetailsScreen(caseDiscussList, caseDiscussionBloc),
          ),
        );
      },
      child: Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    child: CachedNetworkImage(
                      imageUrl:
                          "${AppData.imageUrl}${caseDiscussList.profilePic!.validate()}",
                      height: 50,
                      width: 50,
                      fit: BoxFit.cover,
                    ).cornerRadiusWithClipRRect(20),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${caseDiscussList.name}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        caseDiscussList.createdAt.toString(),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '${caseDiscussList.title}',
                style: const TextStyle(
    fontFamily: 'Poppins',
              )),
              const SizedBox(height: 16),
              Column(
                // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CaseDiscussDetailsScreen(caseDiscussList, caseDiscussionBloc),
                        ),
                      );
                      // AddCaseDiscussScreen().launch(context);
                    },
                    child: Text(translation(context).lbl_view_details),
                  ),
                  const Divider(
                    color: Colors.grey,
                    thickness: 1,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(onPressed: (){
                        caseDiscussionBloc.add(CaseDiscussEvent(caseId: caseDiscussList.caseId.toString(),type: 'case',actionType: 'like'));

                      },icon:const Icon(Icons.thumb_up_alt_outlined)),
                      const SizedBox(width: 4),
                      Text(translation(context).lbl_likes_count(caseDiscussList.likes ?? 0)),
                      const SizedBox(width: 16),
                      const Icon(Icons.comment_outlined),
                      const SizedBox(width: 4),
                      Text(translation(context).lbl_comments_count(caseDiscussList.comments ?? 0)),
                      const SizedBox(width: 16),
                      Text(translation(context).lbl_views_count(caseDiscussList.views ?? 0)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
