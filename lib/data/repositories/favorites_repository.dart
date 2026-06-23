import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sources/local_store.dart';

/// Saved tip ids, persisted on-device in Hive (blueprint §6, §14).
/// State updates optimistically, then writes to disk.
class FavoritesController extends Notifier<Set<String>> {
  @override
  Set<String> build() => LocalStore.instance.favoriteIds.toSet();

  bool contains(String id) => state.contains(id);

  Future<void> toggle(String id) async {
    final next = {...state};
    final adding = !next.contains(id);
    if (adding) {
      next.add(id);
    } else {
      next.remove(id);
    }
    state = next;
    if (adding) {
      await LocalStore.instance.addFavorite(id);
    } else {
      await LocalStore.instance.removeFavorite(id);
    }
  }
}

final favoritesProvider = NotifierProvider<FavoritesController, Set<String>>(
  FavoritesController.new,
);
