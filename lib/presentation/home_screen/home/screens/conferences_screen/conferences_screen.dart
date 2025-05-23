import 'dart:async';

import 'package:doctak_app/ads_setting/ads_widget/native_ads_widget.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/app_comman_data.dart';
import 'package:doctak_app/core/utils/dynamic_link.dart';
import 'package:doctak_app/data/models/countries_model/countries_model.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/SVDashboardScreen.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/splash_screen/bloc/splash_bloc.dart';
import 'package:doctak_app/presentation/splash_screen/bloc/splash_event.dart';
import 'package:doctak_app/presentation/splash_screen/bloc/splash_state.dart';
import 'package:doctak_app/widgets/custom_dropdown_button_from_field.dart';
import 'package:doctak_app/widgets/retry_widget.dart';
import 'package:doctak_app/widgets/shimmer_widget/shimmer_card_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../../../data/models/conference_model/search_conference_model.dart';
import '../../../../../core/utils/post_utils.dart';
import 'bloc/conference_bloc.dart';
import 'bloc/conference_event.dart';
import 'bloc/conference_state.dart';

class ConferencesScreen extends StatefulWidget {
  ConferencesScreen({this.isFromSplash = false, super.key});

  bool isFromSplash;

  @override
  State<ConferencesScreen> createState() => _ConferencesScreenState();
}

