import 'dart:convert';

import 'package:get/get.dart';

import '../config/storage_config.dart';
import '../models/user.dart';

class UserController extends GetxController {
  static UserController get instance => Get.find();

  final Rxn<User> user = Rxn<User>();

  @override
  void onInit() {
    super.onInit();
    fetchUser();
  }

  void fetchUser() {
    String? userJson = ConfigPreference.getUserToken();
    if (userJson != null) {
      try {
        Map<String, dynamic> userMap = json.decode(userJson);
        user.value = User.fromJson(userMap);
      } catch (e) {
        print("Error parsing user data: $e");
      }
    }
  }

  void clearUser() {
    user.value = null;
  }
}
