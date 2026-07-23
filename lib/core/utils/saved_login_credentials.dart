import 'package:doctak_app/core/utils/secure_storage_service.dart';

/// Clears locally cached passwords after a web reset or forgot-password flow.
/// Saved logins otherwise keep submitting the old password and login fails.
class SavedLoginCredentials {
  SavedLoginCredentials._();

  static const passwordResetPendingKey = 'password_reset_pending';

  static Future<void> clearSavedPasswordForEmail(String email) async {
    final normalized = email.trim();
    if (normalized.isEmpty) return;

    final prefs = SecureStorageService.instance;
    await prefs.initialize();

    await prefs.remove('password_$normalized');

    final savedUsernamesStr = await prefs.getString('saved_usernames');
    if (savedUsernamesStr == null || savedUsernamesStr.isEmpty) return;

    for (final username in savedUsernamesStr.split('|||')) {
      if (username.trim().toLowerCase() == normalized.toLowerCase()) {
        await prefs.remove('password_$username');
      }
    }
  }

  static Future<void> clearAllSavedPasswords() async {
    final prefs = SecureStorageService.instance;
    await prefs.initialize();

    final savedUsernamesStr = await prefs.getString('saved_usernames');
    if (savedUsernamesStr == null || savedUsernamesStr.isEmpty) return;

    for (final username in savedUsernamesStr.split('|||')) {
      final trimmed = username.trim();
      if (trimmed.isNotEmpty) {
        await prefs.remove('password_$trimmed');
      }
    }
  }

  /// Mark that the user must sign in with a freshly set password.
  static Future<void> markPasswordResetPending() async {
    final prefs = SecureStorageService.instance;
    await prefs.initialize();
    await prefs.setString(passwordResetPendingKey, '1');
  }

  static Future<bool> consumePasswordResetPending() async {
    final prefs = SecureStorageService.instance;
    await prefs.initialize();
    final pending = await prefs.getString(passwordResetPendingKey);
    if (pending == '1') {
      await prefs.remove(passwordResetPendingKey);
      return true;
    }
    return false;
  }

  static Future<void> prepareForNewPasswordLogin({String? email}) async {
    if (email != null && email.trim().isNotEmpty) {
      await clearSavedPasswordForEmail(email);
    } else {
      await clearAllSavedPasswords();
    }
    await markPasswordResetPending();
  }
}
