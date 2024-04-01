import 'dart:async';

import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/bloc/jobs_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/bloc/jobs_state.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/splash_screen/bloc/splash_bloc.dart';
import 'package:doctak_app/widgets/custom_dropdown_button_from_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  JobsBloc jobsBloc = JobsBloc();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    jobsBloc.add(
      LoadPageEvent(page: 1, countryId: '1', searchTerm: ''),
    );
    super.initState();
  }

  var selectedValue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: svGetScaffoldColor(),
      appBar: AppBar(
        backgroundColor: svGetScaffoldColor(),
        iconTheme: IconThemeData(color: context.iconColor),
        title: Text('Jobs', style: boldTextStyle(size: 18)),
        elevation: 0,
        centerTitle: true,
        actions: const [
          // IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
        ],
      ),
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
              return Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.only(left: 8.0),

                      margin: const EdgeInsets.only(
                          left: 16, top: 16.0, bottom: 16.0),
                      decoration: BoxDecoration(
                          color: context.cardColor, borderRadius: radius(8)),
                      child: AppTextField(
                        textFieldType: TextFieldType.NAME,
                        onChanged: (searchTxt) async {
                          if (_debounce?.isActive ?? false) _debounce?.cancel();

                          _debounce =
                              Timer(const Duration(milliseconds: 500), () {
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
                                    state.searchTerms ?? '',
                                    state.isExpired));
                            jobsBloc.add(LoadPageEvent(
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
                  ),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
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
                            LoadDropdownData(state.countryFlag, newValue ?? "",
                                state.searchTerms ?? '', newValue!));

                        jobsBloc.add(LoadPageEvent(
                            page: 1,
                            countryId: state.countryFlag != ''
                                ? state.countryFlag
                                : '${state.countriesModel.countries?.first.id ?? 1}',
                            searchTerm: state.searchTerms ?? '',
                            isExpired: newValue!));
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CustomDropdownField(
                      items: state.countriesModel.countries ?? [],
                      value: state.countriesModel.countries?.first.flag,
                      width: 50,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 0,
                      ),
                      onChanged: (String? newValue) {
                        print("ddd ${state.countryFlag}");
                        var index = state.countriesModel.countries!
                            .indexWhere((element) => newValue == element.flag);
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
                        jobsBloc.add(LoadPageEvent(
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
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    content: Text(state.errorMessage),
                  ),
                );
              }
            },
            builder: (context, state) {
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
        ],
      ),
    );
  }

  Widget _buildPostList(BuildContext context) {
    final bloc = jobsBloc;
    print("bloc$bloc");
    print("len${bloc.drugsData.length}");
    return Expanded(
      child: ListView.builder(
        itemCount: bloc.drugsData.length,
        itemBuilder: (context, index) {
          if (bloc.pageNumber <= bloc.numberOfPage) {
            if (index == bloc.drugsData.length - bloc.nextPageTrigger) {
              bloc.add(CheckIfNeedMoreDataEvent(index: index));
            }
          }
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
                          style: secondaryTextStyle(color: svGetBodyColor())),
                      const SizedBox(height: 10),
                      Text(
                          'Experience: ${bloc.drugsData[index].experience ?? 'N/A'}',
                          style: secondaryTextStyle(color: svGetBodyColor())),
                      const SizedBox(height: 5),
                      Text(bloc.drugsData[index].description ?? 'N/A',
                          style: secondaryTextStyle(color: svGetBodyColor())),
                      const SizedBox(height: 5),
                      Text(
                          "Location: ${bloc.drugsData[index].location ?? 'N/A'}",
                          style: secondaryTextStyle(color: svGetBodyColor())),
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Apply before: ${bloc.drugsData[index].lastDate != null ? DateFormat('dd MMM, yyyy').format(DateTime.parse(bloc.drugsData[index].lastDate!)) : 'N/A'}',
                              style: TextStyle(
                                color: bloc.drugsData[index].lastDate != null &&
                                        DateTime.now().isAfter(DateTime.parse(
                                            bloc.drugsData[index].lastDate!))
                                    ? Colors
                                        .red // Change font color to red for expired jobs
                                    : svGetBodyColor(),
                              ),
                            ),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () async {
                                final Uri url = Uri.parse(bloc.drugsData[index]
                                    .link!); // Assuming job.link is a non-null String
                                // Show dialog asking the user to confirm navigation
                                final shouldLeave = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Leave App'),
                                    content: const Text(
                                        'Would you like to leave the app to view this content?'),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text('No'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        child: const Text('Yes'),
                                      ),
                                    ],
                                  ),
                                );
                                // If the user confirmed, launch the URL
                                if (shouldLeave == true) {
                                  // await launchUrl(url);
                                } else if (shouldLeave == false) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Leaving the app canceled.')),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Leaving the app canceled.')),
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
