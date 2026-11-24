import 'package:flutter/foundation.dart';

enum DuaOrder { sequential, random, favorites }

/// All user-configurable reminder options. Persisted by `SettingsRepository`.
@immutable
class ReminderSettings {
  const ReminderSettings({
    this.enabled = true,
    this.intervalMinutes = 60,
    this.quietHoursEnabled = false,
    this.quietStartMinutes = 22 * 60, // 22:00
    this.quietEndMinutes = 7 * 60, // 07:00
    this.order = DuaOrder.sequential,
    this.soundEnabled = true,
  });

  final bool enabled;

  /// Gap between two reminders, in minutes (always >= 1).
  final int intervalMinutes;

  final bool quietHoursEnabled;

  /// Quiet window start/end as minutes since midnight (local time).
  /// The window may wrap past midnight (e.g. 22:00 → 07:00).
  final int quietStartMinutes;
  final int quietEndMinutes;

  final DuaOrder order;
  final bool soundEnabled;

  Duration get interval => Duration(minutes: intervalMinutes);

  ReminderSettings copyWith({
    bool? enabled,
    int? intervalMinutes,
    bool? quietHoursEnabled,
    int? quietStartMinutes,
    int? quietEndMinutes,
    DuaOrder? order,
    bool? soundEnabled,
  }) {
    return ReminderSettings(
      enabled: enabled ?? this.enabled,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietStartMinutes: quietStartMinutes ?? this.quietStartMinutes,
      quietEndMinutes: quietEndMinutes ?? this.quietEndMinutes,
      order: order ?? this.order,
      soundEnabled: soundEnabled ?? this.soundEnabled,
    );
  }

  /// True when anything that affects *which times* get scheduled changed.
  /// Used to decide whether the cadence should restart from "now".
  bool timingDiffers(ReminderSettings other) =>
      enabled != other.enabled ||
      intervalMinutes != other.intervalMinutes ||
      quietHoursEnabled != other.quietHoursEnabled ||
      quietStartMinutes != other.quietStartMinutes ||
      quietEndMinutes != other.quietEndMinutes;

  @override
  bool operator ==(Object other) =>
      other is ReminderSettings &&
      other.enabled == enabled &&
      other.intervalMinutes == intervalMinutes &&
      other.quietHoursEnabled == quietHoursEnabled &&
      other.quietStartMinutes == quietStartMinutes &&
      other.quietEndMinutes == quietEndMinutes &&
      other.order == order &&
      other.soundEnabled == soundEnabled;

  @override
  int get hashCode => Object.hash(enabled, intervalMinutes, quietHoursEnabled,
      quietStartMinutes, quietEndMinutes, order, soundEnabled);
}
