// Updated PassengerListScreen with GetX controller integration and cleaned architecture
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/assets.dart';
import '../controllers/passenger_list_controller.dart';
// Framework & Template Imports
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
    return Obx(() {
      final apiCallStatus = controller.apiCallStatus.value;
      final errorData = controller.errorData.value;
      final isLoading = apiCallStatus == ApiCallStatus.loading;

      if (apiCallStatus == ApiCallStatus.error) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar(controller),
          body: Center(
            child: ErrorCard(
              errorData:
                  errorData ??
                  ErrorData(
                    title: 'Error',
                    body: 'An unexpected error occurred.',
                    image: Assets.errorsUnknown,
                    buttonText: 'Retry',
                  ),
              refresh: controller.loadScansData,
            ),
          ),
        );
      }

      if (apiCallStatus == ApiCallStatus.empty) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar(controller),
          body: Center(
            child: ErrorCard(
              errorData: ErrorData(
                title: 'No Active Trip',
                body:
                    'Start a trip on the home screen to view ticket validation scans.',
                image: Assets.empty,
                buttonText: 'Refresh',
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
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(controller),
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
                      title: 'No Scans Recorded',
                      body:
                          'No passengers have been scanned during this trip yet.',
                      image: Assets.empty,
                      buttonText: 'Refresh',
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

  PreferredSizeWidget _buildAppBar(PassengerListController ctrl) {
    final isLoading = ctrl.apiCallStatus.value == ApiCallStatus.loading;
    String busInfo = '';
    final activeTrip = ctrl.activeTrip.value;
    if (!isLoading && activeTrip != null) {
      busInfo =
          'Bus #${activeTrip.busIdentifier} • Route ${activeTrip.route.routeNumber}';
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
        color: const Color(0xFF0B66B2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Passenger List',
                  style: TextStyle(
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: ShimmerWrapper(
        isEnabled: isLoading,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatItem(
              'Total',
              isLoading ? '--' : total.toString(),
              AppColors.mutedForeground,
            ),
            _buildStatItem(
              'Valid',
              isLoading ? '--' : valid.toString(),
              AppColors.success,
            ),
            _buildStatItem(
              'Issues',
              isLoading ? '--' : issues.toString(),
              AppColors.warning,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
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
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.foreground,
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
    BoxDecoration itemDecoration = const BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
    );
    PassengerStatus status = PassengerStatus.valid;
    if (passenger.result == 'EXPIRED') {
      status = PassengerStatus.expired;
    } else if (passenger.result == 'ALREADY_USED' ||
        passenger.isPreviouslySeen) {
      status = PassengerStatus.usedBefore;
    }

    if (!isLoading) {
      if (status == PassengerStatus.usedBefore) {
        itemDecoration = const BoxDecoration(
          color: Color(0xFFFFFBEB),
          border: Border(
            left: BorderSide(color: AppColors.warning, width: 4),
            bottom: BorderSide(color: AppColors.border, width: 0.5),
          ),
        );
      } else if (status == PassengerStatus.expired) {
        itemDecoration = const BoxDecoration(
          color: Color(0xFFFEF2F2),
          border: Border(
            left: BorderSide(color: AppColors.destructive, width: 4),
            bottom: BorderSide(color: AppColors.border, width: 0.5),
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
                _buildInitialsAvatar(truncatedInitials),
                const Padding(padding: EdgeInsets.only(left: 12)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      passenger.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foreground,
                      ),
                    ),
                    const Padding(padding: EdgeInsets.only(top: 2)),
                    Text(
                      passenger.time,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            _buildStatusBadge(status),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialsAvatar(String text) => Container(
    width: 40,
    height: 40,
    decoration: const BoxDecoration(
      color: Color(0xFFE2E8F0),
      shape: BoxShape.circle,
    ),
    alignment: Alignment.center,
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF64748B),
      ),
    ),
  );

  Widget _buildStatusBadge(PassengerStatus status) {
    Color labelColor;
    Color bgColor;
    IconData icon;
    String txt;
    switch (status) {
      case PassengerStatus.valid:
        labelColor = AppColors.success;
        bgColor = AppColors.successBg;
        icon = Icons.check_circle_outline;
        txt = 'Valid';
        break;
      case PassengerStatus.usedBefore:
        labelColor = const Color(0xFFB45309);
        bgColor = const Color(0x26F59E0B);
        icon = Icons.warning_amber_rounded;
        txt = 'Used Before';
        break;
      case PassengerStatus.expired:
        labelColor = AppColors.destructive;
        bgColor = AppColors.destructiveBg;
        icon = Icons.cancel_outlined;
        txt = 'Expired';
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
