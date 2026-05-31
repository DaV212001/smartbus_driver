import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartbus_driver/services/local_queue_service.dart';

void main() {
  const String sharedSecret = 'test_secret_key';
  late LocalTicketValidator validator;

  setUp(() {
    validator = LocalTicketValidator(sharedSecret);
  });

  String generateSignature(String payload) {
    final key = utf8.encode(sharedSecret);
    final bytes = utf8.encode(payload);
    final hmac = Hmac(sha256, key);
    return hmac.convert(bytes).toString().toLowerCase();
  }

  group('LocalTicketValidator Tests', () {
    test('Verifies valid cryptographic signature correctly', () {
      const payload = '{"ticketId":"123","routeId":"route_A"}';
      final signature = generateSignature(payload);

      final isValid = validator.verifySignature(payload, signature);
      expect(isValid, isTrue);
    });

    test('Rejects invalid cryptographic signature', () {
      const payload = '{"ticketId":"123","routeId":"route_A"}';
      const invalidSignature = 'invalid_hash_string_here';

      final isValid = validator.verifySignature(payload, invalidSignature);
      expect(isValid, isFalse);
    });

    test('validateOffline returns VALID for valid unexpired ticket on correct route', () {
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(hours: 1));
      final issuedAt = now.subtract(const Duration(minutes: 10));

      final payloadMap = {
        'ticketId': 'ticket_001',
        'passengerId': 'passenger_001',
        'routeId': 'route_A',
        'boardingStopId': 'stop_1',
        'dropoffStopId': 'stop_2',
        'fareAmount': 10.0,
        'expiresAt': expiresAt.toIso8601String(),
        'issuedAt': issuedAt.toIso8601String(),
      };
      final payload = jsonEncode(payloadMap);
      final signature = generateSignature(payload);

      final result = validator.validateOffline(
        payload: payload,
        signature: signature,
        activeRouteId: 'route_A',
        previouslyScannedTicketIds: [],
        inspectionMode: false,
      );

      expect(result.result, equals('VALID'));
      expect(result.isValid, isTrue);
      expect(result.ticketId, equals('ticket_001'));
    });

    test('validateOffline returns EXPIRED for expired ticket', () {
      final now = DateTime.now();
      final expiresAt = now.subtract(const Duration(hours: 1)); // Expired
      final issuedAt = now.subtract(const Duration(hours: 2));

      final payloadMap = {
        'ticketId': 'ticket_002',
        'passengerId': 'passenger_001',
        'routeId': 'route_A',
        'boardingStopId': 'stop_1',
        'dropoffStopId': 'stop_2',
        'fareAmount': 10.0,
        'expiresAt': expiresAt.toIso8601String(),
        'issuedAt': issuedAt.toIso8601String(),
      };
      final payload = jsonEncode(payloadMap);
      final signature = generateSignature(payload);

      final result = validator.validateOffline(
        payload: payload,
        signature: signature,
        activeRouteId: 'route_A',
        previouslyScannedTicketIds: [],
        inspectionMode: false,
      );

      expect(result.result, equals('EXPIRED'));
      expect(result.isValid, isFalse);
    });

    test('validateOffline returns INVALID_ROUTE if active route does not match', () {
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(hours: 1));
      final issuedAt = now.subtract(const Duration(minutes: 10));

      final payloadMap = {
        'ticketId': 'ticket_003',
        'passengerId': 'passenger_001',
        'routeId': 'route_A',
        'boardingStopId': 'stop_1',
        'dropoffStopId': 'stop_2',
        'fareAmount': 10.0,
        'expiresAt': expiresAt.toIso8601String(),
        'issuedAt': issuedAt.toIso8601String(),
      };
      final payload = jsonEncode(payloadMap);
      final signature = generateSignature(payload);

      final result = validator.validateOffline(
        payload: payload,
        signature: signature,
        activeRouteId: 'route_B', // Different route
        previouslyScannedTicketIds: [],
        inspectionMode: false,
      );

      expect(result.result, equals('INVALID_ROUTE'));
      expect(result.isValid, isFalse);
    });

    test('validateOffline returns ALREADY_USED if ticket is in previously scanned list (Standard Mode)', () {
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(hours: 1));
      final issuedAt = now.subtract(const Duration(minutes: 10));

      final payloadMap = {
        'ticketId': 'ticket_004',
        'passengerId': 'passenger_001',
        'routeId': 'route_A',
        'boardingStopId': 'stop_1',
        'dropoffStopId': 'stop_2',
        'fareAmount': 10.0,
        'expiresAt': expiresAt.toIso8601String(),
        'issuedAt': issuedAt.toIso8601String(),
      };
      final payload = jsonEncode(payloadMap);
      final signature = generateSignature(payload);

      final result = validator.validateOffline(
        payload: payload,
        signature: signature,
        activeRouteId: 'route_A',
        previouslyScannedTicketIds: ['ticket_004'], // Already scanned
        inspectionMode: false,
      );

      expect(result.result, equals('ALREADY_USED'));
      expect(result.isValid, isFalse);
    });

    test('validateOffline bypasses ALREADY_USED check in Inspection Mode and returns INSPECTION_ONLY', () {
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(hours: 1));
      final issuedAt = now.subtract(const Duration(minutes: 10));

      final payloadMap = {
        'ticketId': 'ticket_005',
        'passengerId': 'passenger_001',
        'routeId': 'route_A',
        'boardingStopId': 'stop_1',
        'dropoffStopId': 'stop_2',
        'fareAmount': 10.0,
        'expiresAt': expiresAt.toIso8601String(),
        'issuedAt': issuedAt.toIso8601String(),
      };
      final payload = jsonEncode(payloadMap);
      final signature = generateSignature(payload);

      final result = validator.validateOffline(
        payload: payload,
        signature: signature,
        activeRouteId: 'route_A',
        previouslyScannedTicketIds: ['ticket_005'], // Already scanned
        inspectionMode: true, // Inspection mode enabled
      );

      expect(result.result, equals('INSPECTION_ONLY'));
      expect(result.isValid, isTrue);
    });
  });
}
