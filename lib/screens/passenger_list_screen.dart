// Updated PassengerListScreen with GetX controller integration and cleaned architecture
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/assets.dart';
import '../controllers/passenger_list_controller.dart';
import '../utils/api_call_status.dart';
import '../utils/error_data.dart';
import '../utils/templates/loaded_widgets_template.dart';
import '../utils/wrappers/shimmer_wrapper.dart';
import '../widgets/cards/error_card.dart';

// UI Constants
class AppColors {
  static const background = Color(0xFFFFFFFF);
  static const foreground = Color(0xFF0B2545);
  static const border = Color(0x14000000);
  static const primary = Color(0xFF0A7DC5);
  static const primaryForeground = Color(0xFFFFFFFF);
  static const secondary = Color(0xFFF0F6FF);
  static const mutedForeground = Color(0xFF65707A);
  static const success = Color(0xFF22C55E);
  static const successBg = Color(0x1A22C55E);
  static const warning = Color(0xFFFF8A00);
  static const warningBg = Color(0x1AFF8A00);
  static const destructive = Color(0xFFE02424);
  static const destructiveBg = Color(0x1AE02424);
}

enum PassengerStatus { valid, usedBefore, expired }

class PassengerListScreen extends StatelessWidget {
  const PassengerListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PassengerListController());
    final theme = Theme.of(context);
    return Obx(() {
      final apiCallStatus = controller.apiCallStatus.value;
      final errorData = controller.errorData.value;
      final isLoading = apiCallStatus == ApiCallStatus.loading;

      if (apiCallStatus == ApiCallStatus.error) {
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: _buildAppBar(context, controller),
          body: Center(
            child: ErrorCard(
              errorData:
                  errorData ??
                  ErrorData(
                    title: 'error'.tr,
                    body: 'unexpected_error'.tr,
                    image: Assets.errorsUnknown,
                    buttonText: 'retry'.tr,
                  ),
              refresh: controller.loadScansData,
            ),
          ),
        );
      }

      if (apiCallStatus == ApiCallStatus.empty) {
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: _buildAppBar(context, controller),
          body: Center(
            child: ErrorCard(
              errorData: ErrorData(
                title: 'no_active_trip'.tr,
                body: 'no_active_trip_desc'.tr,
                image: Assets.empty,
                buttonText: 'refresh'.tr,
              ),
              refresh: controller.loadScansData,
            ),
          ),
        );
      }

      final List<ScannedPassenger> displayList = isLoading
          ? List.generate(
              5,
              (i) => ScannedPassenger(
                id: '$i',
                name: 'Placeholder Name',
                time: '--:--',
                result: 'VALID',
                isPreviouslySeen: false,
              ),
            )
          : controller.scans;

      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: _buildAppBar(context, controller),
        body: Column(
          children: [
            StatsBar(
              total: controller.totalScans.value,
              valid: controller.validScans.value,
              issues: controller.issueScans.value,
              isLoading: isLoading,
            ),
            Expanded(
              child: LoadedListWidget(
                apiCallStatus: apiCallStatus,
                errorData: errorData,
                list: displayList,
                onReload: controller.loadScansData,
                onEmpty: Center(
                  child: ErrorCard(
                    errorData: ErrorData(
                      title: 'no_scans_recorded'.tr,
                      body: 'no_scans_recorded_desc'.tr,
                      image: Assets.empty,
                      buttonText: 'refresh'.tr,
                    ),
                    refresh: controller.loadScansData,
                  ),
                ),
                loadingChild: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: 5,
                  itemBuilder: (c, i) =>
                      PassengerItem(passenger: displayList[i], isLoading: true),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: displayList.length,
                  itemBuilder: (c, i) => PassengerItem(
                    passenger: displayList[i],
                    isLoading: false,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, PassengerListController ctrl) {
    final isLoading = ctrl.apiCallStatus.value == ApiCallStatus.loading;
    final theme = Theme.of(context);
    String busInfo = '';
    final activeTrip = ctrl.activeTrip.value;
    if (!isLoading && activeTrip != null) {
      busInfo = 'bus_route_info'.trParams({
        'bus': activeTrip.busIdentifier,
        'route': activeTrip.route.routeNumber,
      });
    }
    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: Container(
        padding: const EdgeInsets.only(
          top: 30,
          left: 20,
          right: 20,
          bottom: 12,
        ),
        color: theme.colorScheme.primary,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'passenger_list'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Padding(padding: EdgeInsets.only(top: 2)),
                Text(
                  busInfo,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: ctrl.loadScansData,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.refresh, size: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatsBar extends StatelessWidget {
  final int total;
  final int valid;
  final int issues;
  final bool isLoading;

  const StatsBar({
    super.key,
    required this.total,
    required this.valid,
    required this.issues,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final warningColor = const Color(0xFFFF8A00);
    final successColor = const Color(0xFF22C55E);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: ShimmerWrapper(
        isEnabled: isLoading,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatItem(
              context,
              'total'.tr,
              isLoading ? '--' : total.toString(),
              theme.textTheme.bodySmall?.color ?? const Color(0xFF65707A),
            ),
            _buildStatItem(
              context,
              'valid'.tr,
              isLoading ? '--' : valid.toString(),
              successColor,
            ),
            _buildStatItem(
              context,
              'issues'.tr,
              isLoading ? '--' : issues.toString(),
              warningColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, Color color) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
        const Padding(padding: EdgeInsets.only(top: 2)),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }
}

class PassengerItem extends StatelessWidget {
  final ScannedPassenger passenger;
  final bool isLoading;

  const PassengerItem({
    super.key,
    required this.passenger,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final warningColor = const Color(0xFFFF8A00);
    final errorColor = theme.colorScheme.error;

    BoxDecoration itemDecoration = BoxDecoration(
      color: theme.cardColor,
      border: Border(bottom: BorderSide(color: theme.dividerColor, width: 0.5)),
    );
    PassengerStatus status = PassengerStatus.valid;
    if (passenger.result == 'EXPIRED') {
      status = PassengerStatus.expired;
    } else if (passenger.result == 'ALREADY_USED') {
      status = PassengerStatus.usedBefore;
    }

    if (!isLoading) {
      if (status == PassengerStatus.usedBefore) {
        itemDecoration = BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? warningColor.withOpacity(0.08)
              : const Color(0xFFFFFBEB),
          border: Border(
            left: BorderSide(color: warningColor, width: 4),
            bottom: BorderSide(color: theme.dividerColor, width: 0.5),
          ),
        );
      } else if (status == PassengerStatus.expired) {
        itemDecoration = BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? errorColor.withOpacity(0.08)
              : const Color(0xFFFEF2F2),
          border: Border(
            left: BorderSide(color: errorColor, width: 4),
            bottom: BorderSide(color: theme.dividerColor, width: 0.5),
          ),
        );
      }
    }

    final nameInitials = passenger.name.isNotEmpty
        ? passenger.name
            .split(' ')
            .map((e) => e.substring(0, 1))
            .join()
            .toUpperCase()
        : '??';
    final truncatedInitials = nameInitials.length > 2
        ? nameInitials.substring(0, 2)
        : nameInitials;

    return Container(
      padding: EdgeInsets.only(
        left: (status == PassengerStatus.valid || isLoading) ? 20 : 16,
        right: 20,
        top: 12,
        bottom: 12,
      ),
      decoration: itemDecoration,
      child: ShimmerWrapper(
        isEnabled: isLoading,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _buildInitialsAvatar(context, truncatedInitials),
                const Padding(padding: EdgeInsets.only(left: 12)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      passenger.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const Padding(padding: EdgeInsets.only(top: 2)),
                    Text(
                      passenger.time,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodySmall?.color ?? const Color(0xFF65707A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            _buildStatusBadge(context, status),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialsAvatar(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: theme.brightness == Brightness.dark ? Colors.white70 : const Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, PassengerStatus status) {
    final theme = Theme.of(context);
    Color labelColor;
    Color bgColor;
    IconData icon;
    String txt;
    switch (status) {
      case PassengerStatus.valid:
        labelColor = const Color(0xFF22C55E);
        bgColor = const Color(0xFF22C55E).withOpacity(0.1);
        icon = Icons.check_circle_outline;
        txt = 'valid'.tr;
        break;
      case PassengerStatus.usedBefore:
        labelColor = const Color(0xFFB45309);
        bgColor = const Color(0xFFB45309).withOpacity(0.1);
        icon = Icons.warning_amber_rounded;
        txt = 'used_before'.tr;
        break;
      case PassengerStatus.expired:
        labelColor = theme.colorScheme.error;
        bgColor = theme.colorScheme.error.withOpacity(0.1);
        icon = Icons.cancel_outlined;
        txt = 'expired'.tr;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: labelColor),
          const Padding(padding: EdgeInsets.only(left: 6)),
          Text(
            txt,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }
}
