import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_event.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/retry_widget.dart';
import 'package:doctak_app/widgets/shimmer_widget/profile_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../profile/components/SVProfileHeaderComponent.dart';
import 'bloc/profile_state.dart';

class SVProfileFragment extends StatefulWidget {
  const SVProfileFragment({this.userId, Key? key}) : super(key: key);
  final String? userId;

  @override
  State<SVProfileFragment> createState() => _SVProfileFragmentState();
}

class _SVProfileFragmentState extends State<SVProfileFragment>
    with SingleTickerProviderStateMixin {
  ProfileBloc profileBloc = ProfileBloc();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    print(widget.userId);
    if (widget.userId == null) {
      print('object1 ${AppData.logInUserId}');
      profileBloc.add(LoadPageEvent(userId: AppData.logInUserId, page: 1));
    } else {
      print('object ${widget.userId}');
      profileBloc.add(LoadPageEvent(userId: widget.userId, page: 1));
    }

    // Initialize fade animation for a smoother experience
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
    );
    super.initState();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (BuildContext context, ProfileState state) {
          if (state is PaginationLoadedState) {
            _fadeController.forward();
          }
        },
        bloc: profileBloc,
        builder: (context, state) {
          if (state is PaginationLoadingState) {
            return Center(child: ProfileShimmer());
          } else if (state is PaginationLoadedState) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SizedBox.expand(
                child: SVProfileHeaderComponent(
                  userProfile: profileBloc.userProfile,
                  profileBoc: profileBloc,
                  isMe: widget.userId == null,
                ),
              ),
            );
          } else if (state is DataError) {
            return RetryWidget(
              errorMessage: translation(context).msg_something_went_wrong_retry,
              onRetry: () {
                try {
                  if (widget.userId == null) {
                    profileBloc.add(
                      LoadPageEvent(userId: AppData.logInUserId, page: 1),
                    );
                  } else {
                    profileBloc.add(
                      LoadPageEvent(userId: widget.userId, page: 1),
                    );
                  }
                } catch (e) {
                  debugPrint(e.toString());
                }
              },
            );
          } else {
            return Center(
              child: Text(
                '${translation(context).lbl_unknown_state}: ${state.toString()}',
                style: TextStyle(color: theme.error),
              ),
            );
          }
        },
      ),
    );
  }
}
