import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/secure_storage_service.dart';
import 'package:doctak_app/data/models/login_device_auth/post_login_device_auth_resp.dart';

/// Centralised helper that persists a [PostLoginDeviceAuthResp] to
/// SecureStorage **and** populates [AppData] statics.
///
/// Call this from any BLoC after a successful login / register / social-login
/// to avoid duplicating ~60 lines of boilerplate in every handler.
class AuthSessionHelper {
  AuthSessionHelper._();

  /// Persist auth response and populate global AppData.
  /// [deviceToken] is the FCM device token obtained earlier.
  /// [rememberMe] controls whether we persist the remember-me flag.
  static Future<void> persistSession(
    PostLoginDeviceAuthResp response, {
    required String deviceToken,
    bool rememberMe = true,
  }) async {
    final prefs = SecureStorageService.instance;
    await prefs.initialize();

    // ── Core auth ──
    await prefs.setBool('rememberMe', rememberMe);
    await prefs.setString('device_token', deviceToken);
    await prefs.setString('token', response.token ?? '');
    await prefs.setString('email_verified_at', response.user?.emailVerifiedAt ?? '');

    // ── User fields ──
    await prefs.setString('userId', response.user?.id ?? '');
    await prefs.setString('name', '${response.user?.firstName ?? ''} ${response.user?.lastName ?? ''}');
    await prefs.setString('profile_pic', response.user?.profilePic ?? '');
    await prefs.setString('email', response.user?.email ?? '');
    await prefs.setString('phone', response.user?.phone ?? '');
    await prefs.setString('background', response.user?.background ?? '');
    await prefs.setString('specialty', response.user?.specialty ?? '');
    await prefs.setString('licenseNo', response.user?.licenseNo ?? '');
    await prefs.setString('title', response.user?.title ?? '');
    await prefs.setString('city', response.user?.state ?? '');
    await prefs.setString('countryOrigin', response.user?.countryOrigin ?? '');
    await prefs.setString('college', response.user?.college ?? '');
    await prefs.setString('clinicName', response.user?.clinicName ?? '');
    await prefs.setString('dob', response.user?.dob ?? '');
    await prefs.setString('user_type', response.user?.userType ?? '');
    await prefs.setString('countryName', response.country?.countryName ?? '');
    await prefs.setString('currency', response.country?.currency ?? '');
    if (response.university != null) {
      await prefs.setString('university', response.university?.name ?? '');
    }
    await prefs.setString('practicingCountry', response.user?.practicingCountry ?? '');
    await prefs.setString('gender', response.user?.gender ?? '');
    await prefs.setString('country', response.user?.country.toString() ?? '');

    // ── Subscription (v6) ──
    if (response.subscription != null) {
      await prefs.setString('is_premium', response.subscription!.isPremium.toString());
      await prefs.setString('account_type', response.subscription!.accountType);
      await prefs.setString('plan_name', response.subscription!.planName ?? '');
      await prefs.setString('plan_slug', response.subscription!.planSlug ?? '');
    }

    // ── Read back & populate AppData ──
    final userToken = await prefs.getString('token') ?? '';
    final userId = await prefs.getString('userId') ?? '';
    final name = await prefs.getString('name') ?? '';
    final profilePic = await prefs.getString('profile_pic') ?? '';
    final background = await prefs.getString('background') ?? '';
    final email = await prefs.getString('email') ?? '';
    final specialty = await prefs.getString('specialty') ?? '';
    final userType = await prefs.getString('user_type') ?? '';
    final university = await prefs.getString('university') ?? '';
    final countryName = await prefs.getString('country') ?? '';
    final city = await prefs.getString('city') ?? '';
    final currency = await prefs.getString('currency') ?? '';

    if (userToken.isNotEmpty) {
      AppData.deviceToken = deviceToken;
      AppData.userToken = userToken;
      AppData.logInUserId = userId;
      AppData.name = name;
      AppData.profile_pic = profilePic;
      AppData.profilePicNotifier.value = AppData.profilePicUrl;
      AppData.university = university;
      AppData.userType = userType;
      AppData.background = background;
      AppData.email = email;
      AppData.specialty = specialty;
      AppData.countryName = countryName;
      AppData.city = city;
      AppData.currency = currency;
    }

    // ── Populate subscription globals (v6) ──
    AppData.updateSubscriptionData(response.subscription, response.features);
  }
}
