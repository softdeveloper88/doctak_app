import 'dart:async';
import 'dart:convert';

import 'package:doctak_app/core/acting/acting_context_service.dart';
import 'package:doctak_app/core/notification_service.dart';
import 'package:doctak_app/core/utils/age_assurance.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/secure_storage_service.dart';
import 'package:doctak_app/core/utils/specialty_display.dart';
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
    /// Optional YYYY-MM-DD from signup when the auth payload omits `dob`.
    String? dateOfBirthOverride,
  }) async {
    final prefs = SecureStorageService.instance;
    await prefs.initialize();

    // ── Core auth ──
    await prefs.setBool('rememberMe', rememberMe);
    await prefs.setString('device_token', deviceToken);
    await prefs.setString('token', response.token ?? '');
    final expiresAt = response.expiresAt;
    if (expiresAt != null && expiresAt > 0) {
      await prefs.setString('token_expires_at', '$expiresAt');
    }
    await prefs.setString('email_verified_at', response.user?.emailVerifiedAt ?? '');

    // ── User fields ──
    await prefs.setString('userId', response.user?.id ?? '');
    await prefs.setString('name', '${response.user?.firstName ?? ''} ${response.user?.lastName ?? ''}');
    await prefs.setString('profile_pic', response.user?.profilePic ?? '');
    await prefs.setString('email', response.user?.email ?? '');
    await prefs.setString('phone', response.user?.phone ?? '');
    await prefs.setString('background', response.user?.background ?? '');
    await SpecialtyDisplay.instance.ensureLoaded();
    final rawSpecialty = response.user?.specialty ?? '';
    final resolvedSpecialty =
        SpecialtyDisplay.instance.resolve(rawSpecialty).isNotEmpty
            ? SpecialtyDisplay.instance.resolve(rawSpecialty)
            : rawSpecialty;
    await prefs.setString('specialty', resolvedSpecialty);
    await prefs.setString(
      'is_verified',
      (response.user?.isVerified == true).toString(),
    );
    await prefs.setString('licenseNo', response.user?.licenseNo ?? '');
    await prefs.setString('title', response.user?.title ?? '');
    await prefs.setString('city', response.user?.state ?? '');
    await prefs.setString('countryOrigin', response.user?.countryOrigin ?? '');
    await prefs.setString('college', response.user?.college ?? '');
    await prefs.setString('clinicName', response.user?.clinicName ?? '');
    final resolvedDob = (response.user?.dob != null && response.user!.dob!.trim().isNotEmpty)
        ? response.user!.dob!.trim()
        : (dateOfBirthOverride?.trim() ?? '');
    await prefs.setString('dob', resolvedDob);
    await prefs.setString('user_type', response.user?.userType ?? '');
    await prefs.setString('countryName', response.country?.countryName ?? '');
    await prefs.setString('currency', response.country?.currency ?? '');
    if (response.university != null) {
      await prefs.setString('university', response.university?.name ?? '');
    }
    await prefs.setString('practicingCountry', response.user?.practicingCountry ?? '');
    await prefs.setString('gender', response.user?.gender ?? '');
    // Prefer the country object's name; fall back to user.country (which may be
    // a name or a legacy numeric ID).
    final resolvedCountry = (response.country?.countryName != null && response.country!.countryName!.isNotEmpty)
        ? response.country!.countryName!
        : (response.user?.country != null ? response.user!.country.toString() : '');
    await prefs.setString('country', resolvedCountry);

    // ── Subscription (v6) ──
    if (response.subscription != null) {
      await prefs.setString('is_premium', response.subscription!.isPremium.toString());
      await prefs.setString('account_type', response.subscription!.accountType);
      await prefs.setString('plan_name', response.subscription!.planName ?? '');
      await prefs.setString('plan_slug', response.subscription!.planSlug ?? '');
      await prefs.setString('subscription_json', jsonEncode(response.subscription!.toJson()));
    }
    // ── Features map (v6) ──
    if (response.features != null) {
      await prefs.setString('features_json', jsonEncode(response.features!.toJson()));
    }

    // ── Read back & populate AppData ──
    final userToken = await prefs.getString('token') ?? '';
    final userId = await prefs.getString('userId') ?? '';
    final name = await prefs.getString('name') ?? '';
    final profilePic = await prefs.getString('profile_pic') ?? '';
    final background = await prefs.getString('background') ?? '';
    final email = await prefs.getString('email') ?? '';
    final specialty = await prefs.getString('specialty') ?? '';
    final isVerified = await prefs.getString('is_verified') ?? 'false';
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
      AppData.specialty = SpecialtyDisplay.instance.resolve(specialty).isNotEmpty
          ? SpecialtyDisplay.instance.resolve(specialty)
          : specialty;
      AppData.isVerified = isVerified == 'true';
      AppData.countryName = countryName;
      AppData.city = city;
      AppData.currency = currency;

      // Register FCM with the server after login (non-blocking).
      unawaited(NotificationService.syncDeviceToken());

      // Age assurance: if profile already has a qualifying DOB, mark verified.
      final dobRaw = response.user?.dob ?? await prefs.getString('dob') ?? '';
      final parsedDob = AgeAssurance.tryParseDob(dobRaw);
      if (parsedDob != null && AgeAssurance.meetsMinimumAge(parsedDob)) {
        await AgeAssurance.markConfirmed(
          dateOfBirth: parsedDob,
          userId: userId,
        );
      }
    }

    // ── Populate subscription globals (v6) ──
    AppData.updateSubscriptionData(response.subscription, response.features);

    // Fresh sign-in should always open the personal workspace — not the last
    // business page stored in users.active_organization_id on the server.
    await _resetActingToPersonal();
  }

  static Future<void> _resetActingToPersonal() async {
    await ActingContextService.instance.clear();
    try {
      await ActingContextService.instance.switchToPersonal();
    } catch (e) {
      // Keep local state personal even if the switch API is unreachable.
      await ActingContextService.instance.clear();
    }
  }
}
