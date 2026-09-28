import 'package:glumate_mobile/data/models/user_model.dart';

class AuthResponseModel {
  final String accessToken;
  final UserModel user;

  AuthResponseModel({
    required this.accessToken,
    required this.user,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      accessToken: json['accessToken'] as String? ?? '',
      user: UserModel.fromJson(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      ...user.toJson(),
    };
  }
}
