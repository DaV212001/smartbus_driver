import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:smartbus_driver/screens/analytics_screen.dart';
import 'package:smartbus_driver/screens/passenger_list_screen.dart';
import 'package:smartbus_driver/screens/scan_screen.dart';
import 'package:smartbus_driver/screens/settings/settings_screen.dart';

import '../controllers/scan_controller.dart';
import 'home_screen.dart';

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen>
    with WidgetsBindingObserver {
  final PersistentTabController _controller = PersistentTabController(
    initialIndex: 0,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Get.put(ScanController());
    // Register the tab controller so ScanController can switch tabs
    Get.put(_controller, tag: 'mainNav');
    _controller.addListener(_handleTabChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleTabChange();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_handleTabChange);
    try {
      Get.delete<PersistentTabController>(tag: 'mainNav');
    } catch (_) {}
    _controller.dispose();
    try {
      Get.delete<ScanController>();
    } catch (_) {}
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _handleTabChange();
    }
  }

  void _handleTabChange() {
    try {
      final scanController = Get.find<ScanController>();
      scanController.onTabVisibilityChanged(_controller.index == 2);
    } catch (_) {
      // ScanController might not be initialized yet
    }
  }

  List<Widget> _buildScreens() {
    return [
      const HomeScreen(),
      const PassengerListScreen(),
      const TicketScannerScreen(),
      AnalyticsScreen(),
      SettingsScreen(),
    ];
  }

  List<PersistentBottomNavBarItem> _navBarsItems(BuildContext context) {
    return [
      PersistentBottomNavBarItem(
        icon: const Icon(LucideIcons.home),
        title: 'bottom_nav_home'.tr,
        activeColorPrimary: Theme.of(context).primaryColor,
        inactiveColorPrimary: const Color(0xFF64748B),
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(LucideIcons.list),
        title: 'bottom_nav_passengers'.tr,
        activeColorPrimary: Theme.of(context).primaryColor,
        inactiveColorPrimary: const Color(0xFF64748B),
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(LucideIcons.qrCode, color: Colors.white),
        title: 'bottom_nav_scan'.tr,
        activeColorPrimary: Theme.of(context).primaryColor,
        inactiveColorPrimary: const Color(0xFF64748B),
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(LucideIcons.lineChart),
        title: 'bottom_nav_analytics'.tr,
        activeColorPrimary: Theme.of(context).primaryColor,
        inactiveColorPrimary: const Color(0xFF64748B),
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(LucideIcons.user),
        title: 'bottom_nav_profile'.tr,
        activeColorPrimary: Theme.of(context).primaryColor,
        inactiveColorPrimary: const Color(0xFF64748B),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PersistentTabView(
      context,
      controller: _controller,
      navBarHeight: 80,
      screens: _buildScreens(),
      items: _navBarsItems(context),
      confineToSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      handleAndroidBackButtonPress: true,
      // resizeToAvoidBottomInset: true,
      stateManagement: true,
      padding: const EdgeInsets.all(16),
      hideNavigationBarWhenKeyboardAppears: true,
      decoration: NavBarDecoration(
        borderRadius: BorderRadius.circular(0.0),
        colorBehindNavBar: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor, width: 1.0),
        ),
      ),
      // popAllScreensOnTapOfSelectedTab: true,
      // popActionScreens: PopActionScreensType.all,
      // itemAnimationProperties: const ItemAnimationProperties(
      //   duration: Duration(milliseconds: 200),
      //   curve: Curves.ease,
      // ),
      // screenTransitionProperties: const ScreenTransitionProperties(
      //   animateTabTransition: true,
      //   curve: Curves.ease,
      //   duration: Duration(milliseconds: 200),
      // ),
      navBarStyle: NavBarStyle.style15, // Choose the nav bar style!
    );
  }
}
