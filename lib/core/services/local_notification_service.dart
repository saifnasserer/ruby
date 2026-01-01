import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

class LocalNotificationService {
  static final LocalNotificationService instance = LocalNotificationService._();
  LocalNotificationService._();

  // Notification channel configuration
  static const String _channelKey = 'ruby_daily_reminder';
  static const String _channelName = 'Ruby Daily Reminder';
  static const String _channelDescription =
      'Daily motivation to start your day with tasks';

  // Daily notification IDs
  static const int _morningNotificationId = 1001;
  static const int _eveningNotificationId = 1002;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (kIsWeb) return; // Web doesn't support local notifications

    await AwesomeNotifications().initialize(
      'resource://mipmap/ic_notification', // Use custom notification icon
      [
        NotificationChannel(
          channelKey: _channelKey,
          channelName: _channelName,
          channelDescription: _channelDescription,
          defaultColor: const Color(0xFFE91E63), // Ruby red color
          ledColor: const Color(0xFFE91E63),
          importance: NotificationImportance.High,
          channelShowBadge: true,
          defaultRingtoneType: DefaultRingtoneType.Notification,
          playSound: true,
          enableVibration: true,
        ),
      ],
      debug: false,
    );

    // Request permissions
    final allowed = await AwesomeNotifications().isNotificationAllowed();
    if (!allowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }

    // Schedule daily notifications
    await _scheduleDailyNotifications();
  }

  /// Schedule daily notifications at 7:00 AM and 10:00 PM
  Future<void> _scheduleDailyNotifications() async {
    if (kIsWeb) return;

    // Schedule morning notification at 7:00 AM
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: _morningNotificationId,
          channelKey: _channelKey,
          title: 'صباح الخير! 🌟',
          body: 'ابدأ يومك بكتابة مهامك اليومية واجعل كل يوم أكثر إنتاجية',
          category: NotificationCategory.Reminder,
          wakeUpScreen: true,
          icon: 'resource://mipmap/ic_notification',
          payload: {
            'type': 'morning_reminder',
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          },
        ),
        schedule: NotificationCalendar(
          hour: 7,
          minute: 0,
          second: 0,
          millisecond: 0,
          repeats: true,
          preciseAlarm: Platform.isAndroid,
        ),
      );
    } catch (e) {
      // Silent error handling for production
    }

    // Schedule evening notification at 10:00 PM
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: _eveningNotificationId,
          channelKey: _channelKey,
          title: 'كيف كان يومك؟ 🌙',
          body: 'تأمل في إنجازاتك اليومية وخطط لغد أفضل',
          category: NotificationCategory.Reminder,
          wakeUpScreen: false,
          icon: 'resource://mipmap/ic_notification',
          payload: {
            'type': 'evening_reflection',
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          },
        ),
        schedule: NotificationCalendar(
          hour: 22,
          minute: 0,
          second: 0,
          millisecond: 0,
          repeats: true,
          preciseAlarm: Platform.isAndroid,
        ),
      );
    } catch (e) {
      // Silent error handling for production
    }
  }

  /// Cancel daily notifications
  Future<void> cancelDailyNotifications() async {
    if (kIsWeb) return;

    try {
      await AwesomeNotifications().cancel(_morningNotificationId);
      await AwesomeNotifications().cancel(_eveningNotificationId);
    } catch (e) {
      // Silent error handling for production
    }
  }

  /// Check if notifications are allowed
  Future<bool> isNotificationAllowed() async {
    if (kIsWeb) return false;
    return await AwesomeNotifications().isNotificationAllowed();
  }

  /// Request notification permissions
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    return await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  /// Get notification statistics
  Future<Map<String, dynamic>> getNotificationInfo() async {
    if (kIsWeb) {
      return {'totalScheduled': 0, 'platform': 'web', 'isAllowed': false};
    }

    try {
      final scheduledNotifications = await AwesomeNotifications()
          .listScheduledNotifications();
      final isAllowed = await isNotificationAllowed();

      return {
        'totalScheduled': scheduledNotifications.length,
        'platform': Platform.operatingSystem,
        'isAllowed': isAllowed,
        'morningNotificationScheduled': scheduledNotifications.any(
          (notification) => notification.content?.id == _morningNotificationId,
        ),
        'eveningNotificationScheduled': scheduledNotifications.any(
          (notification) => notification.content?.id == _eveningNotificationId,
        ),
      };
    } catch (e) {
      return {'error': e.toString(), 'totalScheduled': 0, 'isAllowed': false};
    }
  }
}
