import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/reminder_settings.dart';
import '../home/schedule_controller.dart';

final reminderSettingsProvider =
    NotifierProvider<ReminderSettingsController, ReminderSettings>(
        ReminderSettingsController.new);

class ReminderSettingsController extends Notifier<ReminderSettings> {
  @override
  ReminderSettings build() =>
      ref.read(settingsRepositoryProvider).loadReminderSettings();

  /// Persists [next] and rebuilds the notification batch.
  /// Timing changes restart the cadence from now; order/sound changes keep it.
  Future<void> update(ReminderSettings next) async {
    final previous = state;
    if (next == previous) return;
    state = next;
    await ref.read(settingsRepositoryProvider).saveReminderSettings(next);
    await ref
        .read(scheduleControllerProvider.notifier)
        .refill(restartCadence: previous.timingDiffers(next));
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.read(settingsRepositoryProvider).loadThemeMode();

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(settingsRepositoryProvider).saveThemeMode(mode);
  }
}

/// `null` = follow the device language.
final localeControllerProvider =
    NotifierProvider<LocaleController, Locale?>(LocaleController.new);

class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() => ref.read(settingsRepositoryProvider).loadLocale();

  Future<void> set(Locale? locale) async {
    state = locale;
    await ref.read(settingsRepositoryProvider).saveLocale(locale);
    // Notification titles are localized at scheduling time.
    await ref.read(scheduleControllerProvider.notifier).refill();
  }
}
