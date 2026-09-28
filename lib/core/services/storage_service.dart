import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:glumate_mobile/data/models/user_model.dart';

class StorageService {
  static StorageService? _instance;
  static SharedPreferences? _prefs;

  StorageService._();

  static Future<StorageService> getInstance() async {
    if (_instance == null) {
      _instance = StorageService._();
      _prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  Future<void> saveToken(String token) async {
    await _prefs!.setString('glumate_access_token', token);
  }

  String? getToken() {
    return _prefs!.getString('glumate_access_token');
  }

  Future<void> removeToken() async {
    await _prefs!.remove('glumate_access_token');
  }

  Future<void> saveUser(UserModel user) async {
    final userJson = jsonEncode(user.toJson());
    await _prefs!.setString('glumate_user_data', userJson);
  }

  UserModel? getUser() {
    final userJson = _prefs!.getString('glumate_user_data');
    if (userJson == null) return null;
    return UserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
  }

  Future<void> removeUser() async {
    await _prefs!.remove('glumate_user_data');
  }

  Future<void> clearAll() async {
    await _prefs!.clear();
  }
}
