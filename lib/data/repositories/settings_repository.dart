import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/reminder_settings.dart';
import '../models/scheduled_reminder.dart';

/// Thin, typed wrapper around [SharedPreferences].
///
/// Every read is defensive: corrupt or missing values fall back to defaults.
class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  // Keys
  static const _kEnabled = 'reminder.enabled';
  static const _kInterval = 'reminder.intervalMinutes';
  static const _kQuietEnabled = 'reminder.quiet.enabled';
  static const _kQuietStart = 'reminder.quiet.start';
  static const _kQuietEnd = 'reminder.quiet.end';
  static const _kOrder = 'reminder.order';
  static const _kSound = 'reminder.sound';
  static const _kFavorites = 'duas.favorites';
  static const _kThemeMode = 'ui.themeMode';
  static const _kLocale = 'ui.locale';
  static const _kSeqIndex = 'scheduler.seqIndex';
  static const _kPlan = 'scheduler.plan';
  static const _kLastDuaId = 'scheduler.lastDuaId';
  static const _kBatteryPrompted = 'ui.batteryPrompted';

  // ---------------------------------------------------------------- reminders

  ReminderSettings loadReminderSettings() {
    const d = ReminderSettings();
    final orderName = _prefs.getString(_kOrder);
    return ReminderSettings(
      enabled: _prefs.getBool(_kEnabled) ?? d.enabled,
      intervalMinutes:
          (_prefs.getInt(_kInterval) ?? d.intervalMinutes).clamp(1, 7 * 24 * 60),
      quietHoursEnabled: _prefs.getBool(_kQuietEnabled) ?? d.quietHoursEnabled,
      quietStartMinutes:
          (_prefs.getInt(_kQuietStart) ?? d.quietStartMinutes).clamp(0, 1439),
      quietEndMinutes:
          (_prefs.getInt(_kQuietEnd) ?? d.quietEndMinutes).clamp(0, 1439),
      order: DuaOrder.values.firstWhere(
        (o) => o.name == orderName,
        orElse: () => d.order,
      ),
      soundEnabled: _prefs.getBool(_kSound) ?? d.soundEnabled,
    );
  }

  Future<void> saveReminderSettings(ReminderSettings s) async {
    await Future.wait([
      _prefs.setBool(_kEnabled, s.enabled),
      _prefs.setInt(_kInterval, s.intervalMinutes),
      _prefs.setBool(_kQuietEnabled, s.quietHoursEnabled),
      _prefs.setInt(_kQuietStart, s.quietStartMinutes),
      _prefs.setInt(_kQuietEnd, s.quietEndMinutes),
      _prefs.setString(_kOrder, s.order.name),
      _prefs.setBool(_kSound, s.soundEnabled),
    ]);
  }

  // ---------------------------------------------------------------- favorites

  Set<int> loadFavorites() => (_prefs.getStringList(_kFavorites) ?? const [])
      .map(int.tryParse)
      .whereType<int>()
      .toSet();

  Future<void> saveFavorites(Set<int> ids) =>
      _prefs.setStringList(_kFavorites, ids.map((e) => '$e').toList());

  // ---------------------------------------------------------------- appearance

  ThemeMode loadThemeMode() {
    final name = _prefs.getString(_kThemeMode);
    return ThemeMode.values.firstWhere((m) => m.name == name,
        orElse: () => ThemeMode.system);
  }

  Future<void> saveThemeMode(ThemeMode mode) =>
      _prefs.setString(_kThemeMode, mode.name);

  /// `null` = follow the system language.
  Locale? loadLocale() {
    final code = _prefs.getString(_kLocale);
    return (code == null || code.isEmpty) ? null : Locale(code);
  }

  Future<void> saveLocale(Locale? locale) => locale == null
      ? _prefs.remove(_kLocale)
      : _prefs.setString(_kLocale, locale.languageCode);

  // ---------------------------------------------------------------- scheduler state

  /// Position in the (sequential or favorites) rotation of the *next* dua to send.
  int get seqIndex => _prefs.getInt(_kSeqIndex) ?? 0;
  Future<void> setSeqIndex(int value) => _prefs.setInt(_kSeqIndex, value);

  /// Id of the most recently delivered dua (shown as "dua of the moment").
  int? get lastDuaId => _prefs.getInt(_kLastDuaId);
  Future<void> setLastDuaId(int id) => _prefs.setInt(_kLastDuaId, id);

  List<ScheduledReminder> loadPlan() {
    final raw = _prefs.getString(_kPlan);
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return const [];
      return list.map(ScheduledReminder.tryParse).whereType<ScheduledReminder>().toList()
        ..sort((a, b) => a.time.compareTo(b.time));
    } catch (_) {
      return const [];
    }
  }

  Future<void> savePlan(List<ScheduledReminder> plan) => _prefs.setString(
      _kPlan, jsonEncode(plan.map((e) => e.toJson()).toList()));

  bool get batteryPrompted => _prefs.getBool(_kBatteryPrompted) ?? false;
  Future<void> setBatteryPrompted() => _prefs.setBool(_kBatteryPrompted, true);
}
