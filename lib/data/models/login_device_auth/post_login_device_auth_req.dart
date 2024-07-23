class PostLoginDeviceAuthReq {
  String? email;
  String? password;
  String? deviceType;
  String? deviceId;

  PostLoginDeviceAuthReq(
      {this.email, this.password, this.deviceType, this.deviceId});

  PostLoginDeviceAuthReq.fromJson(Map<String, dynamic> json) {
    email = json['email'];
    password = json['password'];
    deviceType = json['device_type'];
    deviceId = json['device_id'];
  }
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (email != null) {
      data['email'] = email;
    }
    if (password != null) {
      data['password'] = password;
    }
    if (deviceType != null) {
      data['device_type'] = deviceType;
    }
    if (deviceId != null) {
      data['device_id'] = deviceId;
    }
    return data;
  }
}
