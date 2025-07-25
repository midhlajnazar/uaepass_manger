class UAEPASSUserProfile {
  String? sub;
  String? fullNameAR;
  String? gender;
  String? mobile;
  String? lastNameEN;
  String? fullNameEN;
  String? uuid;
  String? lastNameAR;
  String? idn;
  String? nationalityEN;
  String? firstNameEN;
  String? userType;
  String? nationalityAR;
  String? firstNameAR;
  String? email;

  UAEPASSUserProfile(
      {this.sub,
      this.fullNameAR,
      this.gender,
      this.mobile,
      this.lastNameEN,
      this.fullNameEN,
      this.uuid,
      this.lastNameAR,
      this.idn,
      this.nationalityEN,
      this.firstNameEN,
      this.userType,
      this.nationalityAR,
      this.firstNameAR,
      this.email});

  UAEPASSUserProfile.fromJson(Map<String, dynamic> json) {
    sub = json['sub'];
    fullNameAR = json['fullnameAR'];
    gender = json['gender'];
    mobile = json['mobile'];
    lastNameEN = json['lastnameEN'];
    fullNameEN = json['fullnameEN'];
    uuid = json['uuid'];
    lastNameAR = json['lastnameAR'];
    idn = json['idn'];
    nationalityEN = json['nationalityEN'];
    firstNameEN = json['firstnameEN'];
    userType = json['userType'];
    nationalityAR = json['nationalityAR'];
    firstNameAR = json['firstnameAR'];
    email = json['email'];
  }

  Map<String, dynamic> toJson() {
    return {
      'sub': sub,
      'fullnameAR': fullNameAR,
      'gender': gender,
      'mobile': mobile,
      'lastnameEN': lastNameEN,
      'fullnameEN': fullNameEN,
      'uuid': uuid,
      'lastnameAR': lastNameAR,
      'idn': idn,
      'nationalityEN': nationalityEN,
      'firstnameEN': firstNameEN,
      'userType': userType,
      'nationalityAR': nationalityAR,
      'firstnameAR': firstNameAR,
      'email': email,
    };
  }
}
