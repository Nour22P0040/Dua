import 'package:flutter/foundation.dart';

/// A single dua.
///
/// The parser is intentionally tolerant so the JSON file can evolve without
/// code changes. Supported item shapes:
///
///  * a plain string → treated as the Arabic text, id = position (1-based)
///  * an object using any of the key aliases below
///
/// To support a new field name, just add it to the matching alias list.
@immutable
class Dua {
  const Dua({
    required this.id,
    required this.arabic,
    this.title,
    this.transliteration,
    this.translation,
    this.reference,
  });

  final int id;
  final String arabic;
  final String? title;
  final String? transliteration;
  final String? translation;
  final String? reference;

  static const _idKeys = ['id', 'ID', 'number', 'no', 'index'];
  static const _arabicKeys = ['arabic', 'ar', 'text', 'dua', 'content', 'body'];
  static const _titleKeys = ['title', 'name', 'heading'];
  static const _translitKeys = ['transliteration', 'translit', 'latin'];
  static const _translationKeys = ['translation', 'english', 'en', 'meaning'];
  static const _referenceKeys = ['reference', 'source', 'ref', 'hadith'];

  /// Builds a [Dua] from one JSON item. [fallbackId] is used when the item has
  /// no usable id (e.g. a plain string). Returns `null` for unusable items so
  /// a single bad entry never breaks the whole list.
  static Dua? tryParse(Object? json, {required int fallbackId}) {
    if (json is String) {
      final text = json.trim();
      if (text.isEmpty) return null;
      return Dua(id: fallbackId, arabic: text);
    }
    if (json is Map) {
      final map = json.map((k, v) => MapEntry(k.toString(), v));
      final arabic = _pickString(map, _arabicKeys);
      if (arabic == null) return null;
      return Dua(
        id: _pickInt(map, _idKeys) ?? fallbackId,
        arabic: arabic,
        title: _pickString(map, _titleKeys),
        transliteration: _pickString(map, _translitKeys),
        translation: _pickString(map, _translationKeys),
        reference: _pickString(map, _referenceKeys),
      );
    }
    return null;
  }

  /// Convenience constructor matching the conventional `fromJson` naming.
  /// Throws [FormatException] if the item is unusable.
  factory Dua.fromJson(Object? json, {int fallbackId = 0}) {
    final dua = tryParse(json, fallbackId: fallbackId);
    if (dua == null) throw FormatException('Invalid dua entry: $json');
    return dua;
  }

  static String? _pickString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  static int? _pickInt(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value.trim());
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  /// Text used for copy/share.
  String toShareText() {
    final parts = <String>[
      ?title,
      arabic,
      ?transliteration,
      ?translation,
      if (reference != null) '— $reference',
    ];
    return parts.join('\n\n');
  }

  @override
  bool operator ==(Object other) => other is Dua && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
