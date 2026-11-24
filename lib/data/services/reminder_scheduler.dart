import 'dart:async';
import 'dart:math';
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';

import '../models/dua.dart';
import '../models/reminder_settings.dart';
import '../models/scheduled_reminder.dart';
import '../repositories/dua_repository.dart';
import '../repositories/settings_repository.dart';
import 'notification_service.dart';

/// Snapshot of the scheduler state shown on the Home screen.
@immutable
class ScheduleStatus {
  const ScheduleStatus({
    required this.enabled,
    required this.upcoming,
    required this.exact,
    required this.notificationsAllowed,
    this.lastDuaId,
  });

  const ScheduleStatus.idle()
      : enabled = false,
        upcoming = const [],
        exact = false,
        notificationsAllowed = true,
        lastDuaId = null;

  final bool enabled;
  final List<ScheduledReminder> upcoming;
  final bool exact;
  final bool notificationsAllowed;
  final int? lastDuaId;

  DateTime? get next => upcoming.isEmpty ? null : upcoming.first.time;
  DateTime? get horizon => upcoming.isEmpty ? null : upcoming.last.time;
}

/// Pre-schedules a rolling batch of one-shot notifications.
///
/// WHY NOT `periodicallyShow`?
///   It only supports fixed intervals (every minute / hour / day / week) and
///   repeats the *same* content. We need arbitrary gaps, a different dua each
///   time, and quiet hours.
///
/// HOW IT WORKS
///   1. We compute the next [batchSize] fire times, spaced by the user's gap,
///      shifting any time that lands in quiet hours to the end of the window
///      (the cadence then continues from there).
///   2. Each time gets its own dua (sequential / random / favorites) and is
///      scheduled with `zonedSchedule` under a unique id.
///   3. The batch ("plan") is persisted. On every refill, entries whose time
///      has passed are treated as delivered: that advances the rotation and
///      tells us which dua is the current "dua of the moment".
///   4. Refill happens when the app opens/resumes and whenever settings or
///      favorites change. After a reboot Android's
///      ScheduledNotificationBootReceiver restores the already-pending
///      batch; the next app open tops it up again.
///
/// LIMITS
///   iOS keeps at most 64 pending local notifications per app (extra ones are
///   silently dropped). [batchSize] = 48 leaves headroom. With a 15-minute gap
///   the batch covers 12 hours, so the user must open the app at least that
///   often; with 1 hour it covers 2 days, etc.
class ReminderScheduler {
  ReminderScheduler({
    required this._notifications,
    required SettingsRepository settingsRepository,
    required DuaRepository duaRepository,
    Random? random,
    DateTime Function()? clock,
  })  : _settings = settingsRepository,
        _duas = duaRepository,
        _random = random ?? Random(),
        _clock = clock ?? DateTime.now;

  static const batchSize = 48;

  final NotificationService _notifications;
  final SettingsRepository _settings;
  final DuaRepository _duas;
  final Random _random;
  final DateTime Function() _clock;

  /// Serializes refills: resume + settings change can fire at the same time,
  /// and interleaving cancel/schedule calls would corrupt the batch.
  Future<ScheduleStatus>? _running;
  Future<ScheduleStatus> _lock(Future<ScheduleStatus> Function() body) {
    final previous = _running;
    final next = () async {
      if (previous != null) {
        try {
          await previous;
        } catch (_) {}
      }
      return body();
    }();
    _running = next;
    return next;
  }

  /// Cancels the pending batch and rebuilds it.
  ///
  /// [restartCadence] = true starts counting the gap from *now* (use after the
  /// user changes timing settings). false keeps the existing rhythm, e.g. a
  /// 3-hour cadence that started at 09:00 continues at 12:00, 15:00, …
  Future<ScheduleStatus> refill({
    required ReminderSettings settings,
    required Set<int> favorites,
    bool restartCadence = false,
    Locale? locale,
  }) {
    return _lock(() => _refill(settings, favorites, restartCadence, locale));
  }

  /// Cancels everything (used on logout / when disabled).
  Future<ScheduleStatus> cancelAll() {
    return _lock(() async {
      await _consumeDelivered(_settings.loadPlan(), _clock());
      await _notifications.cancelAllScheduled();
      await _settings.savePlan(const []);
      return ScheduleStatus(
        enabled: false,
        upcoming: const [],
        exact: false,
        notificationsAllowed: await _notifications.areNotificationsEnabled(),
        lastDuaId: _settings.lastDuaId,
      );
    });
  }

