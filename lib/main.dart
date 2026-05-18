import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:smartbus_driver/screens/login_screen.dart';
import 'package:smartbus_driver/screens/main_layout_screen.dart';
import 'package:smartbus_driver/screens/reset_password_screen.dart';
import 'package:smartbus_driver/screens/settings/password/forgot_password_screen.dart';
import 'package:smartbus_driver/screens/verify_otp_screen.dart';

import 'config/storage_config.dart';
import 'config/translation.dart';
import 'constants/user_controller.dart';
import 'controllers/auth_controller.dart';
import 'controllers/theme_mode_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ConfigPreference.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize Controllers
    // ThemeModeController requires context for its theme generation logic
    Get.put(ThemeModeController(context));
    Get.put(AuthController());
    Get.put(UserController());

    return Obx(
      () => ScreenUtilInit(
        child: GetMaterialApp(
          title: 'SmartBus',
          debugShowCheckedModeBanner: false,
          theme: ThemeModeController.getThemeMode(),
          locale: ThemeModeController.getLocale(),
          translations: AppTranslations(),
          // Route Management
          initialRoute: ConfigPreference.isUserLoggedIn() ? '/home' : '/login',
          getPages: [
            GetPage(
              name: '/login',
              page: () => const LoginScreen(),
              transition: Transition.fadeIn,
            ),
            GetPage(
              name: '/forgot-password',
              page: () => const ForgotPasswordScreen(),
              transition: Transition.rightToLeft,
            ),
            GetPage(
              name: '/reset-password',
              page: () => const ResetPasswordScreen(),
              transition: Transition.rightToLeft,
            ),
            GetPage(
              name: '/verify-otp',
              page: () => const OtpScreen(),
              transition: Transition.rightToLeft,
            ),
            GetPage(
              name: '/home',
              page: () => const MainLayoutScreen(),
              transition: Transition.fadeIn,
            ),
          ],
        ),
      ),
    );
  }
}
