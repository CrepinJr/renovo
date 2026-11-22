import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/date_utils.dart';
import '../data/models/confession.dart';
import '../data/repositories/confession_repository.dart';
import 'confession_repository_provider.dart';

/// Modern Riverpod AsyncNotifier managing the list of confessions.
class ConfessionsNotifier extends AsyncNotifier<List<Confession>> {
  @override
  Future<List<Confession>> build() async {
    return ref.watch(confessionRepositoryProvider).getAllConfessions();
  }

  Future<void> refreshConfessions({bool cacheOnly = false}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return ref
          .read(confessionRepositoryProvider)
          .getAllConfessions(cacheOnly: cacheOnly);
    });
  }

  Future<ConfessionWriteStatus> addConfession({
    required DateTime date,
    required String parish,
    String? notes,
  }) async {
    final confession = Confession(
      date: RenovoDateUtils.normalizeDate(date),
      parish: parish,
      notes: notes,
    );
    final status = await ref
        .read(confessionRepositoryProvider)
        .insertConfession(confession);
    await refreshConfessions(cacheOnly: status == ConfessionWriteStatus.pending);
    return status;
  }

  Future<ConfessionWriteStatus> updateConfession(Confession confession) async {
    final status = await ref
        .read(confessionRepositoryProvider)
        .updateConfession(confession);
    await refreshConfessions(cacheOnly: status == ConfessionWriteStatus.pending);
    return status;
  }

  Future<ConfessionWriteStatus> deleteConfession(Confession confession) async {
    final status = await ref
        .read(confessionRepositoryProvider)
        .deleteConfession(confession);
    await refreshConfessions(cacheOnly: status == ConfessionWriteStatus.pending);
    return status;
  }
}

/// Main confessions provider.
final confessionsProvider =
    AsyncNotifierProvider<ConfessionsNotifier, List<Confession>>(
  ConfessionsNotifier.new,
);

/// Provider returning the most recent effective confession (by date), or null.
final latestConfessionProvider = Provider<Confession?>((ref) {
  final confessionsAsync = ref.watch(confessionsProvider);
  return confessionsAsync.when(
    data: (list) {
      if (list.isEmpty) return null;
      return list.first; // SQLite query orders by date DESC
    },
    loading: () => null,
    error: (e, st) => null,
  );
});

/// Map of normalized DateTime -> Confession for instant O(1) day inspection in calendar.
final confessionsMapProvider = Provider<Map<DateTime, Confession>>((ref) {
  final confessionsAsync = ref.watch(confessionsProvider);
  final map = <DateTime, Confession>{};

  confessionsAsync.whenData((list) {
    for (final c in list) {
      map.putIfAbsent(c.normalizedDate, () => c);
    }
  });

  return map;
});

/// Provider for distinct parish names for autocomplete suggestions.
final parishesProvider = FutureProvider<List<String>>((ref) async {
  ref.watch(confessionsProvider);
  return ref.watch(confessionRepositoryProvider).getDistinctParishes();
});
