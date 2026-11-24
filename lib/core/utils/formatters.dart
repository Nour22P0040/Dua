import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';

/// "1 hour", "90 minutes" → "1 hour 30 minutes", etc.
String formatInterval(AppLocalizations l10n, int minutes) {
  if (minutes < 60) return l10n.minutesCount(minutes);
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (m == 0) return l10n.hoursCount(h);
  return '${l10n.hoursCount(h)} ${l10n.minutesCount(m)}';
}

/// "Today 14:30", "Tomorrow 07:00", or "Mon 3 Mar 07:00".
String formatReminderTime(BuildContext context, DateTime time) {
  final l10n = AppLocalizations.of(context);
  final locale = Localizations.localeOf(context).toLanguageTag();
  final clock = MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay.fromDateTime(time),
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(time.year, time.month, time.day);
  final diff = day.difference(today).inDays;
  if (diff == 0) return '${l10n.today} $clock';
  if (diff == 1) return '${l10n.tomorrow} $clock';
  return '${DateFormat.MMMEd(locale).format(time)} $clock';
}

String formatMinutesOfDay(BuildContext context, int minutes) =>
    MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
