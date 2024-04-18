import 'package:doctak_app/presentation/home_screen/SVDashboardScreen.dart';
import 'package:flutter/material.dart';
import 'package:doctak_app/presentation/splash_screen/splash_screen.dart';
import 'package:doctak_app/presentation/login_screen/login_screen.dart';
import 'package:doctak_app/presentation/sign_up_screen/sign_up_screen.dart';

class AppRoutes {
  static const String splashScreen = '/splash_screen';

  static const String onboardingOneScreen = '/onboarding_one_screen';

  static const String loginScreen = '/login_screen';

  static const String signUpScreen = '/sign_up_screen';

  static const String resetPasswordEmailPage = '/reset_password_email_page';

  static const String resetPasswordEmailTabContainerScreen =
      '/reset_password_email_tab_container_screen';

  static const String resetPasswordPhonePage = '/reset_password_phone_page';

  static const String resetPasswordVerifyCodeScreen =
      '/reset_password_verify_code_screen';

  static const String createNewPasswordScreen = '/create_new_password_screen';

  static const String homePage = '/home_page';

  static const String homeContainerScreen = '/home_container_screen';

  static const String topDoctorScreen = '/top_doctor_screen';

  static const String findDoctorsScreen = '/find_doctors_screen';

  static const String doctorDetailScreen = '/doctor_detail_screen';

  static const String bookingDoctorScreen = '/booking_doctor_screen';

  static const String chatWithDoctorScreen = '/chat_with_doctor_screen';

  static const String audioCallScreen = '/audio_call_screen';

  static const String videoCallScreen = '/video_call_screen';

  static const String schedulePage = '/schedule_page';

  static const String messageHistoryPage = '/message_history_page';

  static const String messageHistoryTabContainerPage =
      '/message_history_tab_container_page';

  static const String articlesScreen = '/articles_screen';

  static const String pharmacyScreen = '/pharmacy_screen';

  static const String drugsDetailScreen = '/drugs_detail_screen';

  static const String myCartScreen = '/my_cart_screen';

  static const String locationScreen = '/location_screen';

  static const String profilePage = '/profile_page';

  static const String appNavigationScreen = '/app_navigation_screen';

  static const String initialRoute = '/initialRoute';

  static Map<String, WidgetBuilder> get routes => {
        // onboardingOneScreen: OnboardingOneScreen.builder,
        // loginScreen: LoginScreen.builder,
        // signUpScreen: SignUpScreen.builder,
        // resetPasswordEmailTabContainerScreen:
        //     ResetPasswordEmailTabContainerScreen.builder,
        // resetPasswordVerifyCodeScreen: ResetPasswordVerifyCodeScreen.builder,
        // createNewPasswordScreen: CreateNewPasswordScreen.builder,
        // homeContainerScreen: SVDashboardScreen(),
        // topDoctorScreen: TopDoctorScreen.builder,
        // findDoctorsScreen: FindDoctorsScreen.builder,
        // doctorDetailScreen: DoctorDetailScreen.builder,
        // bookingDoctorScreen: BookingDoctorScreen.builder,
        // chatWithDoctorScreen: ChatWithDoctorScreen.builder,
        // audioCallScreen: AudioCallScreen.builder,
        // videoCallScreen: VideoCallScreen.builder,
        // articlesScreen: ArticlesScreen.builder,
        // pharmacyScreen: PharmacyScreen.builder,
        // drugsDetailScreen: DrugsDetailScreen.builder,
        // myCartScreen: MyCartScreen.builder,
        // locationScreen: LocationScreen.builder,
        // appNavigationScreen: AppNavigationScreen.builder,
      };
}
