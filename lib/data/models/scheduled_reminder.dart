import 'package:flutter/foundation.dart';

/// One entry of the pre-scheduled batch, persisted so that on the next refill
/// we know which reminders already fired (time <= now) and which dua each
/// pending reminder carries.
@immutable
class ScheduledReminder {
  const ScheduledReminder({required this.time, required this.duaId});

  final DateTime time;
  final int duaId;

  Map<String, dynamic> toJson() =>
      {'t': time.millisecondsSinceEpoch, 'd': duaId};

  static ScheduledReminder? tryParse(Object? json) {
    if (json is! Map) return null;
    final t = json['t'];
    final d = json['d'];
    if (t is! int || d is! int) return null;
    return ScheduledReminder(
      time: DateTime.fromMillisecondsSinceEpoch(t),
      duaId: d,
    );
  }
}
