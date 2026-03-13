import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'repository/case_discussion_repository.dart';
import 'bloc/discussion_list_bloc.dart';
import 'bloc/discussion_detail_bloc.dart';
import 'bloc/create_discussion_bloc.dart';
import 'screens/discussion_list_screen.dart';

/// Entry point widget for the Case Discussion module.
/// Provides all necessary BLoC providers and the repository.
///
/// Usage:
/// ```dart
/// CaseDiscussionModule(
///   baseUrl: AppData.base2,
///   getAuthToken: () => AppData.userToken ?? '',
/// )
/// ```
class CaseDiscussionModule extends StatelessWidget {
  final String baseUrl;
  final String Function() getAuthToken;

  const CaseDiscussionModule({
    super.key,
    required this.baseUrl,
    required this.getAuthToken,
  });

  @override
  Widget build(BuildContext context) {
    final repository = CaseDiscussionRepository(
      baseUrl: baseUrl,
      getAuthToken: getAuthToken,
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => DiscussionListBloc(repository: repository),
        ),
        BlocProvider(
          create: (_) => DiscussionDetailBloc(repository: repository),
        ),
        BlocProvider(
          create: (_) => CreateDiscussionBloc(repository: repository),
        ),
      ],
      child: const DiscussionListScreen(),
    );
  }
}
