import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/qr_payload_data.dart';

class OfflineValidationResult {
  final String
  result; // 'VALID', 'EXPIRED', 'ALREADY_USED', 'INVALID_SIGNATURE', 'INVALID_ROUTE', 'INSPECTION_ONLY'
  final String message;
  final String? ticketId;
  final QrPayloadData? payload;

  OfflineValidationResult({
    required this.result,
    required this.message,
    this.ticketId,
    this.payload,
  });

  bool get isValid => result == 'VALID' || result == 'INSPECTION_ONLY';
}

class LocalTicketValidator {
  final String _sharedSecret;

  LocalTicketValidator(this._sharedSecret);

  /// 1. Mathematically checks if the QR payload hasn't been altered
  bool verifySignature(String payload, String signature) {
    final key = utf8.encode(_sharedSecret);
    final bytes = utf8.encode(payload);

    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);

    return digest.toString().toLowerCase() == signature.toLowerCase();
  }

  /// 2. Performs local business logic validation
  OfflineValidationResult validateOffline({
    required String payload,
    required String signature,
    required String activeRouteId,
    required List<String> previouslyScannedTicketIds,
    bool inspectionMode = false,
  }) {
    // A. Verify Cryptographic Integrity
    if (!verifySignature(payload, signature)) {
      return OfflineValidationResult(
        result: 'INVALID_SIGNATURE',
        message: 'Cryptographic signature is invalid.',
      );
    }

    // Parse JSON
    Map<String, dynamic> jsonMap;
    try {
      jsonMap = jsonDecode(payload) as Map<String, dynamic>;
    } catch (_) {
      return OfflineValidationResult(
        result: 'INVALID_SIGNATURE',
        message: 'Malformed QR Payload format.',
      );
    }

    final data = QrPayloadData.fromJson(jsonMap);
    final now = DateTime.now();

    // B. Check Expiry
    if (now.isAfter(data.expiresAt)) {
      return OfflineValidationResult(
        result: 'EXPIRED',
        message: 'This ticket has expired.',
        ticketId: data.ticketId,
      );
    }

    // C. Check Route Matching (Ensures passenger is on the right bus/route)
    if (data.routeId != activeRouteId) {
      return OfflineValidationResult(
        result: 'INVALID_ROUTE',
        message: 'Ticket is issued for a different bus route.',
        ticketId: data.ticketId,
      );
    }

    // D. Local Double Boarding Prevention (Check cache)
    if (!inspectionMode && previouslyScannedTicketIds.contains(data.ticketId)) {
      return OfflineValidationResult(
        result: 'ALREADY_USED',
        message: 'This ticket has already been boarded on this bus.',
        ticketId: data.ticketId,
      );
    }

    // E. Validation Successful
    return OfflineValidationResult(
      result: inspectionMode ? 'INSPECTION_ONLY' : 'VALID',
      message: inspectionMode
          ? 'Inspection valid.'
          : 'Ticket validation successful.',
      ticketId: data.ticketId,
      payload: data,
    );
  }
}

class LocalQueueService {
  static const String _cacheBoxName = 'scanned_tickets_cache';
  static const String _queueBoxName = 'offline_sync_queue';
  static const String _notificationBoxName = 'notifications_history';

  /// Call once inside main.dart initialization
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<String>(_cacheBoxName);
    await Hive.openBox<Map>(_queueBoxName);
    await Hive.openBox<Map>(_notificationBoxName);
  }

  final Box<String> _cacheBox = Hive.box<String>(_cacheBoxName);
  final Box<Map> _queueBox = Hive.box<Map>(_queueBoxName);

  List<String> getScannedTicketIds() {
    return _cacheBox.values.toList();
  }

  Future<void> cacheTicketId(String ticketId) async {
    await _cacheBox.add(ticketId);
  }

  Future<void> clearTripCache() async {
    await _cacheBox.clear();
  }

  /// Queues the scan details to be synced batch-wise to /sync/validations
  Future<void> queueScan({
    required String qrPayload,
    required String qrSignature,
    required String scannedAt,
    required bool inspectionMode,
    required String localResult,
  }) async {
    final Map<String, dynamic> scanRecord = {
      'qrPayload': qrPayload,
      'qrSignature': qrSignature,
      'scannedAt': scannedAt,
      'inspectionMode': inspectionMode,
      'localResult': localResult,
    };
    await _queueBox.add(scanRecord);
  }

  List<Map<String, dynamic>> getQueue() {
    return _queueBox.values
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> clearQueueItems(int count) async {
    for (int i = 0; i < count; i++) {
      if (_queueBox.isNotEmpty) {
        await _queueBox.deleteAt(0); // Pop from front
      }
    }
  }

  // --- Notification History Methods ---

  final Box<Map> _notificationBox = Hive.box<Map>(_notificationBoxName);

  Future<void> saveNotification(Map<String, dynamic> notificationJson) async {
    await _notificationBox.add(notificationJson);
  }

  List<Map<String, dynamic>> getNotifications() {
    return _notificationBox.values
        .map((item) => Map<String, dynamic>.from(item))
        .toList()
        .reversed // Most recent first
        .toList();
  }

  Future<void> markNotificationAsRead(int index) async {
    final Map? notification = _notificationBox.getAt(index);
    if (notification != null) {
      final updated = Map<String, dynamic>.from(notification);
      updated['isRead'] = true;
      await _notificationBox.putAt(index, updated);
    }
  }

  Future<void> clearNotifications() async {
    await _notificationBox.clear();
  }
}
