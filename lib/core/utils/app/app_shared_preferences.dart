import 'package:shared_preferences/shared_preferences.dart';

class AppSharedPreferences{

  Future<void> clearSharedPreferencesData(context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('rememberMe');
    await prefs.remove('token');
    await prefs.remove('token');
    await prefs.remove('userId');
    await prefs.remove('name');
    await prefs.remove('profile_pic');
    await prefs.remove('email');
    await prefs.remove('phone');
    await prefs.remove('background');
    await prefs.remove('specialty');
    await prefs.remove('licenseNo');
    await prefs.remove('title');
    await prefs.remove('city');
    await prefs.remove('countryOrigin');
    await prefs.remove('college');
    await prefs.remove('clinicName');
    await prefs.remove('dob');
    await prefs.remove('practicingCountry');
    await prefs.remove('gender');
    await prefs.remove('country');
    await prefs.clear();
  }

}