import 'package:get/get.dart';
import '../models/trip_model.dart';
import '../utils/api_call_status.dart';
import '../utils/error_data.dart';
import '../utils/error_utils.dart';
import '../utils/templates/dio_template.dart';

class PassengerListController extends GetxController {
  // Reactive state
  var apiCallStatus = ApiCallStatus.loading.obs;
  var errorData = Rxn<ErrorData>();
  var activeTrip = Rxn<TripModel>();
  var scans = <ScannedPassenger>[].obs;
  var totalScans = 0.obs;
  var validScans = 0.obs;
  var issueScans = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadScansData();
  }

  Future<void> loadScansData() async {
    if (!Get.isRegistered<PassengerListController>()) return;
    apiCallStatus.value = ApiCallStatus.loading;
    await DioService.dioGet(
      path: '/v1/trips',
      onSuccess: (tripsResponse) async {
        final dynamic rawTrips = tripsResponse.data;
        List<dynamic> items = [];
        if (rawTrips is Map<String, dynamic>) {
          if (rawTrips.containsKey('data')) {
            final nested = rawTrips['data'];
            if (nested is Map<String, dynamic>) {
              items = nested['items'] ?? [];
            } else if (nested is List<dynamic>) {
              items = nested;
            }
          } else {
            items = rawTrips['items'] ?? [];
          }
        } else if (rawTrips is List<dynamic>) {
          items = rawTrips;
        }
        final List<TripModel> trips = items.map((item) => TripModel.fromJson(item)).toList();
        TripModel? active;
        try {
          active = trips.firstWhere((t) => t.status == 'IN_PROGRESS');
        } catch (_) {
          active = null;
        }
        if (active == null) {
          // empty state
          activeTrip.value = null;
          scans.clear();
          totalScans.value = 0;
          validScans.value = 0;
          issueScans.value = 0;
          apiCallStatus.value = ApiCallStatus.empty;
          return;
        }
        await DioService.dioGet(
          path: '/v1/trips/${active.id}/scans',
          queryParameters: {'limit': '100'},
          onSuccess: (scansResponse) async {
            final dynamic rawScans = scansResponse.data;
            List<dynamic> scanItems = [];
            if (rawScans is Map<String, dynamic>) {
              if (rawScans.containsKey('data')) {
                final nested = rawScans['data'];
                if (nested is Map<String, dynamic>) {
                  scanItems = nested['items'] ?? [];
                } else if (nested is List<dynamic>) {
                  scanItems = nested;
                }
              } else {
                scanItems = rawScans['items'] ?? [];
              }
            } else if (rawScans is List<dynamic>) {
              scanItems = rawScans;
            }
            final List<ScannedPassenger> loaded = scanItems.map((item) => ScannedPassenger.fromJson(item)).toList();
            final total = loaded.length;
            final valid = loaded.where((s) => s.result == 'VALID').length;
            final issues = loaded.where((s) => s.result == 'ALREADY_USED' || s.result == 'EXPIRED' || s.isPreviouslySeen).length;
            activeTrip.value = active;
            scans.assignAll(loaded);
            totalScans.value = total;
            validScans.value = valid;
            issueScans.value = issues;
            apiCallStatus.value = loaded.isEmpty ? ApiCallStatus.success : ApiCallStatus.success;
          },
          onFailure: (error, response) async {
            final err = await ErrorUtil.getErrorData(error.toString());
            errorData.value = err;
            apiCallStatus.value = ApiCallStatus.error;
          },
        );
      },
      onFailure: (error, response) async {
        final err = await ErrorUtil.getErrorData(error.toString());
        errorData.value = err;
        apiCallStatus.value = ApiCallStatus.error;
      },
    );
  }
}

// Model for scanned passenger (same as in screen file) – kept here for reuse
class ScannedPassenger {
  final String id;
  final String name;
  final String time;
  final String result;
  final bool isPreviouslySeen;

  ScannedPassenger({
    required this.id,
    required this.name,
    required this.time,
    required this.result,
    required this.isPreviouslySeen,
  });

  factory ScannedPassenger.fromJson(Map<String, dynamic> json) {
    final scannedAtStr = json['scannedAt'];
    String formattedTime = '--:--';
    if (scannedAtStr != null) {
      try {
        final dt = DateTime.parse(scannedAtStr).toLocal();
        final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
        final min = dt.minute.toString().padLeft(2, '0');
        final ampm = dt.hour >= 12 ? 'PM' : 'AM';
        formattedTime = '${hour.toString().padLeft(2, '0')}:$min $ampm';
      } catch (_) {}
    }
    return ScannedPassenger(
      id: json['id'] ?? '',
      name: json['passenger']?['fullName'] ?? 'Unknown Passenger',
      time: formattedTime,
      result: json['result'] ?? 'VALID',
      isPreviouslySeen: json['isPreviouslySeen'] ?? false,
    );
  }
}
