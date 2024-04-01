import 'dart:convert';
PostLoginDeviceAuthResp postLogingDeviceAuthReqsFromJson(String str) => PostLoginDeviceAuthResp.fromJson(json.decode(str));
String postLogingDeviceAuthReqsToJson(PostLoginDeviceAuthResp data) => json.encode(data.toJson());
class PostLoginDeviceAuthResp {
  PostLoginDeviceAuthResp({
      this.success, 
      this.user, 
      this.token, 
      this.university, 
      this.country,});

  PostLoginDeviceAuthResp.fromJson(dynamic json) {
    success = json['success'];
    user = json['user'] != null ? User.fromJson(json['user']) : null;
    token = json['token'];
    university = json['university'] != null ? University.fromJson(json['university']) : null;
    country = json['country'] != null ? Country.fromJson(json['country']) : null;
  }
  bool? success;
  User? user;
  String? token;
  University? university;
  Country? country;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (user != null) {
      map['user'] = user?.toJson();
    }
    map['token'] = token;
    if (university != null) {
      map['university'] = university?.toJson();
    }
    if (country != null) {
      map['country'] = country?.toJson();
    }
    return map;
  }

}

Country countryFromJson(String str) => Country.fromJson(json.decode(str));
String countryToJson(Country data) => json.encode(data.toJson());
class Country {
  Country({
      this.id, 
      this.countryName, 
      this.createdAt, 
      this.updatedAt, 
      this.isRegistered, 
      this.countryCode, 
      this.countryMask, 
      this.currency,});

  Country.fromJson(dynamic json) {
    id = json['id'];
    countryName = json['countryName'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    isRegistered = json['isRegistered'];
    countryCode = json['countryCode'];
    countryMask = json['countryMask'];
    currency = json['currency'];
  }
  int? id;
  String? countryName;
  String? createdAt;
  String? updatedAt;
  String? isRegistered;
  String? countryCode;
  String? countryMask;
  String? currency;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['countryName'] = countryName;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    map['isRegistered'] = isRegistered;
    map['countryCode'] = countryCode;
    map['countryMask'] = countryMask;
    map['currency'] = currency;
    return map;
  }

}

University universityFromJson(String str) => University.fromJson(json.decode(str));
String universityToJson(University data) => json.encode(data.toJson());
class University {
  University({
      this.id, 
      this.name, 
      this.address, 
      this.city, 
      this.stateId, 
      this.countryId, 
      this.zipCode, 
      this.website, 
      this.contactNumber, 
      this.email, 
      this.establishedYear, 
      this.type, 
      this.accreditation, 
      this.facultyCount, 
      this.studentPopulation, 
      this.graduateProgramCount, 
      this.undergraduateProgramCount, 
      this.internationalStudentCount, 
      this.scholarshipProgram, 
      this.libraryCount, 
      this.sportsFaculty, 
      this.ranking, 
      this.createdAt, 
      this.updatedAt,});

  University.fromJson(dynamic json) {
    id = json['id'];
    name = json['name'];
    address = json['address'];
    city = json['city'];
    stateId = json['state_id'];
    countryId = json['country_id'];
    zipCode = json['zip_code'];
    website = json['website'];
    contactNumber = json['contact_number'];
    email = json['email'];
    establishedYear = json['established_year'];
    type = json['type'];
    accreditation = json['accreditation'];
    facultyCount = json['faculty_count'];
    studentPopulation = json['student_population'];
    graduateProgramCount = json['graduate_program_count'];
    undergraduateProgramCount = json['undergraduate_program_count'];
    internationalStudentCount = json['international_student_count'];
    scholarshipProgram = json['Scholarship_program'];
    libraryCount = json['library_count'];
    sportsFaculty = json['sports_faculty'];
    ranking = json['ranking'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }
  int? id;
  String? name;
  dynamic address;
  dynamic city;
  String? stateId;
  dynamic countryId;
  dynamic zipCode;
  dynamic website;
  dynamic contactNumber;
  dynamic email;
  dynamic establishedYear;
  dynamic type;
  dynamic accreditation;
  dynamic facultyCount;
  dynamic studentPopulation;
  dynamic graduateProgramCount;
  dynamic undergraduateProgramCount;
  dynamic internationalStudentCount;
  dynamic scholarshipProgram;
  dynamic libraryCount;
  dynamic sportsFaculty;
  dynamic ranking;
  String? createdAt;
  String? updatedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['name'] = name;
    map['address'] = address;
    map['city'] = city;
    map['state_id'] = stateId;
    map['country_id'] = countryId;
    map['zip_code'] = zipCode;
    map['website'] = website;
    map['contact_number'] = contactNumber;
    map['email'] = email;
    map['established_year'] = establishedYear;
    map['type'] = type;
    map['accreditation'] = accreditation;
    map['faculty_count'] = facultyCount;
    map['student_population'] = studentPopulation;
    map['graduate_program_count'] = graduateProgramCount;
    map['undergraduate_program_count'] = undergraduateProgramCount;
    map['international_student_count'] = internationalStudentCount;
    map['Scholarship_program'] = scholarshipProgram;
    map['library_count'] = libraryCount;
    map['sports_faculty'] = sportsFaculty;
    map['ranking'] = ranking;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    return map;
  }

}

