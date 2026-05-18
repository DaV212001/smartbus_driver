import 'package:get/get.dart';

import '../models/trip_model.dart';
import '../services/analytics_storage.dart';
import '../utils/api_call_status.dart';
import '../utils/error_data.dart';
import '../utils/error_utils.dart';
import '../utils/templates/dio_template.dart';

class AnalyticsController extends GetxController {
  // Reactive state
  var apiCallStatus = ApiCallStatus.loading.obs;
  var errorData = Rxn<ErrorData>();
  var recentTrips = <TripModel>[].obs;
  var todayTripsCount = 0.obs;
  var todayPassengersCount = 0.obs;
  var yesterdayTripsCount = 0.obs;
  var yesterdayPassengersCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadAnalytics();
  }

  Future<void> loadAnalytics() async {
    apiCallStatus.value = ApiCallStatus.loading;
    await AnalyticsStorage.prepopulateFirstRun();
    await DioService.dioGet(
      path: '/v1/trips',
      queryParameters: {'limit': '100'},
      onSuccess: (response) async {
        final dynamic rawData = response.data;
        List<dynamic> items = [];
        if (rawData is Map<String, dynamic>) {
          if (rawData.containsKey('data')) {
            final nested = rawData['data'];
            if (nested is Map<String, dynamic>) {
              items = nested['items'] ?? [];
            } else if (nested is List<dynamic>) {
              items = nested;
            }
          } else {
            items = rawData['items'] ?? [];
          }
        } else if (rawData is List<dynamic>) {
          items = rawData;
        }
        final List<TripModel> trips = items
            .map((e) => TripModel.fromJson(e))
            .toList();

        if (trips.isEmpty) {
          apiCallStatus.value = ApiCallStatus.empty;
          recentTrips.clear();
          todayTripsCount.value = 0;
          todayPassengersCount.value = 0;
          yesterdayTripsCount.value = 0;
          yesterdayPassengersCount.value = 0;
          return;
        }

        final processedTrips = TripModel.getProcessedTrips(trips);
        final now = DateTime.now();
        final yesterdayDate = now.subtract(const Duration(days: 1));

        // Helper to check if two dates are the same day in local time
        bool isSameDay(DateTime a, DateTime b) {
          final locA = a.toLocal();
          final locB = b.toLocal();
          return locA.year == locB.year &&
              locA.month == locB.month &&
              locA.day == locB.day;
        }

        // Calculate Today's Stats
        final todayCompleted = processedTrips
            .where(
              (t) =>
                  t.status == 'COMPLETED' &&
                  isSameDay(t.endedAt ?? t.scheduledFor, now),
            )
            .toList();

        final todayCount = todayCompleted.length;
        final todayPassengers = todayCompleted.fold<int>(
          0,
          (sum, t) => sum + t.passengerCount,
        );

        // Calculate Yesterday's Stats (from API first, fallback to storage)
        final yesterdayCompleted = processedTrips
            .where(
              (t) =>
                  t.status == 'COMPLETED' &&
                  isSameDay(t.endedAt ?? t.scheduledFor, yesterdayDate),
            )
            .toList();

        int yesterdayCount = yesterdayCompleted.length;
        int yesterdayPassengers = yesterdayCompleted.fold<int>(
          0,
          (sum, t) => sum + t.passengerCount,
        );

        // Update storage for today
        await AnalyticsStorage.recordStatsForDate(
          now,
          todayPassengers,
          todayCount,
        );

        // If API didn't have yesterday's data, try storage
        if (yesterdayCount == 0) {
          final yesterdaySummary = await AnalyticsStorage.getSummaryForDate(
            yesterdayDate,
          );
          if (yesterdaySummary != null) {
            yesterdayCount = yesterdaySummary.totalTrips;
            yesterdayPassengers = yesterdaySummary.totalPassengers;
          }
        }

        recentTrips.assignAll(processedTrips.reversed.toList());
        todayTripsCount.value = todayCount;
        todayPassengersCount.value = todayPassengers;
        yesterdayTripsCount.value = yesterdayCount;
        yesterdayPassengersCount.value = yesterdayPassengers;
        apiCallStatus.value = ApiCallStatus.success;
      },
      onFailure: (error, response) async {
        final err = await ErrorUtil.getErrorData(error.toString());
        errorData.value = err;
        apiCallStatus.value = ApiCallStatus.error;
      },
    );
  }
}
