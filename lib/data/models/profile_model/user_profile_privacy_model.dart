class UserProfilePrivacyModel {
  String? aboutMePrivacy='lock';
  String? addressPrivacy='lock';
  String? birthPlacePrivacy='lock';
  String? languagePrivacy='lock';
  String? liveInPrivacy='lock';
  String? dobPrivacy='lock';
  String? emailPrivacy='lock';
  String? genderPrivacy='lock';
  String? phonePrivacy='lock';
  String? licenseNumberPrivacy='lock';
  String? specialtyPrivacy='lock';
  String? countryPrivacy='lock';
  String? cityPrivacy='lock';
  String? countryOrigin='lock';

  UserProfilePrivacyModel({
    this.aboutMePrivacy,
    this.addressPrivacy,
    this.birthPlacePrivacy,
    this.languagePrivacy,
    this.liveInPrivacy,
    this.dobPrivacy,
    this.emailPrivacy,
    this.genderPrivacy,
    this.phonePrivacy,
    this.licenseNumberPrivacy,
    this.specialtyPrivacy,
    this.countryPrivacy,
    this.cityPrivacy,
    this.countryOrigin
  });
  Map<String, dynamic> toJson() {
    return {
      'aboutMePrivacy': aboutMePrivacy,
      'addressPrivacy': addressPrivacy,
      'birthPlacePrivacy': birthPlacePrivacy,
      'languagePrivacy': languagePrivacy,
      'liveInPrivacy': liveInPrivacy,
      'dobPrivacy': dobPrivacy,
      'emailPrivacy': emailPrivacy,
      'genderPrivacy': genderPrivacy,
      'phonePrivacy': phonePrivacy,
      'licenseNumberPrivacy': licenseNumberPrivacy,
      'specialtyPrivacy': specialtyPrivacy,
      'countryPrivacy': countryPrivacy,
      'cityPrivacy': cityPrivacy,
      'countryOrigin': countryOrigin,
    };
  }

}