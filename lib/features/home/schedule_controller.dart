import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/services/reminder_scheduler.dart';
import '../duas/favorites_controller.dart';
import '../settings/settings_controller.dart';

/// Holds the latest [ScheduleStatus] and exposes the refill entry points.
///
/// Refill triggers (see ReminderScheduler for the algorithm):
///  * HomeShell mount (app opened / user signed in)
///  * app resumed from background
///  * reminder settings, favorites (in favorites mode) or language changed
final scheduleControllerProvider =
    NotifierProvider<ScheduleController, ScheduleStatus>(ScheduleController.new);

class ScheduleController extends Notifier<ScheduleStatus> {
  @override
  ScheduleStatus build() => const ScheduleStatus.idle();

  Future<void> refill({bool restartCadence = false}) async {
    try {
      final status = await ref.read(reminderSchedulerProvider).refill(
            settings: ref.read(reminderSettingsProvider),
            favorites: ref.read(favoritesProvider),
            restartCadence: restartCadence,
            locale: ref.read(localeControllerProvider),
          );
      if (ref.mounted) state = status;
    } catch (e, st) {
      debugPrint('Refill failed: $e\n$st');
    }
  }

  Future<void> cancelAll() async {
    try {
      final status = await ref.read(reminderSchedulerProvider).cancelAll();
      if (ref.mounted) state = status;
    } catch (e, st) {
      debugPrint('cancelAll failed: $e\n$st');
    }
  }
}

/// Live permission checks; invalidated when the app resumes so returning from
/// system settings refreshes the UI.
final notificationsAllowedProvider = FutureProvider<bool>(
  (ref) => ref.read(notificationServiceProvider).areNotificationsEnabled(),
);

final exactAlarmAllowedProvider = FutureProvider<bool>(
  (ref) => ref.read(notificationServiceProvider).canScheduleExact(),
);

final batteryRestrictedProvider = FutureProvider<bool>(
  (ref) => ref.read(batteryServiceProvider).isRestricted(),
);

void refreshPermissionProviders(WidgetRef ref) {
  ref.invalidate(notificationsAllowedProvider);
  ref.invalidate(exactAlarmAllowedProvider);
  ref.invalidate(batteryRestrictedProvider);
}
