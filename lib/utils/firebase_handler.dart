import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import '../config/storage_config.dart';
import '../services/local_queue_service.dart';
import '../utils/templates/dio_template.dart';

@pragma("vm:entry-point")
Future<void> handleBackgroundMessage(RemoteMessage message) async {
  Logger().d('Background Message Title: ${message.notification?.title}');
  Logger().d('Background Message Body: ${message.notification?.body}');
  Logger().d('Background Message Payload: ${message.data}');

  // Ensure Hive is initialized for the background isolate
  await LocalQueueService.init();
  final localQueueService = LocalQueueService();

  final title =
      message.notification?.title ??
      message.data['title'] ??
      'SmartBus Notification';
  final body = message.notification?.body ?? message.data['body'] ?? '';

  // Save to local history
  await localQueueService.saveNotification({
    'id': message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
    'title': title,
    'body': body,
    'timestamp': DateTime.now().toIso8601String(),
    'payload': message.data,
    'isRead': false,
  });

  // Display notification manually only if it's a data-only message
  if (message.notification == null) {
    if (message.data['title'] != null || message.data['body'] != null) {
      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: 'basic_channel',
          title: title,
          body: body,
          payload: message.data.map(
            (key, value) => MapEntry(key, value.toString()),
          ),
        ),
      );
    }
  }
}

class FirebaseHandler {
  static final FirebaseHandler _instance = FirebaseHandler._internal();
  factory FirebaseHandler() => _instance;
  FirebaseHandler._internal();

  final _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    // 1. Initialize Awesome Notifications
    await AwesomeNotifications().initialize(
      null, // uses default app icon
      [
        NotificationChannel(
          channelGroupKey: 'basic_channel_group',
          channelKey: 'basic_channel',
          channelName: 'Basic notifications',
          channelDescription: 'Notification channel for basic tests',
          defaultColor: const Color(0xFF9D50DD),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
        ),
      ],
      channelGroups: [
        NotificationChannelGroup(
          channelGroupKey: 'basic_channel_group',
          channelGroupName: 'Basic group',
        ),
      ],
      debug: true,
    );

    // 2. Check and Request Notification Permission via Awesome Notifications
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }

    // 3. Request FCM Permission
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    try {
      if (Platform.isIOS) {
        final apnsToken = await _firebaseMessaging.getAPNSToken();
        Logger().d('APNs Token: $apnsToken');
      }
      final fcmToken = await _firebaseMessaging.getToken();
      Logger().i('FCM Token: $fcmToken');
      if (fcmToken != null) {
        // await uploadFcmToken(fcmToken);
      }
    } catch (e, s) {
      Logger().e('Error retrieving FCM/APNs token: $e', stackTrace: s);
    }

    // 4. Register Background Handlers
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);

    // 5. Register Foreground Message Handler
    FirebaseMessaging.onMessage.listen((message) async {
      Logger().d('Received foreground message: ${message.notification}');
      Logger().d('Title: ${message.notification?.title}');
      Logger().d('Body: ${message.notification?.body}');
      Logger().d('Payload: ${message.data}');

      final title =
          message.notification?.title ??
          message.data['title'] ??
          'SmartBus Notification';
      final body = message.notification?.body ?? message.data['body'] ?? '';

      // Save to local history
      final localQueueService = LocalQueueService();
      await localQueueService.saveNotification({
        'id':
            message.messageId ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        'title': title,
        'body': body,
        'timestamp': DateTime.now().toIso8601String(),
        'payload': message.data,
        'isRead': false,
      });

      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: 'basic_channel',
          title: title,
          body: body,
          payload: message.data.map(
            (key, value) => MapEntry(key, value.toString()),
          ),
        ),
      );
    });

    // 6. Listen for Token Refresh
    _firebaseMessaging.onTokenRefresh.listen((fcmToken) async {
      Logger().i('FCM Token Refreshed: $fcmToken');
      await uploadFcmToken(fcmToken);
    });
  }

  Future<void> uploadCurrentFcmToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await uploadFcmToken(token);
      }
    } catch (e) {
      Logger().e('Failed to get current FCM token: $e');
    }
  }

  Future<void> uploadFcmToken(String token) async {
    if (!ConfigPreference.isUserLoggedIn()) {
      Logger().d('FCM Token upload skipped: User not logged in');
      return;
    }

    Logger().i('Uploading FCM Token: $token');
    await DioService.dioPatch(
      path: '/v1/users/me/fcm-token',
      data: {'token': token},
      onSuccess: (response) {
        Logger().i('FCM Token uploaded successfully.');
      },
      onFailure: (error, response) {
        Logger().e('Failed to upload FCM token to backend: $error');
      },
    );
  }
}
