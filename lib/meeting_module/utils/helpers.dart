import 'package:doctak_app/meeting_module/bloc/chat/chat_bloc.dart';
import 'package:doctak_app/meeting_module/bloc/meeting/meeting_bloc.dart';
import 'package:doctak_app/meeting_module/bloc/participants/participants_bloc.dart';
import 'package:doctak_app/meeting_module/bloc/settings/settings_bloc.dart';
import 'package:doctak_app/meeting_module/services/agora_service.dart';
import 'package:doctak_app/meeting_module/services/api_service.dart';
import 'package:doctak_app/meeting_module/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../ui/join/join_meeting_page.dart';

void main() {
  runApp(const MeetingApp());
}

class MeetingApp extends StatelessWidget {
  const MeetingApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Initialize API service
        Provider<ApiService>(
          create: (_) => ApiService(
            baseUrl: API_BASE_URL,
          ),
        ),

        // Initialize Agora service
        Provider<AgoraService>(
          create: (_) => AgoraService(),
        ),

        // Initialize BLoCs
        BlocProvider<MeetingBloc>(
          create: (context) => MeetingBloc(
            apiService: context.read<ApiService>(),
            agoraService: context.read<AgoraService>(),
          ),
        ),
        BlocProvider<ParticipantsBloc>(
          create: (context) => ParticipantsBloc(
            apiService: context.read<ApiService>(),
          ),
        ),
        BlocProvider<ChatBloc>(
          create: (context) => ChatBloc(
            apiService: context.read<ApiService>(),
          ),
        ),
        BlocProvider<SettingsBloc>(
          create: (context) => SettingsBloc(
            apiService: context.read<ApiService>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Medical Meeting App',
        theme: ThemeData(
          primarySwatch: _createMaterialColor(kPrimaryColor),
          visualDensity: VisualDensity.adaptivePlatformDensity,
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            elevation: 0,
            backgroundColor: kPrimaryColor,
            foregroundColor: Colors.white,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: kPrimaryColor,
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: kPrimaryColor,
              side: const BorderSide(color: kPrimaryColor),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: kPrimaryColor,
            ),
          ),
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
        home: const JoinMeetingPage(),
      ),
    );
  }

  // Helper function to create a MaterialColor from a single Color
  MaterialColor _createMaterialColor(Color color) {
    List<double> strengths = <double>[.05, .1, .2, .3, .4, .5, .6, .7, .8, .9];
    Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }
}