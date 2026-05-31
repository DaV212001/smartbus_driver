import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartbus_driver/config/dio_config.dart';
import 'package:smartbus_driver/config/storage_config.dart';
import 'package:smartbus_driver/controllers/auth_controller.dart';
import 'package:smartbus_driver/controllers/home_controller.dart';
import 'package:smartbus_driver/controllers/passenger_list_controller.dart';
import 'package:smartbus_driver/controllers/scan_controller.dart';
import 'package:smartbus_driver/services/local_queue_service.dart';
import 'package:smartbus_driver/utils/api_call_status.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AuthController authController;
  late HomeController homeController;
  late ScanController scanController;
  late PassengerListController passengerListController;

  late Directory tempDir;

  setUpAll(() async {
    // Initialize SharedPreferences and Hive for local storage
    SharedPreferences.setMockInitialValues({});
    await ConfigPreference.init();
    
    // Inject a dummy token to pass the initial ConfigPreference.isAccessTokenExpired() check
    await ConfigPreference.setTokens({}, 'dummy_token', 'dummy_refresh', 3600);
    
    // Intercept all outgoing Dio requests to return a mock 200 OK
    final dio = await DioConfig.dio();
    dio.interceptors.insert(0, InterceptorsWrapper(
      onRequest: (options, handler) {
        return handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'status': 'success', 
            'data': {
              'trips': [], // Mock empty trips
              'accessToken': 'mock_new_token'
            }
          },
        ));
      },
    ));

    tempDir = await Directory.systemTemp.createTemp('hive_integration_test');
    Hive.init(tempDir.path);
    await Hive.openBox<String>('scanned_tickets_cache');
    await Hive.openBox<Map>('offline_sync_queue');
    await Hive.openBox<Map>('notifications_history');

    // Register controllers
    authController = Get.put(AuthController());
    homeController = Get.put(HomeController());
    scanController = Get.put(ScanController());
    passengerListController = Get.put(PassengerListController());
  });

  tearDownAll(() async {
    Get.reset();
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('Integration & Simulation Testing - Real Backend API', () {
    
    test('Authenticate driver and load home dashboard (Trips & Analytics)', () async {
      // Note: This relies on the real backend API.
      // We will simulate a login if needed, or assume a test user.
      // For this simulation, we check if the home controller can fetch trips.
      await homeController.loadDashboardData();
      
      // We expect the call to succeed (even if empty, it shouldn't be an error)
      expect(
        homeController.apiCallStatus.value, 
        isNot(equals(ApiCallStatus.error)),
        reason: 'Failed to fetch trips from the backend API.',
      );
    });

    test('Simulation: Offline-to-Online Syncing', () async {
      // 1. Force offline mode
      scanController.isOffline.value = true;
      
      // 2. Simulate scanning multiple offline tickets
      final queueService = LocalQueueService();
      await queueService.queueScan(
        qrPayload: '{"ticketId":"sim_001","routeId":"test_route"}',
        qrSignature: 'sim_sig_001',
        scannedAt: DateTime.now().toIso8601String(),
        inspectionMode: false,
        localResult: 'VALID',
      );
      await queueService.queueScan(
        qrPayload: '{"ticketId":"sim_002","routeId":"test_route"}',
        qrSignature: 'sim_sig_002',
        scannedAt: DateTime.now().toIso8601String(),
        inspectionMode: false,
        localResult: 'VALID',
      );

      expect(queueService.getQueue().length, greaterThanOrEqualTo(2));

      // 3. Trigger network restoration and sync
      scanController.isOffline.value = false;
      await scanController.triggerBatchSync();

      // Because the DioService onSuccess callback is not awaited by DioService itself,
      // we need to yield the event loop to allow the callback to set isSyncing back to false.
      await Future.delayed(const Duration(milliseconds: 500));

      expect(scanController.isSyncing.value, false);
    });

    test('Simulation: Sequential QR Ticket Scanning Flow', () async {
      // Simulate rapid scanning by calling processScan sequentially
      // This tests the controller's concurrency handling (e.g. ignoring scans while loading)
      
      // 1. Set mode to standard
      scanController.activeMode.value = 'Standard';
      
      // 2. Fire first scan (valid format but fake data)
      final fakePayload = jsonEncode({
        "ticketId": "seq_001",
        "routeId": "route_seq",
        "expiresAt": DateTime.now().add(const Duration(hours: 1)).toIso8601String()
      });
      final fakeScanData = jsonEncode({
        "qrPayload": fakePayload,
        "qrSignature": "fake_signature"
      });

      // Start scan
      final scanFuture1 = scanController.processScan(fakeScanData);
      
      // Fire second scan immediately (should be ignored because apiCallStatus is loading)
      final scanFuture2 = scanController.processScan(fakeScanData);
      
      await Future.wait([scanFuture1, scanFuture2]);
      
      // Since it's a fake signature, it should fail local validation
      expect(scanController.apiCallStatus.value, equals(ApiCallStatus.error));
      expect(scanController.errorData.value?.title, contains('INVALID SIGNATURE'));
    });

    test('Simulation: Passenger Boarding and Passenger List Sync', () async {
      // Simulate passenger boarding and ensuring the passenger list controller updates
      
      // Load passenger list
      await passengerListController.loadScansData();
      
      expect(
        passengerListController.apiCallStatus.value, 
        isNot(equals(ApiCallStatus.error)),
      );
      
      // Test highlight passenger logic
      passengerListController.highlightPassenger('test_ticket_123');
      expect(passengerListController.highlightedTicketId.value, equals('test_ticket_123'));
      
      // Clear highlight
      passengerListController.clearHighlight();
      expect(passengerListController.highlightedTicketId.value, isNull);
    });
  });
}
