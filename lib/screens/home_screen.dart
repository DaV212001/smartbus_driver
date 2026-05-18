import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../config/storage_config.dart';
import '../constants/assets.dart';
import '../controllers/home_controller.dart';
import '../models/trip_model.dart';
// Framework & Template Imports
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
                    title: 'Error',
                    body: 'An unexpected error occurred.',
                    image: Assets.errorsUnknown,
                    buttonText: 'Retry',
                  ),
              refresh: controller.loadDashboardData,
            ),
          );
        }

        if (apiCallStatus == ApiCallStatus.empty) {
          return Center(
            child: ErrorCard(
              errorData: ErrorData(
                title: 'No Trips Assigned',
                body: 'You have no trips assigned to you today.',
                image: Assets.empty,
                buttonText: 'Refresh',
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

        String busInfo = 'Bus #104 • ET-12345';
        String dutyStatus = 'Off Duty';
        if (!isLoading && activeTrip != null) {
          busInfo =
              'Bus ${activeTrip.busIdentifier} • Route ${activeTrip.route.routeNumber}';
          dutyStatus = activeTrip.status == 'IN_PROGRESS' ? 'On Duty' : 'Ready';
        }

        return Column(
          children: [
            _DriverHeader(
              driverName: 'Hello, $driverName',
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
                      const _SectionTitle(title: 'Current Assignment'),
                      _AssignmentCard(
                        trip: activeTrip,
                        isLoading: isLoading,
                        onAction: controller.handleTripAction,
                        isActionLoading: isActionLoading,
                      ),

                      const _SectionTitle(title: "Today's Activity"),
                      _StatsGrid(
                        tripsCompleted: tripsCompleted,
                        passengersTransported: passengersTransported,
                        isLoading: isLoading,
                      ),

                      const _SectionTitle(title: 'Recent Alerts'),
                      _AlertCard(
                        icon: LucideIcons.mapPin,
                        iconColor: Theme.of(context).colorScheme.primary,
                        backgroundColor: const Color(0xFFEFF6FF),
                        borderColor: const Color(0xFFBFDBFE),
                        title: 'Weraj Request',
                        message:
                            'Passenger requesting drop-off at Bole Bridge Stop.',
                        titleColor: const Color(0xFF1E40AF),
                        messageColor: const Color(0xFF3B82F6),
                      ),
                      _AlertCard(
                        icon: LucideIcons.alertTriangle,
                        iconColor: const Color(0xFFD97706),
                        backgroundColor: const Color(0xFFFFFBEB),
                        borderColor: const Color(0xFFFDE68A),
                        title: 'System Update',
                        message: 'Peak hour traffic reported near Meskel Square.',
                        titleColor: const Color(0xFFB45309),
                        messageColor: const Color(0xFFD97706),
                      ),
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
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6B7280),
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
    final String routeNumber =
        isLoading || trip == null ? 'Route --' : 'Route ${trip!.route.routeNumber}';
    final String time =
        isLoading || trip == null ? '--:-- --' : _formatTimeOnly(trip!.scheduledFor);

    String fromStop = 'Origin Stop';
    String toStop = 'Destination Stop';
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
    final buttonText = isStart ? 'Start Trip' : 'End Trip';
    final buttonColor =
        isStart ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x14000000)),
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
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
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
                      const Text(
                        'FROM',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const Padding(padding: EdgeInsets.only(top: 4)),
                      Text(
                        fromStop,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  LucideIcons.arrowRight,
                  color: Color(0xFF94A3B8),
                  size: 20,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'TO',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const Padding(padding: EdgeInsets.only(top: 4)),
                      Text(
                        toStop,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
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
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(6),
                  ),
                )
                : SizedBox(
                  width: double.infinity,
                  height: 48,
                  child:
                      isActionLoading
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
              label: 'Trips Completed',
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
              label: 'Passengers',
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x14000000)),
      ),
      child: ShimmerWrapper(
        isEnabled: isLoading,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const Padding(padding: EdgeInsets.only(top: 8)),
            Text(
              isLoading ? '--' : value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0B1A2B),
              ),
            ),
            const Padding(padding: EdgeInsets.only(top: 4)),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
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
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
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
                    color: titleColor,
                  ),
                ),
                const Padding(padding: EdgeInsets.only(top: 2)),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    color: messageColor,
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