  Future<ScheduleStatus> _refill(ReminderSettings settings, Set<int> favorites,
      bool restartCadence, Locale? locale) async {
    final now = _clock();
    final oldPlan = _settings.loadPlan();

    // ---- 1. Account for reminders that fired since the last refill.
    final delivered = oldPlan.where((r) => !r.time.isAfter(now)).toList();
    final pending = oldPlan.where((r) => r.time.isAfter(now)).toList();
    // Rotation index of the next dua to send (see _consumeDelivered).
    final startIndex = await _consumeDelivered(oldPlan, now);

    final allowed = await _notifications.areNotificationsEnabled();
    final pool = _pool(settings, favorites);

    if (!settings.enabled || pool.isEmpty) {
      await _notifications.cancelAllScheduled();
      await _settings.savePlan(const []);
      return ScheduleStatus(
        enabled: false,
        upcoming: const [],
        exact: false,
        notificationsAllowed: allowed,
        lastDuaId: _settings.lastDuaId,
      );
    }

    // ---- 2. Choose the first fire time.
    final gap = settings.interval;
    DateTime first;
    if (restartCadence || oldPlan.isEmpty) {
      first = now.add(gap);
    } else if (pending.isNotEmpty) {
      // Keep the rhythm: the next pending reminder stays where it was.
      first = pending.first.time;
    } else {
      // Every queued reminder already fired (app not opened for a while).
      // Continue the cadence from the last one, jumping past "now".
      final last = delivered.last.time;
      final steps = now.difference(last).inMicroseconds ~/ gap.inMicroseconds + 1;
      first = last.add(gap * steps);
    }

    // ---- 3. Build the list of fire times, skipping quiet hours.
    final times = <DateTime>[];
    var t = skipQuietHours(first, settings);
    while (times.length < batchSize) {
      if (t.isAfter(now)) times.add(t);
      t = skipQuietHours(t.add(gap), settings);
    }

    // ---- 4. Pick a dua for each time.
    final chosen = settings.order == DuaOrder.random
        ? _randomSequence(pool, times.length)
        : [for (var i = 0; i < times.length; i++) pool[(startIndex + i) % pool.length]];

    // ---- 5. Replace the pending batch.
    await _notifications.cancelAllScheduled();
    final exact = await _notifications.canScheduleExact();
    final title = NotificationService.l10nFor(locale).notificationTitle;
    final plan = <ScheduledReminder>[];
    for (var i = 0; i < times.length; i++) {
      final dua = chosen[i];
      final ok = await _scheduleOne(
        id: NotificationService.firstReminderId + i,
        when: times[i],
        dua: dua,
        title: dua.title ?? title,
        sound: settings.soundEnabled,
        exact: exact,
      );
      if (ok) plan.add(ScheduledReminder(time: times[i], duaId: dua.id));
    }

    await _settings.savePlan(plan);
    // The new plan starts at `startIndex`; store it (wrapped) for next time.
    await _settings.setSeqIndex(startIndex % pool.length);

    return ScheduleStatus(
      enabled: true,
      upcoming: plan,
      exact: exact,
      notificationsAllowed: allowed,
      lastDuaId: _settings.lastDuaId,
    );
  }

  Future<bool> _scheduleOne({
    required int id,
    required DateTime when,
    required Dua dua,
    required String title,
    required bool sound,
    required bool exact,
  }) async {
    try {
      await _notifications.schedule(
          id: id, when: when, dua: dua, title: title, sound: sound, exact: exact);
      return true;
    } catch (e) {
      // e.g. exact-alarm permission revoked between check and call.
      if (exact) {
        try {
          await _notifications.schedule(
              id: id, when: when, dua: dua, title: title, sound: sound, exact: false);
          return true;
        } catch (_) {}
      }
      debugPrint('Failed to schedule reminder $id at $when: $e');
      return false;
    }
  }

  /// Marks the entries of [plan] whose time has passed as delivered:
  ///  * remembers the last one as the "dua of the moment";
  ///  * advances the persisted rotation index past them.
  ///
  /// `seqIndex` always holds the rotation index of the first entry of the
  /// stored plan, so after N deliveries the next dua is at seqIndex + N.
  /// Returns that next index. Clearing the plan afterwards is then safe.
  Future<int> _consumeDelivered(List<ScheduledReminder> plan, DateTime now) async {
    final delivered = plan.where((r) => !r.time.isAfter(now)).toList();
    final next = _settings.seqIndex + delivered.length;
    if (delivered.isNotEmpty) {
      await _settings.setLastDuaId(delivered.last.duaId);
      await _settings.setSeqIndex(next);
    }
    return next;
  }

  /// Duas eligible for rotation. "Favorites only" falls back to all duas when
  /// there are no favorites, so reminders never silently stop.
  List<Dua> _pool(ReminderSettings settings, Set<int> favorites) {
    final all = _duas.all;
    if (settings.order == DuaOrder.favorites) {
      final favs = all.where((d) => favorites.contains(d.id)).toList();
      if (favs.isNotEmpty) return favs;
    }
    return all;
  }

  /// Shuffle-bag randomness: every dua appears once before any repeats, and
  /// the same dua is never sent twice in a row (incl. across batches).
  List<Dua> _randomSequence(List<Dua> pool, int count) {
    final result = <Dua>[];
    var previousId = _settings.lastDuaId;
    var bag = <Dua>[];
    while (result.length < count) {
      if (bag.isEmpty) {
        bag = List.of(pool)..shuffle(_random);
        if (bag.length > 1 && bag.last.id == previousId) {
          // We pop from the end; avoid an immediate repeat.
          final swap = _random.nextInt(bag.length - 1);
          final tmp = bag[swap];
          bag[swap] = bag.last;
          bag[bag.length - 1] = tmp;
        }
      }
      final next = bag.removeLast();
      result.add(next);
      previousId = next.id;
    }
    return result;
  }

  /// If [t] falls inside the quiet window, returns the end of that window
  /// (next occurrence of the end time); otherwise returns [t] unchanged.
  ///
  /// Works for windows that wrap past midnight (22:00 → 07:00). Uses the local
  /// DateTime constructor so day/month rollover and DST are handled.
  @visibleForTesting
  static DateTime skipQuietHours(DateTime t, ReminderSettings s) {
    if (!s.quietHoursEnabled || s.quietStartMinutes == s.quietEndMinutes) return t;
    final start = s.quietStartMinutes;
    final end = s.quietEndMinutes;
    final m = t.hour * 60 + t.minute;
    final inQuiet = start < end
        ? (m >= start && m < end) // same-day window, e.g. 13:00 → 15:00
        : (m >= start || m < end); // wraps midnight, e.g. 22:00 → 07:00
    if (!inQuiet) return t;

    var endToday = DateTime(t.year, t.month, t.day, end ~/ 60, end % 60);
    if (!endToday.isAfter(t)) {
      endToday = DateTime(t.year, t.month, t.day + 1, end ~/ 60, end % 60);
    }
    return endToday;
  }
}
