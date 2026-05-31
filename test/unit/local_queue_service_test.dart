import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:smartbus_driver/services/local_queue_service.dart';

void main() {
  late LocalQueueService queueService;
  late Directory tempDir;

  setUpAll(() async {
    // Initialize Hive with a temporary directory for testing
    tempDir = await Directory.systemTemp.createTemp('hive_test');
    Hive.init(tempDir.path);
    
    // Open the boxes needed by the service
    await Hive.openBox<String>('scanned_tickets_cache');
    await Hive.openBox<Map>('offline_sync_queue');
    await Hive.openBox<Map>('notifications_history');
    
    queueService = LocalQueueService();
  });

  tearDown(() async {
    // Clear boxes after each test
    await Hive.box<String>('scanned_tickets_cache').clear();
    await Hive.box<Map>('offline_sync_queue').clear();
    await Hive.box<Map>('notifications_history').clear();
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('LocalQueueService - Ticket Cache Tests', () {
    test('cacheTicketId adds ticket to cache', () async {
      await queueService.cacheTicketId('ticket_001');
      final scannedTickets = queueService.getScannedTicketIds();
      
      expect(scannedTickets.length, 1);
      expect(scannedTickets.first, 'ticket_001');
    });

    test('clearTripCache empties the cache', () async {
      await queueService.cacheTicketId('ticket_001');
      await queueService.cacheTicketId('ticket_002');
      
      expect(queueService.getScannedTicketIds().length, 2);
      
      await queueService.clearTripCache();
      
      expect(queueService.getScannedTicketIds().isEmpty, isTrue);
    });
  });

  group('LocalQueueService - Offline Sync Queue Tests', () {
    test('queueScan adds a scan record to the queue', () async {
      await queueService.queueScan(
        qrPayload: '{"data": "test"}',
        qrSignature: 'signature123',
        scannedAt: '2026-05-30T10:00:00Z',
        inspectionMode: false,
        localResult: 'VALID',
      );

      final queue = queueService.getQueue();
      expect(queue.length, 1);
      
      final item = queue.first;
      expect(item['qrPayload'], '{"data": "test"}');
      expect(item['qrSignature'], 'signature123');
      expect(item['inspectionMode'], false);
      expect(item['localResult'], 'VALID');
    });

    test('clearQueueItems removes the specified number of items from front', () async {
      await queueService.queueScan(
        qrPayload: 'payload1', qrSignature: 'sig1', scannedAt: 'time1', inspectionMode: false, localResult: 'VALID',
      );
      await queueService.queueScan(
        qrPayload: 'payload2', qrSignature: 'sig2', scannedAt: 'time2', inspectionMode: false, localResult: 'VALID',
      );
      await queueService.queueScan(
        qrPayload: 'payload3', qrSignature: 'sig3', scannedAt: 'time3', inspectionMode: false, localResult: 'VALID',
      );

      expect(queueService.getQueue().length, 3);

      // Clear 2 items
      await queueService.clearQueueItems(2);

      final remaining = queueService.getQueue();
      expect(remaining.length, 1);
      expect(remaining.first['qrPayload'], 'payload3'); // First 2 were popped
    });
  });

  group('LocalQueueService - Notifications Tests', () {
    test('saveNotification and getNotifications retrieves in reverse order', () async {
      await queueService.saveNotification({'id': 1, 'title': 'First'});
      await queueService.saveNotification({'id': 2, 'title': 'Second'});

      final notifications = queueService.getNotifications();
      expect(notifications.length, 2);
      
      // Most recent first
      expect(notifications[0]['title'], 'Second');
      expect(notifications[1]['title'], 'First');
    });

    test('markNotificationAsRead updates the isRead flag', () async {
      await queueService.saveNotification({'id': 1, 'title': 'Test Notification'}); // Index 0 before reverse
      
      // The box index is 0, let's mark the oldest (first added) as read
      await queueService.markNotificationAsRead(0);
      
      final notifications = queueService.getNotifications();
      // Since it's reversed in getNotifications, it's at index 0 of the returned list if length is 1
      expect(notifications[0]['isRead'], true);
    });
  });
}
