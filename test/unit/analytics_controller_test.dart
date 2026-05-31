import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartbus_driver/config/dio_config.dart';
import 'package:smartbus_driver/config/storage_config.dart';
import 'package:smartbus_driver/controllers/analytics_controller.dart';
import 'package:smartbus_driver/utils/api_call_status.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AnalyticsController analyticsController;
  late Directory tempDir;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await ConfigPreference.init();

    // Mock Dio Interceptor to return fake trips for Analytics
    final dio = await DioConfig.dio();
    dio.interceptors.insert(0, InterceptorsWrapper(
      onRequest: (options, handler) {
        if (options.path.contains('/v1/trips')) {
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'status': 'success',
              'data': {
                'items': [
                  {
                    'id': 'trip_1',
                    'routeId': 'route_A',
                    'driverId': 'drv_1',
                    'busIdentifier': 'BUS-001',
                    'status': 'COMPLETED',
                    'passengerCount': 12,
                    'startedAt': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
                    'endedAt': DateTime.now().toIso8601String(), // Today
                    'scheduledFor': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
                    'createdAt': DateTime.now().toIso8601String(),
                    'updatedAt': DateTime.now().toIso8601String(),
                    'route': {
                      'id': 'route_A',
                      'routeNumber': 'R1',
                      'name': {'en': 'Route A', 'am': 'Route A'}
                    }
                  },
                  {
                    'id': 'trip_2',
                    'routeId': 'route_B',
                    'driverId': 'drv_1',
                    'busIdentifier': 'BUS-002',
                    'status': 'COMPLETED',
                    'passengerCount': 8,
                    'startedAt': DateTime.now().subtract(const Duration(days: 1, hours: 2)).toIso8601String(),
                    'endedAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(), // Yesterday
                    'scheduledFor': DateTime.now().subtract(const Duration(days: 1, hours: 2)).toIso8601String(),
                    'createdAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
                    'updatedAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
                    'route': {
                      'id': 'route_B',
                      'routeNumber': 'R2',
                      'name': {'en': 'Route B', 'am': 'Route B'}
                    }
                  }
                ]
              }
            },
          ));
        }
        return handler.next(options);
      },
    ));

    tempDir = await Directory.systemTemp.createTemp('hive_analytics_test');
    Hive.init(tempDir.path);
    await Hive.openBox<Map>('analytics_summary_cache');

    analyticsController = Get.put(AnalyticsController());
  });

  tearDownAll(() async {
    Get.reset();
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('AnalyticsController Tests', () {
    test('loadAnalytics parses API data and calculates today/yesterday correctly', () async {
      await analyticsController.loadAnalytics();

      // Wait a moment for async onSuccess callback
      await Future.delayed(const Duration(milliseconds: 200));

      expect(analyticsController.apiCallStatus.value, equals(ApiCallStatus.success));
      
      // Total trips fetched should be 2
      expect(analyticsController.recentTrips.length, equals(2));

      // Today should have 1 trip with 12 passengers
      expect(analyticsController.todayTripsCount.value, equals(1));
      expect(analyticsController.todayPassengersCount.value, equals(12));

      // Yesterday should have 1 trip with 8 passengers
      expect(analyticsController.yesterdayTripsCount.value, equals(1));
      expect(analyticsController.yesterdayPassengersCount.value, equals(8));
    });
  });
}
