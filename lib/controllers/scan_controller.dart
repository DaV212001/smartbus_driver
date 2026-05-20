import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../constants/assets.dart';
import '../controllers/home_controller.dart';
import '../services/local_queue_service.dart';
import '../utils/api_call_status.dart';
import '../utils/error_data.dart';
import '../utils/templates/dio_template.dart';

class ScanController extends GetxController with WidgetsBindingObserver {
  final LocalQueueService _queueService = LocalQueueService();
  final Connectivity _connectivity = Connectivity();

  var isOffline = false.obs;
  var isSyncing = false.obs;
  var activeMode = 'Standard'.obs; // 'Standard' or 'Inspection'
  var isScanTabVisible = false.obs;

  // Camera Controller
  final MobileScannerController scannerController = MobileScannerController(
    autoStart: false,
  );
  bool _isCameraRunning = false;

  // State for last scanned ticket
  var apiCallStatus = ApiCallStatus.holding.obs;
  var errorData = Rxn<ErrorData>();
  var lastScanResult = Rxn<OfflineValidationResult>();
  var scannedAtString = ''.obs;

  // Let's keep a shared secret key
  final String _sharedSecret = 'f07a4050db962514e030c4c981673a71';
  late final LocalTicketValidator _validator;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _validator = LocalTicketValidator(_sharedSecret);

    // Check initial connectivity
    _connectivity.checkConnectivity().then((results) {
      isOffline.value =
          results.isEmpty || results.first == ConnectivityResult.none;
      if (!isOffline.value) {
        triggerBatchSync();
      }
    });

