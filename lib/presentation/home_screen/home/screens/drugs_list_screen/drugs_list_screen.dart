import 'dart:async';

import 'package:doctak_app/ads_setting/ads_widget/native_ads_widget.dart';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/countries_model/countries_model.dart';
import 'package:doctak_app/presentation/chat_gpt_screen/ChatDetailScreen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/drugs_list_screen/bloc/drugs_bloc.dart';
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

import '../../../../../widgets/shimmer_widget/shimmer_card_list.dart';
import 'bloc/drugs_event.dart';
import 'bloc/drugs_state.dart';

class DrugsListScreen extends StatefulWidget {
  const DrugsListScreen({Key? key}) : super(key: key);

  @override
  State<DrugsListScreen> createState() => _DrugsListScreenState();
}

class _DrugsListScreenState extends State<DrugsListScreen> {
  Timer? _debounce;

  late final ScrollController _scrollController;
  DrugsBloc drugsBloc = DrugsBloc();
  bool isSearchShow = true;
  @override
  void initState() {
    drugsBloc.add(
      LoadPageEvent(page: 1, countryId: '1', searchTerm: '', type: 'Brand'),
    );
    super.initState();
    // _scrollController = ScrollController()..addListener(_onScroll);
  }

  var selectedValue;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: svGetBgColor(),
      body: Column(
        children: [
          BlocBuilder<SplashBloc, SplashState>(builder: (context, state) {
            if (state is CountriesDataInitial) {
              return const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Center(
                      child: Text('Loading...',
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
                    title: Row(
                      children: [
                        Expanded(
                            child: Center(
                                child: Text('Drugs List',
                                    style: boldTextStyle(size: 20)))),
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
                            isTextBold: true,
                            items: state.countriesModel.countries ?? [],
                            value: state
                                .countriesModel.countries!.first,
                            width: 50,
                            height:50,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 0,
                            ),
                            onChanged: ( newValue) {
                              print("ddd ${state.countryFlag}");
                              // var index = state.countriesModel.countries!
                              //     .indexWhere((element) =>
                              //         newValue == element.countryName);
                              // var countryId =
                              //     state.countriesModel.countries![index].id;
                              // BlocProvider.of<DrugsBloc>(context).add(
                              //   GetPost(
                              //       page: '1',
                              //       countryId: countryId.toString(),
                              //       searchTerm: '',
                              //       type: state.typeValue),
                              // );
                              // countryId = countryIds.toString();
                              BlocProvider.of<SplashBloc>(context).add(
                                  LoadDropdownData(
                                      newValue.id.toString(),
                                      state.typeValue,
                                      state.searchTerms ?? '',
                                      ''));
                              drugsBloc.add(LoadPageEvent(
                                  page: 1,
                                  countryId: newValue.id.toString(),
                                  searchTerm: state.searchTerms ?? "",
                                  type: state.typeValue));

                              // BlocProvider.of<DrugsBloc>(context)
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
                    elevation: 0,
                    surfaceTintColor: svGetScaffoldColor(),
                    centerTitle: true,
                    leading: IconButton(
                        icon: Icon(Icons.arrow_back_ios_new_rounded,
                            color: svGetBodyColor()),
                        onPressed: () {
                          Navigator.pop(context);
                        }),
                    actions: const [
                      // IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
                    ],
                  ),
                  Container(
                    color: svGetScaffoldColor(),
                    child: Column(
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
                                textFieldType: TextFieldType.NAME,
                                onChanged: (searchTxt) async {
                                  if (_debounce?.isActive ?? false)
                                    _debounce?.cancel();
                                  _debounce = Timer(
                                      const Duration(milliseconds: 500), () {
                                    // BlocProvider.of<DrugsBloc>(context).add(
                                    //   GetPost(
                                    //       page: '1',
                                    //       countryId: "1",
                                    //       searchTerm: searchTxt,
                                    //       type: state.typeValue),
                                    // );
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
                                  // BlocProvider.of<SplashBloc>(context).add(LoadDropdownData(newValue,state.typeValue));
                                },
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Search ',
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
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      selectedIndex = 0;
                                      // BlocProvider.of<DrugsBloc>(context).add(
                                      //   GetPost(
                                      //       page: '1',
                                      //       countryId: state.countryFlag,
                                      //       searchTerm: '',
                                      //       type: newValue!),
                                      // );
                                      BlocProvider.of<SplashBloc>(context).add(
                                          LoadDropdownData(
                                              state.countryFlag,
                                              "Brand",
                                              state.searchTerms ?? '',
                                              ''));
                                      drugsBloc.add(LoadPageEvent(
                                          page: 1,
                                          countryId: state.countryFlag != ''
                                              ? state.countryFlag
                                              : '${state.countriesModel.countries?.first.id ?? 1}',
                                          searchTerm: state.searchTerms ?? '',
                                          type: 'Brand'));
                                    },
                                    child: Text(
                                      'Brand',
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
                                              "Generic",
                                              state.searchTerms ?? '',
                                              ''));
                                      drugsBloc.add(LoadPageEvent(
                                          page: 1,
                                          countryId: state.countryFlag != ''
                                              ? state.countryFlag
                                              : '${state.countriesModel.countries?.first.id ?? 1}',
                                          searchTerm: state.searchTerms ?? '',
                                          type: 'Generic'));
                                    },
                                    child: Text(
                                      'Generic',
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
                      ],
                    ),
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
          BlocConsumer<DrugsBloc, DrugsState>(
            bloc: drugsBloc,
            // listenWhen: (previous, current) => current is DrugsState,
            // buildWhen: (previous, current) => current is! DrugsState,
            listener: (BuildContext context, DrugsState state) {
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
              if (state is PaginationLoadingState) {
                return Expanded(
                    child: ShimmerCardList());
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
          // if (AppData.isShowGoogleBannerAds ?? false) BannerAdWidget()
        ],
      ),
    );
  }

  Widget _buildPostList(BuildContext context) {
    final bloc = drugsBloc;

    return Expanded(
      child: bloc.drugsData.isEmpty
          ? const Center(
              child: Text("No Drugs Found"),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 10),
              itemCount: bloc.drugsData.length,
              itemBuilder: (context, index) {
                if (bloc.pageNumber <= bloc.numberOfPage) {
                  if (index == bloc.drugsData.length - bloc.nextPageTrigger) {
                    bloc.add(CheckIfNeedMoreDataEvent(index: index));
                  }
                }
                if (bloc.numberOfPage != bloc.pageNumber - 1 &&
                    index >= bloc.drugsData.length - 1) {
                  return SizedBox(
                      height: 400,
                      child: ShimmerCardList());
                } else if ((index % 5 == 0 && index != 0) &&
                    AppData.isShowGoogleNativeAds) {
                  return NativeAdWidget();
                } else {
                  return GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return _buildDialog(
                              context, bloc.drugsData[index].genericName ?? '');
                        },
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(
                          bottom: 10, left: 10,right: 10.0),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  bloc.drugsData[index].genericName ?? "",
                                  style: TextStyle(
                                      color: SVAppColorPrimary,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                              Image.asset(
                                'assets/images/docktak_ai_light.png',
                                height: 35,
                                width: 35,
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Text(bloc.drugsData[index].strength ?? '',
                                  style: TextStyle(
                                      color: svGetBodyColor(),
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w400)),
                              Text(' - ',
                                  style: TextStyle(
                                      color: svGetBodyColor(),
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w400)),
                              Text(bloc.drugsData[index].packageSize ?? '',
                                  style: TextStyle(
                                      color: svGetBodyColor(),
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w400)),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(bloc.drugsData[index].tradeName ?? 'N/A',
                              style: TextStyle(
                                  color: svGetBodyColor(), fontSize: 10.sp)),
                          const SizedBox(height: 5),
                          const SizedBox(height: 10),
                          Divider(
                            color: Colors.grey[300],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                flex: 6,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Manufacturer Name',
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 12.sp),
                                    ),
                                    Text(
                                      bloc.drugsData[index].manufacturerName ??
                                          '',
                                      style: TextStyle(
                                          color: svGetBodyColor(),
                                          fontSize: 12.sp),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 4,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Price',
                                          style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12.sp)),
                                      Text(bloc.drugsData[index].mrp ?? '0',
                                          style: TextStyle(
                                              color: svGetBodyColor(),
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }
                // return PostItem(bloc.drugsData[index].title, bloc.posts[index].body);
              },
            ),
    );
  }

  Widget _buildDialog(BuildContext context, String genericName) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
              child: Text(
            genericName,
            style:  const TextStyle(color: Colors.black, fontSize: 17,fontWeight: FontWeight.w500),
          )),
          // IconButton(
          //   icon: const Icon(
          //     Icons.close,
          //     size: 15,
          //   ),
          //   onPressed: () {
          //     Navigator.of(context).pop();
          //   },
          // ),
        ],
      ),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            _buildQuestion(context, '1. All information', genericName,
                icInfo,
                clickable: true),
            _buildQuestion(context, '2. Mechanism of action', genericName,icMechanisam,
                clickable: true),
            _buildQuestion(context, '3. Indications', genericName,icIndication,
                clickable: true),
            _buildQuestion(context, '4. Dosage and administration', genericName,icDosage,
                clickable: true),
            _buildQuestion(context, '5. Drug interactions', genericName,icDrug,
                clickable: true),
            _buildQuestion(context, '6. Special populations', genericName,icSpecial,
                clickable: true),
            _buildQuestion(context, '7. Side effects', genericName,icSideEffect,
                clickable: true),
            const SizedBox(height: 10,),
            Container(
              width: 30.w,
              height: 10.w,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: MaterialButton(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6.0),
                ),
                onPressed: () {
                  Navigator.of(context, rootNavigator: true)
                      .pop('dialog');
                },
                child: Center(
                  child: Text(
                    "CLOSE",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                      fontSize: 10.sp,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestion(
      BuildContext context, String question, String genericName,String icon,
      {bool clickable = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: clickable
            ? () {
                // ChatDetailScreen(isFromMainScreen:false,question: '$genericName of $question',).launch(context);
                _showBottomSheet(context, genericName ?? '', question);

                // Handle onTap action here
                // ScaffoldMessenger.of(context).showSnackBar(
                //   SnackBar(content: Text('You clicked: $question')),
                // );
              }
            : null,
        child: Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.2), // Adjust color to match your theme
            borderRadius: BorderRadius.circular(8.0),
            // border: Border.all(color: Colors.blue),
            // boxShadow: [
            //   BoxShadow(
            //     color: Colors.grey.withOpacity(0.5),
            //     spreadRadius: 1,
            //     blurRadius: 3,
            //     offset: const Offset(0, 2), // changes position of shadow
            //   ),
            // ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //spacing: 15,
            children: [
              SvgPicture.asset(
                icon,
                height: 20,
                width: 20,
              ),
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(
                    fontSize: 14.0,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14.0,
                color: Colors.blue[900],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBottomSheet(
      BuildContext context, String genericName, String question) {
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
              builder:
                  (BuildContext context, ScrollController scrollController) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: ChatDetailScreen(
                    isFromMainScreen: false,
                    question: '$question  $genericName',
                  ),
                );
              });
        });
        //   Container(
        //   padding: const EdgeInsets.all(16.0),
        //   child: SingleChildScrollView(
        //     scrollDirection: Axis.vertical,
        //     child:ChatDetailScreen()
        //     // Column(
        //     //   mainAxisSize: MainAxisSize.min,
        //     //   crossAxisAlignment: CrossAxisAlignment.stretch,
        //     //   children: <Widget>[
        //     //
        //     //     _buildQuestion(context, 'All information', genericName, clickable: true),
        //     //     _buildQuestion(context, 'Mechanism of action', genericName, clickable: true),
        //     //     _buildQuestion(context, 'Indications', genericName, clickable: true),
        //     //     _buildQuestion(context, 'Dosage and administration', genericName, clickable: true),
        //     //     _buildQuestion(context, 'Drug interactions', genericName, clickable: true),
        //     //     _buildQuestion(context, 'Special populations', genericName, clickable: true),
        //     //     _buildQuestion(context, 'Side effects', genericName, clickable: true),
        //     //     const SizedBox(height: 16.0), // Optional: Add spacing between items and close button
        //     //     ElevatedButton(
        //     //       onPressed: () {
        //     //         Navigator.pop(context); // Close the bottom sheet
        //     //       },
        //     //       child: const Text('Close'),
        //     //     ),
        //     //   ],
        //     // ),
        //   ),
        // );
      },
    );
  }

// Widget _buildQuestion(BuildContext context, String question, String genericName, {bool clickable = false}) {
//   return InkWell(
//     onTap: clickable
//         ? () {
//       // Handle onTap action here
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('You clicked: $question')),
//       );
//     }
//         : null,
//     child: Padding(
//       padding: const EdgeInsets.all(8.0),
//       child: Container(
//         padding: const EdgeInsets.all(12.0),
//         decoration: BoxDecoration(
//           color: Colors.blue[50],
//           borderRadius: BorderRadius.circular(8.0),
//           border: Border.all(color: Colors.blue),
//         ),
//         child: Text(
//           question,
//           style: TextStyle(
//             fontSize: 16.0,
//             color: Colors.blue[900],
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ),
//     ),
//   );
// }
}
