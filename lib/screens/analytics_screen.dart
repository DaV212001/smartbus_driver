import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../constants/assets.dart';
import '../controllers/analytics_controller.dart';
import '../models/trip_model.dart';
import '../utils/api_call_status.dart';
import '../utils/error_data.dart';
import '../utils/templates/loaded_widgets_template.dart';
import '../utils/wrappers/shimmer_wrapper.dart';
import '../widgets/cards/error_card.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AnalyticsController());
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
              refresh: controller.loadAnalytics,
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
                title: 'no_trip_history'.tr,
                body: 'no_trip_history_desc'.tr,
                image: Assets.empty,
                buttonText: 'refresh'.tr,
              ),
              refresh: controller.loadAnalytics,
            ),
          ),
        );
      }

      final displayTrips = isLoading
          ? List.generate(
              3,
              (i) => TripModel(
                id: i.toString(),
                routeId: (100 + i).toString(),
                driverId: '300',
                scheduledFor: DateTime.now(),
                status: 'COMPLETED',
                passengerCount: 15 + i * 5,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                busIdentifier: 'Bus #10$i',
                route: RouteModel(
                  id: (100 + i).toString(),
                  routeNumber: 'R-0$i',
                  nameEn: 'Route $i',
                  nameAm: 'Route $i',
                ),
              ),
            )
          : controller.recentTrips;

      final chartTrips = controller.recentTrips;

      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: _buildAppBar(context, controller),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TodayStatsSection(
                tripsCount: controller.todayTripsCount.value,
                passengersCount: controller.todayPassengersCount.value,
                tripsDiff:
                    controller.todayTripsCount.value -
                    controller.yesterdayTripsCount.value,
                passengersDiff:
                    controller.todayPassengersCount.value -
                    controller.yesterdayPassengersCount.value,
                isLoading: isLoading,
              ),
              _ChartSection(chartTrips: chartTrips, isLoading: isLoading),
              _TripLogSection(displayTrips: displayTrips, isLoading: isLoading),
            ],
          ),
        ),
      );
    });
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AnalyticsController ctrl,
  ) {
    final theme = Theme.of(context);
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
                  'driver_dashboard'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: ctrl.loadAnalytics,
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

class _TodayStatsSection extends StatelessWidget {
  final int tripsCount;
  final int passengersCount;
  final int tripsDiff;
  final int passengersDiff;
  final bool isLoading;

  const _TodayStatsSection({
    required this.tripsCount,
    required this.passengersCount,
    required this.tripsDiff,
    required this.passengersDiff,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'todays_stats'.tr,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleMedium?.color,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TodayStatCard(
                  icon: LucideIcons.bus,
                  iconColor: const Color(0xFF2563EB),
                  bgColor: const Color(0xFFEFF6FF),
                  value: tripsCount.toString(),
                  label: 'trips_completed_today'.tr,
                  difference: tripsDiff,
                  isLoading: isLoading,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TodayStatCard(
                  icon: LucideIcons.users,
                  iconColor: const Color(0xFF16A34A),
                  bgColor: const Color(0xFFF0FDF4),
                  value: passengersCount.toString(),
                  label: 'passengers_transported'.tr,
                  difference: passengersDiff,
                  isLoading: isLoading,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TodayStatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String value;
  final String label;
  final int difference;
  final bool isLoading;

  const _TodayStatCard({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.value,
    required this.label,
    required this.difference,
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
                    : bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(height: 12),
            Text(
              isLoading ? '--' : value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 8),
            _buildDiffWidget(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDiffWidget(BuildContext context) {
    final theme = Theme.of(context);
    if (isLoading) {
      return Container(
        width: 60,
        height: 12,
        decoration: BoxDecoration(
          color: theme.dividerColor,
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }
    if (difference > 0) {
      return Row(
        children: [
          const Icon(Icons.trending_up, color: Color(0xFF16A34A), size: 14),
          const SizedBox(width: 4),
          Text(
            'plus_vs_yesterday'.trParams({'count': difference.toString()}),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF16A34A),
            ),
          ),
        ],
      );
    } else if (difference < 0) {
      return Row(
        children: [
          const Icon(Icons.trending_down, color: Color(0xFFDC2626), size: 14),
          const SizedBox(width: 4),
          Text(
            'minus_vs_yesterday'.trParams({'count': difference.toString()}),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFFDC2626),
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Icon(
            Icons.trending_flat,
            color: theme.textTheme.bodySmall?.color ?? const Color(0xFF6B7280),
            size: 14,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'same_as_yesterday'.tr,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color:
                    theme.textTheme.bodySmall?.color ?? const Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      );
    }
  }
}

class _ChartSection extends StatelessWidget {
  final List<TripModel> chartTrips;
  final bool isLoading;

  const _ChartSection({required this.chartTrips, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'passenger_volume'.tr,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleMedium?.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isLoading
                ? 'last_trips_default'.tr
                : 'last_trips'.trParams({
                    'count': chartTrips.length.toString(),
                  }),
            style: TextStyle(
              fontSize: 12,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            padding: const EdgeInsets.only(right: 16, top: 16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.dividerColor),
            ),
            child: ShimmerWrapper(
              isEnabled: isLoading,
              child: chartTrips.isEmpty && !isLoading
                  ? Center(
                      child: Text(
                        'no_trip_data_available'.tr,
                        style: TextStyle(
                          color: theme.textTheme.bodySmall?.color,
                          fontSize: 12,
                        ),
                      ),
                    )
                  : BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: _getMaxY(),
                        barTouchData: BarTouchData(enabled: true),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final idx = value.toInt();
                                if (idx >= 0 && idx < chartTrips.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6.0),
                                    child: Text(
                                      'trip_number'.trParams({
                                        'number': (idx + 1).toString(),
                                      }),
                                      style: TextStyle(
                                        color: theme.textTheme.bodySmall?.color,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                            ),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(
                          chartTrips.length,
                          (index) => BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY:
                                    chartTrips[index].passengerCount
                                        ?.toDouble() ??
                                    0.0,
                                color:
                                    (chartTrips[index].passengerCount ?? 0) > 25
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF2563EB),
                                width: 14,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  topRight: Radius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          if (!isLoading && chartTrips.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ChartLegend(
                  color: const Color(0xFF2563EB),
                  label: 'regular_load'.tr,
                ),
                const SizedBox(width: 16),
                _ChartLegend(
                  color: const Color(0xFFEF4444),
                  label: 'peak_load'.tr,
                ),
              ],
            ),
        ],
      ),
    );
  }

  double _getMaxY() {
    double maxVal = 20.0;
    for (var t in chartTrips) {
      final count = t.passengerCount?.toDouble() ?? 0.0;
      if (count > maxVal) {
        maxVal = count;
      }
    }
    return (maxVal * 1.15).roundToDouble();
  }
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _ChartLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }
}

class _TripLogSection extends StatelessWidget {
  final List<TripModel> displayTrips;
  final bool isLoading;

  const _TripLogSection({required this.displayTrips, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.find<AnalyticsController>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'trip_log'.tr,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleMedium?.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isLoading
                ? 'showing_runs_default'.tr
                : 'showing_runs'.trParams({
                    'count': displayTrips.length.toString(),
                  }),
            style: TextStyle(
              fontSize: 12,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 16),
          LoadedListWidget(
            apiCallStatus: isLoading
                ? ApiCallStatus.loading
                : ApiCallStatus.success,
            errorData: null,
            list: displayTrips,
            onReload: controller.loadAnalytics,
            onEmpty: Center(
              child: Text(
                'no_completed_trips'.tr,
                style: TextStyle(
                  color: theme.textTheme.bodySmall?.color,
                  fontSize: 12,
                ),
              ),
            ),
            loadingChild: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              itemBuilder: (c, i) =>
                  _TripLogCard(trip: displayTrips[i], isLoading: true),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayTrips.length,
              itemBuilder: (c, i) =>
                  _TripLogCard(trip: displayTrips[i], isLoading: false),
            ),
          ),
        ],
      ),
    );
  }
}

class _TripLogCard extends StatelessWidget {
  final TripModel trip;
  final bool isLoading;

  const _TripLogCard({required this.trip, required this.isLoading});

  String _formatTimeOnly(DateTime dt) {
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final min = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:$min $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String routeInfo = isLoading
        ? 'route_label_default'.tr + ' · Placeholder Route'
        : 'route_label'.trParams({'route': trip.route.routeNumber}) +
              ' · ${trip.route.name}';
    final String timeInfo = isLoading
        ? 'scheduled_label'.trParams({'time': '--:-- --'})
        : 'scheduled_label'.trParams({
            'time': _formatTimeOnly(trip.scheduledFor),
          });

    final int passengerCount = trip.passengerCount ?? 0;
    final isPeak = passengerCount > 25;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: ShimmerWrapper(
        isEnabled: isLoading,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    routeInfo,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeInfo,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$passengerCount ${'passengers'.tr}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isPeak
                        ? theme.colorScheme.error.withOpacity(0.12)
                        : const Color(0xFF22C55E).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isPeak ? 'peak_load'.tr : 'regular'.tr,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isPeak
                          ? theme.colorScheme.error
                          : const Color(0xFF16A34A),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