User userFromJson(String str) => User.fromJson(json.decode(str));
String userToJson(User data) => json.encode(data.toJson());
class User {
  User({
      this.id, 
      this.firstName, 
      this.lastName, 
      this.email, 
      this.token, 
      this.phone, 
      this.licenseNo, 
      this.specialty, 
      this.status, 
      this.role, 
      this.gender, 
      this.dob, 
      this.clinicName, 
      this.college, 
      this.countryOrigin, 
      this.profilePic, 
      this.practicingCountry, 
      this.otpCode, 
      this.balance, 
      this.title, 
      this.city, 
      this.country, 
      this.isAdmin, 
      this.createdAt, 
      this.updatedAt, 
      this.activeStatus, 
      this.avatar, 
      this.darkMode, 
      this.messengerColor, 
      this.name, 
      this.emailVerifiedAt, 
      this.background, 
      this.userType,});

  User.fromJson(dynamic json) {
    id = json['id'];
    firstName = json['first_name'];
    lastName = json['last_name'];
    email = json['email'];
    token = json['token'];
    phone = json['phone'];
    licenseNo = json['license_no'];
    specialty = json['specialty'];
    status = json['status'];
    role = json['role'];
    gender = json['gender'];
    dob = json['dob'];
    clinicName = json['clinic_name'];
    college = json['college'];
    countryOrigin = json['country_origin'];
    profilePic = json['profile_pic'];
    practicingCountry = json['practicing_country'];
    otpCode = json['otp_code'];
    balance = json['balance'];
    title = json['title'];
    city = json['city'];
    country = json['country'];
    isAdmin = json['is_admin'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    activeStatus = json['active_status'];
    avatar = json['avatar'];
    darkMode = json['dark_mode'];
    messengerColor = json['messenger_color'];
    name = json['name'];
    emailVerifiedAt = json['email_verified_at'];
    background = json['background'];
    userType = json['user_type'];
  }
  String? id;
  String? firstName;
  String? lastName;
  String? email;
  dynamic token;
  String? phone;
  String? licenseNo;
  String? specialty;
  String? status;
  String? role;
  dynamic gender;
  dynamic dob;
  dynamic clinicName;
  dynamic college;
  dynamic countryOrigin;
  String? profilePic;
  dynamic practicingCountry;
  dynamic otpCode;
  String? balance;
  dynamic title;
  dynamic city;
  String? country;
  dynamic isAdmin;
  String? createdAt;
  String? updatedAt;
  String? activeStatus;
  dynamic avatar;
  String? darkMode;
  dynamic messengerColor;
  String? name;
  String? emailVerifiedAt;
  dynamic background;
  String? userType;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['first_name'] = firstName;
    map['last_name'] = lastName;
    map['email'] = email;
    map['token'] = token;
    map['phone'] = phone;
    map['license_no'] = licenseNo;
    map['specialty'] = specialty;
    map['status'] = status;
    map['role'] = role;
    map['gender'] = gender;
    map['dob'] = dob;
    map['clinic_name'] = clinicName;
    map['college'] = college;
    map['country_origin'] = countryOrigin;
    map['profile_pic'] = profilePic;
    map['practicing_country'] = practicingCountry;
    map['otp_code'] = otpCode;
    map['balance'] = balance;
    map['title'] = title;
    map['city'] = city;
    map['country'] = country;
    map['is_admin'] = isAdmin;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    map['active_status'] = activeStatus;
    map['avatar'] = avatar;
    map['dark_mode'] = darkMode;
    map['messenger_color'] = messengerColor;
    map['name'] = name;
    map['email_verified_at'] = emailVerifiedAt;
    map['background'] = background;
    map['user_type'] = userType;
    return map;
  }

}