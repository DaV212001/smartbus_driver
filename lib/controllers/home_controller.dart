import 'dart:ui';

import 'package:get/get.dart';

import '../models/trip_model.dart';
import '../services/analytics_storage.dart';
import '../utils/api_call_status.dart';
import '../utils/error_data.dart';
import '../utils/error_utils.dart';
import '../utils/templates/dio_template.dart';

class HomeController extends GetxController {
  // Reactive state variables
  var apiCallStatus = ApiCallStatus.loading.obs;
  var errorData = Rxn<ErrorData>();
  var activeTrip = Rxn<TripModel>();
  var tripsCompleted = 0.obs;
  var passengersTransported = 0.obs;
  var isActionLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    // if (!mounted) return;
    apiCallStatus.value = ApiCallStatus.loading;
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
        TripModel? active;
        try {
          active = trips.firstWhere((t) => t.status == 'IN_PROGRESS');
        } catch (_) {
          try {
            active = trips.firstWhere((t) => t.status == 'SCHEDULED');
          } catch (_) {
            active = null;
          }
        }
        final now = DateTime.now();
        final todayTrips = trips.where((t) {
          final s = t.scheduledFor;
          return s.year == now.year && s.month == now.month && s.day == now.day;
        }).toList();
        final todayCompleted = todayTrips
            .where((t) => t.status == 'COMPLETED')
            .length;
        final todayPassengers = todayTrips
            .where((t) => t.status == 'COMPLETED' || t.status == 'IN_PROGRESS')
            .fold<int>(0, (sum, t) => sum + t.passengerCount);
        await AnalyticsStorage.recordStatsForDate(
          now,
          todayPassengers,
          todayCompleted,
        );
        activeTrip.value = active;
        tripsCompleted.value = todayCompleted;
        passengersTransported.value = todayPassengers;
        apiCallStatus.value = trips.isEmpty
            ? ApiCallStatus.empty
            : ApiCallStatus.success;
      },
      onFailure: (error, response) async {
        final err = await ErrorUtil.getErrorData(error.toString());
        errorData.value = err;
        apiCallStatus.value = ApiCallStatus.error;
      },
    );
  }

  Future<void> handleTripAction() async {
    final trip = activeTrip.value;
    if (trip == null) return;
    if (isActionLoading.value) return;
    isActionLoading.value = true;
    final isStart = trip.status == 'SCHEDULED';
    final actionPath = isStart
        ? '/v1/trips/${trip.id}/start'
        : '/v1/trips/${trip.id}/end';
    await DioService.dioPatch(
      path: actionPath,
      onSuccess: (response) async {
        Get.snackbar(
          'Success',
          isStart ? 'Trip started successfully!' : 'Trip ended successfully!',
          backgroundColor: const Color(0xFFE6F3EC),
          colorText: const Color(0xFF0B6E4F),
        );
        isActionLoading.value = false;
        await loadDashboardData();
      },
      onFailure: (error, response) {
        isActionLoading.value = false;
        String msg = isStart ? 'Failed to start trip' : 'Failed to end trip';
        if (response.data != null && response.data['message'] != null) {
          msg = response.data['message'].toString();
        }
        Get.snackbar(
          'Error',
          msg,
          backgroundColor: const Color(0xFFFEF2F2),
          colorText: const Color(0xFFDC2626),
        );
      },
    );
  }
}
