import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../config/storage_config.dart';
import '../constants/assets.dart';
import '../controllers/home_controller.dart';
import '../models/trip_model.dart';
import '../utils/api_call_status.dart';
import '../utils/error_data.dart';
import '../utils/wrappers/shimmer_wrapper.dart';
import '../widgets/animated_widgets/loading_animation_button.dart';
import '../widgets/cards/error_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());
    var theme = Theme.of(context);

    return Scaffold(
      body: Obx(() {
        final apiCallStatus = controller.apiCallStatus.value;
        final errorData = controller.errorData.value;
        final activeTrip = controller.activeTrip.value;
        final tripsCompleted = controller.tripsCompleted.value;
        final passengersTransported = controller.passengersTransported.value;
        final isLoading = apiCallStatus == ApiCallStatus.loading;
        final isActionLoading = controller.isActionLoading.value;

        if (apiCallStatus == ApiCallStatus.error) {
          return Center(
            child: ErrorCard(
              errorData:
                  errorData ??
                  ErrorData(
                    title: 'error'.tr,
                    body: 'unexpected_error'.tr,
                    image: Assets.errorsUnknown,
                    buttonText: 'retry'.tr,
                  ),
              refresh: controller.loadDashboardData,
            ),
          );
        }

        if (apiCallStatus == ApiCallStatus.empty) {
          return Center(
            child: ErrorCard(
              errorData: ErrorData(
                title: 'no_trips_assigned'.tr,
                body: 'no_trips_assigned_desc'.tr,
                image: Assets.empty,
                buttonText: 'refresh'.tr,
              ),
              refresh: controller.loadDashboardData,
            ),
          );
        }

        final userStr = ConfigPreference.getUserToken();
        Map<String, dynamic>? userJson;
        if (userStr != null) {
          try {
            userJson = json.decode(userStr);
          } catch (_) {}
        }
        final driverName = userJson?['fullName'] ?? 'Abebe Bikila';

        String busInfo = 'bus_route_info_default'.tr;
        String dutyStatus = 'off_duty'.tr;
        if (!isLoading && activeTrip != null) {
          busInfo = 'bus_route_info'.trParams({
            'bus': activeTrip.busIdentifier,
            'route': activeTrip.route.routeNumber,
          });
          dutyStatus = activeTrip.status == 'IN_PROGRESS'
              ? 'on_duty'.tr
              : 'ready'.tr;
        }

        return Column(
          children: [
            _DriverHeader(
              driverName: 'hello_driver'.trParams({'driver': driverName}),
              busInfo: busInfo,
              status: dutyStatus,
            ),

            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.loadDashboardData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle(title: 'current_assignment'.tr),
                      _AssignmentCard(
                        trip: activeTrip,
                        isLoading: isLoading,
                        onAction: controller.handleTripAction,
                        isActionLoading: isActionLoading,
                      ),

                      _SectionTitle(title: "todays_activity".tr),
                      _StatsGrid(
                        tripsCompleted: tripsCompleted,
                        passengersTransported: passengersTransported,
                        isLoading: isLoading,
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _SectionTitle(title: 'recent_alerts'.tr),
                          Obx(() {
                            if (controller.notifications.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(
                                right: 20,
                                top: 24,
                                bottom: 12,
                              ),
                              child: TextButton(
                                onPressed: controller.clearAllNotifications,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'clear_all'.tr,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                      Obx(() {
                        if (controller.notifications.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              'no_recent_alerts'.tr,
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.color,
                                fontSize: 13,
                              ),
                            ),
                          );
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: controller.notifications.length > 5
                              ? 5
                              : controller.notifications.length,
                          itemBuilder: (context, index) {
                            final notification =
                                controller.notifications[index];
                            return InkWell(
                              onTap: () => controller.markAsRead(index),
                              child: _AlertCard(
                                icon: LucideIcons.bell,
                                iconColor: notification['isRead'] == true
                                    ? Colors.grey
                                    : Theme.of(context).colorScheme.primary,
                                backgroundColor: notification['isRead'] == true
                                    ? Colors.grey.withOpacity(0.05)
                                    : Theme.of(
                                        context,
                                      ).colorScheme.primary.withOpacity(0.05),
                                borderColor: notification['isRead'] == true
                                    ? Colors.grey.withOpacity(0.1)
                                    : Theme.of(
                                        context,
                                      ).colorScheme.primary.withOpacity(0.1),
                                title: notification['title'] ?? '',
                                message: notification['body'] ?? '',
                                titleColor: notification['isRead'] == true
                                    ? Colors.grey
                                    : Theme.of(context).colorScheme.primary,
                                messageColor:
                                    Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color ??
                                    Colors.black,
                              ),
                            );
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _DriverHeader extends StatelessWidget {
  final String driverName;
  final String busInfo;
  final String status;

  const _DriverHeader({
    required this.driverName,
    required this.busInfo,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.primary,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                driverName,
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
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Text(
              status,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: theme.textTheme.bodySmall?.color ?? const Color(0xFF6B7280),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final TripModel? trip;
  final bool isLoading;
  final VoidCallback? onAction;
  final bool isActionLoading;

  const _AssignmentCard({
    required this.trip,
    required this.isLoading,
    this.onAction,
    required this.isActionLoading,
  });

  String _formatTimeOnly(DateTime dt) {
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final min = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:$min $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String routeNumber = isLoading || trip == null
        ? 'route_label_default'.tr
        : 'route_label'.trParams({'route': trip!.route.routeNumber});
    final String time = isLoading || trip == null
        ? '--:-- --'
        : _formatTimeOnly(trip!.scheduledFor);

    String fromStop = 'starting_stop'.tr;
    String toStop = 'destination_stop'.tr;
    if (!isLoading && trip != null) {
      final name = trip!.route.name;
      final parts = name.split(RegExp(r'\s+to\s+|\s+To\s+|\s+↔\s+'));
      if (parts.length >= 2) {
        fromStop = parts[0].trim();
        toStop = parts[1].trim();
      } else {
        fromStop = name;
        toStop = 'Terminal';
      }
    }

    final isStart = trip?.status == 'SCHEDULED';
    final buttonText = isStart ? 'start_trip'.tr : 'end_trip'.tr;
    final buttonColor = isStart
        ? const Color(0xFF16A34A)
        : const Color(0xFFDC2626);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: ShimmerWrapper(
        isEnabled: isLoading,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  routeNumber,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
            const Padding(padding: EdgeInsets.only(top: 20)),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'from_label'.tr.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                      const Padding(padding: EdgeInsets.only(top: 4)),
                      Text(
                        fromStop,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.arrowRight,
                  color:
                      theme.textTheme.bodySmall?.color ??
                      const Color(0xFF94A3B8),
                  size: 20,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'to_label'.tr.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                      const Padding(padding: EdgeInsets.only(top: 4)),
                      Text(
                        toStop,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Padding(padding: EdgeInsets.only(top: 20)),
            isLoading
                ? Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  )
                : SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: isActionLoading
                        ? Center(
                            child: LoadingAnimatedButton(
                              width: MediaQuery.of(context).size.width - 80,
                              height: 48,
                              color: buttonColor,
                              borderRadius: 6.0,
                              borderWidth: 2.0,
                              onTap: () {},
                              child: Text(
                                buttonText,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: onAction,
                            icon: Icon(
                              isStart
                                  ? LucideIcons.playCircle
                                  : LucideIcons.stopCircle,
                              size: 20,
                              color: Colors.white,
                            ),
                            label: Text(
                              buttonText,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: buttonColor,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final int tripsCompleted;
  final int passengersTransported;
  final bool isLoading;

  const _StatsGrid({
    required this.tripsCompleted,
    required this.passengersTransported,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: LucideIcons.bus,
              iconColor: const Color(0xFF2563EB),
              iconBg: const Color(0xFFDBEAFE),
              value: tripsCompleted.toString(),
              label: 'trips_completed'.tr,
              isLoading: isLoading,
            ),
          ),
          const Padding(padding: EdgeInsets.only(left: 12)),
          Expanded(
            child: _StatCard(
              icon: LucideIcons.users,
              iconColor: const Color(0xFF16A34A),
              iconBg: const Color(0xFFDCFCE7),
              value: passengersTransported.toString(),
              label: 'passengers'.tr,
              isLoading: isLoading,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String value;
  final String label;
  final bool isLoading;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.value,
    required this.label,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: ShimmerWrapper(
        isEnabled: isLoading,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? iconColor.withOpacity(0.12)
                    : iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const Padding(padding: EdgeInsets.only(top: 8)),
            Text(
              isLoading ? '--' : value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const Padding(padding: EdgeInsets.only(top: 4)),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;
  final String title;
  final String message;
  final Color titleColor;
  final Color messageColor;

  const _AlertCard({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.title,
    required this.message,
    required this.titleColor,
    required this.messageColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final resolvedBg = isDark ? iconColor.withOpacity(0.08) : backgroundColor;
    final resolvedBorder = isDark ? iconColor.withOpacity(0.24) : borderColor;
    final resolvedTitle = isDark ? iconColor.withOpacity(0.9) : titleColor;
    final resolvedMessage = isDark
        ? theme.textTheme.bodyMedium?.color
        : messageColor;

    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: resolvedBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: resolvedBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const Padding(padding: EdgeInsets.only(left: 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: resolvedTitle,
                  ),
                ),
                const Padding(padding: EdgeInsets.only(top: 2)),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    color: resolvedMessage,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
