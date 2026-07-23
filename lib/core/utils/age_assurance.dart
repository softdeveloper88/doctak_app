import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/secure_storage_service.dart';

/// Apple App Store Age Assurance — DocTak requires users to be 13+.
///
/// Used for signup validation, post-login gating, and App Store Connect
/// Age Ratings (Age Assurance = Yes).
class AgeAssurance {
  AgeAssurance._();

  static const int minimumAge = 13;
  static const String policySummary =
      'DocTak is for healthcare professionals age 13 and older. '
      'By continuing you confirm you meet this age requirement. '
      'Accounts that do not meet the minimum age cannot use DocTak.';

  static const String _confirmedKey = 'age_assurance_confirmed';
  static const String _dobKey = 'age_assurance_dob';
  static const String _userKey = 'age_assurance_user_id';

  /// Age in whole years at [on] (defaults to today).
  static int ageFromDateOfBirth(DateTime dob, {DateTime? on}) {
    final now = on ?? DateTime.now();
    var age = now.year - dob.year;
    final hadBirthday =
        now.month > dob.month || (now.month == dob.month && now.day >= dob.day);
    if (!hadBirthday) age -= 1;
    return age;
  }

  static bool meetsMinimumAge(DateTime dob, {DateTime? on}) =>
      ageFromDateOfBirth(dob, on: on) >= minimumAge;

  static String formatDob(DateTime dob) {
    final m = dob.month.toString().padLeft(2, '0');
    final d = dob.day.toString().padLeft(2, '0');
    return '${dob.year}-$m-$d';
  }

  static DateTime? tryParseDob(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw.trim());
  }

  static Future<bool> isConfirmedForCurrentUser() async {
    final prefs = SecureStorageService.instance;
    await prefs.initialize();
    final confirmed = await prefs.getBool(_confirmedKey) ?? false;
    if (!confirmed) return false;
    final storedUser = await prefs.getString(_userKey) ?? '';
    final current = AppData.logInUserId?.toString() ?? '';
    if (current.isEmpty) return confirmed;
    // If we have a user id, confirmation must match that account.
    return storedUser.isEmpty || storedUser == current;
  }

  static Future<void> markConfirmed({
    required DateTime dateOfBirth,
    String? userId,
  }) async {
    final prefs = SecureStorageService.instance;
    await prefs.initialize();
    await prefs.setBool(_confirmedKey, true);
    await prefs.setString(_dobKey, formatDob(dateOfBirth));
    final id = userId ?? AppData.logInUserId?.toString() ?? '';
    if (id.isNotEmpty) await prefs.setString(_userKey, id);
    AppData.dob = formatDob(dateOfBirth);
  }

  static Future<void> clear() async {
    final prefs = SecureStorageService.instance;
    await prefs.initialize();
    await prefs.remove(_confirmedKey);
    await prefs.remove(_dobKey);
    await prefs.remove(_userKey);
  }
}
