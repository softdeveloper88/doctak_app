import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fa.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fa'),
    Locale('fr')
  ];

  /// No description provided for @lbl_home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get lbl_home;

  /// No description provided for @lbl_get_started.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get lbl_get_started;

  /// No description provided for @lbl_next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get lbl_next;

  /// No description provided for @lbl_skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get lbl_skip;

  /// No description provided for @msg_consult_only_with.
  ///
  /// In en, this message translates to:
  /// **'Consult only with a doctor you trust'**
  String get msg_consult_only_with;

  /// No description provided for @msg_find_a_lot_of_specialist.
  ///
  /// In en, this message translates to:
  /// **'Find a lot of specialist doctors in one place'**
  String get msg_find_a_lot_of_specialist;

  /// No description provided for @msg_get_connect_our.
  ///
  /// In en, this message translates to:
  /// **'Get connect our Online Consultation'**
  String get msg_get_connect_our;

  /// No description provided for @msg_let_s_get_started.
  ///
  /// In en, this message translates to:
  /// **'Let\'s get started!'**
  String get msg_let_s_get_started;

  /// No description provided for @msg_login_to_enjoy_the.
  ///
  /// In en, this message translates to:
  /// **'Login to enjoy the features we\'ve provided, and stay healthy!'**
  String get msg_login_to_enjoy_the;

  /// No description provided for @lbl_login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get lbl_login;

  /// No description provided for @lbl_or.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get lbl_or;

  /// No description provided for @msg_don_t_have_an_account.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get msg_don_t_have_an_account;

  /// No description provided for @msg_forgot_password.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get msg_forgot_password;

  /// No description provided for @msg_sign_in_with_apple.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple'**
  String get msg_sign_in_with_apple;

  /// No description provided for @msg_sign_in_with_facebook.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Facebook'**
  String get msg_sign_in_with_facebook;

  /// No description provided for @msg_sign_in_with_google.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get msg_sign_in_with_google;

  /// No description provided for @lbl_enter_your_name.
  ///
  /// In en, this message translates to:
  /// **'Enter Your Name'**
  String get lbl_enter_your_name;

  /// No description provided for @lbl_enter_your_name1.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get lbl_enter_your_name1;

  /// No description provided for @lbl_enter_your_name2.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lbl_enter_your_name2;

  /// No description provided for @lbl_enter_your_phone.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone'**
  String get lbl_enter_your_phone;

  /// No description provided for @lbl_log_in2.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get lbl_log_in2;

  /// No description provided for @msg_already_have_an.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get msg_already_have_an;

  /// No description provided for @msg_i_agree_to_the_medidoc.
  ///
  /// In en, this message translates to:
  /// **'I agree to the medidoc Terms of Service \nand Privacy Policy'**
  String get msg_i_agree_to_the_medidoc;

  /// No description provided for @lbl_go_to_home.
  ///
  /// In en, this message translates to:
  /// **'Go to Home'**
  String get lbl_go_to_home;

  /// No description provided for @lbl_success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get lbl_success;

  /// No description provided for @msg_your_account_has.
  ///
  /// In en, this message translates to:
  /// **'Your account has been \nsuccessfully registered'**
  String get msg_your_account_has;

  /// No description provided for @lbl_xyz_gmail_com.
  ///
  /// In en, this message translates to:
  /// **'xyz@gmail.com'**
  String get lbl_xyz_gmail_com;

  /// No description provided for @lbl_email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get lbl_email;

  /// No description provided for @lbl_phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get lbl_phone;

  /// No description provided for @msg_enter_your_email2.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get msg_enter_your_email2;

  /// No description provided for @msg_forgot_your_password.
  ///
  /// In en, this message translates to:
  /// **'Forgot Your Password?'**
  String get msg_forgot_your_password;

  /// No description provided for @lbl_1234567890.
  ///
  /// In en, this message translates to:
  /// **'1234567890'**
  String get lbl_1234567890;

  /// No description provided for @lbl_08528188.
  ///
  /// In en, this message translates to:
  /// **'08528188*** '**
  String get lbl_08528188;

  /// No description provided for @lbl_resend.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get lbl_resend;

  /// No description provided for @lbl_verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get lbl_verify;

  /// No description provided for @msg_didn_t_receive_the.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the code?'**
  String get msg_didn_t_receive_the;

  /// No description provided for @msg_enter_code_that.
  ///
  /// In en, this message translates to:
  /// **'Enter code that we have sent to your number 08528188*** '**
  String get msg_enter_code_that;

  /// No description provided for @msg_enter_code_that2.
  ///
  /// In en, this message translates to:
  /// **'Enter code that we have sent to your number '**
  String get msg_enter_code_that2;

  /// No description provided for @msg_enter_verification.
  ///
  /// In en, this message translates to:
  /// **'Enter Verification Code'**
  String get msg_enter_verification;

  /// No description provided for @lbl_create_password.
  ///
  /// In en, this message translates to:
  /// **'Create Password:'**
  String get lbl_create_password;

  /// No description provided for @msg_confirm_password.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get msg_confirm_password;

  /// No description provided for @msg_create_new_password.
  ///
  /// In en, this message translates to:
  /// **'Create New Password'**
  String get msg_create_new_password;

  /// No description provided for @msg_create_your_new.
  ///
  /// In en, this message translates to:
  /// **'Create your new password to login'**
  String get msg_create_your_new;

  /// No description provided for @msg_enter_your_email.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get msg_enter_your_email;

  /// No description provided for @msg_enter_new_password.
  ///
  /// In en, this message translates to:
  /// **'Enter new password'**
  String get msg_enter_new_password;

  /// No description provided for @msg_network_err.
  ///
  /// In en, this message translates to:
  /// **'Network Error'**
  String get msg_network_err;

  /// No description provided for @msg_something_went_wrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get msg_something_went_wrong;

  /// No description provided for @err_msg_please_enter_valid_email.
  ///
  /// In en, this message translates to:
  /// **'Please enter valid email'**
  String get err_msg_please_enter_valid_email;

  /// No description provided for @err_msg_please_enter_valid_password.
  ///
  /// In en, this message translates to:
  /// **'Password should be contain (8-16 chars, with upper,\n lower, number, and special character.'**
  String get err_msg_please_enter_valid_password;

  /// No description provided for @err_msg_please_enter_valid_text.
  ///
  /// In en, this message translates to:
  /// **'Please enter valid text'**
  String get err_msg_please_enter_valid_text;

  /// No description provided for @err_msg_please_enter_valid_phone_number.
  ///
  /// In en, this message translates to:
  /// **'Please enter valid phone number'**
  String get err_msg_please_enter_valid_phone_number;

  /// No description provided for @auction_product_screen_.
  ///
  /// In en, this message translates to:
  /// **'You need to log in'**
  String get auction_product_screen_;

  /// No description provided for @lbl_payment_detail.
  ///
  /// In en, this message translates to:
  /// **'Payment Detail'**
  String get lbl_payment_detail;

  /// No description provided for @lbl_payment_method.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get lbl_payment_method;

  /// No description provided for @lbl_read_more.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get lbl_read_more;

  /// No description provided for @lbl_see_all.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get lbl_see_all;

  /// No description provided for @lbl_send_otp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get lbl_send_otp;

  /// No description provided for @lbl_sign_up.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get lbl_sign_up;

  /// No description provided for @lbl_top_doctor.
  ///
  /// In en, this message translates to:
  /// **'Top Doctor'**
  String get lbl_top_doctor;

  /// No description provided for @lbl_total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get lbl_total;

  /// No description provided for @lbl_jobs.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get lbl_jobs;

  /// No description provided for @lbl_drug_list.
  ///
  /// In en, this message translates to:
  /// **'Drug list'**
  String get lbl_drug_list;

  /// No description provided for @lbl_conference.
  ///
  /// In en, this message translates to:
  /// **'Conferences'**
  String get lbl_conference;

  /// No description provided for @lbl_guidelines.
  ///
  /// In en, this message translates to:
  /// **'Guidelines'**
  String get lbl_guidelines;

  /// No description provided for @lbl_moh_update.
  ///
  /// In en, this message translates to:
  /// **'MOH Updates'**
  String get lbl_moh_update;

  /// No description provided for @lbl_library_magazines.
  ///
  /// In en, this message translates to:
  /// **'Library & Magazines'**
  String get lbl_library_magazines;

  /// No description provided for @lbl_CME.
  ///
  /// In en, this message translates to:
  /// **'CME'**
  String get lbl_CME;

  /// No description provided for @lbl_world_news.
  ///
  /// In en, this message translates to:
  /// **'World News'**
  String get lbl_world_news;

  /// No description provided for @lbl_suggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get lbl_suggestions;

  /// No description provided for @desc_suggestions.
  ///
  /// In en, this message translates to:
  /// **'Submit suggestions'**
  String get desc_suggestions;

  /// No description provided for @lbl_discounts.
  ///
  /// In en, this message translates to:
  /// **'Discounts'**
  String get lbl_discounts;

  /// No description provided for @lbl_share_app.
  ///
  /// In en, this message translates to:
  /// **'Share App'**
  String get lbl_share_app;

  /// No description provided for @lbl_rate_us.
  ///
  /// In en, this message translates to:
  /// **'Rate Us'**
  String get lbl_rate_us;

  /// No description provided for @lbl_logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get lbl_logout;

  /// No description provided for @lbl_delete_account.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get lbl_delete_account;

  /// No description provided for @lbl_welcome_back.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get lbl_welcome_back;

  /// No description provided for @msg_please_login_to_continue.
  ///
  /// In en, this message translates to:
  /// **'Please login to continue'**
  String get msg_please_login_to_continue;

  /// No description provided for @lbl_enter_your_email_colon.
  ///
  /// In en, this message translates to:
  /// **'Enter your Email:'**
  String get lbl_enter_your_email_colon;

  /// No description provided for @lbl_enter_your_password_colon.
  ///
  /// In en, this message translates to:
  /// **'Enter your Password:'**
  String get lbl_enter_your_password_colon;

  /// No description provided for @lbl_remember_me.
  ///
  /// In en, this message translates to:
  /// **'Remember Me'**
  String get lbl_remember_me;

  /// No description provided for @lbl_login_button.
  ///
  /// In en, this message translates to:
  /// **'LOGIN'**
  String get lbl_login_button;

  /// No description provided for @lbl_saved_logins.
  ///
  /// In en, this message translates to:
  /// **'Saved Logins'**
  String get lbl_saved_logins;

  /// No description provided for @msg_no_saved_logins.
  ///
  /// In en, this message translates to:
  /// **'No saved logins available'**
  String get msg_no_saved_logins;

  /// No description provided for @msg_login_success.
  ///
  /// In en, this message translates to:
  /// **'Login successfully'**
  String get msg_login_success;

  /// No description provided for @msg_login_failed.
  ///
  /// In en, this message translates to:
  /// **'Login failed please try again'**
  String get msg_login_failed;

  /// No description provided for @msg_something_wrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get msg_something_wrong;

  /// No description provided for @msg_verification_link_sent.
  ///
  /// In en, this message translates to:
  /// **'Verification link sent successfully'**
  String get msg_verification_link_sent;

  /// No description provided for @msg_validation_error.
  ///
  /// In en, this message translates to:
  /// **'Validation error or user email not found'**
  String get msg_validation_error;

  /// No description provided for @msg_user_already_verified.
  ///
  /// In en, this message translates to:
  /// **'User already verified'**
  String get msg_user_already_verified;

  /// No description provided for @msg_verification_title.
  ///
  /// In en, this message translates to:
  /// **'Sending Verification Link'**
  String get msg_verification_title;

  /// No description provided for @lbl_notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get lbl_notifications;

  /// No description provided for @lbl_mark_all_read.
  ///
  /// In en, this message translates to:
  /// **'Mark All Read'**
  String get lbl_mark_all_read;

  /// No description provided for @msg_no_notifications.
  ///
  /// In en, this message translates to:
  /// **'No Notification Found'**
  String get msg_no_notifications;

  /// No description provided for @msg_notification_error.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get msg_notification_error;

  /// No description provided for @lbl_coming_soon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get lbl_coming_soon;

  /// No description provided for @lbl_forgot_password_title.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get lbl_forgot_password_title;

  /// No description provided for @msg_enter_email_to_reset.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to reset password'**
  String get msg_enter_email_to_reset;

  /// No description provided for @lbl_send_button.
  ///
  /// In en, this message translates to:
  /// **'SEND'**
  String get lbl_send_button;

  /// No description provided for @lbl_next_image.
  ///
  /// In en, this message translates to:
  /// **'Next Image'**
  String get lbl_next_image;

  /// No description provided for @lbl_welcome_doctor.
  ///
  /// In en, this message translates to:
  /// **'Welcome, Doctor!'**
  String get lbl_welcome_doctor;

  /// No description provided for @msg_ai_assistant_intro.
  ///
  /// In en, this message translates to:
  /// **'Your personal & medical assistant powered by Artificial Intelligence'**
  String get msg_ai_assistant_intro;

  /// No description provided for @msg_upload_images_prompt.
  ///
  /// In en, this message translates to:
  /// **'Please upload the medical images for potential diagnoses and analysis'**
  String get msg_upload_images_prompt;

  /// No description provided for @msg_clinical_summary_hint.
  ///
  /// In en, this message translates to:
  /// **'Clinical Summary e.g age, gender, medical history'**
  String get msg_clinical_summary_hint;

  /// No description provided for @msg_ai_disclaimer.
  ///
  /// In en, this message translates to:
  /// **'Artificial Intelligence can make mistakes. Consider checking important information.'**
  String get msg_ai_disclaimer;

  /// No description provided for @lbl_error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get lbl_error;

  /// No description provided for @lbl_try_again.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get lbl_try_again;

  /// No description provided for @lbl_select_option.
  ///
  /// In en, this message translates to:
  /// **'Select Option'**
  String get lbl_select_option;

  /// No description provided for @lbl_please_ask_question.
  ///
  /// In en, this message translates to:
  /// **'Please ask a question'**
  String get lbl_please_ask_question;

  /// No description provided for @lbl_analyse_image.
  ///
  /// In en, this message translates to:
  /// **'Analyse Image'**
  String get lbl_analyse_image;

  /// No description provided for @lbl_only_one_image_allowed.
  ///
  /// In en, this message translates to:
  /// **'Only allowed one time image in one session'**
  String get lbl_only_one_image_allowed;

  /// No description provided for @lbl_dermatological_assessment.
  ///
  /// In en, this message translates to:
  /// **'Dermatological assessment'**
  String get lbl_dermatological_assessment;

  /// No description provided for @lbl_xray_evaluation.
  ///
  /// In en, this message translates to:
  /// **'X-ray evaluation'**
  String get lbl_xray_evaluation;

  /// No description provided for @lbl_ct_scan_evaluation.
  ///
  /// In en, this message translates to:
  /// **'CT scan evaluation'**
  String get lbl_ct_scan_evaluation;

  /// No description provided for @lbl_mri_evaluation.
  ///
  /// In en, this message translates to:
  /// **'MRI evaluation'**
  String get lbl_mri_evaluation;

  /// No description provided for @lbl_mammography_analysis.
  ///
  /// In en, this message translates to:
  /// **'Mammography analysis'**
  String get lbl_mammography_analysis;

  /// No description provided for @lbl_preparing_ai.
  ///
  /// In en, this message translates to:
  /// **'Preparing DocTak AI.'**
  String get lbl_preparing_ai;

  /// No description provided for @lbl_generating_response.
  ///
  /// In en, this message translates to:
  /// **'Generating response...'**
  String get lbl_generating_response;

  /// No description provided for @lbl_regenerate.
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get lbl_regenerate;

  /// No description provided for @lbl_next_session.
  ///
  /// In en, this message translates to:
  /// **'Next Session'**
  String get lbl_next_session;

  /// No description provided for @lbl_code_detection_question.
  ///
  /// In en, this message translates to:
  /// **'Code Detection: Identify CPT or ICD codes'**
  String get lbl_code_detection_question;

  /// No description provided for @lbl_diagnostic_suggestions_question.
  ///
  /// In en, this message translates to:
  /// **'Diagnostic Suggestions: Request suggestions based on symptoms'**
  String get lbl_diagnostic_suggestions_question;

  /// No description provided for @lbl_medication_review_question.
  ///
  /// In en, this message translates to:
  /// **'Medication Review: check interactions and dosage'**
  String get lbl_medication_review_question;

  /// No description provided for @lbl_ready_to_start.
  ///
  /// In en, this message translates to:
  /// **'Ready to start? Type your question below or choose a suggested topic.'**
  String get lbl_ready_to_start;

  /// No description provided for @lbl_code_detection.
  ///
  /// In en, this message translates to:
  /// **'Code Detection'**
  String get lbl_code_detection;

  /// No description provided for @lbl_identify_cpt_icd.
  ///
  /// In en, this message translates to:
  /// **'Identify CPT or ICD codes'**
  String get lbl_identify_cpt_icd;

  /// No description provided for @lbl_diagnostic_suggestions.
  ///
  /// In en, this message translates to:
  /// **'Diagnostic \nSuggestions'**
  String get lbl_diagnostic_suggestions;

  /// No description provided for @lbl_request_suggestions.
  ///
  /// In en, this message translates to:
  /// **'Request suggestions based on symptoms'**
  String get lbl_request_suggestions;

  /// No description provided for @lbl_medication_review.
  ///
  /// In en, this message translates to:
  /// **'Medication Review'**
  String get lbl_medication_review;

  /// No description provided for @lbl_check_interactions.
  ///
  /// In en, this message translates to:
  /// **'Check interactions and dosage'**
  String get lbl_check_interactions;

  /// No description provided for @lbl_ask_medical_ai.
  ///
  /// In en, this message translates to:
  /// **'Ask Medical Ai'**
  String get lbl_ask_medical_ai;

  /// No description provided for @msg_something_went_wrong_try_again.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again...'**
  String get msg_something_went_wrong_try_again;

  /// No description provided for @lbl_delete_chat.
  ///
  /// In en, this message translates to:
  /// **'Delete chat?'**
  String get lbl_delete_chat;

  /// No description provided for @msg_confirm_delete_chat.
  ///
  /// In en, this message translates to:
  /// **'Are you sure that you want to delete this chat'**
  String get msg_confirm_delete_chat;

  /// No description provided for @lbl_cancel_caps.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get lbl_cancel_caps;

  /// No description provided for @lbl_delete_caps.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get lbl_delete_caps;

  /// No description provided for @lbl_history_ai.
  ///
  /// In en, this message translates to:
  /// **'History '**
  String get lbl_history_ai;

  /// No description provided for @lbl_new_chat.
  ///
  /// In en, this message translates to:
  /// **'+ NEW CHAT'**
  String get lbl_new_chat;

  /// No description provided for @lbl_text_copied_clipboard.
  ///
  /// In en, this message translates to:
  /// **'Text copied to clipboard'**
  String get lbl_text_copied_clipboard;

  /// No description provided for @lbl_medical_images.
  ///
  /// In en, this message translates to:
  /// **'Medical Images'**
  String get lbl_medical_images;

  /// No description provided for @lbl_connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get lbl_connecting;

  /// No description provided for @lbl_ringing.
  ///
  /// In en, this message translates to:
  /// **'Ringing'**
  String get lbl_ringing;

  /// No description provided for @lbl_accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get lbl_accept;

  /// No description provided for @lbl_decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get lbl_decline;

  /// No description provided for @lbl_end_call.
  ///
  /// In en, this message translates to:
  /// **'End Call'**
  String get lbl_end_call;

  /// No description provided for @lbl_ringing_format.
  ///
  /// In en, this message translates to:
  /// **'Ringing {name}...'**
  String lbl_ringing_format(Object name);

  /// No description provided for @lbl_initializing_call.
  ///
  /// In en, this message translates to:
  /// **'Initializing call...'**
  String get lbl_initializing_call;

  /// No description provided for @lbl_call_permission_error.
  ///
  /// In en, this message translates to:
  /// **'Call cannot start without required permissions'**
  String get lbl_call_permission_error;

  /// No description provided for @lbl_end_call_confirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to end this call?'**
  String get lbl_end_call_confirmation;

  /// No description provided for @lbl_cancel.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get lbl_cancel;

  /// No description provided for @lbl_mute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get lbl_mute;

  /// No description provided for @lbl_audio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get lbl_audio;

  /// No description provided for @lbl_video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get lbl_video;

  /// No description provided for @lbl_speaker.
  ///
  /// In en, this message translates to:
  /// **'Speaker'**
  String get lbl_speaker;

  /// No description provided for @lbl_flip.
  ///
  /// In en, this message translates to:
  /// **'Flip'**
  String get lbl_flip;

  /// No description provided for @lbl_end.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get lbl_end;

  /// No description provided for @lbl_in_call.
  ///
  /// In en, this message translates to:
  /// **'In call'**
  String get lbl_in_call;

  /// No description provided for @lbl_calling_user.
  ///
  /// In en, this message translates to:
  /// **'Calling {name}...'**
  String lbl_calling_user(Object name);

  /// No description provided for @lbl_video_call.
  ///
  /// In en, this message translates to:
  /// **'Video Call'**
  String get lbl_video_call;

  /// No description provided for @lbl_audio_call.
  ///
  /// In en, this message translates to:
  /// **'Audio Call'**
  String get lbl_audio_call;

  /// No description provided for @lbl_reconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting...'**
  String get lbl_reconnecting;

  /// No description provided for @lbl_please_wait.
  ///
  /// In en, this message translates to:
  /// **'Please wait'**
  String get lbl_please_wait;

  /// No description provided for @lbl_ending_call.
  ///
  /// In en, this message translates to:
  /// **'Ending Call...'**
  String get lbl_ending_call;

  /// No description provided for @lbl_network_quality_excellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get lbl_network_quality_excellent;

  /// No description provided for @lbl_network_quality_good.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get lbl_network_quality_good;

  /// No description provided for @lbl_network_quality_fair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get lbl_network_quality_fair;

  /// No description provided for @lbl_network_quality_poor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get lbl_network_quality_poor;

  /// No description provided for @lbl_network_quality_very_poor.
  ///
  /// In en, this message translates to:
  /// **'Very poor'**
  String get lbl_network_quality_very_poor;

  /// No description provided for @lbl_network_quality_unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get lbl_network_quality_unknown;

  /// No description provided for @lbl_calling_status.
  ///
  /// In en, this message translates to:
  /// **'Calling...'**
  String get lbl_calling_status;

  /// No description provided for @lbl_user_busy.
  ///
  /// In en, this message translates to:
  /// **'User is busy'**
  String get lbl_user_busy;

  /// No description provided for @lbl_user_offline.
  ///
  /// In en, this message translates to:
  /// **'User is offline'**
  String get lbl_user_offline;

  /// No description provided for @lbl_call_rejected.
  ///
  /// In en, this message translates to:
  /// **'Call rejected'**
  String get lbl_call_rejected;

  /// No description provided for @lbl_no_answer.
  ///
  /// In en, this message translates to:
  /// **'No answer'**
  String get lbl_no_answer;

  /// No description provided for @lbl_call_accepted.
  ///
  /// In en, this message translates to:
  /// **'Call accepted'**
  String get lbl_call_accepted;

  /// No description provided for @lbl_failed_to_establish_call.
  ///
  /// In en, this message translates to:
  /// **'Failed to establish call. Please try again.'**
  String get lbl_failed_to_establish_call;

  /// No description provided for @lbl_error_starting_call.
  ///
  /// In en, this message translates to:
  /// **'Error starting call. Please try again.'**
  String get lbl_error_starting_call;

  /// No description provided for @lbl_signup_title.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get lbl_signup_title;

  /// No description provided for @msg_register_account.
  ///
  /// In en, this message translates to:
  /// **'Please Register your account to continue'**
  String get msg_register_account;

  /// No description provided for @lbl_enter_first_name.
  ///
  /// In en, this message translates to:
  /// **'First Name:'**
  String get lbl_enter_first_name;

  /// No description provided for @lbl_enter_last_name.
  ///
  /// In en, this message translates to:
  /// **'Last Name:'**
  String get lbl_enter_last_name;

  /// No description provided for @lbl_enter_email.
  ///
  /// In en, this message translates to:
  /// **'Enter Your Email:'**
  String get lbl_enter_email;

  /// No description provided for @lbl_confirm_password.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password:'**
  String get lbl_confirm_password;

  /// No description provided for @msg_agree_terms.
  ///
  /// In en, this message translates to:
  /// **'I agree to the terms and conditions'**
  String get msg_agree_terms;

  /// No description provided for @lbl_register.
  ///
  /// In en, this message translates to:
  /// **'REGISTER'**
  String get lbl_register;

  /// No description provided for @msg_already_have_account.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get msg_already_have_account;

  /// No description provided for @lbl_doctor.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get lbl_doctor;

  /// No description provided for @lbl_medical_student.
  ///
  /// In en, this message translates to:
  /// **'Medical student'**
  String get lbl_medical_student;

  /// No description provided for @lbl_profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get lbl_profile;

  /// No description provided for @lbl_personal_information.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get lbl_personal_information;

  /// No description provided for @lbl_first_name.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get lbl_first_name;

  /// No description provided for @lbl_last_name.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lbl_last_name;

  /// No description provided for @lbl_phone_number.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get lbl_phone_number;

  /// No description provided for @lbl_date_of_birth.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get lbl_date_of_birth;

  /// No description provided for @lbl_license_no.
  ///
  /// In en, this message translates to:
  /// **'License No'**
  String get lbl_license_no;

  /// No description provided for @lbl_country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get lbl_country;

  /// No description provided for @lbl_state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get lbl_state;

  /// No description provided for @lbl_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get lbl_edit;

  /// No description provided for @lbl_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get lbl_save;

  /// No description provided for @lbl_specialty.
  ///
  /// In en, this message translates to:
  /// **'Specialty'**
  String get lbl_specialty;

  /// No description provided for @lbl_university.
  ///
  /// In en, this message translates to:
  /// **'University'**
  String get lbl_university;

  /// No description provided for @lbl_update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get lbl_update;

  /// No description provided for @lbl_license_info.
  ///
  /// In en, this message translates to:
  /// **'License Info'**
  String get lbl_license_info;

  /// No description provided for @lbl_location_info.
  ///
  /// In en, this message translates to:
  /// **'Location Info'**
  String get lbl_location_info;

  /// No description provided for @msg_personal_info_desc.
  ///
  /// In en, this message translates to:
  /// **'This information will be used to personalize your experience and connect you with relevant professionals.'**
  String get msg_personal_info_desc;

  /// No description provided for @msg_profile_updated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get msg_profile_updated;

  /// No description provided for @lbl_update_profile_picture.
  ///
  /// In en, this message translates to:
  /// **'Update Profile Picture'**
  String get lbl_update_profile_picture;

  /// No description provided for @lbl_update_cover_photo.
  ///
  /// In en, this message translates to:
  /// **'Update Cover Photo'**
  String get lbl_update_cover_photo;

  /// No description provided for @lbl_message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get lbl_message;

  /// No description provided for @lbl_present.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get lbl_present;

  /// No description provided for @lbl_duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get lbl_duration;

  /// No description provided for @lbl_add_experience.
  ///
  /// In en, this message translates to:
  /// **'Add Experience'**
  String get lbl_add_experience;

  /// No description provided for @msg_add_experience.
  ///
  /// In en, this message translates to:
  /// **'Add your professional experience to showcase your expertise and career progression.'**
  String get msg_add_experience;

  /// No description provided for @lbl_rotate.
  ///
  /// In en, this message translates to:
  /// **'Rotate'**
  String get lbl_rotate;

  /// No description provided for @msg_image_saved_to_gallery.
  ///
  /// In en, this message translates to:
  /// **'Image saved to gallery'**
  String get msg_image_saved_to_gallery;

  /// No description provided for @lbl_check_out_profile.
  ///
  /// In en, this message translates to:
  /// **'Check out this profile!'**
  String get lbl_check_out_profile;

  /// No description provided for @msg_interests_info_desc.
  ///
  /// In en, this message translates to:
  /// **'Showcase your professional interests and academic achievements to connect with like-minded colleagues and opportunities.'**
  String get msg_interests_info_desc;

  /// No description provided for @lbl_app_settings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get lbl_app_settings;

  /// No description provided for @lbl_theme_appearance.
  ///
  /// In en, this message translates to:
  /// **'Theme Appearance'**
  String get lbl_theme_appearance;

  /// No description provided for @lbl_app_language.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get lbl_app_language;

  /// No description provided for @lbl_delete_account_confirmation.
  ///
  /// In en, this message translates to:
  /// **'Delete your Account?'**
  String get lbl_delete_account_confirmation;

  /// No description provided for @msg_delete_account_warning.
  ///
  /// In en, this message translates to:
  /// **'If you select Delete we will delete your account on our server.\n\nYour app data will also be deleted and you won\'t be able to retrieve it.\n\nSince this is a security-sensitive operation, you eventually are asked to login before your account can be deleted.'**
  String get msg_delete_account_warning;

  /// No description provided for @lbl_delete.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get lbl_delete;

  /// No description provided for @lbl_english_language.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get lbl_english_language;

  /// No description provided for @lbl_arabic_language.
  ///
  /// In en, this message translates to:
  /// **' اَلْعَرَبِيَّة'**
  String get lbl_arabic_language;

  /// No description provided for @lbl_farsi_language.
  ///
  /// In en, this message translates to:
  /// **' فارسی'**
  String get lbl_farsi_language;

  /// No description provided for @lbl_dr_name_format.
  ///
  /// In en, this message translates to:
  /// **'Dr. {name}'**
  String lbl_dr_name_format(Object name);

  /// No description provided for @lbl_university_student_format.
  ///
  /// In en, this message translates to:
  /// **'{university} Student'**
  String lbl_university_student_format(Object university);

  /// No description provided for @lbl_privacy_policy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get lbl_privacy_policy;

  /// No description provided for @lbl_chats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get lbl_chats;

  /// No description provided for @lbl_groups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get lbl_groups;

  /// No description provided for @lbl_typing.
  ///
  /// In en, this message translates to:
  /// **'Typing...'**
  String get lbl_typing;

  /// No description provided for @msg_no_chats.
  ///
  /// In en, this message translates to:
  /// **'No chat found'**
  String get msg_no_chats;

  /// No description provided for @msg_no_internet.
  ///
  /// In en, this message translates to:
  /// **'No Internet connection, please check internet connection'**
  String get msg_no_internet;

  /// No description provided for @msg_chat_error.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong please try again'**
  String get msg_chat_error;

  /// No description provided for @lbl_welcome_title.
  ///
  /// In en, this message translates to:
  /// **'Hello and Welcome'**
  String get lbl_welcome_title;

  /// No description provided for @msg_account_created.
  ///
  /// In en, this message translates to:
  /// **'Your account has been created successfully. Please check your email to verify your account.'**
  String get msg_account_created;

  /// No description provided for @lbl_send_email_again.
  ///
  /// In en, this message translates to:
  /// **'Send email again'**
  String get lbl_send_email_again;

  /// No description provided for @lbl_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get lbl_retry;

  /// No description provided for @lbl_oops.
  ///
  /// In en, this message translates to:
  /// **'Oops!....'**
  String get lbl_oops;

  /// No description provided for @msg_no_internet_connection.
  ///
  /// In en, this message translates to:
  /// **'No Internet connection, Please connect to internet'**
  String get msg_no_internet_connection;

  /// No description provided for @lbl_meeting_detail.
  ///
  /// In en, this message translates to:
  /// **'Meeting Detail'**
  String get lbl_meeting_detail;

  /// No description provided for @lbl_date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get lbl_date;

  /// No description provided for @lbl_time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get lbl_time;

  /// No description provided for @lbl_topic.
  ///
  /// In en, this message translates to:
  /// **'Topic'**
  String get lbl_topic;

  /// No description provided for @lbl_meeting_id.
  ///
  /// In en, this message translates to:
  /// **'Meeting ID'**
  String get lbl_meeting_id;

  /// No description provided for @lbl_join.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get lbl_join;

  /// No description provided for @lbl_information.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get lbl_information;

  /// No description provided for @msg_user_allowed.
  ///
  /// In en, this message translates to:
  /// **'User has been allowed to join'**
  String get msg_user_allowed;

  /// No description provided for @msg_user_rejected.
  ///
  /// In en, this message translates to:
  /// **'User has been rejected from joining'**
  String get msg_user_rejected;

  /// No description provided for @msg_confirm_delete.
  ///
  /// In en, this message translates to:
  /// **'Would you like to Delete?'**
  String get msg_confirm_delete;

  /// No description provided for @lbl_share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get lbl_share;

  /// No description provided for @lbl_end_meeting.
  ///
  /// In en, this message translates to:
  /// **'End Meeting'**
  String get lbl_end_meeting;

  /// No description provided for @msg_confirm_end_call.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to end this call?'**
  String get msg_confirm_end_call;

  /// No description provided for @msg_meeting_code_copied.
  ///
  /// In en, this message translates to:
  /// **'Meeting code copied to clipboard'**
  String get msg_meeting_code_copied;

  /// No description provided for @lbl_send_invitation_link.
  ///
  /// In en, this message translates to:
  /// **'Invitation Link'**
  String get lbl_send_invitation_link;

  /// No description provided for @lbl_setting.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get lbl_setting;

  /// No description provided for @lbl_chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get lbl_chat;

  /// No description provided for @lbl_type_message_here.
  ///
  /// In en, this message translates to:
  /// **'Type message here'**
  String get lbl_type_message_here;

  /// No description provided for @lbl_want_to_join_meeting.
  ///
  /// In en, this message translates to:
  /// **'want to join the meeting ?'**
  String get lbl_want_to_join_meeting;

  /// No description provided for @lbl_you_want_enable_permission.
  ///
  /// In en, this message translates to:
  /// **'You want to enable permission?'**
  String get lbl_you_want_enable_permission;

  /// No description provided for @lbl_camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get lbl_camera;

  /// No description provided for @lbl_microphone.
  ///
  /// In en, this message translates to:
  /// **'Microphone'**
  String get lbl_microphone;

  /// No description provided for @lbl_leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get lbl_leave;

  /// No description provided for @lbl_invite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get lbl_invite;

  /// No description provided for @lbl_create_meeting.
  ///
  /// In en, this message translates to:
  /// **'Create Meeting'**
  String get lbl_create_meeting;

  /// No description provided for @lbl_key_features.
  ///
  /// In en, this message translates to:
  /// **'Key Features'**
  String get lbl_key_features;

  /// No description provided for @msg_enter_meeting_code_description.
  ///
  /// In en, this message translates to:
  /// **'Enter the meeting code provided by the host to join an existing meeting.'**
  String get msg_enter_meeting_code_description;

  /// No description provided for @msg_create_new_meeting_description.
  ///
  /// In en, this message translates to:
  /// **'Create a new meeting and invite participants to join.'**
  String get msg_create_new_meeting_description;

  /// No description provided for @msg_qr_code_scan_implementation.
  ///
  /// In en, this message translates to:
  /// **'QR code scanning would be implemented here'**
  String get msg_qr_code_scan_implementation;

  /// No description provided for @lbl_hd_video.
  ///
  /// In en, this message translates to:
  /// **'HD Video'**
  String get lbl_hd_video;

  /// No description provided for @desc_hd_video.
  ///
  /// In en, this message translates to:
  /// **'High quality video & audio for clear communication'**
  String get desc_hd_video;

  /// No description provided for @lbl_unlimited_participants.
  ///
  /// In en, this message translates to:
  /// **'Unlimited Participants'**
  String get lbl_unlimited_participants;

  /// No description provided for @desc_unlimited_participants.
  ///
  /// In en, this message translates to:
  /// **'Host meetings with any number of participants'**
  String get desc_unlimited_participants;

  /// No description provided for @lbl_screen_sharing.
  ///
  /// In en, this message translates to:
  /// **'Screen Sharing'**
  String get lbl_screen_sharing;

  /// No description provided for @desc_screen_sharing.
  ///
  /// In en, this message translates to:
  /// **'Share your screen with meeting participants'**
  String get desc_screen_sharing;

  /// No description provided for @lbl_group_chat.
  ///
  /// In en, this message translates to:
  /// **'Group Chat'**
  String get lbl_group_chat;

  /// No description provided for @desc_group_chat.
  ///
  /// In en, this message translates to:
  /// **'Send messages to everyone during the meeting'**
  String get desc_group_chat;

  /// No description provided for @lbl_create_group_wizard.
  ///
  /// In en, this message translates to:
  /// **'Create Group'**
  String get lbl_create_group_wizard;

  /// No description provided for @lbl_basic_info.
  ///
  /// In en, this message translates to:
  /// **'Basic Info'**
  String get lbl_basic_info;

  /// No description provided for @lbl_privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get lbl_privacy;

  /// No description provided for @lbl_image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get lbl_image;

  /// No description provided for @lbl_finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get lbl_finish;

  /// No description provided for @lbl_about_us.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get lbl_about_us;

  /// No description provided for @lbl_medical_ai.
  ///
  /// In en, this message translates to:
  /// **'DocTak AI'**
  String get lbl_medical_ai;

  /// No description provided for @desc_medical_ai.
  ///
  /// In en, this message translates to:
  /// **'AI medical assistant'**
  String get desc_medical_ai;

  /// No description provided for @lbl_case_discussion.
  ///
  /// In en, this message translates to:
  /// **'Case Discussion'**
  String get lbl_case_discussion;

  /// No description provided for @lbl_post_poll.
  ///
  /// In en, this message translates to:
  /// **'Post a poll'**
  String get lbl_post_poll;

  /// No description provided for @lbl_groups_formation.
  ///
  /// In en, this message translates to:
  /// **'Groups Formation'**
  String get lbl_groups_formation;

  /// No description provided for @lbl_meeting.
  ///
  /// In en, this message translates to:
  /// **'Meeting'**
  String get lbl_meeting;

  /// No description provided for @lbl_search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get lbl_search;

  /// No description provided for @lbl_add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get lbl_add;

  /// No description provided for @lbl_ai.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get lbl_ai;

  /// No description provided for @lbl_images.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get lbl_images;

  /// No description provided for @lbl_yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get lbl_yes;

  /// No description provided for @msg_confirm_logout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get msg_confirm_logout;

  /// No description provided for @lbl_better_health_solutions.
  ///
  /// In en, this message translates to:
  /// **'Better Health Solutions'**
  String get lbl_better_health_solutions;

  /// No description provided for @msg_health_mission.
  ///
  /// In en, this message translates to:
  /// **'Our mission is to provide accessible and affordable healthcare to everyone.'**
  String get msg_health_mission;

  /// No description provided for @lbl_our_mission.
  ///
  /// In en, this message translates to:
  /// **'Our Mission'**
  String get lbl_our_mission;

  /// No description provided for @lbl_who_we_are.
  ///
  /// In en, this message translates to:
  /// **'Who We Are'**
  String get lbl_who_we_are;

  /// No description provided for @lbl_what_we_offer.
  ///
  /// In en, this message translates to:
  /// **'What We Offer'**
  String get lbl_what_we_offer;

  /// No description provided for @lbl_our_vision.
  ///
  /// In en, this message translates to:
  /// **'Our Vision'**
  String get lbl_our_vision;

  /// No description provided for @lbl_case_discussion_title.
  ///
  /// In en, this message translates to:
  /// **'Case Discussion'**
  String get lbl_case_discussion_title;

  /// No description provided for @lbl_our_values.
  ///
  /// In en, this message translates to:
  /// **'Our Values'**
  String get lbl_our_values;

  /// No description provided for @lbl_ai_diagnostic.
  ///
  /// In en, this message translates to:
  /// **'How AI Supports Differential Diagnostic'**
  String get lbl_ai_diagnostic;

  /// No description provided for @lbl_join_us.
  ///
  /// In en, this message translates to:
  /// **'Join Us'**
  String get lbl_join_us;

  /// No description provided for @lbl_contact_follow_us.
  ///
  /// In en, this message translates to:
  /// **'Contact / Follow Us Here:'**
  String get lbl_contact_follow_us;

  /// No description provided for @lbl_job_opportunities.
  ///
  /// In en, this message translates to:
  /// **'Job Opportunities'**
  String get lbl_job_opportunities;

  /// No description provided for @lbl_professional_networking.
  ///
  /// In en, this message translates to:
  /// **'Professional Networking'**
  String get lbl_professional_networking;

  /// No description provided for @lbl_drug_list_specific.
  ///
  /// In en, this message translates to:
  /// **'Country-Specific Drug List'**
  String get lbl_drug_list_specific;

  /// No description provided for @lbl_medical_conferences.
  ///
  /// In en, this message translates to:
  /// **'Medical Conferences'**
  String get lbl_medical_conferences;

  /// No description provided for @lbl_medical_guidelines.
  ///
  /// In en, this message translates to:
  /// **'Medical Guidelines'**
  String get lbl_medical_guidelines;

  /// No description provided for @lbl_ai_features.
  ///
  /// In en, this message translates to:
  /// **'AI-Powered Features'**
  String get lbl_ai_features;

  /// No description provided for @lbl_cme_full.
  ///
  /// In en, this message translates to:
  /// **'Continuing Medical Education (CME)'**
  String get lbl_cme_full;

  /// No description provided for @lbl_moh_updates_notifications.
  ///
  /// In en, this message translates to:
  /// **'Ministry of Health Updates & Notifications'**
  String get lbl_moh_updates_notifications;

  /// No description provided for @lbl_differential_diagnosis.
  ///
  /// In en, this message translates to:
  /// **'Differential Diagnosis'**
  String get lbl_differential_diagnosis;

  /// No description provided for @html_our_mission.
  ///
  /// In en, this message translates to:
  /// **'<p align=\'center\'>At Doctak, Our mission is to create a comprehensive & innovative social network for doctors & medical students worldwide. We strive to connect medical professionals, provide valuable resource, and faster collaboration and knowledge sharing across the healthcare community.</p>'**
  String get html_our_mission;

  /// No description provided for @html_who_we_are.
  ///
  /// In en, this message translates to:
  /// **'<p align=\'center\'>Doctak.net is a cutting-edge platform designed specifically for doctors. Our team consists of healthcare professionals, tech enthusiasts, and industry experts who are passionate about revolutionizing the way doctors interact and access information.</p>'**
  String get html_who_we_are;

  /// No description provided for @html_what_we_offer.
  ///
  /// In en, this message translates to:
  /// **'<h4 align=\'center\'>Job Opportunities</h4><p align=\'center\'>Explore the latest job opening across the Middle East and India, with plans to expand globally.</p><h4 align=\'center\'>Professional Networking</h4><p align=\'center\'>Connect with peers, form groups, and discuss medical cases.</p><h4 align=\'center\'>Country-Specific Drug List</h4><p align=\'center\'>Access comprehensive drug information tailored to each country.</p><h4 align=\'center\'>Medical Conferences</h4><p align=\'center\'>Stay updated on conferences worldwide and never miss an important event.</p><h4 align=\'center\'>Medical Guidelines</h4><p align=\'center\'>Access the latest medical guidelines to stay informed on best practices and treatment protocols.</p><h4 align=\'center\'>AI-Powered Features</h4><p align=\'center\'>Utilize the latest in artificial intelligence to enhance your medical practice.</p><h4 align=\'center\'>Continuing Medical Education (CME)</h4><p align=\'center\'>Earn CME credits and keep your knowledge up-to-date.</p><h4 align=\'center\'>Ministry of Health Updates & Notifications</h4><p align=\'center\'>Receive timely updates and notifications from ministries of health in your concerned country.</p><h4 align=\'center\'>Differential Diagnosis</h4><p align=\'center\'>Utilize advanced artificial intelligence to aid in accurate differential diagnosis, enhancing diagnostic precision and efficiency.</p>'**
  String get html_what_we_offer;

  /// No description provided for @html_our_vision.
  ///
  /// In en, this message translates to:
  /// **'<p align=\'center\'>We envision a world where doctors are seamlessly connected, empowered with the latest technology, and have access to a wealth of resources that support their professional growth and improve patient care.</p>'**
  String get html_our_vision;

  /// No description provided for @html_case_discussion.
  ///
  /// In en, this message translates to:
  /// **'<p align=\'center\'>Engage in in-depth discussions on medical cases with your peers, leveraging AI insights to explore differential diagnoses and treatment strategies collaboratively.</p>'**
  String get html_case_discussion;

  /// No description provided for @html_our_values.
  ///
  /// In en, this message translates to:
  /// **'<p align=\'center\'>We are committed to ethical practices and delivering high-quality healthcare.</p>'**
  String get html_our_values;

  /// No description provided for @html_ai_diagnostic.
  ///
  /// In en, this message translates to:
  /// **'<p align=\'center\'>At Doctak, we leverage advanced artificial intelligence technologies to support doctors in making accurate and timely differential diagnoses. Our AI algorithms analyze the given patient data, symptoms, and medical histories to generate insights and suggest potential diagnoses. This assists healthcare professionals in make informed decisions and improving patient care outcomes.</p>'**
  String get html_ai_diagnostic;

  /// No description provided for @html_join_us.
  ///
  /// In en, this message translates to:
  /// **'<p align=\'center\'>Be a part of the Doctak community and experience a new era of medical networking and resources. Together, we can advance the field of medicine and improve healthcare outcomes worldwide. Thank You for choosing Doctak.net!</p>'**
  String get html_join_us;

  /// No description provided for @lbl_name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get lbl_name;

  /// No description provided for @lbl_submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get lbl_submit;

  /// No description provided for @lbl_open_whatsapp.
  ///
  /// In en, this message translates to:
  /// **'Open WhatsApp'**
  String get lbl_open_whatsapp;

  /// No description provided for @lbl_ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get lbl_ok;

  /// No description provided for @msg_suggestion_thank_you.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your suggestions.'**
  String get msg_suggestion_thank_you;

  /// No description provided for @msg_please_enter_name.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get msg_please_enter_name;

  /// No description provided for @msg_please_enter_phone.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get msg_please_enter_phone;

  /// No description provided for @msg_please_enter_email.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get msg_please_enter_email;

  /// No description provided for @msg_please_enter_message.
  ///
  /// In en, this message translates to:
  /// **'Please enter your message'**
  String get msg_please_enter_message;

  /// No description provided for @msg_need_more_help.
  ///
  /// In en, this message translates to:
  /// **'Need More Help?'**
  String get msg_need_more_help;

  /// No description provided for @msg_connect_on_whatsapp.
  ///
  /// In en, this message translates to:
  /// **' Connect on WhatsApp'**
  String get msg_connect_on_whatsapp;

  /// No description provided for @msg_open_whatsapp_confirm.
  ///
  /// In en, this message translates to:
  /// **'Would you like to open WhatsApp to send a message?'**
  String get msg_open_whatsapp_confirm;

  /// No description provided for @lbl_bbc_news.
  ///
  /// In en, this message translates to:
  /// **'BBC News'**
  String get lbl_bbc_news;

  /// No description provided for @lbl_cnn_news.
  ///
  /// In en, this message translates to:
  /// **'CNN News'**
  String get lbl_cnn_news;

  /// No description provided for @lbl_open_link.
  ///
  /// In en, this message translates to:
  /// **'Open Link'**
  String get lbl_open_link;

  /// No description provided for @lbl_open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get lbl_open;

  /// No description provided for @msg_no_news_found.
  ///
  /// In en, this message translates to:
  /// **'No News found'**
  String get msg_no_news_found;

  /// No description provided for @msg_open_link_confirm.
  ///
  /// In en, this message translates to:
  /// **'Would you like to open this link?'**
  String get msg_open_link_confirm;

  /// No description provided for @msg_leaving_app_canceled.
  ///
  /// In en, this message translates to:
  /// **'Leaving the app canceled.'**
  String get msg_leaving_app_canceled;

  /// No description provided for @msg_could_not_launch.
  ///
  /// In en, this message translates to:
  /// **'Could not launch'**
  String get msg_could_not_launch;

  /// No description provided for @lbl_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get lbl_loading;

  /// No description provided for @lbl_search_by_specialty.
  ///
  /// In en, this message translates to:
  /// **'Search by Specialty'**
  String get lbl_search_by_specialty;

  /// No description provided for @msg_no_jobs_found.
  ///
  /// In en, this message translates to:
  /// **'No Jobs Found'**
  String get msg_no_jobs_found;

  /// No description provided for @lbl_job_detail.
  ///
  /// In en, this message translates to:
  /// **'Job Detail'**
  String get lbl_job_detail;

  /// No description provided for @lbl_apply_date.
  ///
  /// In en, this message translates to:
  /// **'Apply Date'**
  String get lbl_apply_date;

  /// No description provided for @lbl_date_from.
  ///
  /// In en, this message translates to:
  /// **'Date From'**
  String get lbl_date_from;

  /// No description provided for @lbl_date_to.
  ///
  /// In en, this message translates to:
  /// **'Date To'**
  String get lbl_date_to;

  /// No description provided for @lbl_leave_app.
  ///
  /// In en, this message translates to:
  /// **'Leave App'**
  String get lbl_leave_app;

  /// No description provided for @lbl_brand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get lbl_brand;

  /// No description provided for @lbl_generic.
  ///
  /// In en, this message translates to:
  /// **'Generic'**
  String get lbl_generic;

  /// No description provided for @lbl_price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get lbl_price;

  /// No description provided for @lbl_manufacturer_name.
  ///
  /// In en, this message translates to:
  /// **'Manufacturer Name'**
  String get lbl_manufacturer_name;

  /// No description provided for @lbl_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get lbl_close;

  /// No description provided for @msg_no_drugs_found.
  ///
  /// In en, this message translates to:
  /// **'No Drugs Found'**
  String get msg_no_drugs_found;

  /// No description provided for @lbl_search_drug.
  ///
  /// In en, this message translates to:
  /// **'Search Drug'**
  String get lbl_search_drug;

  /// No description provided for @lbl_no_drugs_available.
  ///
  /// In en, this message translates to:
  /// **'No Drugs Available'**
  String get lbl_no_drugs_available;

  /// No description provided for @lbl_no_search_results.
  ///
  /// In en, this message translates to:
  /// **'Your search results did not find any drugs'**
  String get lbl_no_search_results;

  /// No description provided for @err_drug_load_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load drug list. Please try again'**
  String get err_drug_load_failed;

  /// No description provided for @lbl_search_conferences.
  ///
  /// In en, this message translates to:
  /// **'Search Conferences'**
  String get lbl_search_conferences;

  /// No description provided for @lbl_city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get lbl_city;

  /// No description provided for @lbl_venue.
  ///
  /// In en, this message translates to:
  /// **'Venue'**
  String get lbl_venue;

  /// No description provided for @lbl_organizer.
  ///
  /// In en, this message translates to:
  /// **'Organizer'**
  String get lbl_organizer;

  /// No description provided for @lbl_cme_credits.
  ///
  /// In en, this message translates to:
  /// **'CME Credits'**
  String get lbl_cme_credits;

  /// No description provided for @lbl_moc_credits.
  ///
  /// In en, this message translates to:
  /// **'MOC Credits'**
  String get lbl_moc_credits;

  /// No description provided for @lbl_specialties_targeted.
  ///
  /// In en, this message translates to:
  /// **'Specialties Targeted'**
  String get lbl_specialties_targeted;

  /// No description provided for @lbl_register_now.
  ///
  /// In en, this message translates to:
  /// **'Register Now'**
  String get lbl_register_now;

  /// No description provided for @lbl_not_available.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get lbl_not_available;

  /// No description provided for @lbl_registration_unavailable.
  ///
  /// In en, this message translates to:
  /// **'Registration unavailable'**
  String get lbl_registration_unavailable;

  /// No description provided for @msg_something_went_wrong_retry.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong please try again'**
  String get msg_something_went_wrong_retry;

  /// No description provided for @msg_no_conference_found.
  ///
  /// In en, this message translates to:
  /// **'No Conference Found'**
  String get msg_no_conference_found;

  /// No description provided for @msg_image_not_available.
  ///
  /// In en, this message translates to:
  /// **'Image not available'**
  String get msg_image_not_available;

  /// No description provided for @msg_no_description.
  ///
  /// In en, this message translates to:
  /// **'No Description Available'**
  String get msg_no_description;

  /// No description provided for @lbl_download_pdf.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get lbl_download_pdf;

  /// No description provided for @lbl_see_more.
  ///
  /// In en, this message translates to:
  /// **'See More'**
  String get lbl_see_more;

  /// No description provided for @msg_error_occurred.
  ///
  /// In en, this message translates to:
  /// **'Error: {errorMessage}'**
  String msg_error_occurred(String errorMessage);

  /// No description provided for @lbl_dr_prefix.
  ///
  /// In en, this message translates to:
  /// **'Dr. '**
  String get lbl_dr_prefix;

  /// No description provided for @lbl_student_suffix.
  ///
  /// In en, this message translates to:
  /// **' Student'**
  String get lbl_student_suffix;

  /// No description provided for @lbl_text_copied.
  ///
  /// In en, this message translates to:
  /// **'Text copied to clipboard'**
  String get lbl_text_copied;

  /// No description provided for @lbl_show_less.
  ///
  /// In en, this message translates to:
  /// **'Show Less'**
  String get lbl_show_less;

  /// No description provided for @lbl_show_more.
  ///
  /// In en, this message translates to:
  /// **'Show More'**
  String get lbl_show_more;

  /// No description provided for @lbl_likes_count.
  ///
  /// In en, this message translates to:
  /// **'{count} Likes'**
  String lbl_likes_count(int count);

  /// No description provided for @lbl_comments_count.
  ///
  /// In en, this message translates to:
  /// **'{count} Comments'**
  String lbl_comments_count(int count);

  /// No description provided for @lbl_like.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get lbl_like;

  /// No description provided for @lbl_comment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get lbl_comment;

  /// No description provided for @lbl_send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get lbl_send;

  /// No description provided for @lbl_likes.
  ///
  /// In en, this message translates to:
  /// **'likes'**
  String get lbl_likes;

  /// No description provided for @lbl_comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get lbl_comments;

  /// No description provided for @msg_downloaded_to.
  ///
  /// In en, this message translates to:
  /// **'Downloaded to'**
  String get msg_downloaded_to;

  /// No description provided for @msg_error_downloading.
  ///
  /// In en, this message translates to:
  /// **'Error occurred while downloading.'**
  String get msg_error_downloading;

  /// No description provided for @msg_permission_denied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied'**
  String get msg_permission_denied;

  /// No description provided for @msg_no_posts.
  ///
  /// In en, this message translates to:
  /// **'No posts found'**
  String get msg_no_posts;

  /// No description provided for @msg_confirm_delete_post.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this post?'**
  String get msg_confirm_delete_post;

  /// No description provided for @lbl_search_post.
  ///
  /// In en, this message translates to:
  /// **'Search Post'**
  String get lbl_search_post;

  /// No description provided for @lbl_android.
  ///
  /// In en, this message translates to:
  /// **'android'**
  String get lbl_android;

  /// No description provided for @lbl_ios.
  ///
  /// In en, this message translates to:
  /// **'ios'**
  String get lbl_ios;

  /// No description provided for @lbl_new_post.
  ///
  /// In en, this message translates to:
  /// **'New Post'**
  String get lbl_new_post;

  /// No description provided for @lbl_post.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get lbl_post;

  /// No description provided for @lbl_from_gallery.
  ///
  /// In en, this message translates to:
  /// **'From Gallery'**
  String get lbl_from_gallery;

  /// No description provided for @lbl_take_video.
  ///
  /// In en, this message translates to:
  /// **'Take Video'**
  String get lbl_take_video;

  /// No description provided for @lbl_take_picture.
  ///
  /// In en, this message translates to:
  /// **'Take Picture'**
  String get lbl_take_picture;

  /// No description provided for @lbl_whats_on_your_mind.
  ///
  /// In en, this message translates to:
  /// **'What\'s on your mind'**
  String get lbl_whats_on_your_mind;

  /// No description provided for @lbl_tag_friends.
  ///
  /// In en, this message translates to:
  /// **'Tag Friends:'**
  String get lbl_tag_friends;

  /// No description provided for @msg_unsupported_file.
  ///
  /// In en, this message translates to:
  /// **'Unsupported file type'**
  String get msg_unsupported_file;

  /// No description provided for @msg_verification_link_sent_success.
  ///
  /// In en, this message translates to:
  /// **'Verification link sent successfully'**
  String get msg_verification_link_sent_success;

  /// No description provided for @msg_verify_email_continue.
  ///
  /// In en, this message translates to:
  /// **'Please verify your email to continue'**
  String get msg_verify_email_continue;

  /// No description provided for @lbl_verify_email.
  ///
  /// In en, this message translates to:
  /// **'VERIFY EMAIL'**
  String get lbl_verify_email;

  /// No description provided for @msg_profile_incomplete.
  ///
  /// In en, this message translates to:
  /// **'Your profile is incomplete'**
  String get msg_profile_incomplete;

  /// No description provided for @msg_complete_following.
  ///
  /// In en, this message translates to:
  /// **'Please complete the following fields'**
  String get msg_complete_following;

  /// No description provided for @lbl_set_country.
  ///
  /// In en, this message translates to:
  /// **'Set Country'**
  String get lbl_set_country;

  /// No description provided for @lbl_set_state.
  ///
  /// In en, this message translates to:
  /// **'Set State'**
  String get lbl_set_state;

  /// No description provided for @lbl_set_specialty.
  ///
  /// In en, this message translates to:
  /// **'Set Specialty'**
  String get lbl_set_specialty;

  /// No description provided for @lbl_complete_profile.
  ///
  /// In en, this message translates to:
  /// **'COMPLETE PROFILE'**
  String get lbl_complete_profile;

  /// No description provided for @msg_confirm_delete_comment.
  ///
  /// In en, this message translates to:
  /// **'Are you sure want to delete comment?'**
  String get msg_confirm_delete_comment;

  /// No description provided for @lbl_no_name.
  ///
  /// In en, this message translates to:
  /// **'No Name'**
  String get lbl_no_name;

  /// No description provided for @lbl_reply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get lbl_reply;

  /// No description provided for @lbl_liked.
  ///
  /// In en, this message translates to:
  /// **'Liked'**
  String get lbl_liked;

  /// No description provided for @lbl_write_a_comment.
  ///
  /// In en, this message translates to:
  /// **'Write a comment'**
  String get lbl_write_a_comment;

  /// No description provided for @msg_no_comments.
  ///
  /// In en, this message translates to:
  /// **'No comments'**
  String get msg_no_comments;

  /// No description provided for @lbl_people_who_likes.
  ///
  /// In en, this message translates to:
  /// **'People who likes'**
  String get lbl_people_who_likes;

  /// No description provided for @msg_no_likes.
  ///
  /// In en, this message translates to:
  /// **'No Likes'**
  String get msg_no_likes;

  /// No description provided for @lbl_write_something.
  ///
  /// In en, this message translates to:
  /// **'Write something here...'**
  String get lbl_write_something;

  /// No description provided for @lbl_share_now.
  ///
  /// In en, this message translates to:
  /// **'Share Now'**
  String get lbl_share_now;

  /// No description provided for @lbl_send_in_messenger.
  ///
  /// In en, this message translates to:
  /// **'Send in Messenger'**
  String get lbl_send_in_messenger;

  /// No description provided for @lbl_instagram.
  ///
  /// In en, this message translates to:
  /// **'Instagram'**
  String get lbl_instagram;

  /// No description provided for @lbl_twitter.
  ///
  /// In en, this message translates to:
  /// **'Twitter'**
  String get lbl_twitter;

  /// No description provided for @lbl_copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get lbl_copy;

  /// No description provided for @lbl_expand.
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get lbl_expand;

  /// No description provided for @lbl_collapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get lbl_collapse;

  /// No description provided for @lbl_search_peoples.
  ///
  /// In en, this message translates to:
  /// **'Search Peoples'**
  String get lbl_search_peoples;

  /// No description provided for @lbl_search_people.
  ///
  /// In en, this message translates to:
  /// **'Search People'**
  String get lbl_search_people;

  /// No description provided for @lbl_privacy_information.
  ///
  /// In en, this message translates to:
  /// **'Privacy Information'**
  String get lbl_privacy_information;

  /// No description provided for @lbl_interest_information.
  ///
  /// In en, this message translates to:
  /// **'Interest Information'**
  String get lbl_interest_information;

  /// No description provided for @lbl_professional_summary.
  ///
  /// In en, this message translates to:
  /// **'Professional Summary'**
  String get lbl_professional_summary;

  /// No description provided for @lbl_professional_experience.
  ///
  /// In en, this message translates to:
  /// **'Professional Experience'**
  String get lbl_professional_experience;

  /// No description provided for @lbl_title_and_specialization.
  ///
  /// In en, this message translates to:
  /// **'Title and Specialization'**
  String get lbl_title_and_specialization;

  /// No description provided for @lbl_current_workplace.
  ///
  /// In en, this message translates to:
  /// **'Current Workplace'**
  String get lbl_current_workplace;

  /// No description provided for @lbl_years_experience.
  ///
  /// In en, this message translates to:
  /// **'Years of Experience'**
  String get lbl_years_experience;

  /// No description provided for @lbl_notable_achievements.
  ///
  /// In en, this message translates to:
  /// **'Notable Achievements'**
  String get lbl_notable_achievements;

  /// No description provided for @lbl_location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get lbl_location;

  /// No description provided for @hint_workplace.
  ///
  /// In en, this message translates to:
  /// **'Name Hospital/Clinic/Organization/Private Practice'**
  String get hint_workplace;

  /// No description provided for @hint_years_experience.
  ///
  /// In en, this message translates to:
  /// **'Years of experience'**
  String get hint_years_experience;

  /// No description provided for @hint_notable_achievements.
  ///
  /// In en, this message translates to:
  /// **'e.g Doctor of the year'**
  String get hint_notable_achievements;

  /// No description provided for @hint_location.
  ///
  /// In en, this message translates to:
  /// **'Enter location (e.g., KSA, UAE)'**
  String get hint_location;

  /// No description provided for @lbl_specialty_area.
  ///
  /// In en, this message translates to:
  /// **'Speciality/Area of practice'**
  String get lbl_specialty_area;

  /// No description provided for @lbl_position_role.
  ///
  /// In en, this message translates to:
  /// **'Position/Role'**
  String get lbl_position_role;

  /// No description provided for @lbl_hospital_clinic_name.
  ///
  /// In en, this message translates to:
  /// **'Hospital/Clinic Name'**
  String get lbl_hospital_clinic_name;

  /// No description provided for @hint_hospital_name.
  ///
  /// In en, this message translates to:
  /// **'Enter Hospital/clinic name'**
  String get hint_hospital_name;

  /// No description provided for @lbl_degree.
  ///
  /// In en, this message translates to:
  /// **'Degree'**
  String get lbl_degree;

  /// No description provided for @lbl_courses.
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get lbl_courses;

  /// No description provided for @lbl_start_date.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get lbl_start_date;

  /// No description provided for @lbl_end_date.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get lbl_end_date;

  /// No description provided for @msg_confirm_delete_info.
  ///
  /// In en, this message translates to:
  /// **'Are you sure want to delete Info?'**
  String get msg_confirm_delete_info;

  /// No description provided for @lbl_no_interest_added.
  ///
  /// In en, this message translates to:
  /// **'No Interest Added'**
  String get lbl_no_interest_added;

  /// No description provided for @lbl_no_experience_found.
  ///
  /// In en, this message translates to:
  /// **'No Experience found'**
  String get lbl_no_experience_found;

  /// No description provided for @lbl_only_me.
  ///
  /// In en, this message translates to:
  /// **'Only me'**
  String get lbl_only_me;

  /// No description provided for @lbl_friends.
  ///
  /// In en, this message translates to:
  /// **'Friend'**
  String get lbl_friends;

  /// No description provided for @lbl_public.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get lbl_public;

  /// No description provided for @lbl_areas_of_interest.
  ///
  /// In en, this message translates to:
  /// **'Areas of Interest'**
  String get lbl_areas_of_interest;

  /// No description provided for @lbl_conferences_participation.
  ///
  /// In en, this message translates to:
  /// **'Participation in Conferences and Workshops'**
  String get lbl_conferences_participation;

  /// No description provided for @lbl_research_projects.
  ///
  /// In en, this message translates to:
  /// **'Research Projects'**
  String get lbl_research_projects;

  /// No description provided for @hint_areas_of_interest.
  ///
  /// In en, this message translates to:
  /// **'Areas of Interest (Specific fields of medicine, research interests)'**
  String get hint_areas_of_interest;

  /// No description provided for @hint_publications.
  ///
  /// In en, this message translates to:
  /// **'Publications (Research papers, articles)'**
  String get hint_publications;

  /// No description provided for @hint_clinical_trials.
  ///
  /// In en, this message translates to:
  /// **'Clinical Trials...'**
  String get hint_clinical_trials;

  /// No description provided for @lbl_interest_details.
  ///
  /// In en, this message translates to:
  /// **'Interest Details'**
  String get lbl_interest_details;

  /// No description provided for @lbl_your_earned_points.
  ///
  /// In en, this message translates to:
  /// **'Your Earned Points'**
  String get lbl_your_earned_points;

  /// No description provided for @lbl_posts.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get lbl_posts;

  /// No description provided for @lbl_followers.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get lbl_followers;

  /// No description provided for @lbl_followings.
  ///
  /// In en, this message translates to:
  /// **'Followings'**
  String get lbl_followings;

  /// No description provided for @lbl_follow.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get lbl_follow;

  /// No description provided for @lbl_following.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get lbl_following;

  /// No description provided for @lbl_choose_from_gallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get lbl_choose_from_gallery;

  /// No description provided for @lbl_take_a_picture.
  ///
  /// In en, this message translates to:
  /// **'Take a picture'**
  String get lbl_take_a_picture;

  /// No description provided for @lbl_unknown_state.
  ///
  /// In en, this message translates to:
  /// **'Unknown state'**
  String get lbl_unknown_state;

  /// No description provided for @lbl_add_interests.
  ///
  /// In en, this message translates to:
  /// **'Add Interests'**
  String get lbl_add_interests;

  /// No description provided for @msg_add_interests.
  ///
  /// In en, this message translates to:
  /// **'Add interests to showcase your professional focus and connect with colleagues in similar fields.'**
  String get msg_add_interests;

  /// No description provided for @msg_no_details_added.
  ///
  /// In en, this message translates to:
  /// **'No details added'**
  String get msg_no_details_added;

  /// No description provided for @msg_interests_updated.
  ///
  /// In en, this message translates to:
  /// **'Interests updated successfully'**
  String get msg_interests_updated;

  /// No description provided for @msg_privacy_info_desc.
  ///
  /// In en, this message translates to:
  /// **'Manage who can see your profile information. Your privacy settings help you control your personal information visibility.'**
  String get msg_privacy_info_desc;

  /// No description provided for @lbl_personal_info_privacy.
  ///
  /// In en, this message translates to:
  /// **'Personal Info Privacy'**
  String get lbl_personal_info_privacy;

  /// No description provided for @lbl_professional_info_privacy.
  ///
  /// In en, this message translates to:
  /// **'Professional Info Privacy'**
  String get lbl_professional_info_privacy;

  /// No description provided for @lbl_location_info_privacy.
  ///
  /// In en, this message translates to:
  /// **'Location Info Privacy'**
  String get lbl_location_info_privacy;

  /// No description provided for @lbl_other_info_privacy.
  ///
  /// In en, this message translates to:
  /// **'Other Info Privacy'**
  String get lbl_other_info_privacy;

  /// No description provided for @msg_privacy_settings_updated.
  ///
  /// In en, this message translates to:
  /// **'Privacy settings updated successfully'**
  String get msg_privacy_settings_updated;

  /// No description provided for @lbl_specialty_info.
  ///
  /// In en, this message translates to:
  /// **'Specialty Information'**
  String get lbl_specialty_info;

  /// No description provided for @lbl_workplace_info.
  ///
  /// In en, this message translates to:
  /// **'Workplace Information'**
  String get lbl_workplace_info;

  /// No description provided for @lbl_achievements_and_location.
  ///
  /// In en, this message translates to:
  /// **'Achievements & Location'**
  String get lbl_achievements_and_location;

  /// No description provided for @msg_professional_info_desc.
  ///
  /// In en, this message translates to:
  /// **'This information helps showcase your professional expertise and connect you with relevant opportunities in your field.'**
  String get msg_professional_info_desc;

  /// No description provided for @lbl_add_experience_details.
  ///
  /// In en, this message translates to:
  /// **'Add Experience Details'**
  String get lbl_add_experience_details;

  /// No description provided for @lbl_update_experience_details.
  ///
  /// In en, this message translates to:
  /// **'Update Experience Details'**
  String get lbl_update_experience_details;

  /// No description provided for @msg_experience_updated.
  ///
  /// In en, this message translates to:
  /// **'Experience updated successfully'**
  String get msg_experience_updated;

  /// No description provided for @msg_experience_added.
  ///
  /// In en, this message translates to:
  /// **'Experience added successfully'**
  String get msg_experience_added;

  /// No description provided for @msg_required_field.
  ///
  /// In en, this message translates to:
  /// **'Required field'**
  String get msg_required_field;

  /// No description provided for @lbl_meeting_topic.
  ///
  /// In en, this message translates to:
  /// **'Meeting Topic'**
  String get lbl_meeting_topic;

  /// No description provided for @lbl_meeting_title.
  ///
  /// In en, this message translates to:
  /// **'Meeting Title'**
  String get lbl_meeting_title;

  /// No description provided for @lbl_meeting_code.
  ///
  /// In en, this message translates to:
  /// **'Meeting Code'**
  String get lbl_meeting_code;

  /// No description provided for @lbl_meeting_management.
  ///
  /// In en, this message translates to:
  /// **'Meeting Management'**
  String get lbl_meeting_management;

  /// No description provided for @lbl_meeting_information.
  ///
  /// In en, this message translates to:
  /// **'Meeting Information'**
  String get lbl_meeting_information;

  /// No description provided for @lbl_settings_host_controls.
  ///
  /// In en, this message translates to:
  /// **'Settings & Host Controls'**
  String get lbl_settings_host_controls;

  /// No description provided for @lbl_schedule.
  ///
  /// In en, this message translates to:
  /// **'SCHEDULE'**
  String get lbl_schedule;

  /// No description provided for @lbl_schedule_meeting.
  ///
  /// In en, this message translates to:
  /// **'Schedule Meeting'**
  String get lbl_schedule_meeting;

  /// No description provided for @lbl_create_instant_meeting.
  ///
  /// In en, this message translates to:
  /// **'Create Instant Meeting'**
  String get lbl_create_instant_meeting;

  /// No description provided for @lbl_join_meeting.
  ///
  /// In en, this message translates to:
  /// **'Join Meeting'**
  String get lbl_join_meeting;

  /// No description provided for @lbl_channel_name.
  ///
  /// In en, this message translates to:
  /// **'Channel Name'**
  String get lbl_channel_name;

  /// No description provided for @lbl_join_create.
  ///
  /// In en, this message translates to:
  /// **'Join/Create'**
  String get lbl_join_create;

  /// No description provided for @lbl_scheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get lbl_scheduled;

  /// No description provided for @lbl_history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get lbl_history;

  /// No description provided for @lbl_recordings.
  ///
  /// In en, this message translates to:
  /// **'Recordings'**
  String get lbl_recordings;

  /// No description provided for @lbl_set_schedule.
  ///
  /// In en, this message translates to:
  /// **'Set Schedule'**
  String get lbl_set_schedule;

  /// No description provided for @lbl_upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get lbl_upcoming;

  /// No description provided for @lbl_search_friends.
  ///
  /// In en, this message translates to:
  /// **'Search Friends'**
  String get lbl_search_friends;

  /// No description provided for @lbl_search_by_name_or_email.
  ///
  /// In en, this message translates to:
  /// **'Search by name or email'**
  String get lbl_search_by_name_or_email;

  /// No description provided for @lbl_send_invite.
  ///
  /// In en, this message translates to:
  /// **'Send Invite'**
  String get lbl_send_invite;

  /// No description provided for @lbl_joining.
  ///
  /// In en, this message translates to:
  /// **'Joining'**
  String get lbl_joining;

  /// No description provided for @lbl_create_instead.
  ///
  /// In en, this message translates to:
  /// **'Create Instead'**
  String get lbl_create_instead;

  /// No description provided for @lbl_join_instead.
  ///
  /// In en, this message translates to:
  /// **'Join Instead'**
  String get lbl_join_instead;

  /// No description provided for @lbl_start_meeting.
  ///
  /// In en, this message translates to:
  /// **'Start Meeting'**
  String get lbl_start_meeting;

  /// No description provided for @lbl_scan_qr_code.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get lbl_scan_qr_code;

  /// No description provided for @lbl_details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get lbl_details;

  /// No description provided for @lbl_30_minutes.
  ///
  /// In en, this message translates to:
  /// **'30 minutes'**
  String get lbl_30_minutes;

  /// No description provided for @lbl_1_hour.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get lbl_1_hour;

  /// No description provided for @lbl_1_5_hours.
  ///
  /// In en, this message translates to:
  /// **'1.5 hours'**
  String get lbl_1_5_hours;

  /// No description provided for @lbl_2_hours.
  ///
  /// In en, this message translates to:
  /// **'2 hours'**
  String get lbl_2_hours;

  /// No description provided for @hint_enter_meeting_code.
  ///
  /// In en, this message translates to:
  /// **'Enter meeting code'**
  String get hint_enter_meeting_code;

  /// No description provided for @hint_enter_meeting_title.
  ///
  /// In en, this message translates to:
  /// **'Enter meeting title'**
  String get hint_enter_meeting_title;

  /// No description provided for @hint_select_date.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get hint_select_date;

  /// No description provided for @hint_select_time.
  ///
  /// In en, this message translates to:
  /// **'Select time'**
  String get hint_select_time;

  /// No description provided for @msg_no_meetings_scheduled.
  ///
  /// In en, this message translates to:
  /// **'No meetings scheduled'**
  String get msg_no_meetings_scheduled;

  /// No description provided for @msg_no_user_found.
  ///
  /// In en, this message translates to:
  /// **'No user found'**
  String get msg_no_user_found;

  /// No description provided for @msg_all_fields_required.
  ///
  /// In en, this message translates to:
  /// **'All fields are required'**
  String get msg_all_fields_required;

  /// No description provided for @msg_error_scheduling_meeting.
  ///
  /// In en, this message translates to:
  /// **'Error scheduling meeting'**
  String get msg_error_scheduling_meeting;

  /// No description provided for @msg_please_enter_meeting_code.
  ///
  /// In en, this message translates to:
  /// **'Please enter a meeting code'**
  String get msg_please_enter_meeting_code;

  /// No description provided for @lbl_start_stop_meeting.
  ///
  /// In en, this message translates to:
  /// **'Start/Stop Meeting'**
  String get lbl_start_stop_meeting;

  /// No description provided for @lbl_mute_all_participants.
  ///
  /// In en, this message translates to:
  /// **'Mute All Participants'**
  String get lbl_mute_all_participants;

  /// No description provided for @lbl_unmute_all_participants.
  ///
  /// In en, this message translates to:
  /// **'Unmute All Participants'**
  String get lbl_unmute_all_participants;

  /// No description provided for @lbl_add_remove_host.
  ///
  /// In en, this message translates to:
  /// **'Add/Remove Host'**
  String get lbl_add_remove_host;

  /// No description provided for @lbl_share_screen.
  ///
  /// In en, this message translates to:
  /// **'Share Screen'**
  String get lbl_share_screen;

  /// No description provided for @lbl_raise_hand.
  ///
  /// In en, this message translates to:
  /// **'Raise Hand'**
  String get lbl_raise_hand;

  /// No description provided for @lbl_send_reactions.
  ///
  /// In en, this message translates to:
  /// **'Send Reactions'**
  String get lbl_send_reactions;

  /// No description provided for @lbl_toggle_microphone.
  ///
  /// In en, this message translates to:
  /// **'Toggle Microphone'**
  String get lbl_toggle_microphone;

  /// No description provided for @lbl_toggle_video.
  ///
  /// In en, this message translates to:
  /// **'Toggle Video'**
  String get lbl_toggle_video;

  /// No description provided for @lbl_enable_waiting_room.
  ///
  /// In en, this message translates to:
  /// **'Enable Waiting Room'**
  String get lbl_enable_waiting_room;

  /// No description provided for @lbl_host_management.
  ///
  /// In en, this message translates to:
  /// **'Host Management'**
  String get lbl_host_management;

  /// No description provided for @lbl_participant_controls.
  ///
  /// In en, this message translates to:
  /// **'Participant Controls'**
  String get lbl_participant_controls;

  /// No description provided for @lbl_meeting_privacy_settings.
  ///
  /// In en, this message translates to:
  /// **'Meeting Privacy Settings'**
  String get lbl_meeting_privacy_settings;

  /// No description provided for @desc_start_stop_meeting.
  ///
  /// In en, this message translates to:
  /// **'Meeting owner can start or stop the meeting'**
  String get desc_start_stop_meeting;

  /// No description provided for @desc_mute_all_participants.
  ///
  /// In en, this message translates to:
  /// **'Meeting owner can not mute all participants'**
  String get desc_mute_all_participants;

  /// No description provided for @desc_unmute_all_participants.
  ///
  /// In en, this message translates to:
  /// **'Meeting owner can not unmute all participants'**
  String get desc_unmute_all_participants;

  /// No description provided for @desc_add_remove_host.
  ///
  /// In en, this message translates to:
  /// **'Meeting owner can add or remove hosts'**
  String get desc_add_remove_host;

  /// No description provided for @desc_share_screen.
  ///
  /// In en, this message translates to:
  /// **'Meeting owner can share their screen'**
  String get desc_share_screen;

  /// No description provided for @desc_raise_hand.
  ///
  /// In en, this message translates to:
  /// **'Meeting participant can raise their hand'**
  String get desc_raise_hand;

  /// No description provided for @desc_send_reactions.
  ///
  /// In en, this message translates to:
  /// **'Meeting participant can send reactions'**
  String get desc_send_reactions;

  /// No description provided for @desc_toggle_microphone.
  ///
  /// In en, this message translates to:
  /// **'Meeting participant can toggle their microphone'**
  String get desc_toggle_microphone;

  /// No description provided for @desc_toggle_video.
  ///
  /// In en, this message translates to:
  /// **'Meeting participant can toggle their video'**
  String get desc_toggle_video;

  /// No description provided for @desc_enable_waiting_room.
  ///
  /// In en, this message translates to:
  /// **'Meeting owner can enable or disable the waiting room\nAsk to Join Meeting'**
  String get desc_enable_waiting_room;

  /// No description provided for @desc_host_management.
  ///
  /// In en, this message translates to:
  /// **'Controls for managing the meeting hosts, including adding, removing, and assigning host privileges.'**
  String get desc_host_management;

  /// No description provided for @desc_participant_controls.
  ///
  /// In en, this message translates to:
  /// **'Controls for participants to interact during the meeting, including sharing screen, sending reactions, turning on/off microphone or video, etc.'**
  String get desc_participant_controls;

  /// No description provided for @desc_meeting_privacy_settings.
  ///
  /// In en, this message translates to:
  /// **'Controls for managing meeting privacy and security, including restricting access, enabling waiting room, requiring passwords, etc.'**
  String get desc_meeting_privacy_settings;

  /// No description provided for @lbl_add_case.
  ///
  /// In en, this message translates to:
  /// **'Add Case'**
  String get lbl_add_case;

  /// No description provided for @lbl_case_title.
  ///
  /// In en, this message translates to:
  /// **'Case Title'**
  String get lbl_case_title;

  /// No description provided for @lbl_case_description.
  ///
  /// In en, this message translates to:
  /// **'Case Description'**
  String get lbl_case_description;

  /// No description provided for @lbl_case_keyword.
  ///
  /// In en, this message translates to:
  /// **'Case Keyword:'**
  String get lbl_case_keyword;

  /// No description provided for @hint_search_by_keyword.
  ///
  /// In en, this message translates to:
  /// **'Search by keyword'**
  String get hint_search_by_keyword;

  /// No description provided for @msg_unknown_state.
  ///
  /// In en, this message translates to:
  /// **'Unknown state'**
  String get msg_unknown_state;

  /// No description provided for @msg_no_case_found.
  ///
  /// In en, this message translates to:
  /// **'No Case Found'**
  String get msg_no_case_found;

  /// No description provided for @lbl_view_details.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get lbl_view_details;

  /// No description provided for @lbl_views_count.
  ///
  /// In en, this message translates to:
  /// **'{count} Views'**
  String lbl_views_count(int count);

  /// No description provided for @lbl_case_details.
  ///
  /// In en, this message translates to:
  /// **'Case Details'**
  String get lbl_case_details;

  /// No description provided for @msg_no_answer_added_yet.
  ///
  /// In en, this message translates to:
  /// **'No answer added yet'**
  String get msg_no_answer_added_yet;

  /// No description provided for @hint_write_your_view.
  ///
  /// In en, this message translates to:
  /// **'Write your view'**
  String get hint_write_your_view;

  /// No description provided for @lbl_about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get lbl_about;

  /// No description provided for @desc_about.
  ///
  /// In en, this message translates to:
  /// **'Learn about DocTak'**
  String get desc_about;

  /// No description provided for @lbl_ai_assistant.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get lbl_ai_assistant;

  /// No description provided for @desc_ai_assistant.
  ///
  /// In en, this message translates to:
  /// **'Medical AI help'**
  String get desc_ai_assistant;

  /// No description provided for @desc_jobs.
  ///
  /// In en, this message translates to:
  /// **'Career opportunities'**
  String get desc_jobs;

  /// No description provided for @lbl_drugs.
  ///
  /// In en, this message translates to:
  /// **'Drugs'**
  String get lbl_drugs;

  /// No description provided for @desc_drugs.
  ///
  /// In en, this message translates to:
  /// **'Medicine database'**
  String get desc_drugs;

  /// No description provided for @lbl_discussions.
  ///
  /// In en, this message translates to:
  /// **'Discussions'**
  String get lbl_discussions;

  /// No description provided for @desc_discussions.
  ///
  /// In en, this message translates to:
  /// **'Case discussions'**
  String get desc_discussions;

  /// No description provided for @desc_groups.
  ///
  /// In en, this message translates to:
  /// **'Professional groups'**
  String get desc_groups;

  /// No description provided for @desc_guidelines.
  ///
  /// In en, this message translates to:
  /// **'Medical protocols'**
  String get desc_guidelines;

  /// No description provided for @lbl_conferences.
  ///
  /// In en, this message translates to:
  /// **'Conferences'**
  String get lbl_conferences;

  /// No description provided for @desc_conferences.
  ///
  /// In en, this message translates to:
  /// **'Medical events'**
  String get desc_conferences;

  /// No description provided for @lbl_meetings.
  ///
  /// In en, this message translates to:
  /// **'Meetings'**
  String get lbl_meetings;

  /// No description provided for @desc_meetings.
  ///
  /// In en, this message translates to:
  /// **'Video conferences'**
  String get desc_meetings;

  /// No description provided for @lbl_feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get lbl_feedback;

  /// No description provided for @desc_feedback.
  ///
  /// In en, this message translates to:
  /// **'Share thoughts'**
  String get desc_feedback;

  /// No description provided for @lbl_settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get lbl_settings;

  /// No description provided for @desc_settings.
  ///
  /// In en, this message translates to:
  /// **'App preferences'**
  String get desc_settings;

  /// No description provided for @desc_privacy.
  ///
  /// In en, this message translates to:
  /// **'Terms & privacy'**
  String get desc_privacy;

  /// No description provided for @lbl_student.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get lbl_student;

  /// No description provided for @lbl_version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get lbl_version;

  /// No description provided for @lbl_post_detail.
  ///
  /// In en, this message translates to:
  /// **'Post Detail'**
  String get lbl_post_detail;

  /// No description provided for @lbl_warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get lbl_warning;

  /// No description provided for @msg_delete_confirm.
  ///
  /// In en, this message translates to:
  /// **'Would you like to Delete?'**
  String get msg_delete_confirm;

  /// No description provided for @msg_post_deleted_successfully.
  ///
  /// In en, this message translates to:
  /// **'Post Deleted Successfully'**
  String get msg_post_deleted_successfully;

  /// No description provided for @msg_no_post_found.
  ///
  /// In en, this message translates to:
  /// **'No Post Found'**
  String get msg_no_post_found;

  /// No description provided for @lbl_normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get lbl_normal;

  /// No description provided for @lbl_bold.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get lbl_bold;

  /// No description provided for @lbl_red.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get lbl_red;

  /// No description provided for @lbl_green.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get lbl_green;

  /// No description provided for @lbl_blue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get lbl_blue;

  /// No description provided for @lbl_new.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get lbl_new;

  /// No description provided for @lbl_expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get lbl_expired;

  /// No description provided for @lbl_visit_site.
  ///
  /// In en, this message translates to:
  /// **'Visit Site'**
  String get lbl_visit_site;

  /// No description provided for @lbl_all_information.
  ///
  /// In en, this message translates to:
  /// **'All information'**
  String get lbl_all_information;

  /// No description provided for @lbl_mechanism.
  ///
  /// In en, this message translates to:
  /// **'Mechanism of action'**
  String get lbl_mechanism;

  /// No description provided for @lbl_indications.
  ///
  /// In en, this message translates to:
  /// **'Indications'**
  String get lbl_indications;

  /// No description provided for @lbl_dosage.
  ///
  /// In en, this message translates to:
  /// **'Dosage and administration'**
  String get lbl_dosage;

  /// No description provided for @lbl_drug_interactions.
  ///
  /// In en, this message translates to:
  /// **'Drug interactions'**
  String get lbl_drug_interactions;

  /// No description provided for @lbl_special_populations.
  ///
  /// In en, this message translates to:
  /// **'Special populations'**
  String get lbl_special_populations;

  /// No description provided for @lbl_side_effects.
  ///
  /// In en, this message translates to:
  /// **'Side effects'**
  String get lbl_side_effects;

  /// No description provided for @lbl_sponsored.
  ///
  /// In en, this message translates to:
  /// **'Sponsored'**
  String get lbl_sponsored;

  /// No description provided for @lbl_apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get lbl_apply;

  /// No description provided for @lbl_tap_for_details.
  ///
  /// In en, this message translates to:
  /// **'Tap for details'**
  String get lbl_tap_for_details;

  /// No description provided for @lbl_select_option_to_learn.
  ///
  /// In en, this message translates to:
  /// **'Select option to learn more'**
  String get lbl_select_option_to_learn;

  /// No description provided for @lbl_step1_info.
  ///
  /// In en, this message translates to:
  /// **'Step 1: Basic Information 1 - 4'**
  String get lbl_step1_info;

  /// No description provided for @lbl_step2_info.
  ///
  /// In en, this message translates to:
  /// **'Step 2: Privacy Setting 1 - 4'**
  String get lbl_step2_info;

  /// No description provided for @lbl_step3_info.
  ///
  /// In en, this message translates to:
  /// **'Step 3: Privacy Setting 1 - 4'**
  String get lbl_step3_info;

  /// No description provided for @lbl_step4_info.
  ///
  /// In en, this message translates to:
  /// **'Step 4: Finish 1 - 4'**
  String get lbl_step4_info;

  /// No description provided for @lbl_specialty_colon.
  ///
  /// In en, this message translates to:
  /// **'Specialty: '**
  String get lbl_specialty_colon;

  /// No description provided for @lbl_upload_logo_banner.
  ///
  /// In en, this message translates to:
  /// **'Upload Logo & Banner Photo'**
  String get lbl_upload_logo_banner;

  /// No description provided for @lbl_successfully.
  ///
  /// In en, this message translates to:
  /// **'Successfully'**
  String get lbl_successfully;

  /// No description provided for @msg_group_created_success.
  ///
  /// In en, this message translates to:
  /// **'Group Created Successfully'**
  String get msg_group_created_success;

  /// No description provided for @lbl_error_exclamation.
  ///
  /// In en, this message translates to:
  /// **'Error !'**
  String get lbl_error_exclamation;

  /// No description provided for @msg_group_create_error.
  ///
  /// In en, this message translates to:
  /// **'An Error Occurred While Creating The Group. Please Go To The Basic Info And Provide The Correct Details'**
  String get msg_group_create_error;

  /// No description provided for @lbl_complete_your_profile.
  ///
  /// In en, this message translates to:
  /// **'Complete Your Profile'**
  String get lbl_complete_your_profile;

  /// No description provided for @msg_unlock_personalized_features.
  ///
  /// In en, this message translates to:
  /// **'To unlock personalized features by providing your country, city, and profession information'**
  String get msg_unlock_personalized_features;

  /// No description provided for @msg_please_select_country.
  ///
  /// In en, this message translates to:
  /// **'Please select country'**
  String get msg_please_select_country;

  /// No description provided for @msg_please_select_state.
  ///
  /// In en, this message translates to:
  /// **'Please select state'**
  String get msg_please_select_state;

  /// No description provided for @msg_please_select_specialty.
  ///
  /// In en, this message translates to:
  /// **'Please select specialty'**
  String get msg_please_select_specialty;

  /// No description provided for @msg_wait_fields_loading.
  ///
  /// In en, this message translates to:
  /// **'Wait a moment, more fields are loading...'**
  String get msg_wait_fields_loading;

  /// No description provided for @msg_account_update_success.
  ///
  /// In en, this message translates to:
  /// **'Account update successfully'**
  String get msg_account_update_success;

  /// No description provided for @lbl_unfollow.
  ///
  /// In en, this message translates to:
  /// **'Unfollow'**
  String get lbl_unfollow;

  /// No description provided for @lbl_verify_your_account.
  ///
  /// In en, this message translates to:
  /// **'Verify Your Account'**
  String get lbl_verify_your_account;

  /// No description provided for @msg_verify_email_description.
  ///
  /// In en, this message translates to:
  /// **'To continue enjoying all features, please verify your email. A verification link will be sent to your inbox.'**
  String get msg_verify_email_description;

  /// No description provided for @lbl_resend_link.
  ///
  /// In en, this message translates to:
  /// **'Resend Link'**
  String get lbl_resend_link;

  /// No description provided for @lbl_validation_error.
  ///
  /// In en, this message translates to:
  /// **'Validation Error'**
  String get lbl_validation_error;

  /// No description provided for @lbl_terms_and_conditions.
  ///
  /// In en, this message translates to:
  /// **'Terms and Conditions'**
  String get lbl_terms_and_conditions;

  /// No description provided for @lbl_agree_terms_conditions.
  ///
  /// In en, this message translates to:
  /// **'I agree to the Terms and Conditions'**
  String get lbl_agree_terms_conditions;

  /// No description provided for @msg_webview_error.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get msg_webview_error;

  /// No description provided for @lbl_delete_with_question.
  ///
  /// In en, this message translates to:
  /// **'Delete ?'**
  String get lbl_delete_with_question;

  /// No description provided for @lbl_empty.
  ///
  /// In en, this message translates to:
  /// **''**
  String get lbl_empty;

  /// No description provided for @lbl_sending_verification_link.
  ///
  /// In en, this message translates to:
  /// **'Sending Verification Link'**
  String get lbl_sending_verification_link;

  /// No description provided for @msg_verification_email_wait.
  ///
  /// In en, this message translates to:
  /// **'Please wait while we send a verification link to your email.'**
  String get msg_verification_email_wait;

  /// No description provided for @lbl_media.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get lbl_media;

  /// No description provided for @lbl_recording_start.
  ///
  /// In en, this message translates to:
  /// **'Recording Start..'**
  String get lbl_recording_start;

  /// No description provided for @msg_confirm_delete_message.
  ///
  /// In en, this message translates to:
  /// **'Are you sure want to delete message?'**
  String get msg_confirm_delete_message;

  /// No description provided for @msg_no_image_selected.
  ///
  /// In en, this message translates to:
  /// **'No image is selected.'**
  String get msg_no_image_selected;

  /// No description provided for @msg_error_picking_file.
  ///
  /// In en, this message translates to:
  /// **'Error picking file'**
  String get msg_error_picking_file;

  /// No description provided for @msg_invalid_string.
  ///
  /// In en, this message translates to:
  /// **'Invalid String'**
  String get msg_invalid_string;

  /// No description provided for @msg_pusher_auth_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch Pusher auth data'**
  String get msg_pusher_auth_failed;

  /// No description provided for @lbl_no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get lbl_no;

  /// No description provided for @lbl_unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get lbl_unknown;

  /// No description provided for @lbl_search_contacts.
  ///
  /// In en, this message translates to:
  /// **'Search Contacts'**
  String get lbl_search_contacts;

  /// No description provided for @msg_screen_share_permission_denied.
  ///
  /// In en, this message translates to:
  /// **'Screen share permission not allowed from host'**
  String get msg_screen_share_permission_denied;

  /// No description provided for @msg_audio_permission_denied.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to enable audio'**
  String get msg_audio_permission_denied;

  /// No description provided for @msg_video_permission_denied.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to enable video'**
  String get msg_video_permission_denied;

  /// No description provided for @lbl_screen_share_error.
  ///
  /// In en, this message translates to:
  /// **'Screen Share Error'**
  String get lbl_screen_share_error;

  /// No description provided for @lbl_initialization_error.
  ///
  /// In en, this message translates to:
  /// **'Initialization Error'**
  String get lbl_initialization_error;

  /// No description provided for @lbl_agora_error.
  ///
  /// In en, this message translates to:
  /// **'Agora Error'**
  String get lbl_agora_error;

  /// No description provided for @lbl_connection_error.
  ///
  /// In en, this message translates to:
  /// **'Connection Error'**
  String get lbl_connection_error;

  /// No description provided for @lbl_applicants.
  ///
  /// In en, this message translates to:
  /// **'Applicants'**
  String get lbl_applicants;

  /// No description provided for @msg_no_applicants.
  ///
  /// In en, this message translates to:
  /// **'No applicants yet'**
  String get msg_no_applicants;

  /// No description provided for @lbl_resume_attached.
  ///
  /// In en, this message translates to:
  /// **'Resume Attached'**
  String get lbl_resume_attached;

  /// No description provided for @lbl_total_applicants.
  ///
  /// In en, this message translates to:
  /// **'Total Applicants'**
  String get lbl_total_applicants;

  /// No description provided for @msg_no_data_found.
  ///
  /// In en, this message translates to:
  /// **'No data found'**
  String get msg_no_data_found;

  /// No description provided for @lbl_experience.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get lbl_experience;

  /// No description provided for @lbl_preferred_language.
  ///
  /// In en, this message translates to:
  /// **'Preferred Language'**
  String get lbl_preferred_language;

  /// No description provided for @lbl_description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get lbl_description;

  /// No description provided for @lbl_actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get lbl_actions;

  /// No description provided for @lbl_withdraw_application.
  ///
  /// In en, this message translates to:
  /// **'Withdraw Application'**
  String get lbl_withdraw_application;

  /// No description provided for @lbl_withdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get lbl_withdraw;

  /// No description provided for @msg_confirm_withdraw.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to withdraw your application?'**
  String get msg_confirm_withdraw;

  /// No description provided for @lbl_view_applicants.
  ///
  /// In en, this message translates to:
  /// **'View Applicants'**
  String get lbl_view_applicants;

  /// No description provided for @lbl_applied.
  ///
  /// In en, this message translates to:
  /// **'Applied'**
  String get lbl_applied;

  /// No description provided for @lbl_not_specified.
  ///
  /// In en, this message translates to:
  /// **'Not Specified'**
  String get lbl_not_specified;

  /// No description provided for @lbl_select_attachment.
  ///
  /// In en, this message translates to:
  /// **'Select Attachment'**
  String get lbl_select_attachment;

  /// No description provided for @lbl_gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get lbl_gallery;

  /// No description provided for @lbl_file.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get lbl_file;

  /// No description provided for @msg_error_picking_image.
  ///
  /// In en, this message translates to:
  /// **'Error picking image'**
  String get msg_error_picking_image;

  /// No description provided for @lbl_clinical_complexity.
  ///
  /// In en, this message translates to:
  /// **'Clinical Complexity'**
  String get lbl_clinical_complexity;

  /// No description provided for @lbl_teaching_value.
  ///
  /// In en, this message translates to:
  /// **'Teaching Value'**
  String get lbl_teaching_value;

  /// No description provided for @lbl_submit_case.
  ///
  /// In en, this message translates to:
  /// **'Submit Case'**
  String get lbl_submit_case;

  /// No description provided for @msg_confirm_patient_info_removed_checkbox.
  ///
  /// In en, this message translates to:
  /// **'I confirm that patient information will be anonymized'**
  String get msg_confirm_patient_info_removed_checkbox;

  /// No description provided for @lbl_create_case_discussion.
  ///
  /// In en, this message translates to:
  /// **'Create Case Discussion'**
  String get lbl_create_case_discussion;

  /// No description provided for @lbl_patient_info.
  ///
  /// In en, this message translates to:
  /// **'Patient Information'**
  String get lbl_patient_info;

  /// No description provided for @lbl_case_info.
  ///
  /// In en, this message translates to:
  /// **'Case Information'**
  String get lbl_case_info;

  /// No description provided for @lbl_clinical_keywords.
  ///
  /// In en, this message translates to:
  /// **'Clinical Keywords'**
  String get lbl_clinical_keywords;

  /// No description provided for @hint_clinical_keywords.
  ///
  /// In en, this message translates to:
  /// **'Enter keywords separated by commas'**
  String get hint_clinical_keywords;

  /// No description provided for @lbl_medical_specialty.
  ///
  /// In en, this message translates to:
  /// **'Medical Specialty'**
  String get lbl_medical_specialty;

  /// No description provided for @lbl_select_specialty.
  ///
  /// In en, this message translates to:
  /// **'Select Specialty'**
  String get lbl_select_specialty;

  /// No description provided for @hint_select_specialty.
  ///
  /// In en, this message translates to:
  /// **'Choose your medical specialty'**
  String get hint_select_specialty;

  /// No description provided for @lbl_no_images_selected.
  ///
  /// In en, this message translates to:
  /// **'No images selected'**
  String get lbl_no_images_selected;

  /// No description provided for @lbl_remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get lbl_remove;

  /// No description provided for @lbl_low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get lbl_low;

  /// No description provided for @lbl_medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get lbl_medium;

  /// No description provided for @lbl_high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get lbl_high;

  /// No description provided for @msg_case_discussion_created.
  ///
  /// In en, this message translates to:
  /// **'Case discussion created successfully'**
  String get msg_case_discussion_created;

  /// No description provided for @msg_failed_to_create_discussion.
  ///
  /// In en, this message translates to:
  /// **'Failed to create discussion'**
  String get msg_failed_to_create_discussion;

  /// No description provided for @hint_case_title.
  ///
  /// In en, this message translates to:
  /// **'Enter a descriptive title for your case'**
  String get hint_case_title;

  /// No description provided for @hint_case_description.
  ///
  /// In en, this message translates to:
  /// **'Describe the details of your medical case'**
  String get hint_case_description;

  /// No description provided for @lbl_patient_age.
  ///
  /// In en, this message translates to:
  /// **'Patient Age'**
  String get lbl_patient_age;

  /// No description provided for @hint_patient_age.
  ///
  /// In en, this message translates to:
  /// **'Enter age'**
  String get hint_patient_age;

  /// No description provided for @lbl_patient_gender.
  ///
  /// In en, this message translates to:
  /// **'Patient Gender'**
  String get lbl_patient_gender;

  /// No description provided for @lbl_male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get lbl_male;

  /// No description provided for @lbl_female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get lbl_female;

  /// No description provided for @lbl_other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get lbl_other;

  /// No description provided for @lbl_patient_ethnicity.
  ///
  /// In en, this message translates to:
  /// **'Patient Ethnicity'**
  String get lbl_patient_ethnicity;

  /// No description provided for @lbl_caucasian.
  ///
  /// In en, this message translates to:
  /// **'Caucasian'**
  String get lbl_caucasian;

  /// No description provided for @lbl_african.
  ///
  /// In en, this message translates to:
  /// **'African'**
  String get lbl_african;

  /// No description provided for @lbl_asian.
  ///
  /// In en, this message translates to:
  /// **'Asian'**
  String get lbl_asian;

  /// No description provided for @lbl_hispanic.
  ///
  /// In en, this message translates to:
  /// **'Hispanic'**
  String get lbl_hispanic;

  /// No description provided for @lbl_native_american.
  ///
  /// In en, this message translates to:
  /// **'Native American'**
  String get lbl_native_american;

  /// No description provided for @lbl_pacific_islander.
  ///
  /// In en, this message translates to:
  /// **'Pacific Islander'**
  String get lbl_pacific_islander;

  /// No description provided for @lbl_mixed_race.
  ///
  /// In en, this message translates to:
  /// **'Mixed Race'**
  String get lbl_mixed_race;

  /// No description provided for @lbl_prefer_not_to_say.
  ///
  /// In en, this message translates to:
  /// **'Prefer not to say'**
  String get lbl_prefer_not_to_say;

  /// No description provided for @msg_title_required.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get msg_title_required;

  /// No description provided for @msg_description_required.
  ///
  /// In en, this message translates to:
  /// **'Description is required'**
  String get msg_description_required;

  /// No description provided for @msg_age_invalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid age'**
  String get msg_age_invalid;

  /// No description provided for @msg_specialty_required.
  ///
  /// In en, this message translates to:
  /// **'Please select a specialty'**
  String get msg_specialty_required;

  /// No description provided for @msg_create_case_discussion_description.
  ///
  /// In en, this message translates to:
  /// **'Create a new medical case discussion by providing all necessary details for the medical community.'**
  String get msg_create_case_discussion_description;

  /// No description provided for @lbl_got_it.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get lbl_got_it;

  /// No description provided for @lbl_patient_demographics.
  ///
  /// In en, this message translates to:
  /// **'Patient Demographics'**
  String get lbl_patient_demographics;

  /// No description provided for @lbl_select_gender.
  ///
  /// In en, this message translates to:
  /// **'Select Gender'**
  String get lbl_select_gender;

  /// No description provided for @lbl_gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get lbl_gender;

  /// No description provided for @lbl_select_ethnicity.
  ///
  /// In en, this message translates to:
  /// **'Select Ethnicity'**
  String get lbl_select_ethnicity;

  /// No description provided for @lbl_ethnicity.
  ///
  /// In en, this message translates to:
  /// **'Ethnicity'**
  String get lbl_ethnicity;

  /// No description provided for @lbl_african_american.
  ///
  /// In en, this message translates to:
  /// **'African American'**
  String get lbl_african_american;

  /// No description provided for @lbl_hispanic_latino.
  ///
  /// In en, this message translates to:
  /// **'Hispanic/Latino'**
  String get lbl_hispanic_latino;

  /// No description provided for @lbl_middle_eastern.
  ///
  /// In en, this message translates to:
  /// **'Middle Eastern'**
  String get lbl_middle_eastern;

  /// No description provided for @msg_enter_keywords.
  ///
  /// In en, this message translates to:
  /// **'Enter clinical keywords (optional)'**
  String get msg_enter_keywords;

  /// No description provided for @lbl_attach_medical_images.
  ///
  /// In en, this message translates to:
  /// **'Attach Medical Images'**
  String get lbl_attach_medical_images;

  /// No description provided for @lbl_add_medical_images.
  ///
  /// In en, this message translates to:
  /// **'Add Medical Images'**
  String get lbl_add_medical_images;

  /// No description provided for @lbl_select_clinical_complexity.
  ///
  /// In en, this message translates to:
  /// **'Select Clinical Complexity'**
  String get lbl_select_clinical_complexity;

  /// No description provided for @lbl_select_teaching_value.
  ///
  /// In en, this message translates to:
  /// **'Select Teaching Value'**
  String get lbl_select_teaching_value;

  /// No description provided for @msg_please_enter_title.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get msg_please_enter_title;

  /// No description provided for @msg_please_enter_description.
  ///
  /// In en, this message translates to:
  /// **'Please enter a description'**
  String get msg_please_enter_description;

  /// No description provided for @msg_confirm_patient_info_removed.
  ///
  /// In en, this message translates to:
  /// **'Patient information will be removed from this case for privacy protection'**
  String get msg_confirm_patient_info_removed;

  /// No description provided for @lbl_french_language.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get lbl_french_language;

  /// No description provided for @lbl_spanish_language.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get lbl_spanish_language;

  /// No description provided for @lbl_german_language.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get lbl_german_language;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'de', 'en', 'es', 'fa', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'de': return AppLocalizationsDe();
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
    case 'fa': return AppLocalizationsFa();
    case 'fr': return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
