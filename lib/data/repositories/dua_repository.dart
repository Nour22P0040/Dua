import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/dua.dart';

/// Result of loading the dua file. Never throws: on failure [duas] is empty
/// and [error] describes what went wrong (shown in the UI, logged in debug).
class DuaLoadResult {
  const DuaLoadResult(this.duas, {this.error});
  final List<Dua> duas;
  final String? error;
  bool get hasError => error != null;
}

/// Loads `assets/data/duas.json` once at startup and serves lookups.
class DuaRepository {
  DuaRepository._(this.result)
      : _byId = {for (final d in result.duas) d.id: d};

  static const assetPath = 'assets/data/duas.json';

  final DuaLoadResult result;
  final Map<int, Dua> _byId;

  List<Dua> get all => result.duas;
  bool get isEmpty => result.duas.isEmpty;
  Dua? byId(int id) => _byId[id];

  /// Reads and parses the asset. Safe to call before `runApp`.
  static Future<DuaRepository> load({AssetBundle? bundle}) async {
    try {
      final raw = await (bundle ?? rootBundle).loadString(assetPath);
      return DuaRepository._(parse(raw));
    } catch (e, st) {
      debugPrint('DuaRepository: failed to load $assetPath: $e\n$st');
      return DuaRepository._(DuaLoadResult(const [], error: e.toString()));
    }
  }

  /// Parses the raw JSON. Accepted root shapes:
  ///  * `[ ...items ]`
  ///  * `{ "duas": [ ...items ] }` (also `data`, `items`, `adhkar`)
  /// Items may be strings or objects — see [Dua.tryParse].
  @visibleForTesting
  static DuaLoadResult parse(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (e) {
      return DuaLoadResult(const [], error: 'Invalid JSON: ${e.message}');
    }

    List<Object?>? items;
    if (decoded is List) {
      items = decoded;
    } else if (decoded is Map) {
      for (final key in const ['duas', 'data', 'items', 'adhkar']) {
        if (decoded[key] is List) {
          items = decoded[key] as List;
          break;
        }
      }
      // Fallback: first list value in the object.
      items ??= decoded.values.whereType<List>().firstOrNull;
    }
    if (items == null) {
      return const DuaLoadResult([], error: 'No list of duas found in JSON');
    }

    final duas = <Dua>[];
    final usedIds = <int>{};
    var skipped = 0;
    for (var i = 0; i < items.length; i++) {
      final dua = Dua.tryParse(items[i], fallbackId: i + 1);
      if (dua == null) {
        skipped++;
        continue;
      }
      // Guarantee unique ids (they are used as notification payloads and
      // favorites keys). Duplicates get the next free id.
      var id = dua.id;
      while (usedIds.contains(id)) {
        id++;
      }
      usedIds.add(id);
      duas.add(id == dua.id
          ? dua
          : Dua(
              id: id,
              arabic: dua.arabic,
              title: dua.title,
              transliteration: dua.transliteration,
              translation: dua.translation,
              reference: dua.reference,
            ));
    }
    if (skipped > 0) debugPrint('DuaRepository: skipped $skipped bad entries');
    return DuaLoadResult(
      duas,
      error: duas.isEmpty ? 'The duas list is empty' : null,
    );
  }
}
