import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../controllers/auth_controller.dart';

class LoginScreen extends GetView<AuthController> {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'login'.tr,
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Theme.of(context).dividerColor, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Obx(
              () => Container(
                width: double.infinity,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  children: [
                    _buildTypeToggle(
                      context,
                      'PHONE',
                      LucideIcons.phone,
                      'phone'.tr,
                    ),
                    _buildTypeToggle(
                      context,
                      'EMAIL',
                      LucideIcons.mail,
                      'email'.tr,
                    ),
                    _buildTypeToggle(context, 'Fayda ID', LucideIcons.qrCode, 'fid'.tr),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Obx(() {
              if (controller.loginType.value == 'PHONE') {
                return _buildInputField(
                  context: context,
                  controller: controller.phoneController,
                  label: 'phone_number'.tr,
                  icon: LucideIcons.phone,
                  hint: '09xxxxxxxx',
                  keyboardType: TextInputType.phone,
                );
              } else if (controller.loginType.value == 'EMAIL') {
                return _buildInputField(
                  context: context,
                  controller: controller.emailController,
                  label: 'email'.tr,
                  icon: LucideIcons.mail,
                  hint: 'example@mail.com',
                  keyboardType: TextInputType.emailAddress,
                );
              } else {
                return _buildInputField(
                  context: context,
                  controller: controller.fidController,
                  label: 'fid'.tr,
                  icon: LucideIcons.qrCode,
                  hint: 'fid_hint'.tr,
                  suffixIcon: IconButton(
                    icon: Icon(
                      LucideIcons.scanLine,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: controller.scanBarcode,
                  ),
                );
              }
            }),
            const SizedBox(height: 20),
            Obx(
              () => _buildInputField(
                context: context,
                controller: controller.passwordController,
                label: 'password'.tr,
                icon: LucideIcons.lock,
                hint: '••••••••',
                isPassword: true,
                obscureText: !controller.isPasswordVisible.value,
                toggleVisibility: controller.togglePasswordVisibility,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Get.toNamed('/forgot-password'),
                child: Text(
                  'forgot_password'.tr,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: Obx(
                () => ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : controller.login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: controller.isLoading.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'login'.tr,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeToggle(
    BuildContext context,
    String type,
    IconData icon,
    String label,
  ) {
    final theme = Theme.of(context);
    final isSelected = controller.loginType.value == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.setLoginType(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : (theme.textTheme.bodySmall?.color ?? const Color(0xFF64748B)),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : (theme.textTheme.bodySmall?.color ?? const Color(0xFF64748B)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? toggleVisibility,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    final theme = Theme.of(context);
    final inputBorderColor = theme.dividerColor;
    final hintColor = theme.textTheme.bodySmall?.color?.withOpacity(0.5) ?? const Color(0xFF94A3B8);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: theme.textTheme.bodySmall?.color ?? const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: inputBorderColor),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: TextStyle(
              fontSize: 14,
              color: theme.textTheme.bodyLarge?.color,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: hintColor),
              prefixIcon: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Icon(icon, color: hintColor, size: 20),
              ),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        obscureText ? LucideIcons.eyeOff : LucideIcons.eye,
                        color: hintColor,
                        size: 20,
                      ),
                      onPressed: toggleVisibility,
                    )
                  : suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
