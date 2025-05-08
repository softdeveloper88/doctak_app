import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future initializeAsync() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

 if(prefs.containsKey('token')) {
   String? userToken = prefs.getString('token');
   String? userId = prefs.getString('userId');

   String? name = prefs.getString('name');
   String? profile_pic = prefs.getString('profile_pic');
   String? background = prefs.getString('background');
   String? email = prefs.getString('email');
   String? specialty = prefs.getString('specialty');
   String? userType = prefs.getString('user_type') ?? '';
   String? university = prefs.getString('university') ?? '';
   String? countryName = prefs.getString('country') ?? '';
   String? currency = prefs.getString('currency') ?? '';
   if (userToken != null) {
     AppData.userToken = userToken;
     AppData.logInUserId = userId;
     AppData.name = name ?? '';
     AppData.profile_pic = profile_pic ?? '';
     // AppData.background= background!;
     AppData.background = background ?? '';
     AppData.email = email ?? '';
     AppData.specialty = specialty ?? '';
     AppData.university = university;
     AppData.userType = userType;
     AppData.countryName = countryName;
     AppData.currency = currency;
   }
 }
}