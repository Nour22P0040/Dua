import 'dart:io' show Platform;
import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../l10n/app_localizations.dart';
import '../models/dua.dart';

/// Low-level wrapper around flutter_local_notifications.
///
/// Owns plugin initialization, channels, permissions, tap handling and the
/// primitive "show / schedule / cancel" operations. The *policy* of what to
/// schedule lives in `ReminderScheduler`.
class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  /// Channel used when sound is ON. Name required by the spec.
  static const channelId = 'dua_reminders';

  /// Android channels are immutable once created (sound can't be toggled per
  /// channel afterwards), so "sound off" uses a second, silent channel.
  static const silentChannelId = 'dua_reminders_silent';

  /// Scheduled reminders use ids [firstReminderId, firstReminderId + batch).
  static const firstReminderId = 1000;
  static const testNotificationId = 1;

  static const _androidIcon = 'ic_stat_dua';
  static const _payloadPrefix = 'dua:';

  /// Set when the user taps a notification (cold start or while running).
  /// The signed-in shell listens and opens the dua detail screen, then clears it.
  final ValueNotifier<int?> tappedDuaId = ValueNotifier<int?>(null);

  bool _initialized = false;

  bool get _isAndroid => !kIsWeb && Platform.isAndroid;
  bool get _isIOS => !kIsWeb && Platform.isIOS;

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  IOSFlutterLocalNotificationsPlugin? get _ios =>
      _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

  /// Must be called once before `runApp`. Never throws.
  Future<void> init({Locale? preferredLocale}) async {
    if (_initialized) return;
    try {
      await _initTimeZone();

      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings(_androidIcon),
          // Don't prompt at launch; we ask from the Home screen with context.
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );

      await _createAndroidChannels(preferredLocale);

      // Cold start: the app was launched by tapping a notification.
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        tappedDuaId.value = parsePayload(launch!.notificationResponse?.payload);
      }
      _initialized = true;
    } catch (e, st) {
      debugPrint('NotificationService.init failed: $e\n$st');
    }
  }

  Future<void> _initTimeZone() async {
    tz_data.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (e) {
      // Unknown zone id → keep tz.local (UTC). Scheduling still fires at the
      // correct instant because we convert absolute DateTimes with
      // TZDateTime.from(); only the zone label differs.
      debugPrint('Could not resolve local timezone: $e');
    }
  }

  Future<void> _createAndroidChannels(Locale? preferredLocale) async {
    final android = _android;
    if (android == null) return;
    final l10n = l10nFor(preferredLocale);
    await android.createNotificationChannel(AndroidNotificationChannel(
      channelId,
      l10n.appTitle,
      description: l10n.notificationTitle,
      importance: Importance.high,
    ));
    await android.createNotificationChannel(AndroidNotificationChannel(
      silentChannelId,
      '${l10n.appTitle} (${l10n.sound} ✕)',
      description: l10n.notificationTitle,
      importance: Importance.high,
      playSound: false,
      enableVibration: false,
    ));
  }

  void _onNotificationResponse(NotificationResponse response) {
    final id = parsePayload(response.payload);
    if (id != null) tappedDuaId.value = id;
  }

  static String payloadFor(Dua dua) => '$_payloadPrefix${dua.id}';

  static int? parsePayload(String? payload) {
    if (payload == null || !payload.startsWith(_payloadPrefix)) return null;
    return int.tryParse(payload.substring(_payloadPrefix.length));
  }

  /// Localizations usable outside the widget tree (for notification text).
  static AppLocalizations l10nFor(Locale? preferred) {
    final candidate = preferred ?? PlatformDispatcher.instance.locale;
    final supported = AppLocalizations.supportedLocales
        .any((l) => l.languageCode == candidate.languageCode);
    return lookupAppLocalizations(
        supported ? Locale(candidate.languageCode) : const Locale('en'));
  }

  // ------------------------------------------------------------------ permissions

  /// Whether the app is currently allowed to post notifications.
  Future<bool> areNotificationsEnabled() async {
    try {
      if (_isAndroid) return await _android?.areNotificationsEnabled() ?? true;
      if (_isIOS) return (await _ios?.checkPermissions())?.isEnabled ?? false;
    } catch (e) {
      debugPrint('areNotificationsEnabled failed: $e');
    }
    return true;
  }

  /// Shows the OS permission prompt (Android 13+ POST_NOTIFICATIONS / iOS).
  /// Returns the resulting state. If the user previously denied permanently
  /// the OS shows nothing and this returns false → UI offers "Open settings".
  Future<bool> requestNotificationPermission() async {
    try {
      if (_isAndroid) {
        return await _android?.requestNotificationsPermission() ?? false;
      }
      if (_isIOS) {
        return await _ios?.requestPermissions(
                alert: true, badge: true, sound: true) ??
            false;
      }
    } catch (e) {
      debugPrint('requestNotificationPermission failed: $e');
    }
    return false;
  }

  /// Android 12+: whether SCHEDULE_EXACT_ALARM is granted. Always true on iOS
  /// (iOS has no such concept) and on Android < 12.
  Future<bool> canScheduleExact() async {
    if (!_isAndroid) return true;
    try {
      return await _android?.canScheduleExactNotifications() ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens the system "Alarms & reminders" screen for this app (Android 12+).
  Future<void> requestExactAlarmPermission() async {
    if (!_isAndroid) return;
    try {
      await _android?.requestExactAlarmsPermission();
    } catch (e) {
      debugPrint('requestExactAlarmPermission failed: $e');
    }
  }

  // ------------------------------------------------------------------ show / schedule

  NotificationDetails _details(Dua dua, {required bool sound, String? title}) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        sound ? channelId : silentChannelId,
        sound ? channelId : silentChannelId,
        icon: _androidIcon,
        importance: Importance.high,
        priority: Priority.high,
        playSound: sound,
        enableVibration: sound,
        category: AndroidNotificationCategory.reminder,
        // Long duas would be truncated to one line without BigText.
        styleInformation: BigTextStyleInformation(dua.arabic, contentTitle: title),
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBanner: true,
        presentList: true,
        presentSound: sound,
        threadIdentifier: channelId,
      ),
    );
  }

  /// Shows [dua] immediately (used by "Send test notification now").
  Future<void> showNow(Dua dua, {required bool sound, required String title}) {
    return _plugin.show(
      id: testNotificationId,
      title: title,
      body: dua.arabic,
      notificationDetails: _details(dua, sound: sound, title: title),
      payload: payloadFor(dua),
    );
  }

  /// Schedules one notification at the absolute instant [when].
  ///
  /// [exact] chooses AndroidScheduleMode.exactAllowWhileIdle (needs the
  /// exact-alarm permission) vs inexactAllowWhileIdle (may be deferred by
  /// Doze / OEM battery savers, typically by a few minutes). Ignored on iOS.
  Future<void> schedule({
    required int id,
    required DateTime when,
    required Dua dua,
    required String title,
    required bool sound,
    required bool exact,
  }) {
    return _plugin.zonedSchedule(
      id: id,
      scheduledDate: tz.TZDateTime.from(when, tz.local),
      notificationDetails: _details(dua, sound: sound, title: title),
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      title: title,
      body: dua.arabic,
      payload: payloadFor(dua),
    );
  }

  /// Removes every *pending* scheduled notification (already-delivered ones
  /// stay in the notification shade).
  Future<void> cancelAllScheduled() async {
    try {
      await _plugin.cancelAllPendingNotifications();
    } catch (e) {
      debugPrint('cancelAllPendingNotifications failed ($e); falling back');
      await _plugin.cancelAll();
    }
  }
}
