import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Android battery-optimization helpers (no-ops on other platforms).
class BatteryService {
  bool get isSupported => !kIsWeb && Platform.isAndroid;

  /// True when Android may restrict the app in the background (Doze/App Standby),
  /// which can delay inexact reminders.
  Future<bool> isRestricted() async {
    if (!isSupported) return false;
    try {
      return !(await Permission.ignoreBatteryOptimizations.isGranted);
    } catch (_) {
      return false;
    }
  }

  /// Shows the system "Let app always run in background?" dialog. If that
  /// is unavailable (permission removed from the manifest / OEM quirks) the
  /// app settings screen is opened instead.
  Future<void> requestUnrestricted() async {
    if (!isSupported) return;
    try {
      final status = await Permission.ignoreBatteryOptimizations.request();
      if (status.isGranted) return;
    } catch (e) {
      debugPrint('ignoreBatteryOptimizations request failed: $e');
    }
    await openAppSettings();
  }
}
