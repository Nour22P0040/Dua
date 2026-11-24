import 'package:dua/core/utils/arabic_normalizer.dart';
import 'package:dua/data/models/dua.dart';
import 'package:dua/data/models/reminder_settings.dart';
import 'package:dua/data/repositories/dua_repository.dart';
import 'package:dua/data/services/reminder_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DuaRepository.parse', () {
    test('accepts {"duas": [strings]}', () {
      final r = DuaRepository.parse('{"duas": ["اللهم ارحمه", "  ", "اللهم اغفر له"]}');
      expect(r.hasError, isFalse);
      expect(r.duas.map((d) => d.id), [1, 3]); // blank entry skipped, ids = position
      expect(r.duas.first.arabic, 'اللهم ارحمه');
    });

    test('accepts a root list of objects with alias keys', () {
      final r = DuaRepository.parse(
          '[{"id": "7", "text": "دعاء", "english": "A dua", "source": "Muslim"}]');
      final d = r.duas.single;
      expect(d.id, 7);
      expect(d.translation, 'A dua');
      expect(d.reference, 'Muslim');
    });

    test('dedupes ids', () {
      final r = DuaRepository.parse('[{"id":1,"arabic":"a"},{"id":1,"arabic":"b"}]');
      expect(r.duas.map((d) => d.id), [1, 2]);
    });

    test('malformed JSON does not throw', () {
      final r = DuaRepository.parse('{"duas": [ "unterminated');
      expect(r.duas, isEmpty);
      expect(r.hasError, isTrue);
    });
  });

  group('skipQuietHours', () {
    const s = ReminderSettings(
        quietHoursEnabled: true, quietStartMinutes: 22 * 60, quietEndMinutes: 7 * 60);

    test('outside window unchanged', () {
      final t = DateTime(2026, 1, 1, 12, 0);
      expect(ReminderScheduler.skipQuietHours(t, s), t);
    });

    test('late evening moves to next morning', () {
      expect(ReminderScheduler.skipQuietHours(DateTime(2026, 1, 31, 23, 30), s),
          DateTime(2026, 2, 1, 7, 0));
    });

    test('early morning moves to same-day end', () {
      expect(ReminderScheduler.skipQuietHours(DateTime(2026, 1, 1, 3, 0), s),
          DateTime(2026, 1, 1, 7, 0));
    });

    test('same-day window', () {
      const day = ReminderSettings(
          quietHoursEnabled: true, quietStartMinutes: 13 * 60, quietEndMinutes: 15 * 60);
      expect(ReminderScheduler.skipQuietHours(DateTime(2026, 1, 1, 14, 0), day),
          DateTime(2026, 1, 1, 15, 0));
      expect(ReminderScheduler.skipQuietHours(DateTime(2026, 1, 1, 15, 0), day),
          DateTime(2026, 1, 1, 15, 0));
    });
  });

  test('Arabic search normalization', () {
    expect(normalizeForSearch('الجنّة'), normalizeForSearch('الجنه'));
    expect(normalizeForSearch('أبواب'), 'ابواب');
  });

  test('Dua.toShareText', () {
    const d = Dua(id: 1, arabic: 'دعاء', translation: 'Dua');
    expect(d.toShareText(), 'دعاء\n\nDua');
  });
}
