import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/reminder_settings.dart';
import '../home/schedule_controller.dart';
import '../settings/settings_controller.dart';

/// Favorite dua ids, stored locally in shared_preferences.
final favoritesProvider =
    NotifierProvider<FavoritesController, Set<int>>(FavoritesController.new);

class FavoritesController extends Notifier<Set<int>> {
  @override
  Set<int> build() => ref.read(settingsRepositoryProvider).loadFavorites();

  bool isFavorite(int id) => state.contains(id);

  Future<void> toggle(int id) async {
    final next = Set<int>.of(state);
    if (!next.remove(id)) next.add(id);
    state = next;
    await ref.read(settingsRepositoryProvider).saveFavorites(next);
    // In "favorites only" mode the rotation pool changed → rebuild the batch.
    if (ref.read(reminderSettingsProvider).order == DuaOrder.favorites) {
      await ref.read(scheduleControllerProvider.notifier).refill();
    }
  }
}
