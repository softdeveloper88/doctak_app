import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/ads_setting/ads_widget/banner_ads_widget.dart';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/case_model/case_discuss_model.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_event.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/case_discussion/add_case_discuss_screen.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/splash_screen/bloc/splash_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
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
                      surfaceTintColor: svGetScaffoldColor(),
                      backgroundColor: svGetScaffoldColor(),
                      iconTheme: IconThemeData(color: context.iconColor),
                      title: Row(
                        // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                              child: Center(
                                  child: Text('Case Discussion',
                                      textAlign: TextAlign.center,
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
                                        state.isExpired ?? 'New'));
                                caseDiscusstionBloc.add(CaseDiscussionLoadPageEvent(
                                  page: 1,
                                  countryId: countryId.toString(),
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
                                ? Icon(Icons.cancel_outlined,
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
                      centerTitle: true,
                    ),
                    Divider(
                      color: Colors.grey[300],
                      endIndent: 16,
                      indent: 16,
                    ),
                    Column(
                      children: [
                        Column(
                          children: [
                            if (isSearchShow)
                              Container(
                                padding: const EdgeInsets.only(left: 8.0),
                                margin: const EdgeInsets.only(
                                  left: 16,
                                  top: 16.0,
                                  bottom: 16.0,
                                  right: 16,
                                ),
                                decoration: BoxDecoration(
                                    color:
                                        context.dividerColor.withOpacity(0.4),
                                    borderRadius: radius(5),
                                    border: Border.all(
                                        color: svGetBodyColor(), width: 0.3)),
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
                                            state.isExpired));
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
                                    hintText: 'Search by keyword',
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
                                                state.isExpired));
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
                        // Padding(
                        //   padding: const EdgeInsets.all(8.0),
                        //   child: Row(
                        //     mainAxisAlignment: MainAxisAlignment.spaceAround,
                        //     children: [
                        //       Column(
                        //         children: [
                        //           TextButton(
                        //             onPressed: () {
                        //               selectedIndex = 0;
                        //               BlocProvider.of<SplashBloc>(context).add(
                        //                   LoadDropdownData(
                        //                       state.countryFlag,
                        //                       "New",
                        //                       state.searchTerms ?? '',
                        //                       'New'));
                        //               caseDiscusstionBloc.add(CaseDiscussionLoadPageEvent(
                        //                   page: 1,
                        //                   countryId: state.countryFlag != ''
                        //                       ? state.countryFlag
                        //                       : '${state.countriesModel.countries?.first.id ?? 1}',
                        //                   searchTerm: state.searchTerms ?? '',
                        //                   isExpired: 'New'));
                        //             },
                        //             child: Text(
                        //               'New',
                        //               style: TextStyle(
                        //                 color: SVAppColorPrimary,
                        //                 fontSize: 14,
                        //                 fontWeight: selectedIndex == 0
                        //                     ? FontWeight.bold
                        //                     : FontWeight.normal,
                        //               ),
                        //             ),
                        //           ),
                        //           Container(
                        //             height: 2,
                        //             width: context.width() / 2 - 10,
                        //             color: selectedIndex == 0
                        //                 ? SVAppColorPrimary
                        //                 : SVAppColorPrimary.withOpacity(0.2),
                        //           ),
                        //         ],
                        //       ),
                        //       Center(
                        //           child: Container(
                        //             color: Colors.grey,
                        //             height: 30,
                        //             width: 1,
                        //           )),
                        //       Column(
                        //         children: [
                        //           TextButton(
                        //             onPressed: () {
                        //               selectedIndex = 1;
                        //               BlocProvider.of<SplashBloc>(context).add(
                        //                   LoadDropdownData(
                        //                       state.countryFlag,
                        //                       "Expired",
                        //                       state.searchTerms ?? '',
                        //                       'Expired'));
                        //               caseDiscusstionBloc.add(CaseDiscussionLoadPageEvent(
                        //                   page: 1,
                        //                   countryId: state.countryFlag != ''
                        //                       ? state.countryFlag
                        //                       : '${state.countriesModel.countries?.first.id ?? 1}',
                        //                   searchTerm: state.searchTerms ?? '');
                        //             },
                        //             child: Text(
                        //               'Expired',
                        //               style: TextStyle(
                        //                 color: SVAppColorPrimary,
                        //                 fontSize: 14,
                        //                 fontWeight: selectedIndex == 1
                        //                     ? FontWeight.bold
                        //                     : FontWeight.normal,
                        //               ),
                        //             ),
                        //           ),
                        //           Container(
                        //             height: 2,
                        //             width: context.width() / 2 - 10,
                        //             color: selectedIndex == 1
                        //                 ? SVAppColorPrimary
                        //                 : SVAppColorPrimary.withOpacity(0.2),
                        //           ),
                        //         ],
                        //       ),
                        //       16.height,
                        //     ],
                        //   ),
                        // ),
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
                        //       // caseDiscusstionBloc.add(
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
                        //       caseDiscusstionBloc.add(CaseDiscussionLoadPageEvent(
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
                      child: Center(
                          child: CircularProgressIndicator(
                    color: svGetBodyColor(),
                  )));
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
          ],
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
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
          ? const Center(
              child: Text("No Case Found"),
            )
          : ListView.builder(
              itemCount: bloc.caseDiscussList.length,
              itemBuilder: (context, index) {
                if (bloc.pageNumber <= bloc.numberOfPage) {
                  if (index ==
                      bloc.caseDiscussList.length - bloc.nextPageTrigger) {
                    bloc.add(
                        CaseDiscussionCheckIfNeedMoreDataEvent(index: index));
                  }
                }
                if (bloc.numberOfPage != bloc.pageNumber - 1 &&
                    index >= bloc.caseDiscussList.length - 1) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: svGetBodyColor(),
                    ),
                  );
                } else {
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
                    //                 //           style: GoogleFonts.poppins(
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
                    //                 //       style: GoogleFonts.poppins(
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
                    //                 //         style: GoogleFonts.poppins(
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
    return Card(
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
                      style: GoogleFonts.roboto(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      caseDiscussList.createdAt.toString(),
                      style: GoogleFonts.roboto(
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
              style: GoogleFonts.roboto(),
            ),
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
                  child: const Text('View Detail'),
                ),
                const Divider(
                  color: Colors.grey,
                  thickness: 1,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(onPressed: (){
                      caseDiscussionBloc.add(CaseDiscussEvent(caseId: caseDiscussList.id.toString(),type: 'case',actionType: 'likes'));

                    },icon:Icon(Icons.thumb_up_alt_outlined)),
                    SizedBox(width: 4),
                    Text('${caseDiscussList.likes} Likes'),
                    SizedBox(width: 16),
                    Icon(Icons.comment_outlined),
                    SizedBox(width: 4),
                    Text('${caseDiscussList.comments} Comments'),
                    SizedBox(width: 16),
                    Text('${caseDiscussList.views} Views'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
