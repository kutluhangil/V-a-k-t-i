import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/sources/local_store.dart';

/// Selected category ids used to personalize the feed order (local-only, §14).
/// Empty = no preference; the feed keeps its natural order.
class InterestsController extends Notifier<Set<String>> {
  LocalStore get _store => LocalStore.instance;

  @override
  Set<String> build() {
    final stored = _store.get<List<dynamic>>(LocalStore.kInterests);
    return stored == null ? <String>{} : stored.map((e) => '$e').toSet();
  }

  Future<void> toggle(String categoryId) async {
    final next = {...state};
    if (!next.add(categoryId)) next.remove(categoryId);
    state = next;
    await _store.set(LocalStore.kInterests, next.toList());
  }
}

final interestsProvider =
    NotifierProvider<InterestsController, Set<String>>(InterestsController.new);