class _ConferencesScreenState extends State<ConferencesScreen> {
  // ConferencesScreensScreen({Key? key}) : super(key: key);
  var selectedValue;
  ConferenceBloc conferenceBloc = ConferenceBloc();
  Timer? _debounce;
  bool isSearchShow = true;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    // var bloc = BlocProvider.of<ConferenceBloc>(context);
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
        appBar: AppBar(
          // toolbarHeight: 200,
          leading: GestureDetector(
              onTap: () {
                if (widget.isFromSplash) {
                  const SVDashboardScreen().launch(context, isNewTask: true);
                } else {
                  Navigator.of(context).pop();
                }
              },
              child: const Icon(Icons.arrow_back_ios)),

          backgroundColor: svGetScaffoldColor(),
          iconTheme: IconThemeData(color: context.iconColor),

          title: BlocConsumer<SplashBloc, SplashState>(
              bloc: SplashBloc()..add(
                LoadDropdownData1('', ''),
              ),
              listener: (e, state) {},
              builder: (context, state) {
                if (state is CountriesDataLoaded1) {
                  List<dynamic> list= state.countriesModelList;
                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(translation(context).lbl_conference, style: boldTextStyle(size: 18)),
                          Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: CustomDropdownButtonFormField(
                              itemBuilder: (item) => Text(
                                item??'',
                                style: const TextStyle(color: Colors.black),
                              ),
                              items: list,
                              value: list.first,
                              width: 100,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 0,
                              ),
                              onChanged: (newValue) {
                                conferenceBloc.add(
                                  LoadPageEvent(
                                    page: 1,
                                    countryName: newValue!,
                                    searchTerm: state.searchTerms!,
                                  ),
                                );
                                BlocProvider.of<SplashBloc>(context).add(
                                    LoadDropdownData1(
                                        newValue??'', state.searchTerms ?? ''));

                                // BlocProvider.of<ConferenceBloc>(context).add(LoadPageEvent(
                                //     page: 1,
                                //     countryId: state.countryFlag != ''
                                //         ? state.countryFlag
                                //         : '${state.countriesModel.countries?.first.id ??1}',
                                //     searchTerm: state.searchTerms ?? '',));
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
                                  ),
                          )
                        ],
                      ),
                      // Container(
                      //   margin: const EdgeInsets.only(
                      //       top: 16.0, bottom: 16.0),
                      //   decoration: BoxDecoration(
                      //       color: context.cardColor,
                      //       borderRadius: radius(8)),
                      //   child: AppTextField(
                      //     textFieldType: TextFieldType.NAME,
                      //     onChanged: (searchTxt) async {
                      //       await 2.seconds.delay;
                      //       BlocProvider.of<ConferenceBloc>(context).add(
                      //         LoadPageEvent(
                      //           page: 1,
                      //           countryName: state.countryName,
                      //           searchTerm: searchTxt,
                      //         ),
                      //       );
                      //       BlocProvider.of<SplashBloc>(context)
                      //           .add(LoadDropdownData1(
                      //         state.countryName ?? '',
                      //         searchTxt,
                      //       ));
                      //     },
                      //     decoration: InputDecoration(
                      //       border: InputBorder.none,
                      //       hintText: 'Search Here',
                      //       hintStyle:
                      //       secondaryTextStyle(color: svGetBodyColor()),
                      //       prefixIcon: Image.asset(
                      //           'images/socialv/icons/ic_Search.png',
                      //           height: 16,
                      //           width: 16,
                      //           fit: BoxFit.cover,
                      //           color: svGetBodyColor())
                      //           .paddingAll(16),
                      //     ),
                      //   ),
                      // ),
                    ],
                  );
                } else if (state is CountriesDataError) {
                  return Center(child: Text('${translation(context).lbl_error}: $state'));
                } else {
                  return const Center(child: Text(''));
                }
              }),
          elevation: 0,
          centerTitle: false,
          // actions:  [
          //   // IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
          // ],
        ),
        body: Column(
          children: [
            BlocConsumer<SplashBloc, SplashState>(
                listener: (e, state) {},
                // bloc: conferenceBloc,
                builder: (context, state) {
                  if (state is CountriesDataLoaded1) {
                    // List<String>? list = state.countriesModelList.cast<String>();
                    return Row(
                      children: [
                        if (isSearchShow)
                          Expanded(
                            child: Container(
                              color: svGetScaffoldColor(),
                              padding: const EdgeInsets.all(10.0),
                              child: Container(
                                padding: const EdgeInsets.only(left: 8.0),
                                decoration: BoxDecoration(
                                    color:
                                        context.dividerColor.withOpacity(0.4),
                                    borderRadius: radius(5),
                                    border: Border.all(
                                        color: Colors.black, width: 0.5)),
                                child: AppTextField(
                                  textFieldType: TextFieldType.NAME,
                                  onChanged: (searchTxt) async {
                                    if (_debounce?.isActive ?? false)
                                      _debounce?.cancel();
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
                                    });
                                  },
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: translation(context).lbl_search_conferences,
                                    hintStyle: secondaryTextStyle(
                                        color: svGetBodyColor()),
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
                            ),
                          ),
                      ],
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
                        });
                  } else {

                    return const Center();
                  }
                }),
            BlocConsumer<ConferenceBloc, ConferenceState>(
              bloc: conferenceBloc,
              // listenWhen: (previous, current) => current is ConferenceState,
              // buildWhen: (previous, current) => current is! ConferenceState,
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
                  return  Expanded(
                      child: ShimmerCardList());
                } else if (state is PaginationLoadedState) {
                  // print(state.drugsModel.length);
                  return _buildPostList(context);
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
                      });
                } else {
                  return const Expanded(child: Center(child: Text('')));
                }
              },
            ),
            // if (AppData.isShowGoogleBannerAds ?? false) BannerAdWidget()
          ],
        ));
  }

  Widget _buildPostList(BuildContext context) {
    final bloc = conferenceBloc;
    print("bloc$bloc");
    print("len${bloc.conferenceList.length}");
    return Expanded(
      child: bloc.conferenceList.isEmpty
          ? Center(
              child: Text(translation(context).msg_no_conference_found),
            )
          : ListView.builder(
              itemCount: bloc.conferenceList.length,
              itemBuilder: (context, index) {
                if (index ==
                    bloc.conferenceList.length - bloc.nextPageTrigger) {
                  bloc.add(CheckIfNeedMoreDataEvent(index: index));
                }
                if (bloc.numberOfPage != bloc.pageNumber - 1 &&
                    index >= bloc.conferenceList.length - 1) {
                  return SizedBox(
                      height: 400,
                      child: ShimmerCardList());

                } else if ((index % 5 == 0 && index != 0) &&
                    AppData.isShowGoogleNativeAds) {
                  return NativeAdWidget();
                } else {
                  return ConferenceWidget(
                    conference: bloc.conferenceList[index],
                  );
                }
                //     : Container(
                //   margin: const EdgeInsets.symmetric(vertical: 5),
                //   padding: const EdgeInsets.all(8),
                //   decoration: BoxDecoration(
                //     color: context.cardColor,
                //     borderRadius: BorderRadius.circular(5),
                //   ),
                //   child: Column(
                //     crossAxisAlignment: CrossAxisAlignment.start,
                //     children: [
                //       Text(
                //         index.toString(),
                //         style: secondaryTextStyle(
                //             color: svGetBodyColor(), size: 18),
                //       ),
                //       Text(
                //         bloc.conferenceList[index].country ?? "",
                //         style: secondaryTextStyle(
                //             color: svGetBodyColor(), size: 18),
                //       ),
                //       const SizedBox(height: 5),
                //       Text(bloc.conferenceList[index].state ?? 'N/A',
                //           style: secondaryTextStyle(color: svGetBodyColor())),
                //       const SizedBox(height: 5),
                //       Text(bloc.conferenceList[index].description ?? 'N/A',
                //           style: secondaryTextStyle(color: svGetBodyColor())),
                //       const SizedBox(height: 10),
                //       Text(bloc.conferenceList[index].city ?? 'N/A',
                //           style: secondaryTextStyle(color: svGetBodyColor())),
                //       const SizedBox(height: 5),
                //       Text(
                //           "${bloc.conferenceList[index].title ?? '0'} ${AppData.currency}",
                //           style: secondaryTextStyle(color: svGetBodyColor())),
                //     ],
                //   ),
                // );
                // return PostItem(bloc.conferenceList[index].title, bloc.posts[index].body);
              },
            ),
    );
  }
}