    // Listen to connectivity changes
    _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      final wasOffline = isOffline.value;
      isOffline.value =
          results.isEmpty || results.first == ConnectivityResult.none;
      if (!isOffline.value && wasOffline) {
        triggerBatchSync();
      }
    });
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    scannerController.dispose();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _stopCameraInternal();
    }
  }

  void onTabVisibilityChanged(bool visible) {
    isScanTabVisible.value = visible;
    _updateCameraState();
  }

  void _updateCameraState() {
    if (isScanTabVisible.value &&
        apiCallStatus.value == ApiCallStatus.holding) {
      _startCameraInternal();
    } else {
      _stopCameraInternal();
    }
  }

  Future<void> _startCameraInternal() async {
    if (_isCameraRunning) return;
    try {
      _isCameraRunning = true;
      await scannerController.start();
    } catch (e) {
      _isCameraRunning = false;
      debugPrint('Error starting camera: $e');
    }
  }

  Future<void> _stopCameraInternal() async {
    if (!_isCameraRunning) return;
    try {
      _isCameraRunning = false;
      await scannerController.stop();
    } catch (e) {
      debugPrint('Error stopping camera: $e');
    }
  }

  @Deprecated('Use onTabVisibilityChanged instead')
  void startCamera() => onTabVisibilityChanged(true);

  @Deprecated('Use onTabVisibilityChanged instead')
  void stopCamera() => onTabVisibilityChanged(false);

  void toggleMode(String mode) {
    activeMode.value = mode;
  }

  Future<void> processScan(String rawPayloadString) async {
    // If already loading/validating, ignore double scanner triggers
    if (apiCallStatus.value == ApiCallStatus.loading) return;

    // Stop camera immediately once a code is detected to save resources and avoid double scans
    _stopCameraInternal();

    apiCallStatus.value = ApiCallStatus.loading;
    errorData.value = null;
    lastScanResult.value = null;

    final now = DateTime.now();
    final hour = now.hour == 0
        ? 12
        : (now.hour > 12 ? now.hour - 12 : now.hour);
    final min = now.minute.toString().padLeft(2, '0');
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    scannedAtString.value = '${hour.toString().padLeft(2, '0')}:$min $ampm';

    // 1. Decode QR code package
    String payload = '';
    String signature = '';
    try {
      final Map<String, dynamic> data = jsonDecode(rawPayloadString);
      payload = data['qrPayload'] as String;
      signature = data['qrSignature'] as String;
    } catch (_) {
      // If the scanned string is not formatted as JSON, let's treat it as invalid
      apiCallStatus.value = ApiCallStatus.error;
      errorData.value = ErrorData(
        title: 'Invalid QR Code',
        body: 'This QR code is not recognized as a valid SmartBus ticket.',
        image: Assets.errorsUnknown,
        buttonText: 'Scan Again',
      );
      return;
    }

    // 2. Retrieve Active Route ID from HomeController
    String activeRouteId = '';
    try {
      final homeController = Get.find<HomeController>();
      activeRouteId = homeController.activeTrip.value?.route.id ?? '';
    } catch (_) {}

    // 3. Local cryptographic check first (Zero Latency Boarding)
    final previouslyScanned = _queueService.getScannedTicketIds();
    final localCheck = _validator.validateOffline(
      payload: payload,
      signature: signature,
      activeRouteId: activeRouteId,
      previouslyScannedTicketIds: previouslyScanned,
      inspectionMode: activeMode.value == 'Inspection',
    );

    if (!localCheck.isValid) {
      // Local verification failed
      apiCallStatus.value = ApiCallStatus.error;

      String errImage = Assets.errorsUnknown;
      if (localCheck.result == 'INVALID_ROUTE') {
        errImage = Assets.errorsNotFound;
      } else if (localCheck.result == 'EXPIRED' ||
          localCheck.result == 'ALREADY_USED') {
        errImage = Assets.errorsForbidden;
      }

      errorData.value = ErrorData(
        title: localCheck.result.replaceAll('_', ' '),
        body: localCheck.message,
        image: errImage,
        buttonText: 'Scan Again',
      );
      return;
    }

    // 4. If we are offline, validate locally & queue
    if (isOffline.value) {
      if (localCheck.result == 'VALID') {
        await _queueService.cacheTicketId(localCheck.ticketId!);
      }
      await _queueService.queueScan(
        qrPayload: payload,
        qrSignature: signature,
        scannedAt: now.toIso8601String(),
        inspectionMode: activeMode.value == 'Inspection',
        localResult: localCheck.result,
      );

      lastScanResult.value = localCheck;
      apiCallStatus.value = ApiCallStatus.success;
      return;
    }

    // 5. If we are online, call POST /v1/tickets/validate
    await DioService.dioPost(
      path: '/v1/tickets/validate',
      data: {
        'qrPayload': payload,
        'qrSignature': signature,
        'inspectionMode': activeMode.value == 'Inspection',
      },
      onSuccess: (response) async {
        final data = response.data;
        final resultData = OfflineValidationResult(
          result: data['result'] ?? 'VALID',
          message: activeMode.value == 'Inspection'
              ? 'Inspection valid.'
              : 'Ticket validation successful.',
          ticketId: localCheck.ticketId,
          payload: localCheck.payload,
        );

        if (activeMode.value != 'Inspection') {
          await _queueService.cacheTicketId(localCheck.ticketId!);
        }

        lastScanResult.value = resultData;
        apiCallStatus.value = ApiCallStatus.success;
      },
      onFailure: (err, response) async {
        int statusCode = 500;
        if (err is DioException) {
          statusCode = err.response?.statusCode ?? 500;
        } else if (response.statusCode != null) {
          statusCode = response.statusCode!;
        }

        // If conflict (409) or expired (410), or invalid (400)
        String title = 'Validation Failed';
        String body = 'Server validation failed.';
        String errImage = Assets.errorsUnknown;

        if (statusCode == 409) {
          title = 'Already Used';
          body = 'This ticket has already been used.';
          errImage = Assets.errorsForbidden;
        } else if (statusCode == 410) {
          title = 'Expired';
          body = 'This ticket has expired.';
          errImage = Assets.errorsForbidden;
        } else if (statusCode == 400) {
          title = 'Invalid Signature';
          body = 'Invalid QR signature detected.';
          errImage = Assets.errorsUnknown;
        }

        apiCallStatus.value = ApiCallStatus.error;
        errorData.value = ErrorData(
          title: title,
          body: body,
          image: errImage,
          buttonText: 'Scan Again',
        );
      },
    );
  }

  Future<void> triggerBatchSync() async {
    if (isSyncing.value) return;

    final queue = _queueService.getQueue();
    if (queue.isEmpty) return;

    isSyncing.value = true;

    try {
      final int batchSize = queue.length > 100 ? 100 : queue.length;
      final List<Map<String, dynamic>> batchScans = queue.sublist(0, batchSize);

      await DioService.dioPost(
        path: '/v1/sync/validations',
        data: {'scans': batchScans},
        onSuccess: (response) async {
          await _queueService.clearQueueItems(batchSize);
          isSyncing.value = false;
          if (_queueService.getQueue().isNotEmpty) {
            await triggerBatchSync();
          }
        },
        onFailure: (err, response) {
          isSyncing.value = false;
        },
      );
    } catch (e) {
      isSyncing.value = false;
    }
  }

  void reset() {
    apiCallStatus.value = ApiCallStatus.holding;
    errorData.value = null;
    lastScanResult.value = null;
    _updateCameraState();
  }
}
