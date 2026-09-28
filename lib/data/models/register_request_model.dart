class RegisterRequestModel {
  final String firstname;
  final String lastname;
  final String email;
  final String password;
  final String? phone;
  final DateTime? dateOfBirth;
  final String? gender;
  final double? weight;
  final double? height;

  RegisterRequestModel({
    required this.firstname,
    required this.lastname,
    required this.email,
    required this.password,
    this.phone,
    this.dateOfBirth,
    this.gender,
    this.weight,
    this.height,
  });

  Map<String, dynamic> toJson() {
    return {
      'firstname': firstname.trim(),
      'lastname': lastname.trim(),
      'email': email.trim(),
      'password': password,
      'phone': phone,
      'dateOfBirth': dateOfBirth?.toIso8601String().split('T').first,
      'gender': gender,
      'weight': weight,
      'height': height,
    };
  }
}