class ConferenceWidget extends StatelessWidget {
  final Data conference;

  const ConferenceWidget({Key? key, required this.conference})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Material(
        elevation: 0,
        color: context.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildConferenceImageOrPlaceholder(),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: const Icon(Icons.apartment_sharp,color: Colors.grey,),
                    ),
                    const SizedBox(width: 10,),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            conference.title ?? 'No Title Available',
                            style: const TextStyle(
                              // fontFamily: 'Robotic',
                              fontWeight: FontWeight.bold,
                              fontSize: 18.0,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '${conference.startDate ?? ''} - ${conference.endDate ?? ''}',
                              style: const TextStyle(fontSize: 14,color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: InkWell(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () {
                          // _showBottomSheet(context,widget
                          //     .homeBloc
                          //     .postList[index]);
                          createDynamicLink(
                              '${conference.title ?? ""} \n  Register Link: ${conference.conferenceAgendaLink ?? ''}',
                              'https://doctak.net/conference/${conference.id}',
                              conference.thumbnail ?? '');
                          // Share.share("Job Title: ${bloc.drugsData[index].jobTitle ?? ""}\n"
                          //     "Company : ${bloc.drugsData[index].companyName}\n"
                          //     "Location: ${bloc.drugsData[index].location ?? 'N/A'}\n"
                          //     "Date From: ${ bloc.drugsData[index]
                          //     .createdAt ??
                          //     'N/A'}\n"
                          //     "Date To: ${ bloc.drugsData[index]
                          //     .lastDate ??
                          //     'N/A'}\n"
                          //     "Experience: ${ bloc.drugsData[index]
                          //     .experience ??
                          //     'N/A'}\n"
                          //     "Job Apply Link: ${ bloc.drugsData[index]
                          //     .link ??
                          //     'N/A'}\n" );
                        },
                        child: Icon(
                          Icons.share_sharp,
                          size: 22,
                          // 'images/socialv/icons/ic_share.png',
                          // height: 22,
                          // width: 22,
                          // fit: BoxFit.cover,
                          color: context.iconColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Conference Dates


              const SizedBox(height: 4),

              // Action button (Register Now)

              const SizedBox(height: 8),

              // Conference Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(conference.description ?? translation(context).msg_no_description),
              ),

              const SizedBox(height: 8),
              //
              // Padding(
              //   padding: const EdgeInsets.symmetric(horizontal: 8),
              //   child: Text('City: ${conference.city ?? 'N/A'}\n'
              //       'Venue: ${conference.venue ?? 'N/A'}\n'
              //       'Organizer: ${conference.organizer ?? 'N/A'}\n'
              //       'Country: ${conference.country ?? 'N/A'}\n'
              //       'CME Credits: ${conference.cmeCredits ?? 'N/A'}\n'
              //       'MOC Credits: ${conference.mocCredits ?? 'N/A'}\n'
              //       // 'Specialties Targeted: ${conference.specialties_targeted ?? 'N/A'}',
              //       ),
              // ),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100, // Light background color
                  borderRadius: BorderRadius.circular(12.0), // Rounded corners
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_city, color: Colors.blue),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            '${translation(context).lbl_city}: ${conference.city ?? translation(context).lbl_not_available}',
                            style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.fade, // Truncate text if needed
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on, color: Colors.green),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            '${translation(context).lbl_venue}: ${conference.venue ?? translation(context).lbl_not_available}',
                            style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.fade,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.person, color: Colors.orange),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            '${translation(context).lbl_organizer}: ${conference.organizer ?? translation(context).lbl_not_available}',
                            style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.fade,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.flag, color: Colors.red),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            '${translation(context).lbl_country}: ${conference.country ?? translation(context).lbl_not_available}',
                            style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.fade,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.school, color: Colors.purple),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            '${translation(context).lbl_cme_credits}: ${conference.cmeCredits ?? translation(context).lbl_not_available}',
                            style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.fade,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.star, color: Colors.teal),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            '${translation(context).lbl_moc_credits}: ${conference.mocCredits ?? translation(context).lbl_not_available}',
                            style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.fade,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.medical_services, color: Colors.pink),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            '${translation(context).lbl_specialties_targeted}: ${conference.specialtiesTargeted ?? translation(context).lbl_not_available}',
                            style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.fade,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: svAppButton(
                  width: 30.w,
                  // color: svGetBodyColor(),
                  onTap: () {
                    Uri registrationUri = Uri.parse(conference.registrationLink!);
                    PostUtils.launchURL(context, registrationUri.toString());
                  },
                  text: translation(context).lbl_register_now, context: context,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConferenceImageOrPlaceholder() {
    if (conference.thumbnail != null && conference.thumbnail!.isNotEmpty) {
      return Container(
        margin: const EdgeInsets.all(8.0), // Add margin to the container
        child: Image.network(
          conference.thumbnail!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 300,
          errorBuilder: (context, error, stackTrace) {
            return Center(child: Text(translation(context).msg_image_not_available));
          },
        ),
      );
    } else {
      return Container(
        margin: const EdgeInsets.all(8.0), // Add margin to the container
        // child: DecoratedBox(
        //   decoration: BoxDecoration(
        //     color: Colors.lightBlueAccent,
        //     borderRadius: BorderRadius.circular(10.0),
        //   ),
        //   child: const SizedBox(
        //     width: double.infinity,
        //     height: 300,
        //     child: Padding(
        //       padding: EdgeInsets.all(16.0),
        //       child: Center(
        //         child: Text(
        //           'No Image Available',
        //           textAlign: TextAlign.center,
        //           style: TextStyle(
        //             fontSize: 18.0,
        //             color: Colors.white,
        //             fontWeight: FontWeight.bold,
        //           ),
        //         ),
        //       ),
        //     ),
        //   ),
        // ),
      );
    }
  }


}
